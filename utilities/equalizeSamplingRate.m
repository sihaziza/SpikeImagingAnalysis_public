function []=equalizeSamplingRate(ePhys,oPhys)
% Assume ePhys always the highest sampling rate

    t_old=getTime(ttlO_temp,oPhys.fps);
    v_old=ttlO_temp;
    t_new=linspace(0,t_old(end),t_old(end)*ePhys.fps);
    v_new = interp1(t_old,v_old,t_new,'nearest')';
    
    figure(1)
    plot(t_new,v_new,ttlE_temp)
    

end