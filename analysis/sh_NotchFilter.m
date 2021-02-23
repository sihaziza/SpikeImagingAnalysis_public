function [DataF]=sh_NotchFilter(Data,Fsampling,Fcenter)

d = designfilt('bandstopiir','FilterOrder',8, ...
    'HalfPowerFrequency1',Fcenter*0.99,'HalfPowerFrequency2',Fcenter*1.01, ...
    'DesignMethod','butter','SampleRate',Fsampling);

DataF = filtfilt(d,Data);
end