function [file_info,summary]=h5addmeta(h5path,meta_structure,varargin)
%
% HELP
% Saving metadata to the file from a structure. Creating datasets whose names correspond to the structure fieldnames.
% SYNTAX
%[file_info,summary]= h5addmeta() - use 1 if no arguments are allowed
%[file_info,summary]= h5addmeta(h5path) - use 2, etc.
%[file_info,summary]= h5addmeta(h5path,meta_structure) - use 3, etc.
%[file_info,summary]= h5addmeta(h5path,meta_structure,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[file_info,summary]= h5addmeta(h5path,meta_structure,'options',options) - passing options as a structure.
%
% INPUTS:
% - h5path - ...
% - meta_structure - ...
%
% OUTPUTS:
% - file_info - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 28-Jun-2020 01:56:44 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct;
options.verbose=1;

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

fnames=fieldnames(meta_structure);

for ii=1:length(fnames)
   try 
       h5save(h5path,meta_structure.(fnames{ii}),['',fnames{ii}]); % adding datasets one by one 
   catch
       disp(sprintf('Can''t create the dataset %s in %s',fnames{ii},h5path));
   end
end

file_info=h5info(h5path);



%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);

    function disp(string) %overloading disp for this function
        if options.verbose
            fprintf('%s h5addmeta: %s\n', datetime('now'),string);
        end
    end

end