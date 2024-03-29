function [outputs,summary]=template_function(arg1,arg2,varargin)
% One line short description
%
% SYNTAX:
% outputs=templateBFM(arg1) - use 1
% outputs=templateBFM(arg1,arg2) - use 2, etc.
% outputs=templateBFM(arg1,arg2,'option1',option1value,'option2',option2value) - use 2, etc.
%
% INPUTS:
% - arg1 - description
%
%
% OUTPUTS:
% - outputs - description
%
% OPTIONS:
%
% 
% DETAILED HELP:
% While collaborating on a code we should use a similar template for function,
% classes etc. Feel free to try fucntion 'genMFile('function name')' as an example. 
% This template has been actually generated by this function. 
% Feel free to copy paste the relevant fragments. The most important part though 
% is the desricption how to use it and perhaps the author 
% - to get support and ask questions.
%
% HISTORY
% - 2019-08-21 16:31:18 - created by Radek Chrapkiewicz
% - 2020-06-05 14:39:31 - updated for new VoltageImagingAnalysis standards RC
%
% DEMO:
% template_function(1,4)
% template_function(1,4,'multiplier',2)
% [out,summary]=template_function(1,4,'multiplier',1)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - Comment with your own ideas



%% OPTIONS
options.putyourinputconfiguration='here';
options.verbose=1; % to control display, this is just an example how to handle annoying display messages 
options.multiplier=5;

%% VARIABLE CHECK 

if nargin>=3
    options=getOptions(options,varargin);
end

%% SUMMARY PREPARATION
summary.input_options=options;
summary.execution_duration=tic;
summary.execution_started=datetime('now');

%% CORE
%The core of the function should just go here. 

disp('This is just a template function to get an inspiration for the standarization of the future function')

outputs=arg1+helper_embedded_function(arg2)*options.multiplier;

disp('Fished!')


%% SAVING SUMMARY 

summary.allvariableyouwanttopass='please pass some lightweight output you can use later for validation, plotting etc.';
summary.execution_duration=toc(summary.execution_duration);
summary.function_path=mfilename('fullpath');
summary.contact='The person who mostly creted this buggy code :)'; % in case of problems or suggestions

%% NESTED FUNCTIONS

function disp(string) %overloading disp for this function - this function should be nested
%    this is just an example how to handle annoying display messages options.verbose
    FUNCTION_NAME='template_function';
    if options.verbose
        fprintf('%s %s: %s\n', datetime('now'),FUNCTION_NAME,string);
    end
end

end % END OF TEMPLATE_FUNCTION

%% EXTRA FUNCTIONS

function y=helper_embedded_function(x)
% just the example
pause(0.5);
y=rand()+x;
end


