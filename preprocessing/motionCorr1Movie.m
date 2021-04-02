function [mov_corrected,bestCorner,template]=motionCorr1Movie(inputData,varargin)
% [mov_corrected,bestCorner]=motionCorr1Movie(input,varargin)
% [mov_corrected,mov_shifted,summary]=mocoMovies(movie4corrections,movie4shifts,'Parameter',Value,...)
%
% options.customTemplate=[]; % just in case you want to use a custom template image it is beyond the specification
% options.customTemplateMethod='corrected';
% options.max_shift=50; % % maximum shift in pixels
% options.us_fac=10; % upsampling factor
% options.windowsize=1000;
% options.templateLastFrame=true;
% options.nonRigid=false;
% options.savePath=[]; %automatically determined based off input path. Give it is working on a workspace
% options.verbose=1;
% options.plot=true;
% options.PlotTemplate=true;
% options.dataspace='/mov'; % only '/mov' is supported by normcorre;
% options.dataset='mov';
% options.diary=false;
%
% HELP:
%   Perform motion correction from the green movie, which contains the best blood vessel contrast
%   and applies shifts on the red movie. Requires Normcorre on the Matlab path.

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

options.isRawInput=[];

options.max_shift=50; % % maximum shift in pixels - could be 25% of the min size
options.us_fac=10; % upsampling factor
options.windowsize=1000;

options.customTemplateMethod='corrected';
options.customTemplate=[]; % just in case you want to use a custom template image it is beyond the specification
options.templateLastFrame=true;
options.TemplateFrame=10;
options.ChunkSize = [];
options.dcRemoval=false; % useful if not treating a bp movie
options.inverseFrames=false; %if main landmark e.g. blood vessel are dark
options.nonRigid=false;
options.gridSize=[];

options.savePath=[];
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

if ischar(inputData)
    [filepath,name,ext]=fileparts(inputData);
    options.savePath=filepath;
    
    if strcmpi(ext,'.h5')
        h5Path=inputData;
        meta=h5info(h5Path);
        disp('h5 file detected')
        dim=meta.Datasets.Dataspace.Size;
        mx=dim(1);my=dim(2);numFrame=dim(3);
        dataset=strcat(meta.Name,meta.Datasets.Name);
        
        if isempty(options.isRawInput)
            prompt = 'Did you input Raw Data? [0-No / 1-Yes]';
            answer = input(prompt);
            if answer
                options.isRawInput=true;
            else
                options.isRawInput=false;
            end
        end
        
        if options.isRawInput
            h5Path_original=inputData;
        else
            h5Path_original=strrep(h5Path,'_bp.h5','.h5');
        end
        
        options.mocoMoviePath=fullfile(filepath,[name '_moco.h5']);
        options.mocoMoviePathTemp=fullfile(filepath,[name '_mocoTEMP.h5']);
        
    elseif istensor(inputData)
        disp('working with data in workspace')
        if isempty(options.savePath)
            disp('Not saving the data. Find it in the workspace')
        else
            options.mocoMoviePath=strrep(options.savePath,'.h5','_moco.h5');
            options.mocoMoviePathTemp=strrep(options.savePath,'.h5','_mocoTEMP.h5');
        end
    else
        error('input data type not accepted - only h5path or workspace')
    end
end

if exist(options.mocoMoviePath,'file')==2
    delete(options.mocoMoviePath)
end
% numFrame=1000;
flims=[1 numFrame];% to update if specific frame number required

windowsize = min(numFrame, options.windowsize);

disps('Getting the template')
options.diagnosticFolder=filepath;


% 2. defining the template
if isempty(options.customTemplate)
    % template as last, first frame or a mean of a vector of frames:
    if options.templateLastFrame
        movie4Template=h5read(h5Path,dataset,[1 1 numFrame-options.TemplateFrame+1],[mx my options.TemplateFrame]);
    else
        movie4Template=h5read(h5Path,dataset,[1 1 1],[mx my options.TemplateFrame]);
    end
    
    if options.inverseFrames
        disp('inverting the frame to get dark background')
        movie4Template = imcomplement(movie4Template);
    end
    
    if options.dcRemoval
        disp('removing DC spatial component')
        movie4Template=bpFilter2D(movie4Template,20,inf,'parallel',false);
    end
    
    %             imshow(movie4Template(:,:,end),[])
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

if options.PlotTemplate
    h=figure(1);
    imshow(template,[])
    title(options.savePath)
    export_figure(h,'Moco Template',options.savePath);close;
end

disps('Start Motion Correction Function')

if options.nonRigid
    disps('Running Non-Rigid Moco')
    %     gridD=max(round(min(mx,my)/5),20);
    if isempty(options.gridSize)
        gridD=40; %test with a patch of 10x10 pixels
    end
    normcorre_options = NoRMCorreSetParms('d1',mx,'d2',my,...
        'grid_size',round([gridD,gridD,1]),'overlap_pre',round([gridD/2,gridD/2,1]),...
        'min_patch_size',round([gridD/2,gridD/2,1]),'min_diff',round([gridD/4,gridD/4,1]),...
        'max_shift',options.max_shift,'correct_bidir',false,...
        'upd_template',false,'boundary','nan','shifts_method','cubic');
    
else
    normcorre_options = NoRMCorreSetParms('d1',mx,'d2',my,'max_shift',options.max_shift,...
        'correct_bidir',false,'upd_template',false,'boundary','nan','shifts_method','cubic');
end


fprintf('Loading and processing %5g frames in chunks.\n', numFrame)
k=0;
p=1;
allCorners=[];
while k<numFrame
    tic;
    
    currentFrame = min(windowsize, numFrame-k);
    fprintf('Loading frames %3.0f to %3.0f out of %3.0f. \n ', k, currentFrame+k, numFrame)
    
    disp('finding shift on the bandpassed movie')
    temp=h5read(h5Path,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
    
    % If data are raw, store it before any modification
    if options.isRawInput
        ori=temp;
    end
    
    if options.inverseFrames
        disp('inverting chunk to get dark background')
        temp = imcomplement(temp);
    end
    
    if options.dcRemoval
        disp('removing DC spatial component')
        temp=bpFilter2D(temp,20,inf,'parallel',true);
    end
    
    [~,normcorre_shifts] = normcorre_batch(temp,normcorre_options,template);
    %     imshow(temp(:,:,end),[])
    
    disps('Applying shifts to the raw movie')
    if options.isRawInput
        mov_corrected = apply_shifts_normcorre(single(ori),normcorre_shifts,normcorre_options);
    else
        temp=h5read(h5Path_original,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
        mov_corrected = apply_shifts_normcorre(single(temp),normcorre_shifts,normcorre_options);
    end
    
    % Save chunk
    if ~isempty(options.mocoMoviePathTemp)
        h5append(options.mocoMoviePathTemp, mov_corrected,options.dataset);
    end
    
    %save the corner for final cropping
    [~, corner] = postcropping(mov_corrected);
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
    currentFrame = min(2*windowsize, numFrame-k); %twice as many frames to speed up the cropping
    
    if ~isempty(options.mocoMoviePathTemp)
        temp=h5read(options.mocoMoviePathTemp,dataset,[1 1 k+flims(1)],[mx my currentFrame]);
    end
    
    [tempCorr, ~] = postcropping(temp,bestCorner);
    
    h5append(options.mocoMoviePath, tempCorr,options.dataset);
    
    % imshow(movie(:,:,200),[])
    k=k+currentFrame;
    p=p+1;
    toc;
end

delete(options.mocoMoviePathTemp)
%     delete(h5Path)

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


