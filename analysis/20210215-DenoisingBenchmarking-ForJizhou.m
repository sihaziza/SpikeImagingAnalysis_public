
%%
filePath='F:\GEVI_Spike\Preprocessed\Whiskers\m83\20201124\meas06';
fileName='m83_d201124_s06dualColorSlidePulsingLEDs-fps781-cR_moco.h5';

% filePath='F:\GEVI_Spike\DatasetAnalysisBenchmarking';
% fileName='yale_NDNF-VIP_moco.h5';

h5Path=fullfile(filePath,fileName);
meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

fs=781;

movie=h5read(h5Path,dataset,[1 1 1],[mx my numFrame]);

%%

% movie_dtr=runPhotoBleachingRemoval(movie,'samplingRate',fs,'lpCutOff',2);
% 
% tic;[movie_outSCh,~, ~] = denoisingLOSS_new(movie_dtr(:,1:236,:),...
%     'gridsize',59,'windowsize',numFrame,'ranks',100);timeSCh=toc;
tic;[movie_outTCh,~, ~] = denoisingLOSS_new(movie(:,1:236,1:23300),...
    'gridsize',-1,'windowsize',100,'ranks',100);timeTCh=toc;

% implay(mat2gray([movie_outSCh;movie_outTCh]))

% pathDNS=strrep(h5Path,'.h5','_dnsSChunk.h5');
% h5save(pathDNS, single(movie_outSCh), '/mov');
pathDNS=strrep(h5Path,'.h5','_dnsTChunk100.h5');
h5save(pathDNS, single(movie_outTCh), '/mov');
% timeSCh
timeTCh
% [NEW_WINDOW]=getBestWindow(mx, 50, 1)
%%
gridsizeX=round(mx/2);
startgridX=1:round(mx/2):mx
startgridY=1:round(my/4):my

dy=round(my/4);
for i=1:2
    for j=1:3
        

    end
end

positionX = [startgridX(k):min(startgridX(k)+gridsizeX-1,nx)];

%
%% Detrend the movie: detrend on movie average and apply

movie_dtr=runPhotoBleachingRemoval(movie,'samplingRate',fs,'lpCutOff',2);

binning=2;
movie_dtr_bin=imresize3(movie_dtr,[mx/binning my/binning size(movie_dtr,3)],'box');

%% Denoising the movie

%[movie_dtr_dns,~, ~] = denoisingLOSS_new(movie_dtr,'windowsize', 500, 'ranks', 50);

tic;
movie_dtr_bin_dns = denoisingStep(single(movie_dtr_bin), 250, 'DnCNN');
toc;

tic;
M=movie_dtr_bin_dns;
avgM=mean(M,3);
M=-M+2*avgM;
% M=(M-avgM)./avgM;
[spatial, temporal] = DecompNMF_ALS(M, 100);
toc;
%%
spatial=output.spatial;
temporal=output.temporal;
%%
nUnits=10;%size(temporal,2);
% decade=1;
figure(1)
for i=1:nUnits
subplot(nUnits,nUnits,[nUnits*(i-1)+1 nUnits*(i-1)+2])
imagesc(spatial(:,:,(decade-1)*nUnits+i))
ylabel(num2str((decade-1)*nUnits+i))
subplot(nUnits,nUnits,[nUnits*(i-1)+3 nUnits*i])
plot(temporal(:,(decade-1)*nUnits+i))
end
decade=decade+1;
%%
[~, boundbox] = autoCropImage(image, 'plot',true);

units=h5read(h5Path,dataset,[boundbox(2) boundbox(1) 2*Fs],[boundbox(4) boundbox(3)  numFrame-2*Fs+1]);

[units, trace,boundbox]=getUnitsROI(h5Path,781);
%%

id=[5 8 11 12 14 16 42 48]
dim=size(spatial);

figure(1)
for i=1:numel(id)
subplot(numel(id),numel(id),numel(id)*(i-1)+1)
S_filter=spatial(:,:,id(i));
S_filter=zscore(S_filter(:));
S_filter(S_filter<0.5)=0;
S_filter=reshape(S_filter,dim(1),dim(2));
imagesc(S_filter)
SF(:,:,i)=S_filter;
% imagesc(S_filter)
ylabel(strcat('n',num2str(id(i))))
subplot(numel(id),numel(id),[numel(id)*(i-1)+2 numel(id)*i])
plot(temporal(:,id(i)))
end

figure()
imshow([sum(SF,3)],[])
%% Binning for EXTRACT
% binning=2;
% movie_dtr_dns_bin=imresize3(movie_dtr_dns,[mx/binning my/binning size(movie_dns,3)],'box');


% pathDNS=strrep(h5Path,'.h5','_dns.h5');
% h5save(pathDNS, single(movie_dns), '/mov');

%%

f0=mean(movie_dtr,3);
f0_dns=mean(movie_dtr_dns,3);
f0_dns_bin=mean(movie_dtr_dns_bin,3);

montage({mat2gray(f0), mat2gray(f0_dns), mat2gray(f0_dns_bin)})

trace=getPointProjection(movie_dtr);
trace_dtr_dns=getPointProjection(movie_dtr_dns);
trace_dtr_dns_bin=getPointProjection(movie_dtr_dns_bin);

t=getTime(trace,fs);
figure()
plot(t,[trace trace_dtr_dns])

%% Demixing using EXTRACT
[output]=runEXTRACT(denoised_LESS,'polarityGEVI','neg');
M=-denoised_LESS+2*mean(denoised_LESS,3);

%Perform post-processing such as cell checking and further data analysis
output=(output.negative);
cell_check(output, M);

%% Demixing using PCAICA
pathDNSMoco=strrep(h5Path,'.h5','_dns_moco.h5');
runPCAICA(pathDNSMoco,fs);

%% 
figure()
plot(time,[trace tempExp])
plotPSD([trace temp tempExp],'FrameRate',Fs,'FreqBand',[0.5 100],'Window',1,'scaleAxis','linear');


%% trying unmixing on EXTRACT output with movie average wavelet fitlered as a ref
% All on native, non-denoised movie.

ref=getPointProjection(movie);
ref=wdenoise(double(ref));
 [x,status] = denoisingTrace(y,0.5e-6);
plot(time,[y x sh_bpFilter(y,[inf 50],Fs) wdenoise(y)])

%%
nUnits=size(output.spatial_weights,3);
for iUnit=1:nUnits-1
temp=full(output.spatial_weights(:,:,iUnit));
temp=imresize(temp,binning,'box');
trace_raw(:,iUnit)=getPointProjection(movie.*temp);
trace_dtr(:,iUnit)=getPointProjection(movie_dtr.*temp);
trace_dns(:,iUnit)=getPointProjection(movie_dtr_dns.*temp);
end

figure(1)
subplot(1,3,1)
plot(time,zscore(trace_raw)+linspace(0,3*nUnits,nUnits))
title('S-filter on Raw movie')
subplot(1,3,2)
plot(time,zscore(trace_dtr)+linspace(0,3*nUnits,nUnits))
title('S-filter on Detrended movie')
subplot(1,3,3)
plot(time,zscore(trace_dns)+linspace(0,3*nUnits,nUnits))
title('S-filter on Denoised movie')

coeffMap = calLocalCorrelation(movie);
imagesc(coeffMap)



