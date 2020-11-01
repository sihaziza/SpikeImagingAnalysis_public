function [commitID,git_lastcommit,options]=gitLastCommit(varargin)
% EXAMPLE USE WITH ARGUMENTS
%[git_lastcommit,options]= gitLastCommit() - assuming path to the repo
%where function is located, two levels up
%[git_lastcommit,options]= gitLastCommit(repo_path) - last commit of repo
%of the path repo_path
%[git_lastcommit,options]= gitLastCommit(function_name_on_repo_path) - last
%commit of repo which has function_name_on_repo_path in the main folder
%[options]= gitLastCommit(path/function_name,options) - use 3 with options
%
% HELP
% Getting information of the last commit of git to make sure what kind of software versions you are actually using.
%
% HISTORY
% - 20-05-05 02:40:14 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - % 2020-06-15 18:52:38 RC simplified and adapted for VIA 
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
options.HEADLogRelativePath='\.git\logs\HEAD'; % function reads out HEAD log path therefore it needs to find it!

options.RepoPath=getPath; % 2020-06-15 18:52:38 RC




%% VARIABLE CHECK 

if nargin>=1
    if isfolder(varargin{1})
        options.RepoPath=varargin{1};
    elseif exist(varargin{1},'file')
        options.RepoPath=fileparts(which(varargin{1}));
    else 
        warning('Can''t find %s on a path',varargin{1});
        commitID=[];
        git_lastcommit=[];        
        return
    end
end

options.HEADLogPath=fullfile(options.RepoPath,options.HEADLogRelativePath);% this option overwrites all previous options indicating location of the repo;

if nargin>=2
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end

%% CORE

fid=fopen(options.HEADLogPath);

%%
readoutline=fgetl(fid);
lineidx=1;
while length(readoutline)>1 && sum(readoutline)~=-1
    previousline=readoutline;
    readoutline=fgetl(fid);
    lineidx=lineidx+1;
end

%%


logfields_indices=strfind(previousline,' ');

git_lastcommit=struct;

git_lastcommit.current_commit_id=previousline(logfields_indices(1)+1:logfields_indices(2)-1);
git_lastcommit.previous_commit_id=previousline(1:logfields_indices(1)-1);
git_lastcommit.user=previousline(logfields_indices(2)+1:logfields_indices(3)-1);
git_lastcommit.email=previousline(logfields_indices(3)+2:logfields_indices(4)-2);
git_lastcommit.date_timestamp=previousline(logfields_indices(4)+1:logfields_indices(5)-1);
git_lastcommit.commit_message=previousline(logfields_indices(5)+1:end);
git_lastcommit.date_of_checking=datetime('now');

if ispc
    git_lastcommit.current_username=getenv('username');
    git_lastcommit.current_computer=getenv('computername');
end


git_lastcommit.log_last_line=previousline;

commitID=git_lastcommit.current_commit_id(1:7);

catch ME
   util.errorHandling(ME)
   if DEBUG_THIS_FILE; keyboard; end
end

end  %%% END GITLASTCOMMIT
