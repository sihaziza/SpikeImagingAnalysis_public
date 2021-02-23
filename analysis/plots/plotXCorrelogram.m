function plotXCorrelogram(spikeRaster,Fs,varargin)

% varargin > ylim, dt for Refractory Period and OSCillations
nTrace=size(spikeRaster,2);

BW=100; %for gamma

rp=figure('defaultaxesfontsize',16,'color','w'); % refractory period
osc=figure('defaultaxesfontsize',16,'color','w');
for iTrace=1:nTrace    
    for jTrace=1:nTrace
        [r,lags] = xcorr(spikeRaster(:,iTrace),spikeRaster(:,jTrace),Fs,'coeff');
        r((length(r)+1)/2)=0;
        
        figure(rp)
        subplot(nTrace,nTrace,nTrace*(iTrace-1)+jTrace)
        plot(lags,r,'k','linewidth',1.5)
        xlim([-50 50])
        ylim([0 0.2])

        figure(osc)
        subplot(nTrace,nTrace,nTrace*(iTrace-1)+jTrace)
%         r((length(r)+1)/2)=0;
        plot(lags,movavg(r,'simple',Fs/BW),'k','linewidth',1.5)
%         plot(lags,r,'k','linewidth',1.5)
        xlim([-500 500])
        ylim([0 0.1])
    end
end
end