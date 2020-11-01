function [options]=genReadme(varargin)
% EXAMPLE USE WITH ARGUMENTS
%[options]= genReadme() - use 1
%[options]= genReadme(readme_suffix) - use 2, etc.
%[options]= genReadme(readme_suffix,folderpath) - use 3 with options
%[options]= genReadme(readme_suffix,folderpath,options) - use 3 with options
%
% HELP
% Generating readme text file in the given folder describing e.g. package functionality.
%
% HISTORY
% - 20-05-05 18:14:50 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% CONSTANTS (never change, use OPTIONS instead)
DEFAULT_AUTHOR='Schnitzer Lab'; % only if not pc and can't recognize 
FUNCTION_AUTHOR='Radek Chrapkiewicz (radekch@stanford.edu)';
DEBUG_THIS_FILE=true; %enter keyboard environment if error


try
    %% OPTIONS
    
    
    % setting default for the author option depending on the user name
    if ispc
        username=getenv('username');
        if strcmpi(username(1:2),FUNCTION_AUTHOR(1:2))
            options.author=FUNCTION_AUTHOR;
        else
            options.author=username;
        end
    else
        options.author=DEFAULT_AUTHOR;
    end
    
    options.PastePath=false; % assuming path is in the keyboard
    options.filetype='function'; % other types not supported yet.
    
    options.UseSuffix=true;
    options.Suffix=''; % folder name on default
    options.FileNameCore='README';
    options.Extension='.txt';
    
    options.SuffixAsParentFolder=true; % if suffix is not specified use the parent folder name for the suffix (crop @ or + symbols)
    
    
    %% VARIABLE CHECK
   

    
    if nargin>=1
        options.Suffix=varargin{1};
    end
    
    if nargin>=2
        folderpath=varargin{2};
    else 
        folderpath=pwd;
    end
    
    if nargin>=3
        options=getOptions(options,varargin(2:end));
    end
    
    % setting up parent folder name as a suffix if suffix not provided    
    if options.SuffixAsParentFolder && isempty(options.Suffix)
        [~,parentfoldername]=fileparts(folderpath);
        options.Suffix=parentfoldername;
    end
    
    if isempty(options.Suffix)
        filename=[options.FileNameCore,options.Extension];
    else
        filename=[options.FileNameCore,'_',options.Suffix,options.Extension];
    end
    

    if exist(fullfile(folderpath,filename),'file')
        warning('This file already exist, this function won''t override for safety reasons')
        return;
    end
    
    if nargin>=2
        if ~isempty(varargin{1})
            if isfolder(varargin{1})
                destination_folder=varargin{1};
                fprintf('Creating %s in %s folder\n',filename,destination_folder);
                filename=fullfile(destination_folder,filename);
            end
        else
            destination_folder=pwd;
            options.folderpath=destination_folder; % potential issue if you want to use recurrently
        end
    end

    %% CORE
    
    fileID = fopen(filename,'w');
    
    prompt = 'Provide a short README description \n';
    user_description = input(prompt,'s');
    fprintf(fileID,'%s\n',user_description);
    

    
    
    fprintf(fileID,'\n\n');
    fprintf(fileID,'# HISTORY\n');
    day=Time.day;
    hour=Time.hour;
    fprintf(fileID,' - %s %s - created by %s\n',day,hour,options.author);
    fprintf(fileID,'# ISSUES\n');
    fprintf(fileID,'- #1 - issue 1\n');
    fprintf(fileID,'# TODO\n');
    fprintf(fileID,'- *1 - get the first working version of the function!\n');
    


   
    
    fprintf(fileID,'\n%%%% PATHS\n');
    
    if options.PastePath %assuming someone previously used getFile or getFolder
        text_from_clipboard = clipboard('paste');
        text_from_clipboard=strrep(text_from_clipboard,'%','%%');
        text_from_clipboard=strrep(text_from_clipboard,'\','\\');
        fprintf(fileID,text_from_clipboard);
    end
    

    
    fclose(fileID);
    edit(filename);
    
    
catch ME
    fclose(fileID);
    util.errorHandling(ME)
    if DEBUG_THIS_FILE
        keyboard
    end
end


end