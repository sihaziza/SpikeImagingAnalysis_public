function runPCAICA(h5Path,Fs,varargin)
%% READ ME -
% Routine to extract spikes from in vivo data (dcimg file).
% The main steps are:
%  - Loading
%  - Motion Correction
%  - Denoising (svd, PMD)
%  - Demixing (PCAICA, CNMFe, EXTRACT)
%
% \\\\TO DO////
% PSD plot for each ICs
% adapted spikes detection
% save figures: average movie / contours / spike traines /

%% OPTIONS
% [options]=defaultOptionsMotionCorr;
% options.windowsize=2000;
% options.dataset='mov';
options.diary=true;
options.plotFigure=true;
options.diary_name='diary';
options.verbose=true;
options.frameRange=[];
options.cropping=false;
options.h5Crop=[];
%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
% [summaryMotionCorr]=outputSummaryMotionCorr(options);
%


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

% if isempty(options.h5Crop)
%     h5cropIndex.Start=[1 1];
%     h5cropIndex.Count=[mx my];
% else
%     h5cropIndex=options.h5Crop;
% end

outputdir=fullfile(folderPath,'DemixingPCAICA',fname);
if ~exist(outputdir,'dir')
    mkdir(outputdir)
end

if options.diary
    diary(fullfile(outputdir,options.diary_name));
end

[mixedsig, mixedfilters, CovEvals, covtrace, movm, ...
    movtm] = CellsortPCA(h5Path, options.frameRange, [], [], outputdir, []);

% [PCuse] = CellsortChoosePCs(fn, mixedfilters);
PCuse=1:50; % always removes the first 3 components.
h=figure('defaultaxesfontsize',16,'color','w');
CellsortPlotPCspectrum(h5Path, CovEvals, PCuse);
if options.plotFigure
    export_figure(h,'Cellsort Plot PC spectrum',outputdir);close;
end

% Step 3a: CellsortICA
mu=0.95; nIC=10;
[ica_sig, ica_filters, ica_A, numiter] = CellsortICA(mixedsig, ...
    mixedfilters, CovEvals, PCuse, mu, nIC);
% Step 3b: CellsortICAplot
%load first 100 frames to compute average frame

% epoch=100;
movie=h5read(h5Path,dataset,[1 1 1],[mx my 100]);
MEAN_PROJECTION=mean(movie,3)';
f0=bpFilter2D(MEAN_PROJECTION,20,2);
f0=f0';
% imcrop
if options.plotFigure
    h=figure('defaultaxesfontsize',16,'color','w');
    imshow(f0,[])
    export_figure(h,'Average Movie',outputdir);close;
end
% figure(3);imshow(fliplr(f0),[])

nUnits=10; % look at the first 10 ICs
mode='contour';
dt=1/Fs;
h=figure('defaultaxesfontsize',16,'color','w');
CellsortICAplot(mode, ica_filters(1:nUnits,:,:), ica_sig(1:nUnits,:), f0, [], dt) ;

if options.plotFigure
    %     title('Template for motion correction')
    export_figure(h,'ICAplot Template',outputdir);%close;
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
%%
% % h=figure(1);
% % for i=1:30
% %     subplot(5,6,i)
% % plotPSD(permute(ica_sig(i,:,:),[2 1]),...
% %     'FrameRate',Fs,'Window',3,'FreqBand',[1 120],'figureHandle',h,'scaleAxis','linear');
% % % hold on
% % % set(gca,'color','k')
% % end
% %
%
%
% % legend(cellstr(num2str([1:10]')))
% % set(gca,'ColorOrder',colord)
% % [mx,my,mz]=size(SF);
% % temp=reshape(SF,mx*nIC,my*5);
% % implay(SF)
% % Step 4a: CellsortSegmentation
% smwidth=3;
% thresh=2.5;
% arealims=[20 50];
% plotting=0;
% [ica_segments, segmentlabel, segcentroid] = CellsortSegmentation(ica_filters, smwidth, thresh, arealims, plotting) ;
%
% % Step 4b:CellsortApplyFilter
% movm=f0;
% subtractmean=1;
% cell_sig = CellsortApplyFilter(fn, ica_segments, flims, movm, subtractmean) ;
% % end
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
%
%
% %% Step 5:CellsortFindspikes
% thresh=1;
% deconvtau=0.5;
% normalization=1;
% [spmat, spt, spc, zsig] = CellsortFindspikes(ica_sig(end-2:end,:), thresh, dt, deconvtau, normalization) ;
%
% figure(1)
% subplot(311)
% imagesc(spmat')
% subplot(3,1,[2 3])
% d=linspace(1,size(zsig,2),size(zsig,2));
% plot(normalize(zsig,'range',[0 1])-d,'linewidth',1.5)
if options.diary
    diary off
end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s Demixing PCAICA: %s\n', datetime('now'),string);
        end
    end

end