function [amplitude,tau,drift,noise]=estimateSpikeParam(trace,fs)


%%
options.minPeakProm=0.01; 
options.maxPeakWidth=20; % in ms
options.minPeakHeight=0.01;
options.spikeDelay=25; % in ms
options.savePath=[];
options.plotFigure=false;

%%

trace=double(trace);
trace=trace-mean(trace);

% estimate drift parameter
temp=sh_bpFilter(trace,[inf 50],fs); % low pass filter
drift=sqrt(mean(temp.^2)); % Vrms
%drift=max(abs(temp))*2; % Vpeak-peak

% estimate noise level
noise=(trace+1)./(wdenoise(trace+1,2));
noise=std(noise);

% estimate spike A & tau on denoised trace
trace=wdenoise(trace,2);

pre=20; % 10 ms preSpike
post=40; % 20 ms postSpike
pre = round(pre/1000*fs);
post = round(post/1000*fs);
% estimate parameters from findpeaks
[spikePks,spikeLcs]=findpeaks(trace,'MinPeakProminence',options.minPeakProm,...
    'WidthReference','halfheight',...
    'MaxPeakWidth',round(options.maxPeakWidth/1000*fs),...
    'MinPeakHeight',options.minPeakHeight,'Annotate','extents');%,'MinPeakDistance',round(0.01*fs));

% parse spike epoch
spikeDist=[spikeLcs(1); diff(spikeLcs); length(trace)-spikeLcs(end)];
p=1;
spikePks_temp=[];
spikeLcs_temp=[];
for i=1:numel(spikeLcs)
    if spikeDist(i)>round(options.spikeDelay/1000*fs)&&spikeDist(i+1)>round(options.spikeDelay/1000*fs)
        spikeLcs_temp(p)= spikeLcs(i);
        spikePks_temp(p)= spikePks(i);
        p=p+1;
    end
end



n=length(trace);
dFspikes=[];
for i = 1:length(spikeLcs_temp)
    if spikeLcs_temp(i)-pre >= 1 && spikeLcs_temp(i)+post <= n
        mm = mean(trace(spikeLcs_temp(i)-pre:spikeLcs_temp(i)));
        dFspikes = [dFspikes trace(spikeLcs_temp(i)-pre:spikeLcs_temp(i)+post)-mm];
    end
end

spikeAVG=mean(dFspikes,2);
t_s = (-pre/fs:1/fs:post/fs)';
toFit=spikeAVG(pre+1:end);
tsFit=t_s(pre+1:end);
[fitresult, ~] = createSpikeFit(tsFit, toFit);

func= @(x) fitresult(x)-fitresult(0)*exp(1);
amplitude=fitresult(0); % fit
% amplitude=max(spikeAVG)-min(spikeAVG); %peak-to-peak
tau=abs(fzero(func,0));

if options.plotFigure
    time=getTime(trace,fs);
figH=figure('Name','MLspike parameters','DefaultAxesFontSize',12,'color','w');
subplot(1,5,[1 4])
plot(time,trace)
xlabel('Time (s)')
ylabel('dFF')
hold on
plot(spikeLcs_temp/fs, max(spikePks_temp),'k','Marker','o','MarkerSize',5)
hold off

subplot(1,5,5)
plot( fitresult,tsFit, toFit);
hold on
plot(t_s,spikeAVG,'k')
hold off
xlabel('Time (s)')
ylabel('dFF')
title(['computed on N = ' num2str(size(dFspikes,2)) ' spikes'])
end

if options.savePath
    savePDF(figH,[filename '_MLspikeParam'],options.savePath)
    disp('Unmixing Summary Figure successfully saved...')
end


end


