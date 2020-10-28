function [summaryLoading] = loading(allPaths,varargin)
% converting two dcimg movies to h5 files and passing all metadata
% this is a high-level functions outputting diagnostic data too!
%
% SYNTAX
% [movieG,movieR,summary] = loadingMovies(dcimgpathG,dcimgpathR,varargin)
% [movieG,movieR,summary] = loadingMovies(dcimgpathG,dcimgpathR,varargin)
%
% INPUT
%
% OPTIONS
%
% OUTPUT
% summary     = Extra outputs, validation and diagnostic


%% GET DEFAULT OPTIONS
[options]=defaultOptionsLoading;

%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
[summaryLoading]=outputSummaryLoading(options);

if options.diary
    diary(fullfile(allPaths.pathDiagLoading,options.diary_name));
end

% temp=load(fullfile(allPaths.metadataPath,allPaths.metadataName));
% metadata=temp.metadata; % should implement recursive saving to avoid this nested structure
% metadata.softwareBinning=1/options.scale_factor;
% metadata.totalBinning=metadata.hardwareBinning*metadata.softwareBinning;
% disp(metadata);
% 
% if metadata.hardwareBinning~=1
%     disps('Changing the scale factor accounting for hte hardware binnign')
%     options.scale_factor = metadata.hardwareBinning*options.scale_factor ;
% end

%% CONVERT DCIMG to H5 files
disps('Starting conversion of two DCIMG to H5 files');

if isempty(options.cropROI)
    options.cropROI.greenChannel=[];
    options.cropROI.redChannel=[];
end
% Loading green channel
[~,summary_loadG]=loadDCIMGchunks(allPaths.dcimgPathG,...
    'binning',options.binning,...
    'cropROI',options.cropROI.greenChannel,...
    'frameRange',options.frameRange,...
    'h5Path',allPaths.h5PathG);

if ~isfile(allPaths.h5PathG)
    error('H5 conversion failed')
end

% Loading red channel
[~,summary_loadR]=loadDCIMGchunks(allPaths.dcimgPathR,...
    'binning',options.binning,...
    'cropROI',options.cropROI.redChannel,...
    'frameRange',options.frameRange,...
    'h5Path',allPaths.h5PathR);

if ~isfile(allPaths.h5PathR)
    error('H5 conversion failed')
end
disps('Two movies loaded')

%% SAVE DIAGNOTIC OUTPUTS
diagnosticFolder=allPaths.pathDiagLoading;

save_summary(summary_loadG,diagnosticFolder);
save_summary(summary_loadR,diagnosticFolder);

hf=figure(1);
plot_loadDCIMG(summary_loadG);
export_figure(hf,'loadG',diagnosticFolder);close;
hf=figure(2);
plot_loadDCIMG(summary_loadR);
export_figure(hf,'loadR',diagnosticFolder);close;

imwrite(rescale16bit(summary_loadG.firstframe),fullfile(diagnosticFolder,'GreenChannel_1stFrame.png'));
imwrite(rescale16bit(summary_loadR.firstframe),fullfile(diagnosticFolder,'RedChannel_1stFrame.png'));

%% COMPUTE AND SAVE TIMESTAMPS
if options.computeTimestamps
    disps('Analysing time stamps to check if there are any dropped frames')
    [~,fpsG,ndroppedG,summary_timestampsG]=getTimestamps(allPaths.dcimgPathG);
    if ndroppedG~=0; warning('Major fuckup, dropped frames'); end
    [~,~,ndroppedR,summary_timestampsR]=getTimestamps(allPaths.dcimgPathR);
    if ndroppedR~=0; warning('Major fuckup, dropped frames'); end
    close all;
    
    % Update frame rate with more accurate estimation
    metadata.fps=round(fpsG);
    save(fullfile(allPaths.metadataPath,[allPaths.metadataName '.mat']),'metadata');
    
    save_summary(summary_timestampsG,diagnosticFolder);
    save_summary(summary_timestampsR,diagnosticFolder);
    plot_getTimestamps(summary_timestampsG);
    export_figure(gcf,'GreenChannel_TimeStamp',diagnosticFolder);close;
    plot_getTimestamps(summary_timestampsR);
    export_figure(gcf,'RedChannel_TimeStamp',diagnosticFolder);close;
    
end
%% SAVE EXTRA METADATA into h5 files.

% if abs(fpsG-fpsR)>0.005
%     error('Discrepancy in fps of red and green channel')
% end
% meta4h5.fps=fpsG;
% meta4h5.ExperimentTime=finfoG.date;
% meta4h5.scale_factor=options.scale_factor;
% meta4h5.original_path=dcimgPathG;
% h5addmeta(h5pathG,meta4h5)
% meta4h5.fps=fpsR;
% meta4h5.original_path=dcimgPathR;
% h5addmeta(h5pathR,meta4h5)


%% SAVE SUMMARY

% summaryLoading.fpsG = fpsG;
% summaryLoading.fpsR = fpsR;
% summaryLoading.finfoG = finfoG;
% summaryLoading.finfoR = finfoR;
summaryLoading.inputOptions=options;
summaryLoading.function_path=mfilename('fullpath');
summaryLoading.execution_duration=toc(summaryLoading.execution_duration);
save_summary(summaryLoading,diagnosticFolder);

if options.diary
    diary off
end

    function disps(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='loading';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
        summaryLoading.log=[summaryLoading.log,sprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string)];
    end
end


