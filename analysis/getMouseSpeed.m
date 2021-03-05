function [disp,speed]=getMouseSpeed(data,Fs)
% [speed]=getMouseSpeed(data,Fs)
% assume rotatory encoder 600 ticks/360° and 12cm diam wheel
% output in cm/s
% speed is kept the same length as data for convenience.

wheelDiam=12;%cm
peri=2*pi*wheelDiam/2;

pos=peri*data/360;
win=Fs/2;
disp=movmean(-pos,win);
speed=diff(disp)*win;
speed=movmean(speed,win);% cm.s-1

speed=[speed; speed(end)];

time=getTime(speed,Fs);
 
figure('Name','Speed','DefaultAxesFontSize',18,'color','w')
yyaxis right
plot(time,disp,'linewidth',2)
xlabel('Time (min)')
ylabel('Displacement (cm)')
yyaxis left
plot(time,speed,'linewidth',2)
xlabel('Time (min)')
ylabel('Speed (cm/s)')

end