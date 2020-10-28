function plotAutoCorrelogram(spikeRaster,Fs,varargin)

nTrace=size(spikeRaster,2);

BW=100; %for gamma
figure('defaultaxesfontsize',16,'color','w')
for iTrace=1:nTrace
    [r,lags] = xcorr(spikeRaster(:,iTrace),Fs,'coeff');
    r((length(r)+1)/2)=0;
    
    subplot(nTrace,2,2*(iTrace-1)+1)
    plot(lags,r,'k','linewidth',1.5)
    xlim([-25 25])
    
    subplot(nTrace,2,2*iTrace)
    r((length(r)+1)/2)=0;
    plot(lags,movavg(r,'simple',Fs/BW),'k','linewidth',1.5)
    xlim([-250 250])
end
end