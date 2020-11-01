function [pathtorepo,options]=getPath(varargin)
% EXAMPLE USE WITH ARGUMENTS
%[options]= getPath() - use 1
%[options]= getPath(options) - use 2, etc.
%
% HELP
% Outputs the path to the MicroscopesRecordings repository
%
% HISTORY
% - 20-05-07 15:41:41 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% 2020-06-15 18:12:19 RC - simplified and adapted for VIA
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!

%% CONSTANTS (never change, use OPTIONS instead)

FUNCTION_AUTHOR='Radek Chrapkiewicz (radekch@stanford.edu)';

%% OPTIONS (Biafra style, type 'help getOptions' for details)
options.contact=FUNCTION_AUTHOR;
options.FunctionName=[];
% options.FunctionName= % name to the function directly in the repo main folder

%% VARIABLE CHECK 

if nargin>=1
    options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end


%% CORE
%The core of the function should just go here. 

% if strcmp(getenv('computername'),'BFM')
%     pathtorepo=fileparts(which('installBFM'));
% else
if ~isempty(options.FunctionName)
    pathtorepo=fileparts(which(options.FunctionName)); % path to microscopes recordings instead
else    
    pathtorepo=fileparts(fileparts(mfilename('fullpath')));
end



end  %%% END getPath
