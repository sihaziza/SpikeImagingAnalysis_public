function denoisingSpatialChunk(h5Path,varargin)
%% mocoMovies
% SYNTAX
% [mov_corrected,mov_shifted,summary]=mocoMovies(movie4corrections,movie4shifts)
% [mov_corrected,mov_shifted,summary]=mocoMovies(movie4corrections,movie4shifts,'Parameter',Value,...)
%
% HELP:
%   Perform motion correction from the green movie, which contains the best blood vessel contrast
%   and applies shifts on the red movie. Requires Normcorre on the Matlab path.
%
% HISTORY
% - 2019-08-13 17:49:56 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-03-07 21:11:17 - modified by Simon Haziza (sihaziza@stanford.edu)
% - 2020-05-29 18:44:20 - adopted for VOltageImagingAnalysis pipeline RC
% - 2020-06-04 16:33:42 - added similarity index vector as a quality metric RC
% - 2020-06-07 14:30:20 - change the order of template determination and prefiltering
% - 2020-06-09 23:50:25 - add h5 file batch processing support, J.Li
% - 2020-06-27 02:11:57 - Fixing chunk sized in h5creat 3rd dim - 1 so you can read frame by frame RC

% ISSUES
% #1 -

% TODO
% *1 - get the first working version of the function!

%% OPTIONS
[options]=defaultOptionsMotionCorr;
options.windowsize=5000;
options.dataset='mov';

%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
% [summaryMotionCorr]=outputSummaryMotionCorr(options);
%
% if options.diary
%     diary(fullfile(allPaths.pathDiagMotionCorr,options.diary_name));
% end

%% CORE OF THE FUNCTION

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);
options.denoisedMoviePath=strrep(h5Path,'.h5','_dns.h5');

% numFrame=1000;
flims=[1 numFrame];% to update if specific frame number required

windowsize = min(numFrame, options.windowsize);
spatialEpoch=4;
timeEpoch=round((flims(2)-flims(1)+1)/options.windowsize);
widthChunk=round(linspace(1,mx,spatialEpoch+1));diffWidth=diff(widthChunk);
heightChunk=round(linspace(1,my,spatialEpoch+1));diffHeight=diff(heightChunk);
timeChunk=round(linspace(flims(1),flims(2),timeEpoch+1));diffTime=diff(timeChunk);

% Spatial denoising
disps('Start Denoisinh Function')

fprintf('Loading and processing %5g frames in chunks.\n', numFrame)

% h5create(options.denoisedMoviePath,dataset,dim,'Datatype','single','ChunkSize',[mx my 1]);
h5create(options.denoisedMoviePath,dataset,dim,'Datatype','single');

% k=0;
% while k<numFrame
%     currentFrame = min(windowsize, numFrame-k);
 for iTime=1:timeEpoch
    for iWidth=1:spatialEpoch
        for iHeight=1:spatialEpoch
            tic;fprintf('Loading %3.0f frames - x-Chunk %3.0f - y-Chunk %3.0f /n', diffTime(iTime),iWidth,iHeight)
            
            temp=h5read(h5Path,dataset,[widthChunk(iWidth) heightChunk(iHeight) timeChunk(iTime)],...
                [diffWidth(iWidth) diffHeight(iHeight) diffTime(iTime)]);
            
            [movie_out] = denoisingLOSS(temp,'windowsize',500);
            
            h5write(options.denoisedMoviePath,dataset,single(movie_out),...
                [widthChunk(iWidth) heightChunk(iHeight) timeChunk(iTime)],...
                [diffWidth(iWidth) diffHeight(iHeight) diffTime(iTime)]);
            %             imshow(temp(:,:,200),[])
            toc;
        end
    end
%     k=k+currentFrame;
end


if options.diary
    diary off
end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s DenoisingLOSS: %s\n', datetime('now'),string);
        end
    end

end

