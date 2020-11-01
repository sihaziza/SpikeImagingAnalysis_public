function [fstamps_path,summary]=find_framestapms(h5orDCIMGpath,varargin)
%
% HELP
% Finding a frame stamp file just given a file location. If h5 file, it is expected to be found in a subfolder
% SYNTAX
%[fstamps_path,summary]= find_framestapms() - use 1 if no arguments are allowed
%[fstamps_path,summary]= find_framestapms(h5orDCIMGpath) - use 2, etc.
%[fstamps_path,summary]= find_framestapms(h5orDCIMGpath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[fstamps_path,summary]= find_framestapms(h5orDCIMGpath,'options',options) - passing options as a structure.
%
% INPUTS:
% - h5orDCIMGpath - ...
%
% OUTPUTS:
% - fstamps_path - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 29-Jun-2020 16:27:42 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below 
options.h5subfolder='LVmeta';

%% VARIABLE CHECK 

if nargin==0
%do something when no arguments?
end


if nargin>=1
%do something when more than 1 arguments?
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
[folderpath,filename,ext]=fileparts(h5orDCIMGpath);
if ~isfile(h5orDCIMGpath)
    if isfolder(folderpath)
        warning('File %s does not exist, but the folder %s does. Searching in',filename,folderpath);
    else 
        error('Neither file %s nor folder %s exist',filename,folderpath)
    end
end

switch lower(ext)
    case '.h5'
        folder2serach=fullfile(folerpath, options.h5subfolder);
        if ~isfolder(folder2serach)
            error('Expected to find subfolder %s in %s to serach for metadata. Did not find it!', options.h5subfolder,folderpath);
        end
    case '.dcimg'
        folder2serach=folderpath;
    otherwise
        error('Extension %s is not supported',ext)
end

flist=dir(fullfile(folder2serach,'*framestamps*.txt'));
if isempty(flist)
    error('Frame stamp file was not found')
elseif length(flist)>=2
    warning('Multiple frame stamp files have been found in %s folder',folder2serach);
end

fstamps_path=fullfile(flist(1).folder,flist(1).name);






%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);


end  %%% END FIND_FRAMESTAPMS
