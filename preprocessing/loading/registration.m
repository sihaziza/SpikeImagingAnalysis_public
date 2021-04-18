function [fixedV,registeredV,summaryRegistration] = registration(fixed, moving,allPaths,varargin)
%% REGMOVIES: Video registration
% [fixedV,registeredV,summary] = regMovies(fixed, moving)
% [fixedV,registeredV,summary] = regMovies(fixed, moving,Parameter,Value,...)
%
% INPUT:
%       fixed   = The fixed video as a reference, can be variable loaded in
%                   memory or a pointer to a h5 file
%       moving  = The video to be registered
% OUTPUT:
%       registeredV  = The output registered video
%       fixedV - fixed video cropped to match the size of the original
%       movie
%       summary     = Extra outputs, validation and diagnostic
%
% OPTIONS SYNTAX
% regMovies(fixed,moving,'options',options);
% regMovies(fixed,moving,'BandPass',false,'options',options);
%
% CONTACT: Jizhou Li (hijizhou@gmail.com) & Radek Chrapkiewicz
% (radekch@stanford.edu)

% HISTORY
% Created: 17 June, 2019
% 2020-05-07 add default flip
% 2020-05-14 switch reg method from pre_reg_frame_v2 to imageReg
% 2020-06-03 adapted for VoltageImagingAnalysis common package by Radek Chrapkiewicz
% 2020-06-07 add hybrid registration to choose the best method, J. Li
% 2020-06-09 add support for h5 files (over the memory limits), J. Li
% 2020-06-27 01:54:01 Replaced all 3rd dimensions of h5 chunks to 1. RC
% 2020-06-27 05:12:39 Getting rid of clearvars, causing bugs RC
% 2020-06-29 22:07:56 chunking based on RAM for clean output RC
%
% TODO
% - plotting
% - validation

%% GET DEFAULT OPTIONS
[options]=defaultOptionsRegistration;

%% UPDATE OPTIONS
if nargin>=4
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
[summaryRegistration]=outputSummaryRegistration(options);

if options.diary
    diary(fullfile(allPaths.pathDiagRegistration,options.diary_name));
end

%% CORE

% if ischar(fixed) % passing movie as filepth to h5 files
%     if ~isfile(fixed); error('Not a file'); end
%     [~,~,ext] = fileparts(fixed);
%     ext = ext(2:end);
%     if strcmpi(ext,'hdf5') || strcmpi(ext,'h5')
%         filetype = 'hdf5';
%         dims_fixed=h5moviesize(fixed,'dataset',options.dataset);
%         dims_moving=h5moviesize(moving,'dataset',options.dataset);
%         num_frame_fixed = dims_fixed(end);
%
%         num_frame_moving = dims_moving(end);
%
%         if num_frame_fixed~=num_frame_moving
%             error('Number of frames are not equal');
%         end
%
%         options.templateFrame=num_frame_fixed; % which frame to take as a template ? on default the last one.
%         fixed_frame =  h5read(fixed,options.dataset,[1,1,options.templateFrame],[dims_fixed(1:end-1),1]);
%         moving_frame =  fliplr(h5read(moving,options.dataset,[1,1,options.templateFrame],[dims_moving(1:end-1),1]));
%          datatype = class(fixed_frame);
%         % output file names
%
%         suff_obj_fixed=suffix(fixed);
%         fixedV=suff_obj_fixed.change(fname_suffix); % handling changing suffixes through class suffix to avoid multiple adding of suffixes and not allowed ones. This causes a problem for automatic file search.
%
%         suff_obj_moving=suffix(moving);
%         registeredV=suff_obj_moving.change(fname_suffix);
%     else
%         error('Filetype %s not supported',ext);
%     end
% else
% array loaded in memory
options.ChunkSize = [];

filetype = 'mat';
dims_fixed = size(fixed);
dims_moving = size(moving);
num_frame_fixed = dims_fixed(end);
options.templateFrame=num_frame_fixed; % which frame to take as a template ? on default the last one.
fixed_frame = fixed(:,:,options.templateFrame);
moving_frame = fliplr(moving(:,:,options.templateFrame));

% end

num_frame = num_frame_fixed;

% outputing some basic info about the processed movie
summaryRegistration.filetype = filetype;
summaryRegistration.nframes=num_frame;
summaryRegistration.fixed_size=dims_fixed;
summaryRegistration.moving_size=dims_moving;
summaryRegistration.original_type=[class(fixed_frame),',',class(moving_frame)];

fprintf('\n'); disps('Registering the template frame');

summaryRegistration.orig_fixed_frame=fixed_frame;
summaryRegistration.orig_moving_frame=moving_frame;

summaryRegistration.sim_metrics_before = evalRegQualityMetrics(fixed_frame, moving_frame, 'BandPass',false);


%% 1. Estimation of the transformation
diagnosticFolder=allPaths.pathDiagRegistration;
options.diagnosticFolder=diagnosticFolder;

if options.plot
    % multiple plots are not great and causing clutter. Better get one good
    % figure in the end summarizing them all. RC
    hf=figure(1);
    plotting(fixed_frame,moving_frame)
    suptitle('Fixed and moving frame before processing')
    export_figure(hf,'raw before processing',diagnosticFolder);close;
end

% Bandpass filter to sharpen the features
if options.BandPass
    disps('Bandpassing single frame')
    fixed_frame=bpFilter2D(fixed_frame,options.BandPx(2),options.BandPx(1)); % high pass filter
    moving_frame=bpFilter2D(moving_frame,options.BandPx(2),options.BandPx(1)); % high pass filter
end

summaryRegistration.sim_metrics_before_bandpassed = evalRegQualityMetrics(fixed_frame, moving_frame, 'BandPass',false);

if options.plot
    hf=figure(2);
    plotting(fixed_frame,moving_frame)
    suptitle('Fixed and moving frame after bandpassing')
    drawnow
    export_figure(hf,'raw after bandpassing',diagnosticFolder);close;
end

% Normalize the frame intensity
if options.Normalize
    disps('Normalizing frame by standard deviation');
    [fixed_frame]=adjustImage(fixed_frame);
    [moving_frame]=adjustImage(moving_frame);
end

if options.Threshold
    fixed_frame(fixed_frame<options.ThresholdValue)=0;
    moving_frame(moving_frame<options.ThresholdValue)=0;
end

if options.Binarize
    disps('Binarizing images');
    fixed_frame=double(imbinarize(fixed_frame));
    moving_frame=double(imbinarize(moving_frame));
end

summaryRegistration.fixed_frame=fixed_frame;
summaryRegistration.moving_frame=moving_frame;


disps('Registering the template frame');
[Reg,regMethod, regScore] = imageRegistration(fixed_frame, moving_frame);
disps('Transformation found');

reg_frame=Reg.RegisteredImage;
summaryRegistration.reg_frame=reg_frame;
summaryRegistration.regScore = regScore;
summaryRegistration.regMethod = regMethod;


% Default spatial referencing objects
fixedRefObj = imref2d(size(fixed_frame));
movingRefObj = imref2d(size(Reg.RegisteredImage));

if options.plot
    hf=figure(3);
    disps('Plotting');
    plotting(fixed_frame,reg_frame)
    suptitle('Fixed and moving frame after processing with bandpass')
    export_figure(hf,'reg with bandpass',diagnosticFolder);close;
end

% Quality metrics
summaryRegistration.sim_metrics_before_bandpassed = evalRegQualityMetrics(fixed_frame, moving_frame, 'BandPass',false);
transformation=Reg.transformation;% to not broadcast the whole variable
summaryRegistration.translation=transformation.T(3,1:2);
summaryRegistration.angle=asin(transformation.T(2,1))*180/pi;

disps('Applying affine transform the original template and moving frame');
RegisteredImage = imwarp(summaryRegistration.orig_moving_frame, movingRefObj, transformation,...
    'OutputView', fixedRefObj, 'SmoothEdges', true, 'FillValues', NaN);
[registered_cropped,fixed_cropped, corn] = postcropping(RegisteredImage,summaryRegistration.orig_fixed_frame);

summaryRegistration.fixed_cropped=fixed_cropped;
summaryRegistration.registered_cropped=registered_cropped;
croppeddims = size(fixed_cropped);
summaryRegistration.croppeddims = croppeddims;

if options.plot
    hf=figure(4);
    plotting(fixed_cropped,registered_cropped)
    suptitle('Fixed and moving frame after processing postcropping')
    export_figure(hf,'reg final',diagnosticFolder);close;
end

% Quality metrics without bandpass
summaryRegistration.sim_metrics_after = evalRegQualityMetrics(fixed_cropped, registered_cropped, 'BandPass',false);
summaryRegistration.sim_metrics_after_bandpassed = evalRegQualityMetrics(fixed_cropped, registered_cropped, 'BandPass',true,'BandPx',options.BandPx);

metrics=summaryRegistration.sim_metrics_before;
metrics(2)=summaryRegistration.sim_metrics_after;
metrics(3)=summaryRegistration.sim_metrics_before_bandpassed;
metrics(4)=summaryRegistration.sim_metrics_after_bandpassed;
metrics=struct2table(metrics);
metrics.Properties.RowNames={'Before','After','Before BP','After BP'};

summaryRegistration.metrics_table=metrics;
disp(metrics);

if (summaryRegistration.sim_metrics_after.ssim<summaryRegistration.sim_metrics_before.ssim)...
        &&  (summaryRegistration.sim_metrics_after.psnr<summaryRegistration.sim_metrics_before.psnr)...
        && (summaryRegistration.sim_metrics_after.ncc<summaryRegistration.sim_metrics_before.ncc)
    summaryRegistration.status=false;
    summaryRegistration.status_message='Registration failed';
else
    summaryRegistration.status=true;
    summaryRegistration.status_message='Looks good';
end

%% 2. Applying the estimate transformation to all data

if strcmpi(filetype,'mat')
    % disp('Preallocating output movies') % allocation added by RC to speed up the function
    registeredV=zeros(size(fixed_cropped,1),size(fixed_cropped,2),size(moving,3),class(moving));
    fixedV=registeredV;
    %     clearvars -except num_frame moving fixed registeredV fixedV
    %     movingRefObj transformation fixedRefObj summary options corn %
    %     causing bugs!
    disps(['Applying transformation to all ' num2str(num_frame) ' frames....']);
    parfor i=1:num_frame % changed for regular for for testing  RC 2020-05-29
        moving_frame = fliplr(moving(:,:,i)); % this should be fliplr specifically ! % 2020-06-03 20:03:47 RC
        fixed_frame = fixed(:,:,i);
        [registeredimage,fixedframe] = applyReg2Frame(fixed_frame,moving_frame,transformation,corn); % fixed missing transformation RC
        registeredV(:,:,i) = registeredimage; % those matrices should be allocated before, otherwise it's taking long to increase the size % 2020-06-03 20:09:45 RC
        fixedV(:,:,i) = fixedframe;
    end
    
    summaryRegistration.output_type=[class(fixedV),',',class(registeredV)];
    
else % h5 file
    
    % create the files, registeredV,fixedV
    if isfile(registeredV)
        disps('Founded a registeredV file, deleting...')
        delete(registeredV);
    end
    if isfile(fixedV)
        disps('Founded a fixedV file, deleting...')
        delete(fixedV);
    end
    
    
    if isempty(options.ChunkSize)
        disps('Finding a chunk size based on available RAM.')
        options.ChunkSize=chunkh5(fixed,options.maxRAM);
    end
    
    for fi = 1:options.ChunkSize:num_frame
        sframe = fi; % start frame
        endframe = min(sframe+options.ChunkSize, dims_fixed(end));
        realframe = min(options.ChunkSize, dims_fixed(end)-sframe+1);
        data_moving = h5read(moving,options.dataset,[ones(1,length(dims_fixed)-1),sframe],[dims_fixed(1:end-1),realframe]);
        data_fixed = h5read(fixed,options.dataset,[ones(1,length(dims_fixed)-1),sframe],[dims_fixed(1:end-1),realframe]);
        
        % preallocate
        
        transformed_moving = zeros([size(fixed_cropped),realframe]);
        transformed_fixed = zeros([size(fixed_cropped),realframe]);
        
        disps( ['processing frames ' num2str(sframe) ' - ' num2str(endframe) ', in total ' num2str(dims_fixed(end)) ' frames']);
        
        parfor ii=1:realframe
            % Jizhou, you may have forgotten about flipping... - 2020-06-30 04:20:45 -   RC
            moving_frame = fliplr(data_moving(:,:,ii)); % this should be fliplr specifically RC
            [registeredimage,fixedframe] = applyReg2Frame(data_fixed(:,:,ii), moving_frame, transformation,corn);
            transformed_moving(:,:,ii) = registeredimage;
            transformed_fixed(:,:,ii) = fixedframe;
        end
        
        h5append(registeredV,single(transformed_moving),options.dataset);
        h5append(fixedV,single(transformed_fixed),options.dataset);
    end
    
end

disps(['Finished - ' summaryRegistration.funcname]);

%% VALIDATION

% summary.status=true; % it worked
% summary.quality_metrics

%%
summaryRegistration.postCroppingCorners = corn;
summaryRegistration.transformation=transformation;
summaryRegistration.execution_duration=toc(summaryRegistration.execution_duration);
save_summary(summaryRegistration,diagnosticFolder);

h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),'_reg.h5');
h5PathR=strcat(erase(allPaths.h5PathR,'.h5'),'_reg.h5');
h5save(h5PathG,fixedV,'mov');
h5save(h5PathR,registeredV,'mov');

if options.diary
    diary off
end
    function disps(string)
        if options.verbose
            fprintf('%s regMovies: %s\n', datetime('now'),string);
        end
    end
end

function [output]=adjustImage(input)
avg = mean2(input);
sigma = std2(input);
% Adjust the contrast based on the standard deviation.
output = (input-avg)./sigma;
end

function plotting(fixed_frame,moving_frame)
% by RC
subplot(2,2,[1,2])
imshowpair(fixed_frame,moving_frame,'montage')
title('Fixed, moving')
subplot(2,2,3)
imshowpair(fixed_frame,moving_frame)
title('Merged')
subplot(2,2,4)
imshowpair(fixed_frame,moving_frame,'diff')
title('Difference')
end


