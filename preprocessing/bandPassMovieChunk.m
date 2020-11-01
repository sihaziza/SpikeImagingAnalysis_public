function bandPassMovieChunk(h5Path,bpFilter,varargin)
%% mocoMovies
% SYNTAX
% [mov_corrected,mov_shifted,summary]=mocoMovies(movie,movie4shifts)
%
% HELP:
%   Perform motion correction from the green movie, which contains the best blood vessel contrast
%   and applies shifts on the red movie. Requires Normcorre on the Matlab path.
%
% HISTORY
% - 2019-08-13 17:49:56 - created by Radek Chrapkiewicz (radekch@stanford.edu)

% ISSUES
% #1 -

% TODO
% *1 - get the first working version of the function!

%% OPTIONS
% [options]=defaultOptionsMotionCorr;
%
% %% UPDATE OPTIONS
% if nargin>=4
%     options=getOptions(options,varargin);
% end
options.windowsize=300;
options.dataset='mov';
options.BandPx=bpFilter;
options.verbose=true;
options.diary=true;
options.diary_name='diary_bp';
%% GET SUMMARY OUTPUT STRUCTURE
% [summary]=outputSummaryMotionCorr(options);

% if options.diary
%     diary(fullfile(allPaths.pathDiagMotionCorr,options.diary_name));
% end

%% CORE OF THE FUNCTION
disps('Start BandPassChunk Function')
% disps('Getting the template')

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);
options.bpMoviePath=strrep(h5Path,'.h5','_bp.h5');

if exist(options.bpMoviePath,'file')==2
    delete(options.bpMoviePath)
end

flims=[1 numFrame];% to update if specific frame number required

windowsize = min(numFrame, options.windowsize);

fprintf('Loading and processing %5g frames in chunks.\n', numFrame)
k=0;
while k<numFrame
    tic;
    currentFrame = min(windowsize, numFrame-k);
    fprintf('Loading %3.0f frames; \n', currentFrame+k)
    temp=h5read(h5Path,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
    movie=bpFilter2D(temp,options.BandPx(2),options.BandPx(1));
    h5append(options.bpMoviePath, single(movie),options.dataset);
    % imshow(movie(:,:,200),[])
    k=k+currentFrame;
    toc;
end


%
%         % Loading green channel
% [~,summary_loadG]=loadDCIMGchunks(allPaths.dcimgPathG,...
%     'binning',options.binning,...
%     'cropROI',options.cropROI.greenChannel,...
%     'frameRange',options.frameRange,...
%     'h5Path',allPaths.h5PathG);
%
%     if isfile(h5Path)
%         disps(['Already found h5 file:' h5Path 'deleting!']);
%         delete(h5Path);
%     end



% disps('Starting motion correction')
% if options.PlotTemplate
%     h=figure(1);
%     imshow(template,[])
%     title('Template for motion correction')
%     export_figure(h,'Moco Template',diagnosticFolder);close;
% end


% just to test, should be replaced
% metadata.fps=50;
% disps('Generating mp4 movie')
% renderMovie(-mov_corrected,fullfile(allPaths.pathDiagMotionCorr,'movie'),metadata.fps);

disps('Spatial Band-Pass filtering finished')

% %% SAVING SUMMARY
% summaryMotionCorr.template=template_out;
% summaryMotionCorr.normcorre_options=normcorre_options;
% save_summary(summaryMotionCorr,diagnosticFolder);

if options.diary
    diary off
end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s BandPassMovie: %s\n', datetime('now'),string);
        end
    end

end



