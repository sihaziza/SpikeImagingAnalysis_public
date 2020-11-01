function varlist=check_matfile(varargin)
%
% HELP
% Checking a content of a mat file, by entering a keyboard environment within a function. So instead of loading and overwriting you will do it within a function scope, in a clean way.
% SYNTAX
%[varlist,summary]= check_matfile() - dialog
%[varlist,summary]= check_matfile(matfilepath) - use 2, etc.
% HISTORY
% - 29-Jun-2020 19:37:52 - created by Radek Chrapkiewicz (radekch@stanford.edu)

if nargin==0
    matfile=getFile;
else 
    matfile=varargin{1};
end

load(matfile);
varlist=whos;

keyboard

end  %%% END CHECK_MATFILE
