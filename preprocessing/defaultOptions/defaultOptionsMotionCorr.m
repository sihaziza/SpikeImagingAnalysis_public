function [options]=defaultOptionsMotionCorr

% This function brings clarity to the many options of the pipeline. Should
% be organize in a logical manner, the naming should follow coding
% convention

% Key parameters
options.ParallelCPU=true;
options.Bandpass=true;
options.BandPx=[1,10]; % cutoff for bandpass filtering
options.Invert=false;
options.customTemplate=[]; % just in case you want to use a custom template image it is beyond the specification
options.customTemplateMethod='corrected';
options.TemplateFrame=[]; % on default using the the last frame of the movie, you can pass any frame number or a range of frames for the average of frames in this range.
% normCorr configuration
options.max_shift=200; % % maximum shift in pixels
options.us_fac=20; % upsampling factor

% Control display
options.verbose=1;
options.plot=true;
options.PlotTemplate=true;
options.dataspace='/mov'; % only '/mov' is supported by normcorre;

% Export data 
options.diary=true;
options.diary_name='log.txt';
options.export_folder=[]; % if empty than created automatically, vide code 
options.diagnosticFolder=fullfile('Diagnostic','motionCorr');
options.suffix='_moco'; % added to the file name

end