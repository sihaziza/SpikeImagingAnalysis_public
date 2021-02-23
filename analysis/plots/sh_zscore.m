function [output]=sh_zscore(input,varargin)

% Check number of parameters
if (nargin > 3) || (mod(length(varargin),2) ~= 0)
    error('Incorrect number of parameters');
end

% Compute normalization on the specified range
if nargin>1
    switch varargin{1}
        case 'range'
            range= varargin{2};
            if ~isvector(range)
                error('Incorrect value for property ''range''');
            end
            m=median(input(range,:));
            s=std(input(range,:));
    end
else
    m=median(input);
    s=std(input);
end

output=(input-m)./s;

end