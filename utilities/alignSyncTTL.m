function [range_ttlE,range_ttlO]=alignSyncTTL(ttlE,ttlO,fps,varargin)
% align two time trace based off a common syncTTL. Assume that both are at
% the same sampling rate
% [ttlE_cal,ttlO_cal]=alignRecording(ttlE,ttlO,fps)

%% OPTIONS
options.savePath=[];
options.plotFigure=true;

%% UPDATE OPTIONS
if nargin>=4
    options=getOptions(options,varargin);
end

%%
if ~iscolumn(ttlE)
    ttlE=ttlE';
end

if ~iscolumn(ttlO)
    ttlO=ttlO';
end

% Find the time lag between using xcorr
[r,lags]=xcorr(ttlE,ttlO);
[~,idShift]=max(r);
shift=lags(idShift);

if shift>0
    disp('ePhys is in advance')
    
    range_ttlO=1:length(ttlO);
    range_ttlE=shift+1:length(ttlO)+shift;
    
    ttlO_cal=ttlO(range_ttlO);
    ttlE_cal=ttlE(range_ttlE);
else
    disp('TEMPO is in advance')
    
    range_ttlO=shift+1:length(ttlE)+shift;
    range_ttlE=1:length(ttlE);
    
    ttlO_cal=ttlO(range_ttlO);
    ttlE_cal=ttlE(range_ttlE);
end

if options.plotFigure
    
    figHandle=figure(1);
    lnWidth=1.5;
    
    subplot(2,3,1)
    plot(lags/fps,r)
    hold on
    plot([0 0],[min(r) max(r)],'k')
    xlim([-10 10])
    title('Time lag - pre alignment')
    
    subplot(2,3,[2 3])
    plot(getTime(ttlO,fps),ttlO,'linewidth',lnWidth)
    hold on
    plot(getTime(ttlE,fps),ttlE-1,'linewidth',lnWidth)
    hold off
    title('Raw data in their own time frame')
    
    subplot(2,3,4)
    [r,lags]=xcorr(ttlE_cal,ttlO_cal);
    
    plot(lags/fps,r)
    hold on
    plot([0 0],[min(r) max(r)],'k')
    xlim([-10 10])
    xlabel('Time (s)')
    title('Time lag - post alignment')
    
    time=getTime(ttlO_cal,fps);
    
    subplot(2,3,[5 6])
    plot(time,ttlO_cal,'linewidth',lnWidth)
    hold on
    plot(time,ttlE_cal-1,'linewidth',lnWidth)
    hold off
    xlabel('Time (s)')
    title('Multimodal re-alignment')
    
    if options.savePath
        savePDF(figHandle,'alignSyncTTL',options.savePath)
    end
end
end