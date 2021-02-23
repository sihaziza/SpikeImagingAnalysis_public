function [umxSource,umxCoeff,options]=unmixing1D(source,reference,varargin)
% GOAL: Unmix the two signal using various method.
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
% DEPENDENCIES: if ICA method is used > https://research.ics.aalto.fi/ica/fastica/
%
% EXAMPLE 1:
%     [umx,a,options]=unmixing1D(V,R); % uses default options
%
% EXAMPLE 2:
%     [umx,a,options]=unmixing1D(V,R,'UnmixingMethod','pca');
%
% CONTACT
% StanfordVoltageGroup@gmail.com
%
% HISTORY
% Created 2020-06-01 by Stanford Voltage Group, Schnitzer Lab


%% CHECK VARIABLES FORMATING
if nargin<2
    error('This function requires at least 2 vector inputs (source & reference).\n');
end

if ~isvector(source)||~isvector(reference)
    error('This function requires 2 vector inputs (source & reference).\n');
end

if mod(nargin-2,2)
    error('Variable input arguments work as Name-Value pairs.\n');
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
options.UnmixingMethod='HDM';
options.freqHemo=[];
%% USER-DEFINED INPUT OPTIONS
if nargin>2
    options=getOptions(options,varargin);
end

%% PREPARE OUTPUT OPTIONS
options.FunctionPath=mfilename('fullpath');
options.ExecutionDate=datetime('now');
options.ExecutionDuration=tic;

%% FUNCTION CORE

Fs=options.FrameRate;
mState=options.MouseState;
vMess=options.VerboseMessage;
vFig=options.VerboseFigure;
Fhemo=options.freqHemo;
% Run Unmixing
switch lower(options.UnmixingMethod)
    case 'hdm'
        if options.VerboseMessage
            cprintf('yellow','Unmixing with method [%s].\n','HDM');
        end
        [umxSource,umxCoeff,umxOptions]=umxHDM(source,reference,...
            'FrameRate',Fs,'MouseState',mState,...
            'VerboseMessage',vMess,'VerboseFigure',vFig);
    case 'rlr'
        if options.VerboseMessage
            cprintf('yellow','Unmixing with method [%s].\n','RLR');
        end
        [umxSource,umxCoeff,umxOptions]=umxRLR(source,reference,...
            'FrameRate',Fs,'MouseState',mState,...
            'VerboseMessage',vMess,'VerboseFigure',vFig);
    case 'pca'
        if options.VerboseMessage
            cprintf('yellow','Unmixing with method [%s].\n','PCA');
        end
        [umxSource,umxCoeff,umxOptions]=umxPCA(source,reference,...
            'FrameRate',Fs,'freqHemo',Fhemo,'MouseState',mState,...
            'VerboseMessage',vMess,'VerboseFigure',vFig);
    case 'ica'
        if options.VerboseMessage
            cprintf('yellow','Unmixing with method [%s].\n','ICA');
        end
        [umxSource,umxCoeff,umxOptions]=umxICA(source,reference,...
            'FrameRate',Fs,'MouseState',mState,...
            'VerboseMessage',vMess,'VerboseFigure',vFig);
end

options.umxOptions=umxOptions;
options.ExecutionDuration=toc(tic);
end
