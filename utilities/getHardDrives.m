function [harddrives,options]=getHardDrives(varargin)
% EXAMPLE USE WITH ARGUMENTS
%[options]= getHardDrives() - use 1
%[options]= getHardDrives(arg1) - use 2, etc.
%[options]= getHardDrives(arg1,options) - use 3 with options
%
% HELP
% Fetches information about hard drives installed on the computer.
%
% HISTORY
% - 20-05-05 03:45:05 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


try

%% CONSTANTS (never change, use OPTIONS instead)
DEBUG_THIS_FILE=false;
FUNCTION_AUTHOR='Radek Chrapkiewicz (radekch@stanford.edu)';

%% OPTIONS (Biafra style, type 'help getOptions' for details)
options.author=FUNCTION_AUTHOR;

%% VARIABLE CHECK 

if nargin==0
%do something when no arguments?
end


if nargin>=1
%do something when more than 1 arguments?
end


if nargin>=2
options=getOptions(options,varargin(1:end)) % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

%% PATHS


%% CORE
%The core of the function should just go here. 

harddrives=evalc('system(''wmic diskdrive get model,index,firmwareRevision,status,interfaceType,totalSectors,partitions,serialNumber,Size'');');

catch ME
   util.errorHandling(ME)
   if DEBUG_THIS_FILE; keyboard; end
end

end  %%% END GETHARDDRIVES
