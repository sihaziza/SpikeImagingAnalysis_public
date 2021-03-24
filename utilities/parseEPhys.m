function [parsedData]=parseEPhys(ePhys)
% assume continuous recording of ePhys data along with multiple oPhys
% measurements. You sould have as many ttlE epoch as oPhys measurment files

if ~isstruct(ePhys)
    error('input must be a structure with data to align, syncTTL and fps')
end

field={'data','ttl','fps'};
if sum(isfield(ePhys,field))~=3
    error('you are missing a structure field. Check doc')
end

% timeO=getTime(ttlO,fpsO);
ttlE=ePhys.ttl;
fpsE=ePhys.fps;
timeE=getTime(ttlE,fpsE);

smoothDuration=30;%seconds

[~,locs] =findpeaks(movmean(ttlE,smoothDuration*fpsE),'MinPeakDistance',smoothDuration*fpsE);
delta=diff(locs)./2;
delta=[0 delta' length(ttlE)-locs(end)];

parsedData=struct('ttl',[],'time',[]);
for iLocs=1:length(locs)
    parsedData(iLocs).ttl= ttlE(round(locs(iLocs)-delta(iLocs)):round(locs(iLocs)+delta(iLocs+1)));
    parsedData(iLocs).time=timeE(round(locs(iLocs)-delta(iLocs)):round(locs(iLocs)+delta(iLocs+1)));
end

figure(1)
subplot(2,length(locs),[1 length(locs)])
temp=movmean(ttlE,smoothDuration*fpsE);
plot(timeE,[ttlE rescale(temp)])
xlim([timeE(1) timeE(end)])
title('Parsing ePhys syncTTL')
xlabel('Time (s)')

for iLocs=1:length(locs)
    subplot(2,length(locs),length(locs)+iLocs)
    plot(parsedData(iLocs).time,parsedData(iLocs).ttl)
    xlim([parsedData(iLocs).time(1) parsedData(iLocs).time(end)])
    xlabel('Time (s)')
end


end