function [frame,summary]=h5frame(fpath,iframe,varargin)
%
% HELP
% Load one frame from a movie.
% SYNTAX
%[frame,summary]= h5frame() - use 1 if no arguments are allowed
%[frame,summary]= h5frame(fpath) - use 2, etc.
%[frame,summary]= h5frame(fpath,iframe) - use 3, etc.
%[frame,summary]= h5frame(fpath,iframe,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[frame,summary]= h5frame(fpath,iframe,'options',options) - passing options as a structure.
%
% INPUTS:
% - fpath - ...
% - iframe - ...
%
% OUTPUTS:
% - frame - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 30-Jun-2020 04:10:43 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!

%% CONSTANTS (never change, use OPTIONS instead)


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below 
options.dataset='/mov';

%% VARIABLE CHECK 

if nargin>=3
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use


%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.
msize=h5moviesize(fpath,'dataset',options.dataset);
frame=h5read(fpath,options.dataset,[1,1,iframe],[msize(1:2),1]);


%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);


end  %%% END H5FRAME
