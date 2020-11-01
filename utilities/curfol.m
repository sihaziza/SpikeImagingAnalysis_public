function curfol()
% EXAMPLE USE WITH ARGUMENTS
% curfol() - use 1
% HELP:
% Simple opening of the current folder in Windows explorer.
%
% HISTORY
% - 19-04-24 17:34:40 - created by Radek Chrapkiewicz
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% CONSTANTS

%% VARIABLE CHECK 

if nargin==0
%do something when no arguments?
end


%% PATHS


%% CORE
%The core of the function should just go here. 

winopen(pwd)

end  %%% END CURFOL
