function options=savetxt(string,varargin)
% EXAMPLE USE WITH ARGUMENTS
% savetxt(string)
% savetxt(string,filename)
% savetxt(string,filename,folder)
% savetxt(string,filename,folder)
% savetxt(string,filename,folder,options)
%
% HELP
% Saves string to a text file
%
% HISTORY
% - 20-04-10 12:55:39 - created by Radek Chrapkiewicz
% % 2020-05-06 15:14:40 RC debugged options 
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


try

%% OPTIONS
options.filename='exported';
options.folder=pwd;
options.addtime=true;
options.extension='.txt';

%% CONSTANTS

%% VARIABLE CHECK 

if nargin==0
error('At least one argument needed')
end


if nargin>=2
    options.filename=varargin{1};
end

if nargin>=3
    options.folder=varargin{2};
end

if nargin>=4
    options=getOptions(options,varargin(3:end));
end

%% PATHS


%% CORE
%The core of the function should just go here. 



if options.addtime
    t=Time;
    options.filename=[options.filename,'_',t.now];
end
    

options.filepath=fullfile(options.folder,[options.filename,options.extension]);

options.exported_string=strrep(string,'\','\\');


fileID = fopen(options.filepath,'w');
if fileID==-1
    warning('Creating a file went wrong, terminating')
    return;
end
fprintf(fileID,options.exported_string);
fclose(fileID);
disp('string successfully exported')

catch ME
   ME
   util.errorHandling(ME)
   keyboard
end

end  %%% END SAVETXT
