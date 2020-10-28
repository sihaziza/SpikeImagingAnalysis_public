
tic;
%% Routine 20200715 >  Test with all defaults
dcimgPath='D:\GEVI_Wave\Spontaneous\mControl1\20200724\meas01';
filenameG='5mm-V1-YFPTomato--BL8-fps121-cG.dcimg';

filepathG=fullfile(dcimgPath,filenameG);
filepathR = strrep(filepathG,'cG','cR');
filepathR = strrep(filepathR,'D:\','E:\');

[movieG,~,~]=loadDCIMG(filepathG,[1000, 1000]);
[movieR,~,~]=loadDCIMG(filepathR,[1000, 1000]);

figure()
subplot(121)
imshow(movieG,[])
subplot(122)
imshow(fliplr(movieR),[])

fprintf('Green max %2.0f | Red max %2.0f \n', max(movieG(:)), max(movieR(:)));

%% SET EXPORT PATH (define all necessary pointers)
[allPaths]=setExportPath(dcimgPath); % create all path for canonical steps

%% GET METADATA
[metadata]=getRawMetaData(allPaths,...
     'savePath',allPaths.pathDiagLoading,...
     'softwareBinning',4); 
 
% does not work for old recording ORCA flash

%% LOADING
[summaryLoading] = loading(allPaths,...
    'frameRange',[1000 1010],...
    'cropROI',metadata.ROI,...
    'binning',metadata.softwareBinning);

%% REGISTRATION
V=h5read(allPaths.h5PathG,'/mov');
R=h5read(allPaths.h5PathR,'/mov');

[Vreg,Rreg,summaryRegistration] = registration(V,R,allPaths,...
    'BandPx',metadata.vectorBandPassFilter);

%% MOTION CORRECTION
[Vcorr,Rcorr,summaryMotionCorr] = motionCorr(Vreg,Rreg,allPaths,...
    'BandPx',metadata.vectorBandPassFilter);

%% UNMIXING
[Vumx,coeff,summaryUnmixing] = unmixing(Vcorr,Rcorr,allPaths,...
    'method','rlr','type','local');

%%
toc;