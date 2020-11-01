function [folderpath_out,foldername,formatted_string]=getFolder(varargin)
% EXAMPLE USE WITH ARGUMENTS
% getFolder() - dialog
% getFolder(initial_folder_path) - folder to start
%
% This function prompts a window to choose a folder, whose path is passed 
% as an output argument and corresponding matlab commands are formatted
% and conviniently copied to a clipboard.
%
% HISTORY
% - 2019-04-12 12:40:24 - created by Radek Chrapkiewicz
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!

try

%% CONSTANTS

persistent folderpath;

DEFAULT_PATH='I:\Radek';


%% VARIABLE CHECK 

if nargin>=1
    initial_folder_path=varargin{1};
    if ~isfolder(initial_folder_path)
        warning('%s is not a valid folder path!', initial_folder_path)
        initial_folder_path=DEFAULT_PATH;
    end
else
    if isempty(folderpath)
        initial_folder_path=DEFAULT_PATH;
    elseif folderpath==0
        initial_folder_path=DEFAULT_PATH;
    else
        initial_folder_path=folderpath;
    end
end


%% PATHS


%% CORE

folderpath_tmp=uigetdir(initial_folder_path,'Choose a folder whose path you want to copy');
if (folderpath_tmp==0)
    warndlg('No folder selected','FATAL ERROR')
    cprintf('yellow','Terminating')
    folderpath_out=0;
    return % something went wrong
else
    folderpath=folderpath_tmp;
end
% or pulls out the path from the variable
[~,foldername,~]=fileparts(folderpath);

formatted_string=sprintf('folderpath=''%s'';\nfoldername=''%s'';\n',folderpath,foldername);

fprintf('Formated text about %s copied to clipboard\n',foldername)

clipboard('copy',formatted_string) 

folderpath_out=folderpath;

catch  ME
    ME
    ME.stack(1)
    keyboard
end 
    

end  %%% END GETFILE
