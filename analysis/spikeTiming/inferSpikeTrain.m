function [spikeRaster, spikest, fit, drift, parest]=inferSpikeTrain(trace,fs,varargin)

% TO DO > estimate more accuratly the par.a parameters... some neurons have
% slightly different 1-spike dff

%% OPTIONS
options.duration=[]; %in sec
options.MLspikeParam=[];
options.plotFigure=true;
options.savePath=[];

%% UPDATE OPTIONS
if nargin>2
    options=getOptions(options,varargin);
end
%%
duration=options.duration;

if isempty(duration)
    duration=length(trace)/fs;
end

if isempty(options.MLspikeParam)
    par.dt = 1/fs;
    % (set physiological parameters)
    par.a = 0.03; % DF/F for one spike
    par.tau = 0.001; % decay time constant (second)
    par.saturation = 1; % OGB dye saturation
    % (set noise parameters)
    par.finetune.sigma = 0.001; % a priori level of noise (if par.finetune.sigma
    % is left empty, MLspike has a low-level routine
    % to try estimating it from the data
    par.drift.parameter = .01; % if par.drift parameter is not set, the
    % algorithm assumes that the baseline remains
    % flat; it is also possible to tell the
    % algorithm the value of the baseline by setting
    % par.F0
    % (do not display graph summary)
    par.dographsummary = false;
    par.algo.estimate='map';
    
    % check tps_mlspikes.m>defaultpar.m for more info
else
    par=options.MLspikeParam;
    par.dt = 1/fs;
    par.saturation = 1; % OGB dye saturation
    par.dographsummary = false;
    par.algo.estimate='map';
end

trace=trace(1:duration*fs);
% spike estimation
[spikest, fit, drift, parest] = spk_est(trace,par);

% assign detected spikes and remove duplicates
spikeRaster=zeros(size(trace));
temp=round(spikest*fs+1);
spikeRaster(temp)=1;
a=find(spikeRaster>0);
b=diff(a)==1;% logical indexing
spikeRaster(a(b))=0; 

if options.plotFigure
    disp('outputting figure')
    figHandle=figure('Name','Spike Inference','DefaultAxesFontSize',16,'color','w');
    time=getTime(spikeRaster,fs);
    spk_display(1/fs,{spikest},{trace rescale(fit,min(trace),max(trace))+max(trace)-1},'linewidth', [1 1 1])
    set(1,'numbertitle','off','name','MLspike alone');
    xlim([0 min(5,duration)])
    hold on
    plot(time(spikeRaster>0),1+2*max(trace-1),'k','Marker','|','MarkerSize',5,'linewidth',1)
    hold off
    ylim([0.98 1.1])

    if options.savePath
        savePDF(figHandle,'MLspike output',options.savePath)
    end    
end

end