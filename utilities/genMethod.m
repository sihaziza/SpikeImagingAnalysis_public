function [formatted_method_string,options]=genMethod(method_name,varargin)
% EXAMPLE USE WITH ARGUMENTS
% [formatted_method_string,options]=genMethod(method_name)
% [formatted_method_string,options]=genMethod(method_name,options)
%
% HELP
% Generates class method template to be pasted into existing class file.
% Created to ensure consistency.
%
% HISTORY
% - 20-04-29 00:41:25 - created by Radek Chrapkiewicz
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1

%% CONSTANTS


options.author='Radek Chrapkiewicz';
options.debug=false;
options.variable_check=false;
options.add_options=false;
options.function_header=true;

options.logMethodExecution=true; % log method execution in the Recording

options.short=false; % just overwriting flags to shorten lengt of the file;
short_configuration.debug=false;
short_configuration.variable_check=false;
short_configuration.add_options=true;
short_configuration.function_header=false; 

option.short_configuration=short_configuration;

try
    
    %% VARIABLE CHECK
    if nargin>=2
        options=getOptions(options,varargin);
    end
    
    if options.short
        options=getOptions(options,{'options',option.short_configuration}); % overwriting 
    end

    
    %% CORE
    
    formatted_method_string=''; % just starting from scratch
    
    if options.function_header
    formatted_method_string=sprintf('%sfunction [outputs,options]=%s(obj,varargin)\n',formatted_method_string,method_name);
    end
    formatted_method_string=sprintf('%s%% EXAMPLE USE WITH ARGUMENTS\n',formatted_method_string);
    formatted_method_string=sprintf('%s%% [outputs,options]=%s(obj) - use 1, no arguments\n',formatted_method_string,method_name);
    formatted_method_string=sprintf('%s%% [outputs,options]=%s(obj,arg1,options) - use 2, ag1 - ?, options (configuration) in the matlab or struct style.\n',formatted_method_string,method_name);
    
    
    
    prompt = 'Provide a short description of the created method\n';
    user_description = input(prompt,'s');
    
    formatted_method_string=sprintf('%s%%\n%% HELP\n',formatted_method_string);
    formatted_method_string=sprintf('%s%% %s\n',formatted_method_string,user_description);
    formatted_method_string=sprintf('%s%%\n%% HISTORY\n',formatted_method_string);
    day=Time.day;
    hour=Time.hour;
    formatted_method_string=sprintf('%s%% - %s %s - created by %s\n',formatted_method_string,day,hour,options.author);
    formatted_method_string=sprintf('%s%%\n%% ISSUES\n',formatted_method_string);
    formatted_method_string=sprintf('%s%% #1 - issue 1\n',formatted_method_string);
    formatted_method_string=sprintf('%s%%\n%% TODO\n',formatted_method_string);
    formatted_method_string=sprintf('%s%% *1 - get the first working version of the function!\n',formatted_method_string);
    
    if options.debug
        formatted_method_string=sprintf('%s\n\ntry\n',formatted_method_string);
    end
    formatted_method_string=sprintf('%s hT=Time;\n',formatted_method_string);
    
    if options.add_options
        formatted_method_string=sprintf('%s\n%%%% OPTIONS\n',formatted_method_string);
        formatted_method_string=sprintf('%s\n\noptions.author=''%s''; %% who to blame for poor implementation and bugs ;)\n',formatted_method_string,options.author);  
    end
    
    formatted_method_string=sprintf('%s\n%%%% CONSTANTS\n',formatted_method_string);
    
    if options.variable_check
        formatted_method_string=sprintf('%s\n%%%% VARIABLE CHECK \n',formatted_method_string);
        formatted_method_string=sprintf('%s\nif nargin==0\n%%do something when no arguments?\nend\n',formatted_method_string);
        formatted_method_string=sprintf('%s\n\nif nargin>=1\n%%do something when more than 1 arguments?\nend\n',formatted_method_string);
        formatted_method_string=sprintf('%s\n\nif nargin>=2\n%%do something when more than 2 arguments?\nend\n',formatted_method_string);
    end
    
    if options.add_options
        formatted_method_string=sprintf('%s\n%%%% CHECK OPTIONS - enter correct number of option argument \n',formatted_method_string);
        formatted_method_string=sprintf('%s\n\nif nargin>=1\noptions=getOptions(options,varargin(1:end));\nend\n',formatted_method_string);      
    end

    formatted_method_string=sprintf('%s%%%% CORE\n%%The core of the function should just go here.\n',formatted_method_string);

    
    % for debugging:
    if options.debug
        formatted_method_string=sprintf('%s\n\ncatch ME\n',formatted_method_string);
        formatted_method_string=sprintf('%s   ME\n',formatted_method_string);
        formatted_method_string=sprintf('%s   util.errorHandling(ME)\n',formatted_method_string); % 2019-06-12 13:27:05 RC - more descriptive error message
        formatted_method_string=sprintf('%s   keyboard\n',formatted_method_string);
        formatted_method_string=sprintf('%send\n',formatted_method_string);        
    end
    
    
    if options.logMethodExecution
            formatted_method_string=sprintf('%s hT.update;\n',formatted_method_string); 
            formatted_method_string=sprintf('%s  logMethodExecution(obj,''%s'',hT.from_start,options)\n',formatted_method_string,method_name);
    end
    
    if options.function_header
    formatted_method_string=sprintf('%s\n\nend  %%%%%% END %s\n',formatted_method_string, upper(method_name));
    end 
    
    clipboard('copy',formatted_method_string)
    
    options.method_string=formatted_method_string;
    t=Time;
    options.created=t.now;
    
catch ME
    ME
    util.errorHandling(ME)
    keyboard
end


end %%% END FUNCTION



