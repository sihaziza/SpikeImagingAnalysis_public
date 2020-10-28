%% READ ME - 
% Routine to extract spikes from in vivo data (dcimg file). 
% The main steps are:
%  - Loading
%  - Motion Correction
%  - Denoising (svd, PMD)
%  - Demixing (PCAICA, CNMFe, EXTRACT)

%% LOAD RAW DCMIG DATA
% dcimgPath='P:\GEVI_Spike\Raw\Spontaneous\m81\20200131\meas03';
dcimgPath='P:\GEVI_Spike\Raw\Visual\m81\20200416\meas00';
[h5pathG,h5pathR,summary] = loading(dcimgPath,'framerange',[1 1000],'binning',1); % save h5

G=h5read(h5pathG,'/mov');
R=h5read(h5pathR,'/mov');

imshow(R(:,:,1),[])
%% CORRECT MOVIE FROM MOTION ARTEFACT

savepath='F:\GEVI_Spike\Preprocessed\Visual\m81\20200416\meas01';
% savepath='F:\GEVI_Spike\Preprocessed\Spontaneous\m81\20200131\meas03';
Gmoco=Moco2Movies_v2(G,[],[1 25]);
Rmoco=Moco2Movies_v2(R,[],[1 25]);

%%
[croppedImage, roi] = autoCropImage(Gmoco(:,:,1),'verbose',1);
Mtrim=Gmoco(roi(2):roi(4)+roi(2),roi(1):roi(3)+roi(1),:);

        h5create(fullfile(savepath,'mocoGcrop.h5'),'/G',size(Mtrim),'Datatype','single');
        h5create(fullfile(savepath,'mocoR.h5'),'/R',size(Rmoco),'Datatype','single');
        h5write(fullfile(savepath,'mocoGcrop.h5'), '/G',Mtrim);
        h5write(fullfile(savepath,'mocoR.h5'), '/R',Rmoco);
        
  fn=fullfile(savepath,'mocoGcrop.h5');      


%% DENOISE MOVIES
% to be implemented

%% DEMIX THE SIGNAL SOURCES
% fn='I:\GEVI_Spike\Spontaneous\m82\20200724\meas00\5mm-V1-retroAceVarnam--BL100-GL50-fps401-cG_moco_bp.tif';
% fn=fullfile(savepath,'mocoGcrop.tif');
% fn='P:\GEVI_Spike\Preprocessed\Spontaneous\m82\20200130\meas03\spike-ace-varnam-trigstart-fov2-1000Hz--BL100-fps401-cG_dns_SVD_G.h5';
path='F:\GEVI_Spike\Preprocessed\Spontaneous\m82\20200130\meas03';
fileName='spike-ace-varnam-trigstart-fov2-1000Hz--BL100-fps401-cG_moco.h5';
fn=fullfile(path,fileName);
% spike-ace-varnam-trigstart-fov2-1000Hz--BL100-fps401-cG_moco.h5';
h5info(fn)
% imfinfo(fn);
[~,fname,ext]=fileparts(fn);
savepath=fileparts(fn);
Fs=1000;

% Mtrim=h5read('C:\Users\Simon\Desktop\U01Grant_Mark_20200418\Movie_Spike\MoCoDataCropv2.h5','/movie');
% MEAN_PROJECTION=mean(movie_outLOSS,3)';
% imshow(bpFilter2D(MEAN_PROJECTION,20,1),[])
% % so long and bug...
% parfor iFrame=1:size(Mtrim,3)
%   tiff = double(Mtrim(:, :, iFrame));
% %   imshow(tiff,[])
% %   outputFileName = sprintf('smb%d.tiff', iFrame);
%   imwrite(tiff,'test.tiff','WriteMode', 'append')
% end

%% Step 1: CellsortPCA

flims=[];
nPCs=50;
dsamp=[];

outputdir=fullfile(savepath,'PCAICA');
if ~exist(outputdir,'dir')
    mkdir(outputdir)
end

badframes=[];

[mixedsig, mixedfilters, CovEvals, covtrace, movm, ...
    movtm] = CellsortPCA(fn, flims, nPCs, dsamp, outputdir, badframes);

imshow(movm,[])
%% Step 2a: CellsortChoosePCs
[PCuse] = CellsortChoosePCs(fn, mixedfilters);

%% Step 2b: CellsortPlotPCspectrum
CellsortPlotPCspectrum(fn, CovEvals, PCuse);

%% Step 3a: CellsortICA
mu=0.99;
nIC=30;
% ica_A_guess=std(Mtrim,[],3);
% ica_A_guess(ica_A_guess.^2<0.8*max(ica_A_guess(:).^2))=0;
% imshow(ica_A_guess,[]);
termtol=[];
maxrounds=1000;
  [ica_sig, ica_filters, ica_A, numiter] = CellsortICA(mixedsig, ...
    mixedfilters, CovEvals, PCuse, mu, nIC, [], termtol, maxrounds);
%% Step 3b: CellsortICAplot
mode='contour';
movie=h5read(fn,'/mov');
MEAN_PROJECTION=mean(movie,3)';
figure();imshow(bpFilter2D(MEAN_PROJECTION,20,1),[])
f0=MEAN_PROJECTION';
%%
% f0=max(SF,[],3);
tlims=[]; 
dt=1/Fs; 
ratebin=[]; 
plottype=[];
ICuse=[];
spt=[];
spc=[];
% range=[];
range=1:nIC;
figure()
CellsortICAplot(mode, ica_filters(range,:,:), ica_sig(range,:,:), f0, tlims, dt, ratebin, plottype, ICuse, spt, spc) ;

%%


for i=1:nIC
plot(permute(ica_sig,[2 3 1])+linspace(1,nIC,nIC))
end
%%
range=[1 3 5:12];

figure()
for iSF=1:length(range)   
sf00=squeeze(ica_filters(range(iSF),:,:));
sf00=sf00-median(sf00,'all');
thres=1;
sf00(sf00<thres)=0;
SF(:,:,iSF)=wiener2(normalize(sf00,'range',[0 1]),[10 10]);
end

imshow(max(SF,[],3),[])
%%
% colord=[         0         0    1.0000
%     0    0.4000         0
%     1.0000         0         0
%     0    0.7500    0.7500
%     0.7500         0    0.7500
%     0.8, 0.5, 0
%     0         0    0.5
%     0         0.85      0];

h=figure(1);
for i=1:30
%     subplot(3,10,i)
plotPSD(permute(ica_sig(i,:,:),[2 3 1]),...
    'FrameRate',Fs,'Window',3,'FreqBand',[1 120],'figureHandle',h,'scaleAxis','log');
hold on

% set(gca,'color','k')
end

% legend(cellstr(num2str([1:10]')))
% set(gca,'ColorOrder',colord)
% [mx,my,mz]=size(SF);
% temp=reshape(SF,mx*nIC,my*5);
% implay(SF)
%% Step 4a: CellsortSegmentation
smwidth=3;
thresh=1;
arealims=[10 20];
plotting=1;
[ica_segments, segmentlabel, segcentroid] = CellsortSegmentation(ica_filters(range,:,:), smwidth, thresh, arealims, plotting) ;
  
%% Step 4b:CellsortApplyFilter
movm=f0;
subtractmean=1;
cell_sig = CellsortApplyFilter(fn, ica_segments, flims, movm, subtractmean) ;

figure()
plot(cell_sig')
%% Step 5:CellsortFindspikes
deconvtau=0.01;
normalization=1;
[spmat, spt, spc, zsig] = CellsortFindspikes(ica_sig, thresh, dt, deconvtau, normalization) ;


%%
figure(1)
subplot(311)
imagesc(spmat')
subplot(3,1,[2 3])
d=linspace(1,size(zsig,2),size(zsig,2));
plot(normalize(zsig,'range',[0 1])-d,'linewidth',1.5)


