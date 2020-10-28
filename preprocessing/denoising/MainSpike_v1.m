%{ 
TO BE UPDATED / TO BE UPDATED / TO BE UPDATED / TO BE UPDATED 

               %%%%%%% Preprocessing of BFM data %%%%%%%%
*** INPUT ***
Point to the master folder that contains the .dcimg data to process
(green and red channels)
The convention imposes: 'basename + _G or _R + .dcimg'

*** OUTPUT ***
Unmixed voltage signal in dF/F (%) as 'basename_DFF.tiff'
Unmixing phase mask as 'basename_UnmixCoeff.tiff'
  
*** VARIABLES ***
'Crop': give a handle to the user to crop the movie, keep ROI coordinates
'Bin': bin the movie
'Bits': convert from 16-bits (default) to 8-bits
'Unmixing': default 'YES' (need to have the reference channel properly labelled
'Photobleaching': detect if important

Simon HAZIZA, Mark SCHNITZER Lab, STANFORD 2019

TO BE UPDATED / TO BE UPDATED / TO BE UPDATED / TO BE UPDATED 

%} 
clear % all 
tic;
% Load MetaData
rootName='F:\TEMPO2D_raw\Whiskers\m972\20191031\meas28\whiskers_fullwindow--BL100-fps100-';
% GreenDir=strcat('D:\',rootName);
% RedDir=strcat('E:\',rootName);

FPS=50;
[metadata]=sh_getMetaDatav2(rootName,'cG.dcimg',FPS,[10 3000]);
DIM=metadata.Dimension;
metadata.FPS=FPS;

% define the cropping ROI
% ROIxG=(1:1200)';
% ROIxR=(401:1600)';
% ROIy=(1:890)';
% % 
ROIx=(1:DIM(1))';
ROIy=(1:DIM(2))';

BIN=8;
metadata.ROI={ROIx; ROIy};
metadata.Binning=BIN;
%%
        % Load & Pre-Process Green Channel
        tic;[movieG]=sh_LoadDCIMGv2(rootName,'cG.dcimg',metadata,0);
        disp('//////////Done... LOADING DATA GREEN\\\\\\\\\\'); toc;
%%       
        tic;[movieR]=sh_LoadDCIMGv2(rootName,'cR.dcimg',metadata,1);
        disp('//////////Done... LOADING DATA RED\\\\\\\\\\'); toc;
%%
[movieR]=sh_LoadDCIMGv2(rootName,'cR.dcimg',metadata,ROIxR,ROIy,BIN);
movieR=flip(movieR,1); % Flip red channel to match green channel
disp('//////////Done... LOADING DATA RED\\\\\\\\\\'); toc;

tic; movieG=single(movieG); movieR=single(movieR);
disp('//////////Done... CONVERTION\\\\\\\\\\'); toc;

% Two channels registration
tic;[movieG, movieR] = pre_reg_video(movieG, movieR);
disp('//////////Done... REGISTRATION\\\\\\\\\\'); toc;

% Motion correct each channel
tic;[movieG, movieR] = pre_reg_video(movieG, movieR);
disp('//////////Done... REGISTRATION\\\\\\\\\\'); toc;

figure('Name','First & Last frame both channels')
imshow([movieG(:,:,1) movieG(:,:,end); movieR(:,:,1) movieR(:,:,end)],[]);

tic;[mSCEnorm,mREFnorm,UMX]=sh_rLRUnmixing(movieG, movieR, FPS);
disp('//////////Done... UNMIXING\\\\\\\\\\'); toc;

% implay(-VOLT,100)
% 
figure('Name','First & Last frame both channels after standardization')
imshow([mSCEnorm(:,:,1) mSCEnorm(:,:,end); mREFnorm(:,:,1) mREFnorm(:,:,end)],[]); 

figure('Name','Unmixing Coefficient')
imshow([UMX imgaussfilt(UMX,5)],[]); 
caxis([0.8 1.2])
% figure('Name','First & Last frame both channels after standardization')
% imshow([mSCEnorm(:,:,1) mSCEnorm(:,:,end); VOLT(:,:,1) VOLT(:,:,end)],[]); 
%%
% Convert movie 2D-t into time trace 0D-t to find global unmixing coeff
xa=1:DIM(2);
ya=1:DIM(1);

G_t=sh_PointProjection(mSCEnorm);
R_t=sh_PointProjection(mREFnorm);

VOLT=sh_Standardize(mSCEnorm-UMX.*mREFnorm);
VOLTs=sh_Standardize(mSCEnorm-imgaussfilt(UMX,1).*mREFnorm);
pr=robustfit(R_t,G_t);
VOLTg=sh_Standardize(mSCEnorm-1.*mREFnorm);

V_t=sh_PointProjection(VOLT);
Vs_t=sh_PointProjection(VOLTs);
Vg_t=sh_PointProjection(VOLTg);

[map]=sh_PowerMap([mSCEnorm mREFnorm VOLT VOLTs VOLTg],[10 13],FPS);
figure()
imshow(map,[])
caxis([0 0.05])

% [b,a]=butter(3,[1 30]/(0.5*FPS),'bandpass');

%need to put the best matrix Wi
AllMatrix=[G_t R_t V_t Vs_t Vg_t]; 

Time=0:1/FPS:DIM(3)/FPS-1/FPS;
figure('Name','0D-t Conversion')
subplot(2,3,[1 3])
plot(Time,AllMatrix)
title('Time Traces')
xlabel('Time(s)')
ylabel('z-Score')
legend('Green','Red','LUMX','GUMX')

subplot(2,3,4)
plot(R_t,G_t)
robustfit(R_t,G_t)
title('Raw')
xlabel('Reference')
ylabel('Source')

subplot(2,3,5)
plot(R_t,V_t)
hold on
robustfit(R_t,V_t)
hold off
title('Unmixed Local')
xlabel('Reference')
ylabel('Source')

subplot(2,3,6)
plot(R_t,Vg_t)
hold on
robustfit(R_t,Vg_t)
hold off
title('Unmixed Global')
xlabel('Reference')
ylabel('Source')

% Plot power spectrum density to further compare Raw versus Unmixed
win=1*FPS;
ovl=0.5*FPS;
nfft=10*FPS;

[x,f]=pwelch(AllMatrix,win,ovl,nfft,FPS,'onesided');

figure('Name','Power Spectrum Density','defaultAxesFontSize',20)
plot(f,10*log10(x),'linewidth',2)
xlim([0.1 90])
legend('Green','Red','LUMX','LUMXs','GUMX')

%%
% Compute unmixed movies
W=reshape([W1 W2 W3 W4],2,2,4);

UMX(1,2)=-0.9059 ;
UMX(2,1)=-0.0724;
mGcorr=movieG + UMX(1,2).*movieR;
mRcorr=UMX(2,1).*movieG + movieR;
disp('Unmixing movies:'); toc;

G_tc=sh_PointProjection(mGcorr);
R_tc=sh_PointProjection(mRcorr);
time=(0:1/FPS:length(G_tc)/FPS-1/FPS)';
[b,a]=butter(3,[30 60]/(0.5*FPS),'bandpass');
figure(123)
plot(time,filtfilt(b,a,double([G_t R_t]))) 
Gtfilt=filtfilt(b,a,double(G_t));
Rtfilt=filtfilt(b,a,double(R_t));

%%
% Save the 4 movies in HDF5 format
experiment='KX_m696';
saveDir='G:\Simon_ProcessedData\19-03-07_m696_KX-ASAP2_mRuby\';
saveName={'/Green','/Red','/Voltage','/Hemo'};
varName={'movieG','movieR','mGcorr','mRcorr'};
filename=strcat(saveDir,experiment,'.h5');

save(strcat(saveDir,experiment,'_MetaData','.mat'),'metadata');%,'Mx','UMX','W');

for i=1:4
h5create(filename,saveName{i},size(mGcorr));%,'Datatype','single');  
h5write(filename,saveName{i},eval(varName{i}));
end
toc;
h5disp(filename)

%%
% Create rendering movie for ppt presentation
Name='m696voltage_GratingAll_movieRegGreen.avi';
sh_MakeMovie(mGcorr,Name,100)

Name='m696voltage_GratingAll_movieRegHemo.avi';
sh_MakeMovie(mRcorr,Name,100)

