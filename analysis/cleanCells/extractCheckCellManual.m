function [cellList,figH]=extractCheckCellManual(output,varargin)

% can input your own cell list.
% % options.cellList=[];
options.waitForUser=true;
options.frameRate=[];
options.positionFig=[100,100,800,400]; 

%% UPDATE OPTIONS
if nargin>1
    options=getOptions(options,varargin);
end

%%
if isempty(output.temporal_weights)
    cellList=[];
    figH=figure();
    return;
end

spatial=full(output.spatial_weights);
temporal=wdenoise(double(output.temporal_weights),1);
if ~isempty(options.frameRate) && isnumeric(options.frameRate) && isscalar(options.frameRate) && options.frameRate>0
    fs=double(options.frameRate);
elseif isstruct(output) && isfield(output,'fs') && isnumeric(output.fs) && isscalar(output.fs) && output.fs>0
    fs=double(output.fs);
elseif isstruct(output) && isfield(output,'fps') && isnumeric(output.fps) && isscalar(output.fps) && output.fps>0
    fs=double(output.fps);
else
    fs=700;
    warning('Frame rate not provided. Falling back to 700 Hz. Pass ''frameRate'',metadata.fps to avoid wrong time axis.');
end
time=getTime(temporal,fs);
decade=1;
p=0;
cellList=[];
while p<=size(temporal,2)
    figure('defaultaxesfontsize',12,'color','w','Position',options.positionFig);
    nUnits=min(10,size(temporal,2)-p);
    for i=1:nUnits
        subplot(10,10,[10*(i-1)+1 10*(i-1)+2])
        imagesc(spatial(:,:,p+i))
        ylabel(num2str(p+i))
        %         axis off
        subplot(10,10,[10*(i-1)+3 10*(i-1)+10])
        plot(time,100*temporal(:,p+i))
        xlim([0 time(end)])
        ylabel('dF/F (%)')
        title('Press any key to enter your favorite cell number')
    end
    xlabel('Time (s)')
    if options.waitForUser
        prompt = {'which cells to keep? [as a list, just space e.g. 1 5 8 9 15'};
        dlgtitle = 'Input';
        dims = [2 50];
        pause 
        answer = inputdlg(prompt,dlgtitle,dims);
        cellList=[cellList str2num(answer{1})];
    end
    decade=decade+1;
    p=10*(decade-1);
end

close all

% double check with the user
figH=figure('defaultaxesfontsize',12,'color','w','Name','summary of selected cells','Position',options.positionFig);
nUnits=max(10,numel(cellList));
for i=1:numel(cellList)
    subplot(nUnits,10,[10*(i-1)+1 10*(i-1)+2])
    imagesc(spatial(:,:,cellList(i)))
    %     axis off
    ylabel(num2str(cellList(i)))
    subplot(nUnits,10,[10*(i-1)+3 10*i])
    plot(time,100*temporal(:,cellList(i)))
    xlim([0 time(end)])
    ylabel('dF/F (%)')
    axis tight
    title('Press any key to enter your favorite cell number')
end
xlabel('Time (s)')

answer = questdlg('Are you happy with you cell choice? (press any key to continue)', ...
    'Cell selection Summary', ...
    'Yes Happy','No do it again','Yes Happy');

% Handle response
switch answer
    case 'Yes Happy'
        disp('outputting results..')
%         close all
    case 'No do it again'
        close all
        disp('Lets run cell-check again')
        [cellList,figH]=extractCheckCellManual(output,'frameRate',fs);
end
%dont close figure for PDF saving
end
