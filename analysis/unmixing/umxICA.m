function [unmixsource,umxcoeff,options]=umxICA(source,reference,varargin)
% GOAL: Unmix the two signal using Blind Source Separation method.
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
% DEPENDENCIES: FastICA https://research.ics.aalto.fi/ica/fastica/
% 
% EXAMPLE 1:
%     [umx,a,options]=umxICA(V,R); % uses default options
% 
% EXAMPLE 2:
%     [umx,a,options]=umxICA(V,R,'FrameRate',100);
% 
% HISTORY
%     - 2020-06-01 - created by Simon Haziza,PhD (sihaziza@stanford.edu)
% 
% TO IMPLEMENT
% ICASSO: analysing and visualising the reliability of independent components
% ISCTEST: principled statistical testing of independent components

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
options.Savefig=true;
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

% Data conditioning
M=[source reference];
[b,a]=butter(3,[Fh-2 Fh+2]/(Fs/2),'bandpass');
Mfilt=filtfilt(b,a,M);

% Run Unmixing
[icasig, ~, W] = fastica(Mfilt','approach','symm','g','tanh','epsilon',1e-6,'stabilization','on','displayMode','on','verbose','off');
icaS=normalize(icasig');
[Fhemo1,~]=unmixing.FindHBpeak(icaS(:,1),'FrameRate',Fs,'VerboseMessage',false,'VerboseFigure',false);
[Fhemo2,~]=unmixing.FindHBpeak(icaS(:,2),'FrameRate',Fs,'VerboseMessage',false,'VerboseFigure',false);

if (Fhemo1.Prominence>Fhemo2.Prominence)
    idxHemo=1;
else
    idxHemo=2;
end
if options.VerboseMessage
    fprintf('The hemodynamic signal is in column%2.0f.\n',idxHemo)
end

alpha=abs(W(idxHemo,idxHemo)/W(2,2));
% Highest variance PC1 is hemodynamic aka reference. Source is the first
% input. The signal can be reconstructed using the first element of the
% diagonal/anti-diagonal ratio.
temp=diag(W,0)/diag(W,1);
temp=diag(W,1)/diag(W,0);
W./[diag(W,1) diag(W,-1)];
umxcoeff=temp(1); 
unmixsource=M(:,1)-umxcoeff.*M(:,2); % compute the residual
% solve this wave change... so annoying

options.ICAcoeff=coeff;
options.ICAexplained=explained;
    
%% COMMAND WINDOW OUTPUT

if options.VerboseMessage
    fprintf('Unmixing coefficient is @ %2.3f \n',umxcoeff)
end

if options.VerboseFigure
    h=figure('Name','Output Summary for Independent Component Analysis (ICA) method');
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
    xlim([0 10*1/Fh])
    
    if options.Savefig
        if isempty(options.FigureDir)
            disp('Figure not saved. Input save directory.')
        else
            savePDF(h,'PCA Unmixing Summary',options.FigureDir)
        end
    end
end
options.ExecutionDuration=toc(options.ExecutionDuration);
options.FindHBpeak=optsHB;
end


