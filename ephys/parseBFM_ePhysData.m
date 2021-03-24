

ePhysPath='F:\GEVI_Spike\ePhys\Spontaneous\m915\20210221';
oPhysPath='F:\GEVI_Spike\Preprocessed\Spontaneous\m915\20210221';

iMeas=1;
folder=strcat('meas0',num2str(iMeas-1));
filePath=fullfile(oPhysPath,folder,'metadata.mat');
% Load Behavior data
if isfile(filePath)
    load(filePath);
    oPhys.data=metadata.Locomotion;
    oPhys.ttl=metadata.TTL;
    oPhys.fps=metadata.fps;
else
    warning('No behavioral data - is it normal?')
end

% Load ePhys data
ePhysPath=dir(fullfile(ePhysPath,'*.rhd'));
fprintf('%2.0f intan files detected \n',length(ePhysPath));
disp('Recursive readout of INTAN data')

iFile=1;
read_Intan_RHD2000_file(fullfile(ePhysPath(iFile).folder,ePhysPath(iFile).name))
ePhys.data=amplifier_data';
ePhys.ttl=board_dig_in_data';
ePhys.fps=frequency_parameters.board_adc_sample_rate;

%% 


[ePhys_cal,oPhys_cal]=alignRecording(ePhys,oPhys);

%%
timeE=getTime(ttlE,fpsE);
timeO=getTime(ttlO,fpsO);

plot(timeE, [ttlE 10*movmean(ttlE,30*fpsE)], timeO,ttlO - linspace(0,11,6))

[~,locs] =findpeaks(movmean(ttlE,30*fpsE),'MinPeakDistance',30*fpsE);
delta=diff(locs)./2;
delta=[0 delta' length(ttlE)-locs(end)];

for iLocs=1:length(locs)
    meas(iLocs).ttlE= ttlE(round(locs(iLocs)-delta(iLocs)):round(locs(iLocs)+delta(iLocs+1)));
end

for iMeas=1:6
    ttlE_temp=meas(iMeas).ttlE;
    ttlO_temp=ttlO(:,iMeas);
    
    x=getTime(ttlO_temp,fpsO);
    v=ttlO_temp;
    xq=linspace(0,x(end),x(end)*fpsE);
    vq = interp1(x,v,xq,'nearest')';
    plot(xq, vq,ttlE_temp)
    
    % Find the delay between the last ttl and the end of the recording
    [offsetO,~]=find(diff(ttlO_temp)==1,1,'last');
    dT=(length(ttlO_temp)-offsetO+1)/fpsO;
    
    % detect the equivalent end on the ePhys data
    [offsetE,~]=find(diff(ttlE_temp)==1,1,'last');
%     truncE=ttlE_temp(
    timeE=getTime(ttlE_temp,fpsE);
    timeO=getTime(ttlO_temp,fpsO);
    
    [onsetO,~]=find(diff(ttlO_temp)==1,1,'first');
    [offsetO,~]=find(diff(ttlO_temp)==-1,1,'last');
    timeO([onsetO offsetO end])
    
    [onsetE,~]=find(diff(ttlE_temp)==1,1,'first');
    [offsetE,~]=find(diff(ttlE_temp)==-1,1,'last');
    timeE([onsetE offsetE end])
    
    plot(timeE, ttlE_temp, timeO,ttlO_temp)
    [allEventsO,~]=find(diff(ttlO_temp)==1);
    [allEventsE,~]=find(diff(ttlE_temp)==1);
    
    if numel(allEventsO)~=numel(allEventsE)
        warning('n')
    end
end
%%

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
