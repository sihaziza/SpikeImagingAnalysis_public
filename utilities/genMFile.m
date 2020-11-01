function [summary]=genMFile(filename,varargin)
% genMFile(filename)
% genMFile(filename)
% genMFile(filename,'optionsName',optionsValue,...) - check out below
% OPTIONS section in the main function body to review witch options are
% available to reconfigure this function.
% dialog to create filepaths
% function used to generate standarized functions, script and classes
%
% HISTORY
% - 2019-04-12 11:31:35 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-05-05 01:53:56 - introducing options and removing old, rarely used
% input arguments such as: % genMFile(filename,destination_folder,filetype,'folder'/'file')
% -  2020-05-23 01:26:48 - custom names for output structure, genReport for
% error handling RC
%
%
% TODO
% - function generating class template
% - add more strings from genMethod % 2020-04-29 01:34:34 RC
%
% ISSUES
%
% DETAILED HELP AND DEMO
% MicroscopesRecordings is equipped with a comprehensive, reconfigurable
% function generating function codes that are meeting the above specification.
% You can simply create a function executing the following command:
%
% genMFile('yourFunctionName')
%
% Then you will be asked for a short description that will be placed in the HELP section of the function preamble.
%
% You can also define inputs and/or outputs while calling the genMFile so as the inputs/outputs specification
% will be formatted for you automatically. Example with the optional parameters:
%
% genMFile('yourFunctionName','Inputs',{'argin1','argin2'},'Outputs',{'argout1','argout2','argout3'})

%% CONSTANTS (never change, use OPTIONS instead)
DEFAULT_AUTHOR='Schnitzer Lab'; % only if not pc
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
    
    options.Inputs={'arg1','arg2'}; % define input artuments
    options.Outputs={'output_arg1'}; % define input artuments
    
    
    options.PastePath=false; % assuming path is in the keyboard
    options.filetype='function'; % other types not supported yet.
    options.UseOptions=true;
    options.UseRecording=false;
    options.Debug=false;
    
    options.UnfinishedError=true;
    
    options.OutputStructureName='summary';
    
    options.Summary=true; % summarizing the function diagnostic
    
    options.SummarizeAutoGeneration=false;
    
    options.ShowInputOptionsSummary=false;
    
    
    
    
    %% VARIABLE CHECK
    
    if nargin==0
        warning('Provide at least a function name! Terminating')
        return
    end
    
    if ~strcmp(filename(end-1:end),'.m')
        filename=[filename,'.m'];
    end
    
    filename_noext=filename(1:end-2);
    
    if exist(fullfile(pwd,filename),'file')
        warning('This file already exist, this function won''t override for safety reasons')
        return;
    end
    
    % OBSOLETE % 2020-05-23 02:42:07 RC
    %     if nargin>=2
    %         if ~isempty(varargin{1})
    %             if isfolder(varargin{1})
    %                 destination_folder=varargin{1};
    %                 fprintf('Creating %s in %s folder\n',filename,destination_folder);
    %                 filename=fullfile(destination_folder,filename);
    %             end
    %         else
    %             destination_folder=pwd;
    %             options.folderpath=destination_folder; % potential issue if you want to use recurrently
    %         end
    %     end
    
    
    if nargin>=2
        options=getOptions(options,varargin(1:end));
    end
    input_options=options;
    
    %% Summary setup
    try
        summary.function_path=mfilename('fullpath');
        summary.execution_started=datetime('now');
        summary.execution_duration=tic;
        if ispc
            summary.computer=getenv('computername');
            summary.user=getenv('username');
        else
            summary.computer='non-PC';
        end
%         summary.git_commit_voltage=gitLastCommit(getPath('FunctionName','installVIA')); % this dependency will be removed 2020-05-23 02:25:23 RC
%         summary.git_commit_mrecordings=gitLastCommit(getPath('FunctionName','install'));
    catch ME1
        genReport(ME1)
        warning('Generating summary did not work');
    end
    
    
    %% CORE
    
    fileID = fopen(filename,'w');
    
    arguments_string='';
    for ii=1:length(options.Inputs)
        if ii==1
            arguments_string=options.Inputs{1};
        else
            arguments_string=[arguments_string,',',options.Inputs{ii}];
        end
    end
    
    arguments_string_out='';
    for ii=1:length(options.Outputs)
        if ii==1
            arguments_string_out=options.Outputs{1};
        else
            arguments_string_out=[arguments_string_out,',',options.Outputs{ii}];
        end
    end
    
    if strcmpi(options.filetype,'function')
        if options.UseOptions
            fprintf(fileID,'function [%s,%s]=%s(%s,varargin)\n',arguments_string_out,options.OutputStructureName,filename_noext,arguments_string);
            prompt = 'Provide a short description of the created file \n';
            user_description = input(prompt,'s');
            
            fprintf(fileID,'%%\n%% HELP\n');
            fprintf(fileID,'%% %s\n',user_description);
            fprintf(fileID,'%% SYNTAX\n');
            fprintf(fileID,'%%[%s,%s]= %s() - use 1 if no arguments are allowed\n',arguments_string_out,options.OutputStructureName,filename_noext);
            arguments_string='';
            for ii=1:length(options.Inputs)
                if ii==1
                    arguments_string=options.Inputs{1};
                else
                    arguments_string=[arguments_string,',',options.Inputs{ii}];
                end
                fprintf(fileID,'%%[%s,%s]= %s(%s) - use %i, etc.\n',cell2mat(options.Outputs),options.OutputStructureName,filename_noext,arguments_string,ii+1);
            end
            fprintf(fileID,'%%[%s,%s]= %s(%s,''optionName'',optionValue,...) - passing options using a ''Name'', ''Value'' paradigm frequently used by Matlab native functions.\n',cell2mat(options.Outputs),options.OutputStructureName,filename_noext,arguments_string);
            fprintf(fileID,'%%[%s,%s]= %s(%s,''options'',options) - passing options as a structure.\n',cell2mat(options.Outputs),options.OutputStructureName,filename_noext,arguments_string);
            fprintf(fileID,'%%\n%% INPUTS:\n');
            for ii=1:length(options.Inputs)
                fprintf(fileID,'%% - %s - ...\n', options.Inputs{ii});
            end
            fprintf(fileID,'%%\n%% OUTPUTS:\n');
            for ii=1:length(options.Outputs)
                fprintf(fileID,'%% - %s - ...\n', options.Outputs{ii});
            end
            fprintf(fileID,'%% - %s - % - structure containing extra function outputs, diagnostic of execution, performance \n%% as well as the internal configuration of the function that includes all input options structure \n%% containing an internal configuration of the function that includes all input options as well as the imporant parameters characterizing the function configuration, performance and execution. \n',options.OutputStructureName);
            fprintf(fileID,'%%\n%% OPTIONS:\n%% - see below the section of code showing all possible input options and comments for their meaning. \n');
        else
            fprintf(fileID,'function %s(varargin)\n',filename_noext);
            prompt = 'Provide a short description of the created file \n';
            user_description = input(prompt,'s');
            
            fprintf(fileID,'%%\n%% HELP\n');
            fprintf(fileID,'%% %s\n',user_description);
            fprintf(fileID,'%% SYNTAX\n');
            fprintf(fileID,'%%%s() - use 1\n',filename_noext);
            fprintf(fileID,'%%%s(arg1) - use 2, etc.\n',filename_noext);
            fprintf(fileID,'%%%s(arg1,arg2) - use 3\n',filename_noext);
        end
    end
    
    
    
    fprintf(fileID,'%%\n%% HISTORY\n');

    fprintf(fileID,'%% - %s - created by %s\n',datetime('now'),options.author);
    fprintf(fileID,'%%\n%% ISSUES\n');
    fprintf(fileID,'%% #1 - issue 1\n');
    fprintf(fileID,'%%\n%% TODO\n');
    fprintf(fileID,'%% *1 - get the first working version of the function!\n');
    
    if strcmpi(options.filetype,'function') && options.Debug
        fprintf(fileID,'\n\ntry\n');
    end
    
    fprintf(fileID,'\n%%%% CONSTANTS (never change, use OPTIONS instead)\n');
    fprintf(fileID,'DEBUG_THIS_FILE=false;\n');

    if options.UseOptions
        fprintf(fileID,'\n%%%% OPTIONS (Biafra style, type ''help getOptions'' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/''options'':-structure-with-function-configuration\n');
        fprintf(fileID,'options=struct; %% add your options below \n');
    end
    
    
    if strcmpi(options.filetype,'function')
        fprintf(fileID,'\n%%%% VARIABLE CHECK \n');
        fprintf(fileID,'\nif nargin==0\n%%do something when no arguments?\nend\n');
        fprintf(fileID,'\n\nif nargin>=1\n%%do something when more than 1 arguments?\nend\n');
        if options.UseOptions
            fprintf(fileID,'\n\nif nargin>=2\noptions=getOptions(options,varargin(1:end)); %% CHECK IF NUMBER OF THE OPTION ARGUMENT OK!\nend\ninput_options=options; %% saving orginally passed options to output them in the original form for potential next use\n');
        end
    end
    
    
    fprintf(fileID,'\n%%%% PATHS\n');
    if options.Summary
        fprintf(fileID,'\n%%%% Summary preparation\n');
        fprintf(fileID,'%s.function_path=mfilename(''fullpath'');\n',options.OutputStructureName);
        fprintf(fileID,'%s.execution_started=datetime(''now'');\n',options.OutputStructureName);
        fprintf(fileID,'%s.execution_duration=tic;\n',options.OutputStructureName);
    end
    
    if options.PastePath %assuming someone previously used getFile or getFolder
        text_from_clipboard = clipboard('paste');
        text_from_clipboard=strrep(text_from_clipboard,'%','%%');
        text_from_clipboard=strrep(text_from_clipboard,'\','\\');
        fprintf(fileID,text_from_clipboard);
    end
    %% CORE
    %The core of the function should just go here.
    % error('Function not finished')
    
    fprintf(fileID,'\n\n%%%% CORE\n%%The core of the function should just go here.\n');
    if options.UnfinishedError
        fprintf(fileID,'error(''Function not finished'')\n');
    end
    
    if options.PastePath && options.UseRecording
        fprintf(fileID,'\n\nobj=Recording(filepath);\n');
    end
    
    if options.Summary
        fprintf(fileID,'\n\n%%%% CLOSING\n%s.input_options=input_options; %% passing input options separately so they can be used later to feed back to function input.\n',options.OutputStructureName);
        fprintf(fileID,'%s.execution_duration=toc(%s.execution_duration);\n',options.OutputStructureName,options.OutputStructureName);
    end
    
    % for debugging:
    if strcmpi(options.filetype,'function') && options.Debug
        fprintf(fileID,'\n\ncatch ME\n');
        %         fprintf(fileID,'   ME\n'); % I think it should be obsolete % 2020-05-05 02:47:16 RC
        %         fprintf(fileID,'   getReport(ME,''extended'',''hyperlinks'',''on'')\n'); % 2019-06-12 13:27:05 RC - more descriptive error message
        fprintf(fileID,'   if DEBUG_THIS_FILE; getReport(ME,''extended'',''hyperlinks'',''on''); keyboard; else; rethrow(ME); end\n'); % 2020-05-23 01:26:48 RC
        fprintf(fileID,'end');
    end
    

    fprintf(fileID,'\n\nend  %%%%%% END %s\n', upper(filename_noext));
    
    %% closing summary
    
    summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
    summary.execution_duration=toc(summary.execution_duration);
    
    if options.SummarizeAutoGeneration
        fprintf(fileID,'\n\n%%%%%% Automatically generated using ''genMFile'' function (by Radek Chrapkiewicz) with the following configuration:\n');
        fprintf(fileID,'%% summary=\n%% %s',...
            strrep(evalc('disp(summary)'),newline,sprintf('\n%%')));
        if options.ShowInputOptionsSummary
            fprintf(fileID,'%%\n%%\n%% input_options=\n%% %s',...
                strrep(evalc('disp(summary.input_options)'),newline,sprintf('\n%%')));
        end
        
    end
    
    
    
    %% closing the file
    
    
    fclose(fileID);
    edit(filename);
    
    
catch ME
    fclose(fileID);
    getReport(ME)
    if DEBUG_THIS_FILE
        keyboard
    end
end


end