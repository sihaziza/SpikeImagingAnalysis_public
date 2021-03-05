function [spikeRaster]=plotSpikeRaster(spikes,Fs,thres,varargin)

% assume row > timestamps and column > neuron ID

nTrace=size(spikes,2);
[b,a]=butter(6,100/(Fs/2),'high');

Time=0:1/Fs:(size(spikes,1)-1)/Fs;

spikeRaster=cell(nTrace);
negDFF=false;
if negDFF
    spikes=-spikes;
end

spikeRaster=zeros(length(Time),nTrace);

figure('defaultaxesfontsize',16,'color','w')
for iTrace=1:nTrace
    
    subplot(nTrace,1,iTrace)
    
    t1=zscore(spikes(:,iTrace));
    
    t1RP=zscore(filtfilt(b,a,double(t1)));
    t1RP(t1RP<0)=0;
    [peaks,location,width,prominence]=findpeaks(t1RP.^2,'MinPeakHeight',thres);
    
    plot(Time,t1,'k','linewidth',1.5)
    hold on
    plot(Time(location),7,'k','Marker','v','MarkerSize',5,'linewidth',1)
    plot([0 Time(end)],[3 3],':k','linewidth',1)
    hold off
    xlim([0 Time(end)])
    ylim([-8 8])
    
    spikeRaster(location,iTrace)=1;
    
    fprintf('neuron %1.0f: %3.0f spikes \n',iTrace,length(location))
end

end
