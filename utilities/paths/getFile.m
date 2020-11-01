function [filepath,filename,formatted_string,options]=getFile(varargin)
% EXAMPLE USE WITH ARGUMENTS
% [filepath,filename,formatted_string]=getFile()
% [filepath,filename,formatted_string]=getFile(options)
% This function prompts a window to choose a file, whose path is passed as an output argument 
% and corresponding matlab commands are formatted and copied to a clipboard.
%
% HISTORY
% - 19-04-12 12:25:04 - created by Radek Chrapkiewicz
% - 2020-04-06 21:34:43 - filter as an argument RC
% - 2020-05-05 19:41:33 - moving filter just to options. RC
% OPTIONS
%   - quiet - if true, doesn't display any messages 
%   - filter - like extension e.g. '*.tif'
%   - starting_path 
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!

%% OPTIONS

options.quiet=true;
options.filter='*.*';
options.starting_path='\\multiscope\J';
options.copy2clipboard=true;


%% CONSTANTS

persistent folderpath; % persistence is just to make the prompt dialog opening always in the same place

%% VARIABLE CHECK 

if nargin>=1
    options=getOptions(options,varargin);
end


%% PATHS

if isempty(folderpath)
    starting_path=options.starting_path;
else
    starting_path=folderpath;
    options.starting_path=folderpath;
end

if folderpath==0
    starting_path=options.starting_path;
end
    


%% CORE


[filename,folderpath_tmp,~]=uigetfile({options.filter},'Choose a file whose path you want to copy',starting_path);
if (filename==0)
    cprintf('yellow','No file selected\n');
    filepath=0;
    filename=0;
    formatted_string=0;
    return % something went wrong
else
    folderpath=folderpath_tmp;
end
% or pulls out the path from the variable
filepath=fullfile(folderpath,filename);
options.filepath=filepath;
formatted_string=sprintf('filepath=''%s'';\nfilename=''%s'';\nfolderpath=''%s'';\n',filepath,filename,folderpath);

if ~options.quiet
    fprintf('Formated text about %s copied to clipboard',filename)
end

if options.copy2clipboard
    clipboard('copy',formatted_string)
end


end  %%% END GETFILE
