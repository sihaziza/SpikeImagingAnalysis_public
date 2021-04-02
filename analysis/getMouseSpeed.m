function [displacement,speed,locoRestTTL,figHandle]=getMouseSpeed(data,Fs,varargin)
% [displacement,speed,locoRestTTL,figH]=getMouseSpeed(data,Fs)
% data correspond to the number of ticks from the rotary encoder
% assume rotatory encoder 600 ticks/360° and 12cm diam wheel
% output in cm/s
% speed is kept the same length as data for convenience.
% Options
% 'wheelDiam',12; % running wheel diameter in cm
% 'smoothWin',Fs/2; % 0.5 second smoothing window
% 'speedCutOff',1; % in cm/s > cutoff to find the rest>locotion transition
% 'verbose',1
% 'plot',true

%% OPTIONS
options.wheelDiam=12; % running wheel diameter in cm
options.smoothWin=Fs/4; % 0.5 second smoothing window
options.speedCutOff=1; % in cm/s > cutoff to find the rest>locotion transition
options.verbose=1;
options.savePath=[];
options.plotFigure=true;

%% UPDATE OPTIONS
if nargin>=3
    options=getOptions(options,varargin);
end

%%

wheelDiam=options.wheelDiam;
peri=2*pi*wheelDiam/2;

pos=peri*data/360;
win=options.smoothWin;
displacement=abs(movmean(pos,win)); % change the direction convention to get speed >0
speed=diff(displacement)*win;
speed=movmean(speed,win);% cm.s-1

speed=[speed; speed(end)];

locoRestTTL=double(speed>=options.speedCutOff);

time=getTime(speed,Fs)';

if options.plotFigure
    disp('outputting figure')
    figHandle=figure('Name','Speed','DefaultAxesFontSize',18,'color','w');
    yyaxis left
    plot(time,displacement,'linewidth',2)
    xlabel('Time (sec)')
    ylabel('Displacement (cm)')
    %     ylim([0 max(displacement)])
    yyaxis right
    plot(time,speed,'linewidth',2)
    hold on
    plot(time,locoRestTTL,'k','linewidth',2)
    hold off
    %         ylim([0 max(speed)])
    legend('displ.','speed','stateTrans','Location','south','Orientation','horizontal')
    xlabel('Time (sec)')
    ylabel('Speed (cm/s)')
    title('Displacement, Speed and rest/loco transitions')

    if options.savePath
        savePDF(figHandle,'Mouse Locomotion-Speed',options.savePath)
    end
    
end
end