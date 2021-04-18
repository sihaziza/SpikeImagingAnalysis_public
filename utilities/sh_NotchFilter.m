function [DataF]=sh_NotchFilter(Data,Fsampling,Fcenter,harmonics)
% apply a notch filter on a time trace. Data can be a matrix or tensor
% [DataFilt]=sh_NotchFilter(movie,fs,60)
% [DataFilt]=sh_NotchFilter(trace,fs,60,2)

dim=size(Data);

if istensor(Data)
    DataF=reshape(Data,dim(1)*dim(2),dim(3));
elseif dim(1)<dim(2)
    DataF=Data';
end

if isempty(harmonics)
    harmonics=1;
end

if ~strcmpi(class(DataF),'double')
    DataF=double(DataF);
end

% mind the dimension to which to operate > filtfilt operates on the 1st dim
% > so make sure size(data,1) is time.
if size(DataF,1)<size(DataF,2)
    DataF=DataF';
end

for i=1:harmonics
    Fcenter=Fcenter*i;
    d= designfilt('bandstopiir','FilterOrder',8, ...
        'HalfPowerFrequency1',Fcenter*0.99,'HalfPowerFrequency2',Fcenter*1.01, ...
        'DesignMethod','butter','SampleRate',Fsampling);
    
    DataF = filtfilt(d,DataF); % mind the dimension to which to operate
end

DataF=single(DataF');

DataF=reshape(DataF,dim(1),dim(2),dim(3));

end