
directory=uigetdir;

% Load Behavior data
if isfile(fullfile(directory,'behaviorIO.txt'))
    behav=importdata(fullfile(directory,'behaviorIO.txt'));
else
    warning('No behavioral data - is it normal?')
end

% Load ePhys data
ePhysPath=dir(fullfile(directory,'*.rhd'));
fprintf('%2.0f intan files detected \n',length(ePhysPath));
disp('Recursive readout of INTAN data')
ePhys=[];dioE=[];
for iFile=1:length(ePhysPath)
    read_Intan_RHD2000_file(fullfile(directory,ePhysPath(iFile).name))
    ePhys=[ePhys amplifier_data];
    dioE=[dioE board_dig_in_data];
end
amplifier_data=ePhys;
board_dig_in_data=dioE;
fpsE=frequency_parameters.board_adc_sample_rate;
t_amplifier=linspace(0,(length(amplifier_data)-1)/fpsE,length(amplifier_data));

% Load oPhys data
oPhysPath=dir(fullfile(directory,'*.mat'));
load(fullfile(directory,oPhysPath(1).name))
load(fullfile(directory,oPhysPath(2).name))

% Find first-last behaviorTTL on ePhys and oPhys DIO data
datatemp=Data;
fpsO=Fs;

INTANdio=downsample(board_dig_in_data',fpsE/fpsO);
INTANePhys=downsample(amplifier_data',fpsE/fpsO);
t_amplifier=downsample(t_amplifier',fpsE/fpsO);

dioChannelO=4;
dioChannelE=1;
ttlO=datatemp(:,dioChannelO);
ttlE=INTANdio(:,dioChannelE);

figure()
title('Raw data in their own time frame')
plot(TimeStamps,ttlO)
hold on
plot(t_amplifier,ttlE-1)
hold off

%% 
t=getTime(dioE,fpsE);
plot(t,[ePhys' dioE'])

plotPSD(ePhys','FreqBand',[-1 2.5],'FrameRate',fpsE,'Window',2,'scaleAxis','log');
%% Other method to be more conservative and don't throw away too many data

[r,lags]=xcorr(ttlO,ttlE);
[~,idShift]=max(r);
shift=lags(idShift)+1;

if shift>0
    disp('ePhys is in advance')
    idO_first=shift;
    idE_first=1;
    
    deltaO=length(ttlO)-shift;
    deltaE=length(ttlE);
    delta=min(deltaO,deltaE);
    
else
    disp('TEMPO is in advance')
    shift=-shift;

    idO_first=1;
    idE_first=shift;
    
    deltaO=length(ttlO);
    deltaE=length(ttlE)-shift;
    delta=min(deltaO,deltaE);
end

figure()
lnWidth=1.5;
subplot(211)
plot(TimeStamps,ttlO,'linewidth',lnWidth)
hold on
plot(t_amplifier,ttlE-1,'linewidth',lnWidth)
hold off
title('Raw data in their own time frame')

time=linspace(0,delta/fpsO,delta);
subplot(212)
plot(time,ttlO(idO_first:idO_first+delta-1),'linewidth',lnWidth)
hold on
plot(time,ttlE(idE_first:idE_first+delta-1)-1,'linewidth',lnWidth)
hold off
xlabel('Time (s)')
title('Multimodal re-alignment')

% Check for incorrect parsing of data
clear ePhys oPhys dio metadata

ePhys=amplifier_data(:,idE_first:idE_first+delta-1)';
oPhys=datatemp(idO_first:idO_first+delta-1,1:4);
dio=datatemp(idO_first:idO_first+delta-1,dioChannelO);

figure()
subplot(311)
plot(time,zscore(ePhys))
title('LFP recordings')

subplot(312)
plot(time,zscore(oPhys))
title('TEMPO recordings')

subplot(313)
plot(time,dio,'k')
title('Camera Frames')

ylim([0 1.1])
xlabel('Time (s)')

% Save Metadata
metadata.fps=min(fpsO,fpsE);
metadata.dioInput='true';
metadata.dioInputChannel={'AirPuff'};
metadata.ePhysChannel={'LFP1' 'LFP2' 'LFP3'};
metadata.oPhysChannel={'DIO-Ace1.0' 'cag-cyOFP' 'Camk2-Varnam1.0'};
metadata.mouseID='m4 PV-Cre Het male';
metadata.mouseDOB='20191107';
metadata.originalFilePath=directory;
metadata.originalePhysFile=ePhysPath.name;
metadata.originaloPhysFile=oPhysPath(2).name;
metadata

% Save parsed data
pathName=fullfile(metadata.originalFilePath,'preprocessed');
if ~exist(pathName,'dir')
    mkdir(pathName)
end
save(fullfile(pathName,'dio.mat'),'dio');
save(fullfile(pathName,'metadata.mat'),'metadata');
save(fullfile(pathName,'ePhys.mat'),'ePhys');
save(fullfile(pathName,'oPhys.mat'),'oPhys');
