function [mov_corrected,template]=motionCorr1Movie(inputData,varargin)
% with output       > [mov_corrected]=motionCorr1Movie(input)
% without output    > motionCorr1Movie(pathG,'nonRigid', false,'isRawInput',false,'dcRemoval',false);
%
% options.isRawInput=[];
% options.dcRemoval=false; % useful if not treating a bp movie
% options.inverseFrames=false; %if main landmark e.g. blood vessel are dark
% 
% options.customTemplateMethod='corrected';
% options.customTemplate=[]; % just in case you want to use a custom template image it is beyond the specification
% options.templateLastFrame=true;
% options.TemplateFrame=100;
% options.ChunkSize = [];
% 
% options.nonRigid=false;
% options.gridSize=[];
% options.max_shift=50; % % maximum shift in pixels - could be 25% of the min size
% options.windowsize=1000;
% 
% options.savePath=[];
% options.verbose=1;
% options.plot=true;
% options.PlotTemplate=true;
% options.dataspace='/mov'; % only '/mov' is supported by normcorre;
% options.dataset='mov';
%
% Dependencies: require NormCorre on the path

%% OPTIONS
options.isRawInput=[];
options.dcRemoval=false; % useful if not treating a bp movie
options.inverseFrames=false; %if main landmark e.g. blood vessel are dark

options.customTemplateMethod='corrected';
options.customTemplate=[]; % just in case you want to use a custom template image it is beyond the specification
options.templateLastFrame=true;
options.TemplateFrame=100;
options.ChunkSize = [];

options.nonRigid=false;
options.gridSize=[];
options.max_shift=50; % % maximum shift in pixels - could be 25% of the min size
options.windowsize=1000;

options.savePath=[];
options.verbose=1;
options.plot=true;
options.PlotTemplate=true;
options.dataspace='/mov'; % only '/mov' is supported by normcorre;
options.dataset='mov';

%% UPDATE OPTIONS
if nargin>1
    options=getOptions(options,varargin);
end

%% GATHER METADATA, parse data path vs in RAM
if ischar(inputData)
    [filepath,name,ext]=fileparts(inputData);
    if strcmpi(ext,'.h5')
        h5Path=inputData;
        meta=h5info(h5Path);
        disp('h5 file detected')
        dim=meta.Datasets.Dataspace.Size;
        mx=dim(1);my=dim(2);numFrame=dim(3);
        dataset=strcat(meta.Name,meta.Datasets.Name);
        
        % if h5 contains more than just /mov dataset
        if numel(meta.Datasets)>1
            dataset=strcat(meta.Name,'mov');
            find(meta.Datasets.Name=='mov')
        end
        
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
        
        if isempty(options.savePath)
            options.savePath=filepath;
        end
        options.mocoMoviePath=fullfile(options.savePath,[name '_moco.h5']);
        options.mocoMoviePathTemp=fullfile(options.savePath,[name '_mocoTEMP.h5']);
        % delete files is they exist
        if exist(options.mocoMoviePath,'file')==2
            delete(options.mocoMoviePath)
        end
        if exist(options.mocoMoviePathTemp,'file')==2
            delete(options.mocoMoviePathTemp)
        end
    else
        error('can only process h5 file')
    end
    
elseif istensor(inputData)
    disp('working with data in workspace')
    M=inputData;
    dim=size(M);
    mx=dim(1);my=dim(2);numFrame=dim(3);
    if isempty(options.savePath)
        disp('Not saving the data. Find it in the workspace')
    else
        options.mocoMoviePath=strrep(options.savePath,'.h5','_moco.h5');
        options.mocoMoviePathTemp=strrep(options.savePath,'.h5','_mocoTEMP.h5');
        if exist(options.mocoMoviePath,'file')==2
            delete(options.mocoMoviePath)
        end
    end
else
    error('input data type not accepted - only h5path or workspace')
end

%% CORE OF THE FUNCTION

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
        movie4Template=bpFilter2D(movie4Template,25,inf,'parallel',false);
    end
    
    switch options.customTemplateMethod
        case 'average'
            template=squeeze(mean(movie4Template,3));
            disps('Template generated using average method')
        case 'corrected'
            [template,~]=generateTemplate(movie4Template,...
                'nFrames',options.TemplateFrame,...
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

if options.PlotTemplate
    h=figure(1);
    imshow(template,[])
    title(options.savePath)
    export_figure(h,['Moco Template_' name],options.savePath);close;
end

disps('Start Motion Correction Function')

% Decide whether to use Rigid or NonRigid
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

% Process in chunks
fprintf('Loading and processing %5g frames in chunks.\n', numFrame)
k=0;
p=1;
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
        temp=bpFilter2D(temp,25,inf,'parallel',true);
    end
    
    [~,normcorre_shifts] = normcorre_batch(temp,normcorre_options,template);
    
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
    
    k=k+currentFrame;
    p=p+1;
    toc;
end

%% Trim the irrelevant edges of the motion corrected movie.
trimMovieEdges(options.mocoMoviePathTemp);

% delete the temporary file
delete(options.mocoMoviePathTemp)

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s motionCorr: %s\n', datetime('now'),string);
        end
    end

end