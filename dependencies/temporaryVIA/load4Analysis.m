function [movie,fps,stimulus,exportFolder,summary]=load4Analysis(filePath,varargin)
% HELP LOAD4ANALYSIS.M
% Loading dataset files for analysis. High level function, creating export folder, parsing fps etc.
% SYNTAX
%[movie,fpstimulusexportFolder,summary]= load4Analysis(filePath) - use 2, etc.
%[moviefpsstimulusexportFolder,summary]= load4Analysis(filePath,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[moviefpsstimulusexportFolder,summary]= load4Analysis(filePath,'options',options) - passing options as a structure.
%
% INPUTS:
% - filePath - path to processed h5 file
%
% OUTPUTS:
% - movie - ...
% - fps - ...
% - stimulus - ...
% - exportFolder - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 

%
% HISTORY
% - 29-Sep-2020 11:28:46 - created by Radek Chrapkiewicz (radekch@stanford.edu)

%% OPTIONS (type 'help getOptions' for details)
options=struct; % add your options below 
options.exportSubFolder=[]; % 'grant';

%% VARIABLE CHECK 
if nargin>=2
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
summary=initSummary(options);

movie1file=h5load(filePath);
if ~isstruct(movie1file)
    movie=movie1file;
    fps=getFps(filePath);
else
    movie=movie1file.mov;
    fps=movie1file.fps;
end

disps('movies loaded')

%% setting up export folder
exportFolder=strrep(fileparts(filePath),'Preprocessed','Analysis');
if ~isempty(options.exportSubFolder)
    exportFolder=fullfile(exportFolder,options.exportSubFolder);
end
mkdirs(exportFolder)

%% finding stimulus 

dfiles=findDatasetFiles(filePath);


try
fstamps=importFrameStamps(dfiles.frameStamps);
stimulus=fstamps.stimulus;
stimulus=stimulus(1:size(movie,3));
catch 
    warning('Stimulus not imported')
    stimulus=[];
end



%% CLOSING
summary=closeSummary(summary);
disps('Dataset loaded for analysis')


end  %%% END LOAD4ANALYSIS