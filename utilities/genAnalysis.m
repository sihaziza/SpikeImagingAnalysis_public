function genAnalysis(varargin)
% genAnalysis() - automatically creating analysis file
% genAnalysis(customfilename) - automatically creating analysis file
%
% HISTORY
% - % 2020-04-18 15:37:39 RC - created by RC
%
% TODO
% *1 add options checking
% *2 variables checking
%
% ISSUES
% #1

%% CONSTANTS

FILETYPE_DEFAULT='script'; % FUNCTION or SCRIPT

ext='.m';
AUTHOR='Radek Chrapkiewicz';

%% OPTIONS

options.author=AUTHOR;
options.filename='analysis';
options.adddate=true;
options.addhour=false;


%%% *1 add checking options from varargin !

if nargin>=1
    options.filename=varargin{1};
end


try
    
    %% VARIABLE CHECK
    
    hTime=Time;
    
    if ~options.addhour
        hTime.reformat('days')
    end
    
    if options.adddate
        filename=[options.filename,'_',strrep(hTime.now,'-','')];
    else
        filename=options.filename;
    end
    
    
    if ~strcmp(filename(end-1:end),'.m')
        filename=[filename,'.m'];
    end
    
    filename_noext=filename(1:end-2);
    
    if exist(filename)
        warning('This file already exist, this function won''t override for safety reasons')
        return;
    end
  
% *2 TO REWRITE
%     if nargin>=2
%         if ~isempty(varargin{1})
%             if isfolder(varargin{1})
%                 destination_folder=varargin{1};
%                 fprintf('Creating %s in %s folder\n',filename,destination_folder);
%                 filename=fullfile(destination_folder,filename);
%             end
%         else
%             destination_folder=cd;
%         end
%     end
%     
%     
%     if nargin>=3
%         filetype=varargin{2};
%         if isempty(filetype)
%             filetype=FILETYPE_DEFAULT;
%         end
%     else
%         filetype=FILETYPE_DEFAULT;
%     end
%     
%     switch upper(filetype)
%         case 'FUNCTION'
%             ifunction=true;
%         case 'SCRIPT' % #1
%             ifunction=false;
%         otherwise
%             error('%s file type not supported',filetype)
%     end
%     
%     
%     if nargin>=4
%         dialogtype=varargin{3};
%     else
%         dialogtype='';
%     end
%     
%     
    %% CORE
    
    fileID = fopen(filename,'w');
    
    

   fprintf(fileID,'%% Automatically generate analysis file: %s\n',filename_noext);

    
    
    prompt = 'Provide a short description of the created file \n';
    user_description = input(prompt,'s');
    
    fprintf(fileID,'%%\n%% HELP\n');
    fprintf(fileID,'%% %s\n',user_description);
    fprintf(fileID,'%%\n%% HISTORY\n');
    day=Time.day;
    hour=Time.hour;
    fprintf(fileID,'%% - %s %s - created by %s\n',day,hour,AUTHOR);
%     fprintf(fileID,'%%\n%% ISSUES\n');
%     fprintf(fileID,'%% #1 - issue 1\n');
%     fprintf(fileID,'%%\n%% TODO\n');
%     fprintf(fileID,'%% *1 - get the first working version of the function!\n');

    fprintf(fileID,'\n%%%% PATHS\n');
    fprintf(fileID,'\noriginal_folderpath=''%s'';\n',pwd);
    %% prompting dialog for file paths
%     path=0;
%     if ~isempty(dialogtype)
%         switch dialogtype
%             case 'file'
%                 path=getFile;
%             case 'folder'
%                 path=getFolder;
%             otherwise
%                 error('%s dialog type not supported',dialogtype)
%         end
%     end
%     
%     if path % pasted from a dialog for nargin>=4
%         text_from_clipboard = clipboard('paste');
%         text_from_clipboard=strrep(text_from_clipboard,'%','%%');
%         text_from_clipboard=strrep(text_from_clipboard,'\','\\');
%         fprintf(fileID,text_from_clipboard);
%     end
    
    
    fprintf(fileID,'\n\n%%%% CORE\n%%The core of the function should just go here. ');
%     if path
%         fprintf(fileID,'\n\nrec=Recording(filepath);\n');
%     end
    
    
%% automatic copyting of the script to repo
  fprintf(fileID,'\n\n\n%%%% EXECUTE THIS SECTION COPY THIS ANALYSIS SCRIPT TO REPO''S PRIVATE FOLDER\n');
  fprintf(fileID,'pathtoscript = matlab.desktop.editor.getActiveFilename;\n');
  fprintf(fileID,'[~,scrtiptname,ext]=fileparts(pathtoscript);\n');
  % OBSOLETE % 2020-05-13 02:08:35 RC
%   fprintf(fileID,'if strcmp(getenv(''computername''),''BFM'')\n');
%   fprintf(fileID,'    pathtorepo=fileparts(which(''installBFM''));\n');
%   fprintf(fileID,'else\n');
%   fprintf(fileID,'pathtorepo=fileparts(which(''install'')); %% path to microscopes recordings instead\n');
%   fprintf(fileID,'end\n');

fprintf(fileID,'pathtorepo=getPath;\n');

fprintf(fileID,'destinationfolder=''private\\analysis_history'';\n');
fprintf(fileID,'%%Alternatively:\n');
fprintf(fileID,'%%destinationfolder=''private\\figures_history'';\n');
fprintf(fileID,'%%destinationfolder=''private\\movies_history''; %% etc.\n');
fprintf(fileID,'destinationfolder=fullfile(pathtorepo,destinationfolder);\n');
fprintf(fileID,'if ~exist(destinationfolder)\n');
fprintf(fileID,'   mkdir(destinationfolder)\n');
fprintf(fileID,'end\n');
fprintf(fileID,'newscriptpath=fullfile(destinationfolder,[scrtiptname,ext])\n');
fprintf(fileID,'copyfile(pathtoscript,newscriptpath,''f'')\n');



    
    fclose(fileID);
    
    edit(filename);
    
catch ME
%     fclose(fileID);
    ME
    util.errorHandling(ME)
    keyboard
end


end