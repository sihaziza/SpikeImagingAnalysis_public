function [metadata,summary]=h5readmeta(fpath,varargin)
% HELP
% Reading all metadata from the h5 file while skiping the main dataspace with movie ('/mov' on defaults
% SYNTAX
%[metadata,summary]= h5readmeta(fpath) - use 2, etc.
%[metadata,summary]= h5readmeta(fpath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[metadata,summary]= h5readmeta(fpath,'options',options) - passing options as a structure.
%
% INPUTS:
% - fpath - path to h5 file
%
% OUTPUTS:
% - metadata - structure metadata reflecting the content of the h5 file.
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 29-Jun-2020 23:52:00 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below 
options.skip='mov'; % dataset to skip
options.verbose=1;


%% VARIABLE CHECK 

if nargin>=2
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use


%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.

info=h5info(fpath);
summary.h5info=info;

datasets=info.Datasets;
groups=info.Groups;

metadata=struct;
idx=0;
for ii=1:length(datasets)
    name=datasets(ii).Name;
    if strcmp(name,options.skip)
        disp(['Found ' name ' - skipping']);
        continue;
    else
        idx=idx+1;
        metadata.(name)=h5read(fpath,['/', name]); % using h5 read for datasets as h5laod returns errors % - 2020-06-30 00:03:41 -   RC
    end
end

disp(sprintf('Read %d datasets',idx));

disp('Reading groups')
for ii=1:length(groups)
    name=groups(ii).Name;
    metadata.(name(2:end))=h5load(fpath,name); % using h5load for groups in contrast to h5read for datasets  2020-06-30 00:03:41 -   RC
end

disp(sprintf('Read %d groups',length(groups)));
disp('Finished');

%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);

    function disp(string) %overloading disp for this function
        if options.verbose
            fprintf('%s h5readmeta: %s\n', datetime('now'),string);
        end
    end

end  %%% END H5READMETA
