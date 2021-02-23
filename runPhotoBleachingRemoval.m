function [dataCorr]=runPhotoBleachingRemoval(data,varargin)

% data is 3d matrix - fit each pixel with 2 term exponential and output the
% residual
% use lowpass filter at a better estimate of the trend
% All options arguments:
% options.methods='lowpass'; %could be createFitExp
% options.samplingRate=[];
% options.verbose=1;
% options.plot=true;
% options.diary=false;

%% OPTIONS
options.methods='lowpass'; %could be createFitExp
options.samplingRate=[];
options.verbose=1;
options.plot=true;
options.diary=false;

%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%% CHECK OPTIONS VALIDITY
if strcmp(options.methods,'lowpass') && isempty(options.samplingRate)
    error('Need to input sampling rate Fs for lowpass method')
end

%% CORE FUNCTION

d=size(data);
temp=reshape(data,d(1)*d(2),d(3));
tempCorr=zeros(size(temp));
Fs=options.samplingRate;

if strcmp(options.methods,'lowpass')
    lowF=1; % 5Hz low pass filter
    [b,a]=butter(4,lowF/(Fs/2),'low');
    
    tic;
    parfor iPixel=1:d(1)*d(2)
        vect=double(temp(iPixel,:));
        vectTrend=filtfilt(b,a,vect);
%         tempCorr(iPixel,:)=(vect-vectTrend)./vectTrend; % compute trended dff
        tempCorr(iPixel,:)=(vect-vectTrend)+vectTrend(1); % compute trended dff
    end
    toc;
else
    tic;
    parfor iPixel=1:d(1)*d(2)
        [~, ~,outputExp] = createFitExp(temp(iPixel,:));
        tempCorr(iPixel,:)=outputExp.residuals;
    end
    toc;
end

dataCorr=reshape(tempCorr,d(1),d(2),d(3));
dataCorr=single(dataCorr);
end
