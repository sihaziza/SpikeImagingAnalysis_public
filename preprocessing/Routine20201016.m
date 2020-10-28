%% READ ME -
% Routine to extract spikes from in vivo data (dcimg file).
% The main steps are:
%  - Loading
%  - Motion Correction
%  - Denoising (svd, PMD)
%  - Demixing (PCAICA, CNMFe, EXTRACT)

%% LOAD RAW DCMIG DATA
% dcimgPath='P:\GEVI_Spike\Raw\Spontaneous\m81\20200131\meas03';

experimentPath='F:\GEVI_Spike\Preprocessed\Visual8Angles\m82\20201026';
folder=dir(fullfile(experimentPath, 'meas*')); % G always comes before R
folderName=[];k=1;
for iFolder=1:length(folder)
    if strlength(folder(iFolder).name)==6
        folderName{k}=folder(iFolder).name;
        k=k+1;
    end
end
%EXPERIMENT PERFORMED AT:

Fs=500;
                
for iFolder=1:length(folderName)
    try
        fileName=dir(fullfile(fullfile(experimentPath,folderName{iFolder}), '*_moco.h5')); % G always comes before R
        
        for iFile=1:2
            try
                fn=fullfile(fileName(iFile).folder,fileName(iFile).name);
%                 [h5cropStart,h5cropCount,imcropRect]=h5movieCropping(fn);
                runPCAICA(fn,Fs)
            catch
                fprintf('something wrong with the file %s \n',fn)
            end
        end
%         fileName=dir(fullfile(fullfile(experimentPath,folderName{iFolder}), '*_dns*')); % G always comes before R
%         
%         for iFile=1:2
%             try
%                 fn=fullfile(fileName(iFile).folder,fileName(iFile).name);
%                 runPCAICA(fn,Fs)
%             catch
%                 fprintf('something wrong with the file %s \n',fn)
%             end
%         end
%         
    catch
        fprintf('something wrong with the folder %s \n',folderName{iFolder})
    end
end

%%
h5info(fn)
[~,fname,ext]=fileparts(fn);
savepath=fileparts(fn);

outputdir=fullfile(savepath,'PCAICA');
if ~exist(outputdir,'dir')
    mkdir(outputdir)
end

% flims=[]; nPCs=50;
[mixedsig, mixedfilters, CovEvals, covtrace, movm, ...
    movtm] = CellsortPCA(fn, [1 10*Fs], [], [], outputdir, []);

% [PCuse] = CellsortChoosePCs(fn, mixedfilters);
PCuse=5:30; % always removes the first components.
CellsortPlotPCspectrum(fn, CovEvals, PCuse);

% Step 3a: CellsortICA
mu=0.95; nIC=20;
[ica_sig, ica_filters, ica_A, numiter] = CellsortICA(mixedsig, ...
    mixedfilters, CovEvals, PCuse, mu, nIC);
% Step 3b: CellsortICAplot
mode='contour';
movie=h5read(fn,'/mov');
MEAN_PROJECTION=mean(movie,3)';
f0=bpFilter2D(MEAN_PROJECTION,20,2);
f0=f0';figure(2);imshow(f0,[])
% figure(3);imshow(fliplr(f0),[])

tlims=[];
dt=1/Fs;
figure()
CellsortICAplot(mode, ica_filters, ica_sig, f0, [], dt) ;
%         catch
%    disp(strcat('failed case for meas0',num2str(iMeas)));
%     end
% end

%%

savePath=strrep(fn,'.h5','_unitsPCAICA.mat');
% Save the output data
if isempty(savePath)
    save(savePath,'ica_filters', 'ica_sig')
else
    savePath=strrep(savepath,'.mat','temp.mat');
    save(savePath,'ica_filters', 'ica_sig')
end
%%
% h=figure(1);
% for i=1:30
%     subplot(5,6,i)
% plotPSD(permute(ica_sig(i,:,:),[2 1]),...
%     'FrameRate',Fs,'Window',3,'FreqBand',[1 120],'figureHandle',h,'scaleAxis','linear');
% % hold on
% % set(gca,'color','k')
% end
%


% legend(cellstr(num2str([1:10]')))
% set(gca,'ColorOrder',colord)
% [mx,my,mz]=size(SF);
% temp=reshape(SF,mx*nIC,my*5);
% implay(SF)
% Step 4a: CellsortSegmentation
smwidth=3;
thresh=2.5;
arealims=[20 50];
plotting=0;
[ica_segments, segmentlabel, segcentroid] = CellsortSegmentation(ica_filters, smwidth, thresh, arealims, plotting) ;

% Step 4b:CellsortApplyFilter
movm=f0;
subtractmean=1;
cell_sig = CellsortApplyFilter(fn, ica_segments, flims, movm, subtractmean) ;
% end
%%
nSpikingCells=2;
% IDs=[end-nSpikingCells+1:end];
IDs=[9 10];
spikes=zscore(ica_sig(IDs,:)');
figure()
plot(spikes)

% for thres=6:0.5:8
[spikeRaster]=plotSpikeRaster(cell_sig(end-9:end,:)',Fs,6);
% end
plotXCorrelogram(spikeRaster,Fs);
% plotAutoCorrelogram(spikeRaster,Fs);
%% \\\\TO DO////
% PSD plot for each ICs
% adapted spikes detection
% save figures: average movie / contours / spike traines /

%% do logical sparse matrix

%%
% xcorr/autocorr...
%     corrcoef(double(spikes))
%% Step 5:CellsortFindspikes
thresh=1;
deconvtau=0.5;
normalization=1;
[spmat, spt, spc, zsig] = CellsortFindspikes(ica_sig(end-2:end,:), thresh, dt, deconvtau, normalization) ;

figure(1)
subplot(311)
imagesc(spmat')
subplot(3,1,[2 3])
d=linspace(1,size(zsig,2),size(zsig,2));
plot(normalize(zsig,'range',[0 1])-d,'linewidth',1.5)

