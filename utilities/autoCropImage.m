function [croppedImage, boundbox] = autoCropImage(image, varargin)

% DESCRIPTION
%
% SYNTAX
%
% EXAMPLE
%
% CONTACT: StanfordVoltageGroup@gmail.com

%% GET DEFAULT OPTIONS
options.plot=false;
options.verbose=true;
options.boundbox=[];
options.threshold=0.1; % remove 10% of above background level
options.savePath=[];

%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%% CORE FUNCTION

thres=options.threshold; % percent cutoff from background baseline

if isempty(options.boundbox)
    xs=sum(image,1);
    ys=sum(image,2);
    xs=rescale(xs,0,1);
    ys=rescale(ys,0,1);
    
    x_i=find(xs>thres,1,'first');
    x_f=find(xs>thres,1,'last');
    y_i=find(ys>thres,1,'first');
    y_f=find(ys>thres,1,'last');
    
    % Matlab convention: [xmin ymin width height]
    % ORCA and matlab different XY convention
    boundbox=[x_i y_i x_f-x_i y_f-y_i];
end

croppedImage = imcrop(image, boundbox);

% Diagnostic Output
if options.plot
    h=figure;
    subplot(1,2,1)
    imshow(image,[])
    title('Before')
    subplot(1,2,2)
    imshow(croppedImage,[])
    title('After')
    if options.savePath
        export_figure(h,'autoCrop',options.savePath);close;
    end
end

disps('Auto-cropping done...')

    function disps(string) %overloading disp for this function - this function should be nested
        FUNCTION_NAME='autoCropImage';
        if options.verbose
            fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
        end
    end
end

