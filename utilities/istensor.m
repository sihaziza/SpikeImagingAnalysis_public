function [out]=istensor(M)
%   ISTENSOR True if input is a 3D array.
%   ISTENSOR(M) returns logical 1 (true) if M is a 1-by-n or n-by-1 vector,
%   and logical 0 (false) otherwise.
%
%   See also ISSCALAR, ISROW, ISCOLUMN, ISMATRIX, ISNUMERIC, ISLOGICAL,
%            ISCHAR, ISEMPTY, SIZE.

%   2020-06-01: created by Simon Haziza (sihaziza@stnaford.edu)

if numel(size(M))==3
    out=true;
else
    out=false;
end

end