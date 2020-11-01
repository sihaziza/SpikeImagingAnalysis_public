function [foundh5path,summary]=findh5(sourcefile,varargin)
% HELP
% Finding processed h5 file at the latest analysis step. 
% 'sourcefile' can be a path to a dcimg or h5 file from a previous analysis
% step. You may provide a drive to serach in the corresponding
% 'Preprocessed' folder.
% SYNTAX
%[foundh5path,summary]= findh5(sourcefile) 
%[foundh5path,summary]= findh5(sourcefile,drive) 
%[foundh5path,summary]= findh5(sourcefile,drive,suffix) 
%[foundh5path,summary]= findh5(sourcefile,drive,suffix,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[foundh5path,summary]= findh5(sourcefile,drive,suffix,'options',options) - passing options as a structure.
%
% INPUTS:
% - sourcefile - ...
% - drive - e.g 'I' - just a drive letter
% - suffix - e.g. '_moco' filename suffix representing the last processing
% step
%
% OUTPUTS:
% - foundh5path - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 29-Jun-2020 18:12:24 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!



%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct; % add your options below 

options.TargetStage='Preprocessed';
options.verbose=1;

%% VARIABLE CHECK 

if nargin>=2
    drive=varargin{1};
    if length(drive)>1
        drive=drive(1);
    end
else 
    drive=sourcefile(1);
end

if nargin>=3
    suff=varargin{2};
    if ~isempty(suff)
        if suff(1)~='_'; suff=['_',suff]; end
        if ~suffix.is(suff); error('Not a valid suffix'); end
    end
else
    suff=[];
end


if nargin>=4
options=getOptions(options,varargin(3:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% PATHS

%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.

[sourcefolder,filename, ext]=fileparts(sourcefile);
vpaths=voltPaths(sourcefolder);
if ~vpaths.valid_structure
    vpaths
    error('File is not in the valid folder')
end

current_stage=vpaths.Stage;

searchfolder=strrep(sourcefolder,current_stage,options.TargetStage);
searchfolder(1)=drive;

if ~isfolder(searchfolder)
    disp(['Search folder' searchfolder ' does not exist. Terminating']);
    return 
end

default_path=fullfile(searchfolder,[filename,'.h5']);


% easy case the same file name just different folder and extension:
if isfile(default_path)
    disp(['Found: ' default_path])
    foundh5path=default_path;
    return
else
    disp(['Did not find ' default_path ' but searching with suffices']);
    foundh5path=[]; % searching further
end
    
% trying with differetn suffixes
suff_obj=suffix(default_path);

if suff_obj.hassuffix
    disp('Suffix detecte in the original filename')
end

flist=rdir(fullfile(searchfolder,[filename,'*.h5']));
summary.flist=flist;
disp(sprintf('Detected %d h5 files in %s',length(flist),searchfolder));

% now going in the reversed diretion through the allowed suffix list
% (suffix.list)

if isempty(suff)
    sufflist=fliplr(suffix.slist); % all possible suffixes
else
    sufflist={suff}; % just a chosen suffix passed as a function argument
end

% trying different filenames:
for ii=1:length(sufflist)
    fname_tmp=fullfile(searchfolder,[filename,sufflist{ii},'.h5']);
    if isfile(fname_tmp)
        disp(['H5 file found: ' fname_tmp])
        foundh5path=fname_tmp;
        break;
    end
end

if isempty(foundh5path)
    disp('No h5 file found with this criteria')
end
        

%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);

    function disp(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='findh5';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end
    
end  %%% END FINDH5
