function detrending(h5Path,varargin)
%% mocoMovies
% SYNTAX
% [mov_corrected,mov_shifted,summary]=mocoMovies(movie4corrections,movie4shifts)
%
% HELP:
% HISTORY

%% OPTIONS

options.windowsize=1000;
options.templateLastFrame=true;
options.nonRigid=false;
options.spatialChunk=false;
options.methods='lowpass';

options.verbose=1;
options.plot=true;
options.PlotTemplate=true;
options.dataspace='/mov'; % only '/mov' is supported by normcorre;
options.dataset='mov';
options.diary=false;
%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
% [summaryMotionCorr]=outputSummaryMotionCorr(options);
%
if options.diary
    diary(fullfile(allPaths.pathDiagMotionCorr,options.diary_name));
end

%% CORE OF THE FUNCTION

meta=h5info(h5Path);
disp('h5 file detected')
dim=meta.Datasets.Dataspace.Size;
mx=dim(1);my=dim(2);nFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);

h5Path_original=strrep(h5Path,'_moco.h5','.h5');
options.detrendMoviePath=strrep(h5Path_original,'.h5','_dtr2.h5');

if exist(options.detrendMoviePath,'file')==2
    delete(options.detrendMoviePath)
end

disps('detrending each pixel...')

if options.spatialChunk
    disps('sorry no ready yet... ask for implementation')

%     flims=[1 numFrame];% to update if specific frame number required
% 
% windowsize = min(numFrame, options.windowsize);
% 
% fprintf('Loading and processing %5g frames in chunks.\n', numFrame)
% k=0;
% p=1;
% 
% while k<numFrame
%     tic;
%     
%     currentFrame = min(windowsize, numFrame-k);
%     fprintf('Loading %3.0f frames; ', currentFrame+k)
%     temp=h5read(h5Path,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
% 
%     h5append(options.mocoMoviePath, tempCorr,options.dataset);
% 
%     % imshow(movie(:,:,200),[])
%     k=k+currentFrame;
%     p=p+1;
%     toc;
% end
% 
% clear temp
else  

   data=h5read(h5Path,dataset,[1 1 1],[mx my nFrame]);
   [dataCorr]=runPhotoBleachingRemoval(data);
   h5append(options.detrendMoviePath, single(dataCorr),options.dataset);
   clear dataCorr data
end

if options.diary
    diary off
end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s motionCorr: %s\n', datetime('now'),string);
        end
    end

end
