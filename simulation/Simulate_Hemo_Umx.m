clear all; clc; close all;
%% SIMULATE Hemodynamic Artefacts for 0D+T  recordings
Fs=1000;
Fhb=12; % heartbeat in Hz
A=10; % average photon count 
R=0.9; % correlation coeff between voltage and reference
t=linspace(0,30,30*Fs)';%generate 30s recording

k=5;
reference=A*(1+sin(2*pi*(t*Fhb)))+poissrnd(k*sqrt(A),size(t));
voltage=R*A*(1+sin(2*pi*(t*Fhb)))+poissrnd(k*sqrt(A),size(t));

% Plot time trace
figure(1)
plot(t,[reference voltage])
xlim([0 2])

% Plot PSD
plotPSD([reference voltage],'FrameRate',Fs,'FreqBand',[1 15]);

%% RUN UNMIXING FUNCTIONS on 1D simulated data
[Fhemo,optionsHB]=unmixing.FindHBpeak(voltage,'FrameRate',Fs);

[umxSource,umxCoeff,options]=unmixing1D(voltage,reference,'FrameRate',Fs);

[umxSource2,umxCoeff2,options2]=unmixing1D(voltage,reference,...
'FrameRate',Fs,'UnmixingMethod','PCA',...    
'VerboseMessage',true,'VerboseFigure',true);

[umxSource3,umxCoeff3,options3]=unmixing1D(voltage,reference,...
'FrameRate',Fs,'UnmixingMethod','RLR',...    
'VerboseMessage',true,'VerboseFigure',true);

%% SIMULATE Hemodynamic Artefacts for 2D+T  recordings
duration=30;
Fs=100; %sampling rate
Fhb=12; % heartbeat in Hz
d1=50; % frame size
d2=d1;
d3=duration*Fs; % time in second
A=100; % average photon count 
R=0.9; % correlation coeff between voltage and reference
tau=30; % photobleaching half-time

t=linspace(0,duration,d3)';%generate 30s recording
reference=zeros(d1,d2,d3);
voltage=zeros(d1,d2,d3);

reference=reshape(reference,d1*d2,d3);
voltage=reshape(voltage,d1*d2,d3);tic;
parfor i=1:d1*d2
% Create correlated Voltage and Reference signals   
reference(i,:)=A*(1+sin(2*pi*(t*Fhb)));
voltage(i,:)=R*reference(i,:);

% Add Photon Shot noise 
reference(i,:)=reference(i,:)'+(poissrnd(A,size(t))-A);
voltage(i,:)=voltage(i,:)'+(poissrnd(A,size(t))-A);

% Add Photobleaching @tau
reference(i,:)=reference(i,:)'.*exp(-(1/tau).*t);
voltage(i,:)=voltage(i,:)'.*exp(-(1/tau).*t);

% plot([reference(i,:)' voltage(i,:)'])
end

reference=reshape(reference,d1,d2,d3);
voltage=reshape(voltage,d1,d2,d3);
toc;

tref=pointProjection(reference);
tvolt=pointProjection(voltage);

%% Plot time trace of single pixel versus frame average
figure(1)
subplot(211)
plot(t,[squeeze(reference(10,10,:)) tref])
xlim([0 5])
subplot(212)
plot(t,[squeeze(voltage(10,10,:)) tvolt])
xlim([0 5])
legend('Single Pixel','Frame-Average')
title('Plot time trace of single pixel versus frame average')

%% Plot PSD of single pixel versus frame average
h=figure('name','Comparative PSD');
subplot(121)
plotPSD([squeeze(reference(10,10,:)) tref],'FrameRate',Fs,...
    'FreqBand',[0.5 30],'figureHandle',h);
subplot(122)
plotPSD([squeeze(voltage(10,10,:)) tvolt],'FrameRate',Fs,...
    'FreqBand',[0.5 30],'figureHandle',h);
legend('Single Pixel','Frame-Average')
title('Plot PSD of single pixel versus frame average')

%% Check heartbeat video
figure(1)
r = randi([1 d3],1,1);
M=[reference(:,:,r) voltage(:,:,r)];
imshow(M,[])

implay(uint8(voltage),Fs/2)

%% RUN UNMIXING FUNCTIONS on 3D simulated data 

[Fhemo,optionsHB]=unmixing.FindHBpeak(tvolt,'FrameRate',Fs);

[unmixSource,unmixCoeff,options3d]=unmixing3D(voltage,reference,...
    'FrameRate',Fs); %run with the defaults

[unmixSource1,unmixCoeff1,options3d_1]=unmixing3D(voltage,reference,...
    'FrameRate',Fs,'DataConditioning',false,...
    'UnmixingMethod','hdm','UnmixingType','global');

[unmixSource2,unmixCoeff2,options3d_2]=unmixing3D(voltage,reference,...
    'FrameRate',Fs,'DataConditioning',false,...
    'UnmixingMethod','pca','UnmixingType','local');

[unmixSource3,unmixCoeff3,options3d_3]=unmixing3D(voltage,reference,...
    'FrameRate',Fs,'DataConditioning',false,...
    'UnmixingMethod','rlr','UnmixingType','local');

%%



