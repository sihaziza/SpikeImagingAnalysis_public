function [mov_corrected,bestCorner]=motionCorr1Movie(h5Path,varargin)
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
% - 2020-09-30 - make if 1 movie at a time SH

%% OPTIONS

options.customTemplate=[]; % just in case you want to use a custom template image it is beyond the specification
options.customTemplateMethod='corrected';
options.max_shift=200; % % maximum shift in pixels
options.us_fac=20; % upsampling factor
options.windowsize=250;
options.templateLastFrame=true;

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
mx=dim(1);my=dim(2);numFrame=dim(3);
dataset=strcat(meta.Name,meta.Datasets.Name);
h5Path_original=strrep(h5Path,'_bp.h5','.h5');
options.mocoMoviePath=strrep(h5Path_original,'.h5','_moco.h5');
options.mocoMoviePathTemp=strrep(h5Path_original,'.h5','_mocoTEMP.h5');

if exist(options.mocoMoviePath,'file')==2
    delete(options.mocoMoviePath)
end
% numFrame=1000;
flims=[1 numFrame];% to update if specific frame number required

windowsize = min(numFrame, options.windowsize);

disps('Getting the template')
% diagnosticFolder=allPaths.pathDiagMotionCorr;
% options.diagnosticFolder=diagnosticFolder;
options.TemplateFrame=10;
options.ChunkSize = [];

% 2. defining the template
if isempty(options.customTemplate)
    % template as last, first frame or a mean of a vector of frames:
    if options.templateLastFrame
        movie4Template=h5read(h5Path,dataset,[1 1 numFrame-options.TemplateFrame+1],[mx my options.TemplateFrame]);
    else
        movie4Template=h5read(h5Path,dataset,[1 1 1],[mx my options.TemplateFrame]);
    end
    movie4Template=double(movie4Template);
    %     imshow(-movie4Template(:,:,end),[])
    switch options.customTemplateMethod
        case 'average'
            template=squeeze(mean(movie4Template,3));
            disps('Template generated using average method')
        case 'corrected'
            [template,~]=generateTemplate(movie4Template,...
                'nFrames',options.TemplateFrame,...
                'upSampling',options.us_fac,...
                'plot',false);
            disps('Template generated using corrected method')
        otherwise
            warning('Wrong template case. No template generate')
    end
    
else
    % custom template
    template=options.customTemplate;
end
template = single(template);
% end

% disps('Starting motion correction')
% if options.PlotTemplate
%     h=figure(1);
imshow(template,[])
%     title('Template for motion correction')
%     export_figure(h,'Moco Template',diagnosticFolder);close;
% end

disps('Start Motion Correction Function')

normcorre_options = NoRMCorreSetParms('d1',mx,'d2',my,'max_shift',options.max_shift,...
    'us_fac',options.us_fac,'correct_bidir',false,'upd_template',false,'boundary','nan','shifts_method','cubic');

fprintf('Loading and processing %5g frames in chunks.\n', numFrame)
k=0;
p=1;
allCorners=[];
while k<numFrame
    tic;
    
    currentFrame = min(windowsize, numFrame-k);
    fprintf('Loading %3.0f frames; ', currentFrame+k)
    temp=h5read(h5Path,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
    
    [~,normcorre_shifts] = normcorre_batch(temp,normcorre_options,template);
    temp=h5read(h5Path_original,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
    
    disps('Applying shifts to the movie')
    mov_corrected = apply_shifts_normcorre(single(temp),normcorre_shifts,normcorre_options);
    [~, corner] = postcropping(mov_corrected);
    
    h5append(options.mocoMoviePathTemp, mov_corrected,options.dataset);
    
    %save the corner for final cropping
    allCorners(:,:,p)=corner;
    
    % imshow(movie(:,:,200),[])
    k=k+currentFrame;
    p=p+1;
    toc;
end

disps('motion correction finished')
bestCorner(1,1)=max(allCorners(1,1,:));
bestCorner(1,2)=max(allCorners(1,2,:));
bestCorner(2,1)=min(allCorners(2,1,:));
bestCorner(2,2)=max(allCorners(2,2,:));
bestCorner(3,1)=min(allCorners(3,1,:));
bestCorner(3,2)=min(allCorners(3,2,:));
bestCorner(4,1)=max(allCorners(4,1,:));
bestCorner(4,2)=min(allCorners(4,2,:));

% [corner,~]=postcropping(mov_corrected);
% sum(~corner,'all');
disps('postcropping started')
% crop=allCorners;
k=0;
while k<numFrame
    tic;
    fprintf('Loading %3.0f frames; ', k)
    currentFrame = min(windowsize, numFrame-k);
    
    temp=h5read(options.mocoMoviePathTemp,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
    
    [tempCorr, ~] = postcropping(temp,bestCorner);
    
    h5append(options.mocoMoviePath, tempCorr,options.dataset);
    
    % imshow(movie(:,:,200),[])
    k=k+currentFrame;
    p=p+1;
    toc;
end

delete(options.mocoMoviePathTemp)

if options.diary
    diary off
end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s motionCorr: %s\n', datetime('now'),string);
        end
    end

end

function [cropMovie, corn] = postcropping(movie,corn)
% crop image to remove boundary values
% more advanced version, 2019-12-04 by Jizhou Li
% improved version, 2020-05-14 by Simon Haziza
% add corn output, 2020-06-07 by Jizhou Li

[movie_pad]=padarray(movie,[1 1],0,'both');

if nargin<2
    % needs to compute corn
    
    % to get mask with 1 in the overlapping area
    maskNAN = isnan(movie); % detect any nan value
    % maskZERO=~movie; % detect any zero value
    mask3d=maskNAN;%+maskZERO; % intersection of both
    mask2d=min(~mask3d,[],3);
    [AugmentedMask]=padarray(mask2d,[1 1],0,'both');
    % imshow(AugmentedMask,[])
    % imshow(mask2d,[])
    
    % corn = pre_crop_nan(1-mask);
    %registeredimage =  registeredimage(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));
    %fixedframe =  fixed_frame(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));
    
    LRout = LargestRectangle(AugmentedMask,1,0,0,0,0);%small rotation angles allowed
    corn = [LRout(2:end,1) LRout(2:end,2)];
    
    % test =  AugmentedMask(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)));
    % mask = ~isnan(test);
    % imshow(mask,[])
end
% Corner as:
% 1st row: x,y of top corner of largest rectangle
% 2sc row: x,y of right corner of largest rectangle
% 3rd row: x,y of bottom corner of largest rectangle
% 4th row: x,y of left corner of largest rectangle
cropMovie =  movie_pad(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)),:);

end


