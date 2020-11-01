function [output]=bpFilter2D(input,low,high,varargin)

% created by Oscar Hernandez
% modified by Radek Chrapkiewicz, Simon Haziza

%% Gather options
options.parallel=true;

%% UPDATE OPTIONS
if nargin>=4
    options=getOptions(options,varargin);
end

stack=double(input);

fwhm_scaling=2*sqrt(2*log(2));

output=stack;
sz=size(stack);
if length(sz)==2
    sz=[sz,1];
end

if options.parallel
    parfor ii=1:sz(3)
        if low==Inf
            output(:,:,ii)=imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial');
        else
            output(:,:,ii)=...
                imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial')...
                -imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
        end
    end
else
    for ii=1:sz(3)
        if low==Inf
            output(:,:,ii)=imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial');
        else
            output(:,:,ii)=...
                imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial')...
                -imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
        end
    end
end
end