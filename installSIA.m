function folders_on_path=installSIA()
% EXAMPLE USE WITH ARGUMENTS
% folders_on_path=installVIA()
%
% This function automatically intall whole "VoltageImagingAnalisis" package by permanently configuring the paths.
% In the future releases it will also check dependencies for the external packages and programs.
%
% HISTORY
% - 19-04-24 15:55:12 - created by Simon Haziza, originally for BFM
% - 2019-09-20 11:06:43  adapted for BFM  by RC
% - 2020-04-18 14:30:05 RC - fixing bug with empty options.FoldersToAdd
% - 2020-05-22 23:24:16 RC - uzipping some packages if they are not found
% on the path.
% - 2020-06-15 17:44:60 RC - removing Biafra and MicroscopesRecordings
% dependencies
% - cleaned up display, and removed warnings RC
% - 2020-06-30 20:58:13 - installing the new structure with all subfolders
% handled by 'genpath' RC
% - 2020-07-18 15:05:33 - updated the Folder Lists for the new organization SH


%% OPTIONS (THERE IS NO GET OPTIONS YET, SO YOU CANNOT INPUT THEM YET AS NORMALLY
options.unzip_quickaccessfunctions=false; % obsolete 06/30/2020 RC
options.ExternalPackages=false;
options.FoldersToAdd={'dependencies','preprocessing','packages','utilities'};

%% VARIABLE CHECK

%% PATHS
function_path = mfilename('fullpath');
voltageanalysis_shared_path=fileparts(function_path);
folder_list=[]; % otherwise it will return an error fi no folcers on the default list
disps('Installing "VoltageImagingAnalysis" package')
disps(voltageanalysis_shared_path);

for ii=1:length(options.FoldersToAdd)
    if ii==1
        folder_list=dir(fullfile(voltageanalysis_shared_path,options.FoldersToAdd{ii}));
    else
        folder_list=[folder_list;dir(fullfile(voltageanalysis_shared_path,options.FoldersToAdd{ii}))];
    end
    
end


%% CORE
%The core of the function should just go here.

addpath(voltageanalysis_shared_path);
disps(sprintf('Added to the Matlab path the main folder: %s',voltageanalysis_shared_path));


disps('Adding to the path subfolders')
for ii=1:length(folder_list)
    folder=folder_list(ii).name;
    if isfolder(folder) && ~strcmp(folder,'.') && ~strcmp(folder,'..')
        addpath(folder);
        disps(sprintf('Added to the Matlab path : %s and its subfolders',folder));
    end
end

for ii=1:length(options.FoldersToAdd)
    addpath(genpath(fullfile(voltageanalysis_shared_path,options.FoldersToAdd{ii})));
    disps(sprintf('Added to the Matlab path %s',fullfile(voltageanalysis_shared_path,options.FoldersToAdd{ii})));
end


savepath;
disps('New folder list saved on path')
if options.unzip_quickaccessfunctions
    %% unzipping
    disps('Checking if quick access function are on the path')
    if ~exist('quick_access_functions')
        disps('Unzipping quick access functions and adding them to the repo path')
        unzip('installation\quick_access_functions.zip','\');
        addpath('quick_access_functions');
        savepath
        disps('Quick access functions added to the path')
    end
end

%% adding external packages such as extract, normcorre, or biafra's packages

disps('Checking dependencies.... ')

if options.ExternalPackages
    answear=input('Do you want to load external packages such as NORMCORRE for motion correction? [y/n]\n','s');
else
    answear='N';
end

if strcmpi(answear,'N')
    disps('OK, not loading external packages, as you wish');
    
end
if strcmpi(answear,'Y')
    disps('Here you go, loading external packages')
    

    
    disps('Provide folder for normcorre')
    normcorre_folder=getFolder;
    if normcorre_folder
        addpath(normcorre_folder);
        savepath
    end
    
end



disps('VoltageImagingAnalysis instalation finished')
folders_on_path=folder_list;


function disps(string) %overloading disp for this function 
    FUNCTION_NAME='installVIA';
    fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
end

end  %%% END INSTALL

function onPath=isOnPath(folder)
% doesn't seem to work...
% adapted from
% https://www.mathworks.com/matlabcentral/answers/86740-how-can-i-determine-if-a-directory-is-on-the-matlab-path-programmatically
warning('This function doesn''t really seem to work, I am disabling its use')
onPath=-1;
return
pathCell = regexp(path, pathsep, 'split');
if ispc  % Windows is not case-sensitive
    onPath = any(strcmpi(folder, pathCell));
else
    onPath = any(strcmp(folder, pathCell));
end
end

function [folderpath_out,foldername,formatted_string]=getFolder(varargin)
% EXAMPLE USE WITH ARGUMENTS
% getFolder() - dialog
% getFolder(initial_folder_path) - folder to start
%
% This function prompts a window to choose a folder, whose path is passed
% as an output argument and corresponding matlab commands are formatted
% and conviniently copied to a clipboard.
%
% by Radek Chrapkiewicz 2019-2020


%% CONSTANTS

persistent folderpath;

DEFAULT_PATH='C:\Users';


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


folderpath_out=folderpath;

end  %%% END GETFILE

