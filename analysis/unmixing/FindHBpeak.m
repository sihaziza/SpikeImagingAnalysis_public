function [Fhemo,options]=FindHBpeak(wave,varargin)

% GOAL: automatically find the heartbeat frequency (Fhemo.Location)
% and amplitude (Fhemo.Prominence)
% 
% INPUT:
%     - wave (vector): input time trace. Only work for a vector
%     - opts (struct): available options
%         * FrameRate: sampling frequency of time trace. (default: 1kHz)
%         * HeartbeatRange: a 2-element-vector. (default: awake > 9-13Hz
%         * Verbose: command window output
% OUTPUT:
%     - Fhemo (struct): the fundamental heartbeat frequency and the peak caraceristics
% 
% DEPENDENCIES: none
% 
% EXAMPLE 1:
% [Fhemo,opts]=FindHBpeak(wave); % will use the default options
% 
% EXAMPLE 2:
% [Fhemo,opts]=FindHBpeak(wave,[],'FrameRate',500,'MouseState','anesthesia');
% 
% CONTACT
% StanfordVoltageGroup@gmail.com
%
% HISTORY
% Created 2020-06-01 by Stanford Voltage Group, Schnitzer Lab

%% CHECK VARIABLES FORMATING
if isempty(varargin)
    cprintf('yellow','WARNING: Default options used...\n');
end

if mod(nargin-1,2)
    error('Variable input arguments work as Name-Value pairs');
end

if ~isvector(wave)
    error('This function requires 1st argument to be vector.\n');
end

%% DEFAULT INPUT OPTIONS
options.VerboseMessage=true;
options.VerboseFigure=true;
options.figureHandle=[];
options.Savefig=false;
options.FigureDir='I:\USERS\Simon\TEST';
options.FrameRate=1000; % default: for TEMPO
options.MouseState=[]; % default: no assumption
options.HeartbeatRange=[];
options.WindowPSD=3;

%% USER-DEFINED INPUT OPTIONS
if nargin>2
    options=getOptions(options,varargin);
end

%% PREPARE OUTPUT OPTIONS
options.FunctionPath=mfilename('fullpath');
options.ExecutionDate=datetime('now');
options.ExecutionDuration=tic;

%% FUNCTION CORE
Fs=round(options.FrameRate);
win=options.WindowPSD*Fs;
ovl=round(win/2);
nfft=10*Fs;

% Narrow down the heart beat location
if strcmpi(options.MouseState,'awake')
    options.HeartbeatRange=[9 min(14,Fs/2)];
elseif  strcmpi(options.MouseState,'anesthesia')
    options.HeartbeatRange=[2 min(14,Fs/2)];
else
    options.HeartbeatRange=[2 min(14,Fs/2)]; % default: no assumption
end

if numel(wave)<win
    cprintf('yellow','Input length is smaller than the frame window.\nIncrese the frame number');
end

range=options.HeartbeatRange;

[x,f]=pwelch(normalize(wave),win,ovl,nfft,Fs,'onesided');

[pks,locs,wdth,prom] =findpeaks(...
    10*log10(x(range(1)*nfft/Fs:range(2)*nfft/Fs)),...
    f(range(1)*nfft/Fs:range(2)*nfft/Fs),...
    'SortStr','Descend','NPeaks',1,'Annotate','Extents');

Fhemo.Location=locs;
Fhemo.Prominence=prom;
Fhemo.Peak=pks;
Fhemo.Width=wdth;

if options.VerboseMessage
    disps(sprintf('Heart beat @ %2.1f Hz \n',locs))
end

if options.VerboseFigure
    fig=figure('Name','Output of FindHBPeak function','defaultaxesfontsize',16);
    options.figureHandle=fig;
    plot(f,10*log10(x),'linewidth',2,'color','k')
    hold on
    plot(locs,pks,'vr','linewidth',3,'markersize',10)
    plot([locs-wdth/2 locs+wdth/2],[pks-prom/2 pks-prom/2],'--m','linewidth',1)
    plot([locs locs],[pks-prom pks],'--b','linewidth',1)
    hold off
    
    xlim([1 15])
    legend({'PSD','Peak','Width','Prominence'},'Location','northwest','NumColumns',1)
    title('Heartbeat peak')
    
    if options.Savefig
        if isempty(options.FigureDir)
            warning('Figure not saved. Input save directory.')
        else
            sh_SavePDF(fig,'Heartbeat peak',options.FigureDir)
        end
    end
end
options.ExecutionDuration=toc(options.ExecutionDuration);

    function disps(string) %overloading disp for this function
            fprintf('%s findHBpeak: %s\n', datetime('now'),string);
    end
end
