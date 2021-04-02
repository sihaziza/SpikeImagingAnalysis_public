function [unmixsource,umxcoeff,options]=umxHDM(source,reference,varargin)
% GOAL: Minimization of the energy within the heartbeat frequency band. This 
% function works on vector variable only.
% 
% INPUT:
%     - source: input signal to be unmixed 
%     - reference: input reference.
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
%     [umx,a,options]=umxHDM(V,R); % uses default options
% 
% EXAMPLE 2:
%     [umx,a,options]=umxHDM(V,R,'FrameRate',100);
% 
% HISTORY
%     - 2020-06-01 - created by Simon Haziza,PhD (sihaziza@stanford.edu)

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
    options.HeartbeatRange=[2 14]; % default: no assumption
end

Fs=options.FrameRate;

% Find Hemo peak
[Fhemo,optsHB]=FindHBpeak(source,'FrameRate',Fs,'VerboseMessage',false,'VerboseFigure',false);
Fh=Fhemo.Location;
options.FreqHB=Fh;

% Run optimization
Valpha=(0:0.01:2)';
x=source*ones(size(Valpha))';
y=reference*Valpha';
E=bandpower(x-y,Fs,[Fh-2 Fh+2]);
[Eval,idx]=min(E);
umxcoeff=Valpha(idx);
unmixsource=source-umxcoeff.*reference;

%% COMMAND WINDOW OUTPUT

if options.VerboseMessage
    fprintf('Unmixing coefficient is @ %2.3f \n',umxcoeff)
end

if options.VerboseFigure
    h=figure('Name','Output Summary for HemoDynamic Minimization (HDM) method');
    subplot(221)
    plot(Valpha,E','k','linewidth',2)
    hold on
    plot([umxcoeff umxcoeff],[Eval Eval],'+r','linewidth',2,'markersize',10)
    hold off
    title('Evolution of Hemodynamic peak power')
    xlabel('unmixing coefficient')
    
    subplot(222)
    plotPSD([reference source unmixsource],'FrameRate',Fs,...
        'FreqBand',options.HeartbeatRange,'figureHandle',h);
    title('pWelch PSD plot')
    
    subplot(212)
    t=linspace(0,(length(source)-1)/Fs,length(source))';
    plot(t,reference,t,source,t,unmixsource)
    title('Time Trace for Reference and Source signals')
    xlim([0 10*1/Fhemo.Location])
    
    if options.Savefig
        if isempty(options.FigureDir)
            disp('Figure not saved. Input save directory.')
        else
            savePDF(h,'HDM Unmixing Summary',options.FigureDir)
        end
    end 
end
    options.ExecutionDuration=toc(options.ExecutionDuration);
    options.FindHBpeak=optsHB;
end
