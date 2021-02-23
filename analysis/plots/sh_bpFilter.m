function [DataF]=sh_bpFilter(Data, Fband, Fs)
% Fband=[0.5 100]-band or  [inf 100]-low or [1 ing]-high
% updated SH-20210210

% Often single type are passed trough...
Data=double(Data);

if Fband(1)==inf
    [b,a]=butter(4,Fband(2)/(Fs/2),'low');
elseif Fband(2)==inf
    [b,a]=butter(4,Fband(1)/(Fs/2),'high');
else
    [b,a]=butter(2,Fband/(Fs/2),'bandpass');
end

DataF=filtfilt(b,a,Data);

end
