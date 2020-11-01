function [output]=functionTemplateSIA(input,varargin)
% GOAL: Batch process all data. Assume that all metadata have been
% generated
%
% INPUTS
%     - input: the input variable
% OUTPUTS
%     - output: the output variable
% OPTIONS
%       - 'option1' : to set option1 (default: true)
% EXAMPLE 
%     [output]=functionTemplateSIA(input, 'option1',false)
% DEPENDENCIES
%
% CONTACT
% xxxxx@gmail.com

%% CHECK VARIABLES FORMATING
if nargin<1
    error('This function requires at least 1 file path');
end

if mod(nargin-1,2)
    error('Variable input arguments work as Name-Value pairs');
end

if ~ischar(mainFolder)
error('should point to a .dcimg or .h5 file path');
end
%% DEFAULT INPUT OPTIONS

% Control display
options.verbose=true;
options.plot=true;
options.savePlot=true;

% Export data
options.diary=true;
options.diaryName='log.txt';
options.savingFolderPath=[]; % if empty than created automatically, vide code 
options.diagnosticFolderPath=[];

%% UPDATE OPTIONS
if nargin>1
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
summary.funcName = 'registration';
summary.inputOptions=options;
summary.functionPath=[];
summary.executionTime=datetime('now');

if options.diary
    diary(fullfile(options.diagnosticFolderPath,options.diaryName));
end

%% RUN CORE FUNCTION
disps('Starting REPLACEbyFUNCTION ...');

output=input;

%% PLOT RELEVANT METRICS

if options.plot
    disps('plotting figures')
    
    name=strcat(type,'_FIGURENAME_',method);
    h=figure('Name',strcat('_FIGURENAME_',name));
    
    
    if options.savePlot
        if isempty(savingFolderPath)
            warning('Figure not saved. Indicate saving path.\n')
        else
            disps('saving figures')
            export_figure(h,'_FIGURENAME_',savingFolderPath);
            close;
        end
    end
    
end

%% SAVE RELEVANT METRICS

save(fullfile(options.diagnosticFolderPath,'summary.mat'),'summary');
 
if options.diary
    diary off
end
    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s REPLACEbyFUNCTIONname: %s\n', datetime('now'),string);
        end
    end
end
