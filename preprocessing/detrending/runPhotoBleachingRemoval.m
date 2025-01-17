function [data_dtr]=runPhotoBleachingRemoval(data,varargin)
% temporal detrending of fluorescence movie using lowpass method by default. Sampling Rate must be pass through 
% [data_dtr]=runPhotoBleachingRemoval(data,'samplingRate',Fs)
% All options arguments:
% options.methods='lowpass'; %could be exp or spline
% options.samplingRate=[];
% options.lpCutOff=0.1;%in Hz
% options.verbose=1;
% options.plot=true;
% options.diary=false;

%% OPTIONS
options.methods='lowpass'; %could be exp or spline
options.samplingRate=[];
options.lpCutOff=0.1;%in Hz
options.verbose=1;
options.plot=true;
options.diary=false;
options.filterOrder=2;

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

% check if vector, matrix or tensor
if numel(d)>2
temp=reshape(data,d(1)*d(2),d(3));
elseif d(1)>d(2) % need row vector
    temp=data';
else
    temp=data;
end

Fs=options.samplingRate;
lowF=options.lpCutOff;
order=options.filterOrder;

data_dtr=zeros(size(temp));

% only process ~nan vector
% sum along time for each pixel then only keep those with no nan value
q=sum(isnan(temp),2);
idx=find(q<1);
temp=temp(idx,:);

switch options.methods
    case 'lowpass'
        [b,a]=butter(order,lowF/(Fs/2),'low');
        vectTrend=filtfilt(b,a,double(temp'));
        tempCorr=double(temp)./vectTrend'; % normalization to 1
%         tempCorr=vectTrend'; % no normalization
    case 'exp'
        tic;
        tempCorr=zeros(size(temp));
        parfor iPixel=1%:d(1)*d(2)
            [fitresult, ~,~] = createFitExp(temp(iPixel,:));
            baseline=fitresult(1:numel(temp));
            tempCorr(iPixel,:)=temp./baseline';
        end
        toc;
    case 'spline'
        tic;
        tempCorr=zeros(size(temp));
        parfor iPixel=1%:d(1)*d(2)
%             [fitresult, ~,outputExp] = createFitSpline(temp(iPixel,:));
            [fitresult, ~,~] = createFitSpline(temp(iPixel,:));
            baseline=fitresult(1:numel(temp));
            tempCorr(iPixel,:)=temp./baseline';
        end
        toc;
end

% nPix=dim(1)*dim(2);

data_dtr(idx,:)=tempCorr;

%reassign nan
data_dtr(~idx,:)=nan;

if  numel(d)>2
data_dtr=reshape(data_dtr,d(1),d(2),d(3));
end

data_dtr=single(data_dtr);
end
