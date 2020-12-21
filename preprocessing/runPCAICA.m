function runPCAICA(h5Path,Fs,varargin)


%% OPTIONS

% options.windowsize=2000;
% options.dataset='mov';
options.diary=true;
options.plotFigure=true;
options.diary_name='diary';
options.verbose=true;
options.frameRange=[];

%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE


%% LOAD RAW DCMIG DATA
disps('Starting Neuron Demixing (PCAICA)')

[folderPath,fname,ext]=fileparts(h5Path);
if strcmpi(ext,'.h5')
    disps('h5 file detected')
else
    error('not a h5 or Tiff file')
end

meta=h5info(h5Path);
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

outputdir=fullfile(folderPath,'DemixingPCAICA',fname);
if ~exist(outputdir,'dir')
    mkdir(outputdir)
end

if options.diary
    diary(fullfile(outputdir,options.diary_name));
end

[mixedsig, mixedfilters, CovEvals] = CellsortPCA(h5Path,...
                                    options.frameRange, [], [], outputdir);

PCuse=20:100; % always removes the first component, usually background.
h=figure('defaultaxesfontsize',16,'color','w');
CellsortPlotPCspectrum(h5Path, CovEvals, PCuse);
if options.plotFigure
    savePDF(h,'Cellsort Plot PC spectrum',outputdir);%close;
end

% Step 3a: CellsortICA
mu=0.99; nIC=50;
[ica_sig, ica_filters] = CellsortICA(mixedsig, mixedfilters,...
                        CovEvals, PCuse, mu, nIC);

% Step 3b: CellsortICAplot
% load first 100 frames to compute average frame
movie=h5read(h5Path,dataset,[1 1 1],[mx my 100]);
MEAN_PROJECTION=mean(movie,3)';
f0=bpFilter2D(MEAN_PROJECTION,20,2,'parallel',false);
f0=f0';

if options.plotFigure
    h=figure('defaultaxesfontsize',16,'color','w');
    imshow(f0,[])
    title('Average Intensity - bandpassed')
    savePDF(h,'Average Intensity - bandpassed',outputdir);%close;
end

nUnits=nIC; % look at the first 10 ICs
mode='contour';
dt=1/Fs;
h=figure('defaultaxesfontsize',16,'color','w');
CellsortICAplot(mode, ica_filters(1:nUnits,:,:), ica_sig(1:nUnits,:), f0, [], dt) ;

if options.plotFigure
    savePDF(h,'ICAplot Template',outputdir);%close;
end

%%

savePath=fullfile(outputdir,strcat(fname,'_unitsPCAICA.mat'));
% Save the output data
if isempty(savePath)
    save(savePath,'ica_filters', 'ica_sig')
else
    savePath=strrep(savePath,'.mat','temp.mat');
    save(savePath,'ica_filters', 'ica_sig')
end

disps('PCAICA-based Demixing output succesfully saved')

% %%
% nSpikingCells=2;
% % IDs=[end-nSpikingCells+1:end];
% IDs=[9 10];
% spikes=zscore(ica_sig(IDs,:)');
% figure()
% plot(spikes)
%
% % for thres=6:0.5:8
% [spikeRaster]=plotSpikeRaster(cell_sig(end-9:end,:)',Fs,6);
% % end
% plotXCorrelogram(spikeRaster,Fs);
% % plotAutoCorrelogram(spikeRaster,Fs);

if options.diary
    diary off
end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s Demixing PCAICA: %s\n', datetime('now'),string);
        end
    end

end