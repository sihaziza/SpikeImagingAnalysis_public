function [trace, deltaF] = getTrace(movie, mask)

% return the trace within the mask
[m,n,p] = size(movie);
if nargin<2
    mask = ones(m,n);
end

movie2 = bsxfun(@times, movie, mask);

trace = zeros(p,1);
parfor i=1:p
    trace(i) = mean(nonzeros(movie2(:,:,i)));
    
end

parfor i=1:p
    deltaF(i) = (trace(i)-trace(1))/trace(1);
end

end