function [data_dtr]=runPhotoBleachingRemoval(data,varargin)
% temporal detrending of fluorescence movie using lowpass method by default. Sampling Rate must be pass through 
% [data_dtr]=runPhotoBleachingRemoval(data,'samplingRate',Fs)
% All options arguments:
% options.methods='lowpass'; %could be exp or spline
% options.samplingRate=[];
% options.lpCutOff=0.5;%in Hz
% options.verbose=1;
% options.plot=true;
% options.diary=false;

%% OPTIONS
options.methods='lowpass'; %could be exp or spline
options.samplingRate=[];
options.lpCutOff=0.5;%in Hz
options.verbose=1;
options.plot=true;
options.diary=false;

%% UPDATE OPTIONS
if nargin>=2
    options=getOptions(options,varargin);
end

%% CHECK OPTIONS VALIDITY
if strcmp(options.methods,'lowpass') && isempty(options.samplingRate)
    error('Need to input sampling rate Fs for lowpass method. [data_dtr]=runPhotoBleachingRemoval(data,"samplingRate",Fs)')
end

%% CORE FUNCTION
d=size(data);
temp=reshape(data,d(1)*d(2),d(3));
Fs=options.samplingRate;
lowF=options.lpCutOff;

switch options.methods
    case 'lowpass'
        [b,a]=butter(2,lowF/(Fs/2),'low');
        vectTrend=filtfilt(b,a,double(temp'));
        tempCorr=double(temp)./vectTrend'; % normalization to 1
    case 'exp'
        tic;
        tempCorr=zeros(size(temp));
        parfor iPixel=1:d(1)*d(2)
            [~, ~,outputExp] = createFitExp(temp(iPixel,:));
            tempCorr(iPixel,:)=outputExp.residuals;
        end
        toc;
    case 'spline'
        tic;
        tempCorr=zeros(size(temp));
        parfor iPixel=1:d(1)*d(2)
            [~, ~,outputExp] = createFitSpline(temp(iPixel,:));
            tempCorr(iPixel,:)=outputExp.residuals;
        end
        toc;
end

data_dtr=reshape(tempCorr,d(1),d(2),d(3));
data_dtr=single(data_dtr);
end
