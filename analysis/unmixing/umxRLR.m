function [unmixsource,umxcoeff,options]=umxRLR(source,reference,varargin)
% GOAL: Unmix the two signal using robust linear regression method.
% 
% INPUT:
%     - source: source trace 'sce' to be unmixed from the reference trace 'ref'.
%     - reference:
%     - options (as input struct or variable arguments):
%         * FrameRate: sampling frequency of time trace. (default: 1kHz)
%         * HeartbeatRange: a 2-element-vector. (default: awake > 9-13Hz
%         * Verbose: command window output
% OUTPUT:
%     - unmixsource: unmixed source signal
%     - umxcoeff: unmixing coefficient used to correct signal from reference
%     - options: all options used in the function
% 
% DEPENDENCIES: none
% 
% EXAMPLE 1:
%     [umx,a,options]=umxRLR(V,R); % uses default options
% 
% EXAMPLE 2:
%     [umx,a,options]=umxRLR(V,R,'FrameRate',100);
% 
% CONTACT
% StanfordVoltageGroup@gmail.com
%
% HISTORY
% Created 2020-06-01 by Stanford Voltage Group, Schnitzer Lab
%% CHECK VARIABLES FORMATING
if nargin<2
    cprintf('yellow','This function requires at least 2 vector inputs (source & reference).\n',nargin);
end

if ~isvector(source)||~isvector(reference)
    cprintf('yellow','This function requires 2 vector inputs (source & reference).\n');
end

if mod(nargin-2,2)
    cprintf('red','Variable input arguments work as Name-Value pairs');
end

%% DEFAULT INPUT OPTIONS
options.VerboseMessage=true;
options.VerboseFigure=true;
options.Savefig=false;
options.FigureDir='I:\USERS\Simon\TEST';
options.FrameRate=1000; % default: for TEMPO
options.MouseState=[]; % default: no assumption
options.HeartbeatRange=[];
options.WindowPSD=5;

%% USER-DEFINED INPUT OPTIONS
if nargin>2
    options=getOptions(options,varargin);
end

%% PREPARE OUTPUT OPTIONS
options.FunctionPath=mfilename('fullpath');
options.ExecutionDate=datetime('now');
options.ExecutionDuration=tic;

%% FUNCTION CORE

% Narrow down the heart beat location
if strcmpi(options.MouseState,'awake')
    options.HeartbeatRange=[9 14];
elseif  strcmpi(options.MouseState,'anesthesia')
    options.HeartbeatRange=[2 6];
else
    options.HeartbeatRange=[]; % default: no assumption
end

Fs=options.FrameRate;

% Find Hemo peak
[Fhemo,optsHB]=FindHBpeak(reference,'FrameRate',Fs,'VerboseMessage',false,'VerboseFigure',false);
Fh=Fhemo.Location;
options.FreqHB=Fh;

% Data conditioning
M=double([source reference]);
[b,a]=butter(3,[Fh-2 Fh+2]/(Fs/2),'bandpass');
Mfilt=filtfilt(b,a,M);

% Run Unmixing
p=robustfit(Mfilt(:,2),Mfilt(:,1));
umxcoeff=p(2);
unmixsource=M(:,1)-p(2).*M(:,2); % compute the residual
[~, MSGID] = lastwarn();
warning('off', MSGID);

%% COMMAND WINDOW OUTPUT

if options.VerboseMessage
    fprintf('Unmixing coefficient is @ %2.3f \n',umxcoeff)
end

if options.VerboseFigure
    h=figure('Name','Output Summary for Robust Linear Regression (RLR) method');
    subplot(221)
    plot(M(1:100:end,end),M(1:100:end,1),'+k')
    hold on
    plot(M(1:100:end,end),unmixsource(1:100:end,1),'+r')
    hold off
    title('Correlation plot')
    xlabel('Reference')
    
    subplot(222)
    plotPSD([reference source unmixsource],'FrameRate',Fs,...
        'FreqBand',options.HeartbeatRange,'figureHandle',h);
    title('pWelch PSD plot')
    
    subplot(212)
    t=linspace(0,(length(source)-1)/Fs,length(source))';
    plot(t,reference,t,source,t,unmixsource)
    title('Time Trace for all signals')
    xlim([0 5*1/Fh])
    
    if options.Savefig
        if isempty(options.FigureDir)
            disp('Figure not saved. Input save directory.')
        else
            savePDF(h,'RLR Unmixing Summary',options.FigureDir)
        end
    end
end
options.ExecutionDuration=toc(options.ExecutionDuration);
options.FindHBpeak=optsHB;
end
