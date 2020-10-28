function [mov_corrected,mov_shifted,summaryMotionCorr]=motionCorr(movie4corrections,movie4shifts,allPaths,varargin)
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

%% UPDATE OPTIONS
if nargin>=4
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
[summaryMotionCorr]=outputSummaryMotionCorr(options);

if options.diary
    diary(fullfile(allPaths.pathDiagMotionCorr,options.diary_name));
end

%% CORE OF THE FUNCTION
disps('Start')
disps('Getting the template')

diagnosticFolder=allPaths.pathDiagMotionCorr;
options.diagnosticFolder=diagnosticFolder;
options.TemplateFrame=size(movie4corrections,3);
options.ChunkSize = [];

filetype = 'mat';
num_frame_fixed=size(movie4corrections,3);

% 1. bandpassing to focus on blood vessels
if options.Bandpass
    disps('Bandpassing the whole movie')
    %template=bpFilter2D(template,options.BandPx(1),options.BandPx(2)); % high pass filter
    % buffering movie before highpassing, to be replaced by the original in the end
    movie4corrections_orig=movie4corrections;
    % high pass filter
    movie4corrections=bpFilter2D(movie4corrections,options.BandPx(2),options.BandPx(1));
    % dark blood vessel/bright background is inverted for better result
    
    % 3. inverting the movie to have bright blood vessels
    if options.Invert
        disps('Inverting the movie')
        movie4corrections=-movie4corrections;
        % min value should be just 0 not negative >> not sure why this is important
        movie4corrections=movie4corrections-min(movie4corrections(:));
    end
    
    dims_fixed = size(movie4corrections);
end

% 2. defining the template
if isempty(options.customTemplate)
    % template as last, first frame or a mean of a vector of frames:
    switch options.customTemplateMethod
        case 'average'
            template=squeeze(mean(movie4corrections(:,:,options.TemplateFrame),3));
                        disps('Template generated using average method')
        case 'corrected'
            [template,~]=generateTemplate(movie4corrections,...
                'nFrames',options.TemplateFrame,...
                'upSampling',options.us_fac,...
                'plot',false);
            disps('Template generated using corrected method')
        otherwise
            warning('Wrong template case. No template generate')
    end
    %2020-06-07 21:09:12 J.Li add value to customTemplate to avoid hdf5
    %warning
    options.customTemplate = 0; % - 2020-07-18 18:43:05 - SH weird because it is a custom template
else
    % custom template
    template=options.customTemplate;
end
template = single(template);
% end

% plotting the template for diagnostic, we can remove this part, on default
% it is disabled % 2020-05-29 20:55:09 RC
disps('Starting motion correction')
if options.PlotTemplate
    h=figure(1);
    imshow(template,[])
    title('Template for motion correction')
    export_figure(h,'Moco Template',diagnosticFolder);close;
end

normcorre_options = NoRMCorreSetParms('d1',size(movie4corrections,1),'d2',size(movie4corrections,2),...
    'max_shift',options.max_shift,'us_fac',options.us_fac,'correct_bidir',false,'boundary','nan','shifts_method','cubic');

if options.ParallelCPU
    [mov_corrected,normcorre_shifts,template_out,~] = normcorre_batch(movie4corrections,normcorre_options,template);
else
    [mov_corrected,normcorre_shifts,template_out,~] = normcorre(movie4corrections,normcorre_options,template);
end

% end

disps('motion correction finished')

% 5. Applying shifts for the second movie

disps('Applying shifts on the first movie')
mov_corrected = apply_shifts_normcorre(movie4corrections_orig,normcorre_shifts,normcorre_options);
[mov_corrected, ~] = postcropping(mov_corrected);
% mask = isnan(mov_corrected);
% if sum(mask,'all')
%     disps('Naaaaan again! let"s try another iteration')
%     [mov_corrected, ~] = postcropping(mov_corrected);
% mask = isnan(mov_corrected);
% if sum(mask,'all')
% disps('I give up, and go to bed...')
% end
% end

disps('Applying shifts on the second movie')
mov_shifted = apply_shifts_normcorre(movie4shifts,normcorre_shifts,normcorre_options);
[mov_shifted, ~] = postcropping(mov_shifted);
% mask = isnan(mov_shifted);
% sum(mask,'all')
% 6. If movie was bandpassed, applying shifts to the original movie
% if options.Bandpass
%     
%     % just to test, should be replaced
%     metadata.fps=50;
%     disps('Generating mp4 movie from bandpass movie')
%     renderMovie(-mov_corrected,fullfile(allPaths.pathDiagMotionCorr,'movie_bp'),metadata.fps);
%     
%     disps('Applying shifts from the high pass to the original movie')
%  
%     mov_corrected = apply_shifts_normcorre(movie4corrections_orig,normcorre_shifts,normcorre_options);
%     %     end
%     
% end

% just to test, should be replaced
% metadata.fps=50;
% disps('Generating mp4 movie')
% renderMovie(-mov_corrected,fullfile(allPaths.pathDiagMotionCorr,'movie'),metadata.fps);

disps('Saving h5 outputs')
h5PathG=strcat(erase(allPaths.h5PathG,'.h5'),[options.suffix '.h5']);
h5PathR=strcat(erase(allPaths.h5PathR,'.h5'),[options.suffix '.h5']);
h5save(h5PathG,mov_corrected,'mov');
h5save(h5PathR,mov_shifted,'mov');

%% THIS SECTION COULD BE SET AS A SEPARATE FUNCITON

ssim_vec=zeros(1,num_frame_fixed);

disps('Calculating the similarity index for all the frames from the first channel')
% parfor to accelerate the ssim computation
% fixed the bug of template
% 2020-06-07 14:49:55 J.Li
% 2020-06-09 add h5 file support, J. Li
adjustImage = @(x) (x - min(x(:))) ./ (max(x(:)-min(x(:))));

if strcmpi(filetype,'mat')
    
    template = mov_corrected(:,:,options.TemplateFrame);
    template = adjustImage(template);
    parfor iframe=1:size(mov_corrected,3)
        tmp = mov_corrected(:,:,iframe);
        tmp = adjustImage(tmp);
        ssim_vec(iframe)=ssim(tmp, template);
    end
    
else
    
    template = h5read(mov_corrected,options.dataspace,[1,1,num_frame_fixed],[size(template_out,1), size(template_out,2),1]);
    template = adjustImage(template);
    
    for fi = 1:options.ChunkSize:num_frame_fixed
        sframe = fi; % start frame
        endframe = min(sframe+options.ChunkSize-1, num_frame_fixed(end));
        realframe_num = min(options.ChunkSize, num_frame_fixed(end)-sframe+1);
        data = h5read(mov_corrected,options.dataspace,[1,1,sframe],[size(template_out,1), size(template_out,2),realframe_num]);
        
        disps( ['processing frames ' num2str(sframe) ' - ' num2str(endframe) ', in total ' num2str(dims_fixed(end)) ' frames']);
        
        ssim_each = zeros(1,realframe_num);
        parfor ii=1:realframe_num
            
            tmp = data(:,:,ii);
            tmp = adjustImage(tmp);
            ssim_each(ii)=ssim(tmp, template);
            
            
        end
        ssim_vec(sframe:endframe) = ssim_each;
        
    end
    
end


if options.plot
    h=figure();
    plot(ssim_vec);
    xlabel('Frame (#)')
    ylabel('SSIM')
    export_figure(h,'Quality Control SSIM',diagnosticFolder);close;
end

summaryMotionCorr.ssim_vecG=ssim_vec; %only G channel is recorded
disps('Motion correction finished')

%% SAVING SUMMARY
summaryMotionCorr.template=template_out;
summaryMotionCorr.normcorre_options=normcorre_options;


%% convert ncorre_shifts to matrix
shifts = zeros(num_frame_fixed, 2);
parfor i=1:numel(normcorre_shifts)
    shifts(i,:) = [normcorre_shifts(i).shifts(1) normcorre_shifts(i).shifts(2)];
end

summaryMotionCorr.normcorre_shifts=shifts;
summaryMotionCorr.function_path=mfilename('fullpath');
summaryMotionCorr.execution_duration=toc(summaryMotionCorr.execution_duration);
summaryMotionCorr.status=1;
summaryMotionCorr.status_message = 'success';
save_summary(summaryMotionCorr,diagnosticFolder);

if options.diary
    diary off
end

    function disps(string) %overloading disp for this function
        if options.verbose
            fprintf('%s motionCorr: %s\n', datetime('now'),string);
        end
    end

end  %%% END MOCO2MOVIES

function [cropMovie, corn] = postcropping(movie,corn)
% crop image to remove boundary values
% more advanced version, 2019-12-04 by Jizhou Li
% improved version, 2020-05-14 by Simon Haziza
% add corn output, 2020-06-07 by Jizhou Li
% add initilizing corn, 2020-06-09 by Jizhou Li

[movie_pad]=padarray(movie,[1 1],0,'both');

if nargin<2
    % needs to compute corn
    
% to get mask with 1 in the overlapping area
mask = ~isnan(movie);
mask=min(mask,[],3);
[AugmentedMask]=padarray(mask,[1 1],0,'both');
% imshow(AugmentedMask,[])
% imshow(mask,[])

% corn = pre_crop_nan(1-mask);
%registeredimage =  registeredimage(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));
%fixedframe =  fixed_frame(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));

LRout = LargestRectangle(AugmentedMask,1,0,0,0,0);%small rotation angles allowed
corn = [LRout(2:end,1) LRout(2:end,2)];

% test =  AugmentedMask(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)));
% mask = ~isnan(test);
% imshow(mask,[])
end

cropMovie =  movie_pad(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)),:);

end


