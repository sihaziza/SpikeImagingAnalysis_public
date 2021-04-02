function [datafilt]=movieTimeFiltering(data, freqBand,fs)
% fast temporal filtering of movie (3D matrix). Time is assumed to be the
% last dimension.

d=size(data);
temp=reshape(data,d(1)*d(2),d(3));
[b,a]=butter(3,freqBand/(fs/2),'bandpass');

tic;
datafilt=filtfilt(b,a,double(temp'));
toc;

datafilt=reshape(datafilt',d(1),d(2),d(3));
end