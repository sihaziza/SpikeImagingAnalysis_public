function custom_colormap=getCurrentColormap(varargin)
% EXAMPLE USE WITH ARGUMENTS
% getCurrentColormap() - use 1
% getCurrentColormap(name) - use 2, etc.
% getCurrentColormap(name,options) - use 2, etc.
%
% HELP
% Getting custom colormap and exporting it.
%
% HISTORY
% - 20-05-09 16:13:59 - created by Radek Chrapkiewicz
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


try
    
%% CONSTANTS


%% OPTIONS
options.author=getenv('username');
options.name='mycolormap';
options.application='colormap for voltage';
options.hAxes=gca;


%% VARIABLE CHECK 

if nargin>=1
	options.name=varargin{1};
end

if nargin>=2
	options=getOptions(options,varargin(2:end));
end

%% PATHS
export_path=fileparts(mfilename('fullfile'));


%% CORE
%The core of the function should just go here. 

custom_colormap.map=get(options.hAxes,'colormap');
custom_colormap.created_by=options.author;
custom_colormap.date=Time.day;
custom_colormap.name=options.name;
custom_colormap.original_application=options.application;

save(fullfile(export_path,options.name),sprintf('custom_colormap'));



catch ME
   ME
   util.errorHandling(ME)
   keyboard
end

end  %%% END GETCURRENTCOLORMAP
