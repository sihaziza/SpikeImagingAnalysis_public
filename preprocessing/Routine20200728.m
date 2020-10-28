
tic;
%% Routine 20200715 >  Test with all defaults
% dcimgPath='D:\GEVI_Spike\Spontaneous\m81\20200724\meas00';
% D:\GEVI_Spike\Spontaneous\m78\20200724\meas00

root='D:\GEVI_Spike\Spontaneous';
mouse=[78 81 82];
date='20200724';
measurements=[2 3 4];

k=1;
for iMouse=1:3
    for iMeas=1:measurements(iMouse)
        dcimgPath{k}=fullfile(root,...
            strcat('m',num2str(mouse(iMouse))),...
            date,...
            strcat('meas0',num2str(iMeas-1)));
%         disp(dcimgPath)
        k=k+1;
    end
end

% filenameG='5mm-V1-retroAceVarnam--BL30-GL100-fps401-cG.dcimg';
% 
% filepathG=fullfile(dcimgPath,filenameG);
% filepathR = strrep(filepathG,'cG','cR');
% filepathR = strrep(filepathR,'D:\','E:\');
% 
% [movieG,~,~]=loadDCIMG(filepathG,[1 10000]);
% [movieR,~,~]=loadDCIMG(filepathR,[1000, 1000]);
% [~,summary_loadG]=loadDCIMGchunks(allPaths.dcimgPathG,...
%     'binning',1,...
%     'cropROI',options.cropROI.greenChannel,...
%     'frameRange',options.frameRange,...
%     'h5Path',allPaths.h5PathG);
% figure()
% subplot(121)
% imshow(movieG,[])
% subplot(122)
% imshow(fliplr(movieR),[])
% 
% fprintf('Green max %2.0f | Red max %2.0f \n', max(movieG(:)), max(movieR(:)));

% %%
% % J=imcrop;
% % temp=(J);
% imshow(bpFilter2D(double(movieG),10,3),[])
% figure()
% for i=1:4
%     for j=1:5
% temp=bpFilter2D(J,10*i,j);
% subplot(4,5,j+5*(i-1))
% imshow(temp,[])
%     end
% end

for iFile=1:length(dcimgPath)
% SET EXPORT PATH (define all necessary pointers)
[allPaths]=setExportPath(dcimgPath,...
    'export_folder',strrep(dcimgPath,'D:\','I:\')); % create all path for canonical steps

% GET METADATA
[metadata]=getRawMetaData(allPaths,...
     'savePath',allPaths.pathDiagLoading,...
     'softwareBinning',1); 
 metadata.vectorBandPassFilter=[3 10];
% does not work for old recording ORCA flash

% LOADING
[summaryLoading] = loading(allPaths,...
    'frameRange',[1 20000],...
    'cropROI',metadata.ROI,...
    'binning',metadata.softwareBinning);

% REGISTRATION
V=h5read(allPaths.h5PathG,'/mov');
R=h5read(allPaths.h5PathR,'/mov');

[Vreg,Rreg,summaryRegistration] = registration(V,R,allPaths,...
    'BandPx',metadata.vectorBandPassFilter);

% MOTION CORRECTION
[Vcorr,Rcorr,summaryMotionCorr] = motionCorr(Vreg,Rreg,allPaths,...
    'BandPx',metadata.vectorBandPassFilter);
end

%% UNMIXING
[Vumx,coeff,summaryUnmixing] = unmixing(Vcorr,Rcorr,allPaths,...
    'method','rlr','type','global','conditioning',true,'renderMovie',true,...
    'fps',metadata.fps);

%% DEMIXING
[spatialFilter,tempFilter,summaryDemixing] = ...
                demixing(Vcorr,allPaths,'method','pcaica');
% other method > CNMFe, CellMax, Extract, PMD...

%%
toc;