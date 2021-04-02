function [summary]=export_figure(figure_handle,filename,folder,varargin)
% Exporting diagnostic figures for VIA preprocessing.
% SYNTAX
%[output_arg1,summary]= export_figure(figure_handle,filename,folder) - use 4, etc.
%[output_arg1,summary]= export_figure(figure_handle,filename,folder,'optionName',optionValue,...) - passing options using a 'Name', 'Value' paradigm frequently used by Matlab native functions.
%[output_arg1,summary]= export_figure(figure_handle,filename,folder,'options',options) - passing options as a structure.
%
% INPUTS:
% - figure_handle - ...
% - filename - ...
% - folder - ...
%
% OUTPUTS:
% - output_arg1 - ...
% - summary - %
% OPTIONS:
% - see below the section of code showing all possible input options and comments for their meaning. 
%
% HISTORY
% - 28-Jun-2020 04:39:08 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!



%% OPTIONS (Biafra style, type 'help getOptions' for details) or: https://github.com/schnitzer-lab/VoltageImagingAnalysis/wiki/'options':-structure-with-function-configuration
options=struct;
options.default_format='png';
% options.other_formats={'fig','pdf'};
options.position=[10 10 1200 800];


%% VARIABLE CHECK 

if nargin>=4
options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end
input_options=options; % saving orginally passed options to output them in the original form for potential next use


%% Summary preparation
summary.function_path=mfilename('fullpath');
summary.execution_started=datetime('now');
summary.execution_duration=tic;


%% CORE
%The core of the function should just go here.

previous_position=figure_handle.Position;
figure_handle.Position=options.position;
figure_handle.Color=[1,1,1];

default_path=fullfile(folder,[filename,'.',options.default_format]);

saveas_local(figure_handle,default_path);

% for ii=1:length(options.other_formats)
%     additional_folder=fullfile(folder,options.other_formats{ii});
%     if ~isfolder(additional_folder)
%         mkdir(additional_folder)
%     end
%     extra_path=fullfile(additional_folder,[filename,'.',options.other_formats{ii}]);
%     saveas_local(figure_handle,extra_path);
%  
% end

figure_handle.Position=previous_position;



%% CLOSING
summary.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.
summary.execution_duration=toc(summary.execution_duration);

end

function saveas_local(hfig,fpath)

[folder,fname,ext]=fileparts(fpath);
if strcmp(ext,'.fig')
    saveas(hfig,fpath)
    return;
end

format=['-', ext(2:end)];

options.FileFormats={format}; %{'-pdf','-png'}; % provided in a cell format 
options.CreateSubfolder=false;
options.SubfolderName='';
options.AddTimeStamp=false;
options.OpenFolder=false;
options.hFigure=hfig; % although this function has been written for gcf, it allows for exporting other figure handles too!
options.savefig=false; % saving fig file 

try
Fig.export_gcf(fname,folder,'options',options);
catch 
    warning('export_gcf fuckup')
    saveas(hfig,fpath)
end


end

%%% Automatically generated using 'genMFile' function (by Radek Chrapkiewicz) with the following configuration:
% summary=
%          function_path: 'C:\Users\Radek\Documents\repos\Analysis\VoltageImagingAnalysis\quick_access_functions\genMFile'
%     execution_started: 28-Jun-2020 04:38:45
%    execution_duration: 23.8696
%              computer: 'BFM'
%                  user: 'Radek'
%         input_options: [1×1 struct]
%
%