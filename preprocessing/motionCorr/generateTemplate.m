function [template,summary]=generateTemplate(movie,varargin)

% generate an acurate template for motion correction using n last,
% first or random frames. Inspired from Normcorr template estimation
% DEPENDENCIES > NormCorr package

%% GET DEFAULT OPTIONS
options.nFrames=20;
options.order='last'; % options: 'last' (default),'first','random'
options.upSampling = 20 ; % upsampling factor for subpixel registration (default: 20)
options.verbose=true;
options.plot=true;
options.savePath=[];

%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%% GET SUMMARY OUTPUT STRUCTURE
summary.inputOptions=options; % saving orginally passed options to output them in the original form for potential next use

%% COMPUTE TEMPLATE for MOCO

switch options.order
    case 'last' % default; away from photobleaching
        Y_temp=movie(:,:,end-options.nFrames+1:end);
    case 'first'
        Y_temp=movie(:,:,1:1+options.nFrames);
    case 'random'
        p = randperm(size(movie,3),options.nFrames);
        Y_temp=movie(:,:,p);
end

template = median(Y_temp,3);
fftTemp = fftn(template);

for t = 1:size(Y_temp,3)
    [~,Greg] = dftregistration_min_max(fftTemp,fftn(Y_temp(:,:,t)),options.upSampling);
    M_temp = real(ifftn(Greg));
    template = template*(t-1)/t + M_temp/t;
end

template = single(template);

if options.plot
   h=figure(); 
   imshow(template,[]);
    if options.savePath
        export_figure(h,'Template',options.savePath);close;
    end
end

if options.verbose
    disps('Template generation... done');
end

    function disps(string) %overloading disp for this function
        FUNCTION_NAME='generateTemplate';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end
end