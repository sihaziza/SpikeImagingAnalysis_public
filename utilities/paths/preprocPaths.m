function [folderStructure,summary]=preprocPaths(preprocessedRoot,varargin)
%
% HELP
% Creating folder structdure for preprocessing outputs.
% SYNTAX
%[folderStructure,summary]= preprocPaths() - use 1 if no arguments are allowed
%[folderStructure,summary]= preprocPaths(preprocessedRoot) - use 2, etc.
%[folderStructure,summary]= preprocPaths(preprocessedRoot,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[folderStructure,summary]= preprocPaths(preprocessedRoot,'options',options) - passing options as a structure.
%
% INPUTS:
% - preprocessedRoot - ...
%
% OUTPUTS:
% - folderStructure - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 27-Jun-2020 04:40:24 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!

%% CONSTANTS (never change, use OPTIONS instead)


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration

options.stages={'Loading','Registration','MotionCorrection','Unmixing'};
options.subfolders={'figs'};

%% VARIABLE CHECK 

if nargin==0
%do something when no arguments?
end

if nargin>=2
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% PATHS

%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.

mkdir_cell(preprocessedRoot,options.stages)

% creating subsubfolders
for ii=1:length(options.stages)
    mkdir_cell(fullfile(preprocessedRoot,options.stages{ii}),options.subfolders)
end

%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);

end

function mkdir_cell(root,subfolders_cell)
    for ii=1:length(subfolders_cell)
        mkdirex(fullfile(root,subfolders_cell{ii}))
    end
end

function mkdirex(folderpath)
% don't create the folder if exists 
if ~isfolder(folderpath)
    mkdir(folderpath)
end
end