function [output]=bpFilter2D(input,low,high,varargin)
%  perform spatial filtering using one or two gaussian filtered images.
% [output]=bpFilter2D(input,low,high,varargin)
% e.g. DC removal > [output]=bpFilter2D(input,inf,1,'parallel',false);

%% Gather options
options.parallel=true;
options.loop=1; %apply the filter only once, equivalent to the filter order.
%% UPDATE OPTIONS
if nargin>=4
    options=getOptions(options,varargin);
end

% Convert to double than cast back into original input class
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
        elseif high==Inf
            output(:,:,ii)=squeeze(stack(:,:,ii))...
                -imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
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
        elseif high==Inf
            output(:,:,ii)=squeeze(stack(:,:,ii))...
                -imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
        else
            output(:,:,ii)=...
                imgaussfilt(squeeze(stack(:,:,ii)),high/fwhm_scaling,'FilterDomain','spatial')...
                -imgaussfilt(squeeze(stack(:,:,ii)),low/fwhm_scaling,'FilterDomain','spatial');
        end
    end
end

if options.loop>1
    disp('computing additional filtering order')
    for iOrder=1:options.loop-1
        [output]=bpFilter2D(output,low,high,'parallel',options.parallel);
    end
end
end