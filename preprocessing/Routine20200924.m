
tic;
%% Routine 20200715 >  Test with all defaults
k=1;
for iMeas=10:14
    try
 meas=strcat('meas',num2str(iMeas));
h5Path=fullfile('F:\GEVI_Spike\Raw\Visual8Angles\m78\20201012',meas);   
    fileName=dir(fullfile(h5Path, '*.dcimg')); % G always comes before R

[fileNameG, fileNameR]=fileName.name; % for saving other outputs

options.dcimgPathG=fullfile(h5Path,fileNameG);
options.dcimgPathR=fullfile(h5Path,fileNameR);


% %%
% filenameG='spike-ace-varnam-trigstart-fov2-1000Hz--BL100-fps401-cG.dcimg';
% % dcimgPath='P:\GEVI_Spike\Raw\Visual8Angles\m78\20201012\meas01';
% % filenameG='m78_d201012_s01_--fps500-cG.dcimg';
% filepathG=fullfile(dcimgPath,meas,filenameG);
% filepathR = strrep(filepathG,'cG','cR');
% % filepathR = strrep(filepathR,'D:\','E:\');
frame=1;
[movieG,~,~]=loadDCIMG(options.dcimgPathG,[frame, frame]);
[movieR,~,~]=loadDCIMG(options.dcimgPathR,[frame, frame]);

figure()
subplot(121)
imshow(movieG,[])
subplot(122)
imshow(fliplr(movieR),[])

fprintf('Green max %2.0f | Red max %2.0f \n', max(movieG(:)), max(movieR(:)));

%
filepathTTL = strrep(options.dcimgPathG,'.dcimg','_framestamps 0.txt');
[TTL]=importdata(filepathTTL);
loco=TTL.data(:,2);
stim=TTL.data(:,4);
fluctuationLED=TTL.data(:,5:6);
plot(zscore([loco stim]))
% plot(zscore(fluctuationLED))

temp=diff(stim);
plot(temp)
frame0=find(diff(stim)==1,1,'first');
frameX=find(diff(stim)==-1,1,'last');
baseline=0.5; %in sec
fps=500; % in Hz

frameRange=[frame0-baseline*fps frameX+baseline*fps-1];
temp=stim(frameRange(1):frameRange(2));plot(temp,'o')


% %% SET EXPORT PATH (define all necessary pointers)
[allPaths]=setExportPath(h5Path); % create all path for canonical steps

% %% GET METADATA
[metadata]=getRawMetaData(allPaths,...
     'savePath',allPaths.pathDiagLoading,...
     'softwareBinning',1,...
     'autoCropping',false); 
 
% does not work for old recording ORCA flash

% %% LOADING
% frameRange=[frame inf];
[summaryLoading] = loading(allPaths,...
    'frameRange',frameRange,...
    'cropROI',metadata.ROI,...
    'binning',metadata.softwareBinning);
% 
% % %% REGISTRATION
% V=h5read(allPaths.h5PathG,'/mov');
% R=h5read(allPaths.h5PathR,'/mov');

% make a small snippet to find the best BPF parameters
% V=single(V(2:end-1,2:end-1,:));
% R=single(R(2:end-1,2:end-1,:));
% 
% [Vreg,Rreg,summaryRegistration] = registration(V,R,allPaths,...
%     'BandPx',metadata.vectorBandPassFilter);
% clear V R
% %% MOTION CORRECTION

% tempName = strrep(allPaths.h5PathG,'cG.h5','cG_reg.h5');
% dim=h5info(tempName);
% dim=dim.Datasets.Dataspace.Size;
% start=[1 1 1]; 
% count=[dim(1) dim(2) 5000]; 
% 
% Vreg=h5read(tempName,'/mov',start,count); 
% tempName = strrep(tempName,'cG','cR');
% Rreg=h5read(tempName,'/mov',start,count); 
% %%
% imshow(Vreg(:,:,1),[])
%     mov=bpFilter2D(Vreg(:,:,1),40,2);
% imshow(mov,[])
% 
% % Vtest=padarray(Vreg,[1 1],'replicate','both');
% % Rtest=padarray(Rreg,[1 1],'replicate','both');
% metadata.vectorBandPassFilter=[1 10]; % just for this spike dataset (25x obj.)
% [Vcorr,summaryMotionCorr] = motionCorr1Movie(V,allPaths,...
%     'BandPx',metadata.vectorBandPassFilter,'us_fac',10);
% clear V
% % %% DENOISING
% tic;
% % spike-ace-varnam-trigstart-fov2-1000Hz--BL100-fps401-cR_moco.h5
% tempName = strrep(allPaths.h5PathG,'cG.h5','cG_moco.h5');
% % dim=h5info(tempName);
% % dim=dim.Datasets.Dataspace.Size;
% % start=[1 1 1]; 
% % count=[dim(1) dim(2) 5000]; 
% Vcorr=h5read(tempName,'/mov'); 
% tempName = strrep(tempName,'cG','cR');
% Rcorr=h5read(tempName,'/mov'); 

% tic;
% [movie_outSVD_G, ~, ~] = denoisingSVD(Vcorr);
% toc;
% tic;
% [movie_outSVD_R, ~, ~] = denoisingSVD(Rcorr);
% toc;
% 
% tic;
% [movie_outLOSS_G,~, ~] = denoisingLOSS(Vcorr);
% toc;
% tic;
% [movie_outLOSS_R,~, ~] = denoisingLOSS(Rcorr);
% toc;
% 
% % figure()
% subplot(311)
% imshow([Vcorr(:,:,end) Rcorr(:,:,end)],[])
% subplot(312)
% imshow([Vcorr(:,:,end) Rcorr(:,:,end)],[])
% subplot(313)
% imshow([Vcorr(:,:,end) Rcorr(:,:,end)],[])

% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_SVD_G' '.h5']);
% h5save(h5PathG,movie_outSVD_G,'mov');
% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_SVD_R' '.h5']);
% % h5save(h5PathG,movie_outSVD_R,'mov');
% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_LOSS_G' '.h5']);
% h5save(h5PathG,movie_outLOSS_G,'mov');
% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_LOSS_R' '.h5']);
% h5save(h5PathG,movie_outLOSS_R,'mov');
% clear Vcorr Rcorr movie_outLOSS_G movie_outLOSS_R
toc;
    catch
        disp('oups, this one failed...')
        fail(k)=iMeas;k=k+1;   
    end
    
end
disp('failed measurements')
fail
toc;
% %% UNMIXING
% [Vumx,coeff,summaryUnmixing] = unmixing(Vcorr,Rcorr,allPaths,...
%     'method','rlr','type','local');
%% BAND-PASS filter movie in chunks

h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual8Angles\m78\20201012');
folder=dir(fullfile(h5Path, 'meas*')); % G always comes before R
folderName=[];k=1;
for iFolder=1:length(folder)
    if strlength(folder(iFolder).name)==6
    folderName{k}=folder(iFolder).name;
    k=k+1;
    end
end

fileName=dir(fullfile(fullfile(h5Path,folderName{end}), '*.h5')); % G always comes before R
[fileNameG]=fileName.name; % for saving other outputs, 

h5PathG=fullfile(fileName(1).folder,fileNameG);

[high,low]=findBestFilterParameters(h5PathG);
bpFilter=[low high];
%%
tic;
k=1;
fail=[];
for iFolder=length(folderName)
    try
h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual8Angles\m78\20201012',folderName{iFolder});   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileName=dir(fullfile(h5Path, '*.h5')); % G always comes before R
[fileNameG, fileNameR]=fileName.name; % for saving other outputs

h5PathG=fullfile(h5Path,fileNameG);
h5PathR=fullfile(h5Path,fileNameR);

bandPassMovieChunk(h5PathG,bpFilter)
bandPassMovieChunk(h5PathR,bpFilter)
disp('End bandpass movie');toc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fileName=dir(fullfile(h5Path, '*_bp.h5')); % G always comes before R
[fileNameG, fileNameR]=fileName.name; % for saving other outputs

h5PathG=fullfile(h5Path,fileNameG);
h5PathR=fullfile(h5Path,fileNameR);

motionCorr1Movie(h5PathG);
motionCorr1Movie(h5PathR);
 
disp('End Moco movie');toc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileName=dir(fullfile(h5Path, '*_moco.h5')); % G always comes before R
[fileNameG, fileNameR]=fileName.name; % for saving other outputs

h5PathG=fullfile(h5Path,fileNameG);
h5PathR=fullfile(h5Path,fileNameR);

motionCorr1Movie(h5PathG);
motionCorr1Movie(h5PathR);
 
disp('End Denoising movie');toc;
    catch
        disp('oups, this one failed...')
        fail(k)=iMeas;k=k+1;   
    end
    
end
disp('failed measurements')
fail
toc;

%% Denoising movie in chunks
tic;
k=1;
fail=[];
for iMeas=1:13
    try
        if iMeas<10
 meas=strcat('meas0',num2str(iMeas));
        else
             meas=strcat('meas',num2str(iMeas));
        end
h5Path=fullfile('F:\GEVI_Spike\Preprocessed\Visual8Angles\m78\20201012',meas);   
    fileName=dir(fullfile(h5Path, '*_moco.h5')); % G always comes before R
[fileNameG, fileNameR]=fileName.name; % for saving other outputs

h5PathG=fullfile(h5Path,fileNameG);
h5PathR=fullfile(h5Path,fileNameR);

denoisingSpatialChunk(h5PathG);
denoisingSpatialChunk(h5PathR);

% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_SVD_G' '.h5']);
% h5save(h5PathG,movie_outSVD_G,'mov');
% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_SVD_R' '.h5']);
% % h5save(h5PathG,movie_outSVD_R,'mov');
% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_LOSS_G' '.h5']);
% h5save(h5PathG,movie_outLOSS_G,'mov');
% h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),['_dns_LOSS_R' '.h5']);
% h5save(h5PathG,movie_outLOSS_R,'mov');
% clear Vcorr Rcorr movie_outLOSS_G movie_outLOSS_R
toc;
 
toc;
    catch
        disp('oups, this one failed...')
        fail(k)=iMeas;k=k+1;   
    end
    
end
disp('failed measurements')
fail
toc;














