function [options]=defaultOptionsUnmixing

% This function brings clarity to the many options of the pipeline. Should
% be organize in a logical manner, the naming should follow coding
% convention

% Key parametersoptions.ParallelCPU=true;
options.fps=100; % default: for TEMPO
options.mouseState=[]; % default: no assumption
options.heartbeatRange=[];
options.windowPSD=5;
options.conditioning=true;
options.method='rlr';
options.type='global';

% Control display
options.verbose=true;
% options.FigureDir='I:\USERS\Simon\TEST';
options.plot=true;
options.savePlot=true;
options.dataspace='/mov'; % only '/mov' is supported by normcorre;

% Export data
options.suffix='_umx';
options.diary=true;
options.diary_name='log.txt';
options.export_folder=[]; % if empty than created automatically, vide code 
options.diagnosticFolder=[];

end