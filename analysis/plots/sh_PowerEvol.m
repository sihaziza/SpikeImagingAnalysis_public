function [TTL]=sh_TTLextraction(Swave,Fs)

[b,a] = butter(3,band/(0.5*Fs),'bandpass');
A=filtfilt(b,a,arrayBL(:,:,Nch));
B=filtfilt(b,a,arrayOB(:,:,Nch));

wnd=0.5*Fs; % window of 0.5 sec
ovl=0.90; % 90% overlap

bpwOB=[];
bpwBL=[];
for k=1:1000 % should be large enough
    if (round(k*wnd-(k-1)*wnd*ovl,0)>=size(arrayBL,1))
        break
    end
    born=round((k-1)*wnd+1-(k-1)*wnd*ovl,0):round(k*wnd-(k-1)*wnd*ovl,0);
    %     [born(1) born(end)]
    for i=1:size(A,2)
        bpwBL(k,i)=bandpower(A(born,i));
    end
    for i=1:size(B,2)
        bpwOB(k,i)=bandpower(B(born,i));
    end
end

%%%%%%% PLOT Figure %%%%%%%
figure('Name',strcat(fName,'/ Over Time'),'DefaultAxesFontSize',18,'color','w')
wave=bpwBL;
L= (size(wave,2)-mod(size(wave,2),2*stp))/(2*stp);
cc=jet(L);
T=(-2.5:6/size(wave,1):3.5-1/size(wave,1))';
Mx=0;
for k=1:L
    temp=mean(wave(:,(k-1)*stp+1:k*stp),2);
    MM=max(temp);
    if MM>Mx
        Mx=MM;
    end
    subplot(1,3,1)
    plot(T,temp,'LineWidth',2,'color',cc(k,:))
    hold on
end
xlim([-2.5 3.5])
title('Baseline')
legend('Location','northwest')

nn=size(wave,1);
Tg=(-2.5:6/nn:3.5-1/nn)';

subplot(1,3,3)
plot(Tg,mean(bpwBL,2),'k','LineWidth',2)
hold on

wave=bpwOB;
L= (size(wave,2)-mod(size(wave,2),stp))/stp;
cc=jet(L);
T=(-2.5:6/size(wave,1):3.5-1/size(wave,1))';
for k=1:L
    temp=mean(wave(:,(k-1)*stp+1:k*stp),2);
    MM=max(temp);
    if MM>Mx
        Mx=MM;
    end
    subplot(1,3,2)
    plot(T,temp,'LineWidth',2,'color',cc(k,:))
    hold on
end
xlim([-2.5 3.5])
title('OddBall')
legend('Location','northwest')

subplot(1,3,1)
plot([0 0],[0 Mx],'--k','LineWidth',0.5)
hold off
ylim([0 Mx])

subplot(1,3,2)
plot([0 0],[0 Mx],'--k','LineWidth',0.5)
hold off
ylim([0 Mx])

subplot(1,3,3)
plot(Tg,mean(bpwOB,2),'r','LineWidth',2)
plot([0 0],[0 Mx],'--k','LineWidth',0.5)
hold off
xlim([-2.5 3.5])
ylim([0 Mx])
legend('Baseline','OddBall','Location','northwest')
title('Grand Average')

end