
function [output]=getSpikesAllNeurons(path)
% path should contain the '*_clean.mat' structure fom EXTRACT and after
% manual clean up.
% the output is the updated strucutre with the spikeRaster and metadata
% stimulus TTL, speed is requested
% options.
if ~contains(path,'_clean.mat')
    cleanExtractPath=dir(fullfile(path,'*_clean.mat'));
    load(fullfile(cleanExtractPath.folder,cleanExtractPath.name),'output');
    % assign savePath
    options.savePath=cleanExtractPath.folder;
    outputSavePath=strrep(fullfile(cleanExtractPath.folder,cleanExtractPath.name),'.mat','_spikes.mat');
else
    load(path,'output');
    % assign savePath
    pathParts=strsplit(path,filesep);
    filename=strrep(pathParts{end},'_','-');
    filename=erase(filename,'.mat');
    options.savePath=fullfile(pathParts{1:end-1});
    outputSavePath=strrep(path,'.mat','_spikes.mat');
end

disp(output)

if isempty(output.cellID)
    return;
end

% Get Spatial&Temporal filters
[S,T,map,binaryMap]=getCellSTfilters(output);
output.SpatialUnits=S;
output.TimeUnits=T;

% Load the original movie to generate the reference trace
if ~contains(path,'_clean.mat')
    rootPath=fullfile(pathParts{1:end-2});
    moviePath=fullfile(rootPath,[pathParts{end} '.h5']);
    metaPath=fullfile(rootPath,'metadata.mat');
    load(metaPath,'metadata');
else
    rootPath=fullfile(pathParts{1:end-3});
    moviePath=fullfile(rootPath,[pathParts{end-1} '.h5']);
    metaPath=fullfile(rootPath,'metadata.mat');
    load(metaPath,'metadata');
end

fs=metadata.fps;
ttl=metadata.TTL;
loco=metadata.Locomotion;
% [displacement,speed,locoRestTTL,~]=getMouseSpeed(loco,fs);

% Generate the local reference
disp('Loading moving for local referencing...')
data=h5load(moviePath);
dim=size(data);
if dim(1)~=size(map,1)
    binning=round(dim(1)/size(map,1));
    data=imresize3(data,[dim(1)/binning dim(2)/binning dim(3)],'box');
end
avgData=mean(data,3);
negatif=avgData.*imcomplement(binaryMap);

figH=figure('Name','Unmixing Summary','DefaultAxesFontSize',12,'color','w');
subplot(211)
imshow(map,[])
hold on
plot_cells_overlay(S,[],3,0.5)
hold off
title('Spatial filters')
subplot(212)
imshow(negatif,[])
title('Mask for local referencing')

if options.savePath
    savePDF(figH,[filename '_Spatial filters and Mask'],options.savePath)
    disp('-Spatial filters and Mask- Figure successfully saved...')
end

%% Remove motion artefacts from time traces
disp('Removing motion artefact using ICA...')
options.localReference=true;
nNeuron=min(size(T));
Tumx=zeros(size(T));

% unmixing using band-pass filtered [20-50Hz] to remove oscillations.
dataNeg=data.*imcomplement(binaryMap);
ref=getPointProjection(dataNeg);ref(1)=ref(2);
ref=runPhotoBleachingRemoval(ref,'samplingRate',fs)';
ref=wdenoise(double(ref),2)-1;

for iTrace=1:nNeuron
    try
        input=T(:,iTrace);
        if options.localReference
            [xa,ya]=alignsignals(input,ref,round(1/50*fs),'truncate');
            [Tumx(:,iTrace),~]=runFastICA(xa,ya);
        else
            ref= sh_bpFilter(input,[25 45],fs);
            Tumx(:,iTrace)=input-ref;
        end
    catch
    end
end
% plotPSD(input,'FrameRate',600,'FreqBand',[0.1 100],'Window',1);
% plot([input ref Tumx])
%    Tumx=T-sh_bpFilter(T,[25 40],fs);
output.umxTrace=Tumx;
%%
spacing=0:0.04:0.04*size(T,2);
xl=find(diff(ttl)==1,1,'first')/fs;
trange=[xl-1 xl+4];
figH=figure('Name','Unmixing Summary','DefaultAxesFontSize',12,'color','w');
subplot(211)
time=getTime(ttl,fs);
plot(time,wdenoise(double([T ref]),2)+spacing)
hold on
plot(time,rescale(ttl,0,spacing(end)),'--k')
hold off
xlim(trange)
xlabel('Time (s)')
ylabel('dF/F (%)')
title('Before local unmixing')

subplot(212)
time=getTime(ttl,fs);
plot(time,wdenoise(double([Tumx ref]),2)+spacing)
hold on
plot(time,rescale(ttl,0,spacing(end)),'--k')
hold off
title('After local unmixing')
xlim(trange)
xlabel('Time (s)')

if options.savePath
    savePDF(figH,[filename '_Unmixing Summary'],options.savePath)
    disp('Unmixing Summary Figure successfully saved...')
end

%% GET BEST PARAMETERS MLspikes

disp('Estimating MLspikes parameters...')
amplitude=zeros(1,nNeuron);
tau=zeros(1,nNeuron);
baseline=zeros(1,nNeuron);
noise=zeros(1,nNeuron);

for iTrace=1:nNeuron
    try
        trace=Tumx(:,iTrace);
        [amplitude(:,iTrace),tau(:,iTrace),baseline(:,iTrace),noise(:,iTrace)]=estimateSpikeParam(trace,fs);
    catch
    end
end


%% RUN MLSPIKES

% spikeRaster=zeros(size(T));
% fit=zeros(size(T));
% drift=zeros(size(T));
% 
% for iTrace=1:nNeuron
%     try
%         disp(['running MLspikes for neuron #' num2str(iTrace) ' ...'])
%         % make sure to get a baseline of 1
%         trace=Tumx(:,iTrace);
%         trace=trace-mean(trace)+1;
%         
%         % (set physiological parameters)
%         par.a = amplitude(:,iTrace); % DF/F for one spike
%         par.tau = tau(:,iTrace); % decay time constant (second)
%         
%         % (set noise parameters)
%         par.finetune.sigma = noise(:,iTrace); % noise level
%         par.drift.parameter = baseline(:,iTrace); % baseline level
%         
%         [spikeRaster(:,iTrace), ~, fit(:,iTrace), drift(:,iTrace)]=...
%             inferSpikeTrain(trace,fs,'MLspikeParam',par);
%     catch
%     end
% end
% %%
% output.MLspikeParam.a=a;
% output.MLspikeParam.tau=tau;
% output.fit=fit;
% output.spikeRaster=spikeRaster;
% output.loco=loco;
% output.ttl=ttl;
% output.fs=fs;
% 
% if options.savePath
%     save(outputSavePath,'output')
%     disp('Data successfully saved...')
% end
% 
% close all
end


