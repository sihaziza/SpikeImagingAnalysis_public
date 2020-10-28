function imgt = imscale(img, range)
% IMSCALE  Scale an image to fit the range
%
%  This function scales the values of an image to fit the range.
%
%  Params:
%
% img   = The image.
% range  = The min target value. (def=[0,1])
%
% imgt  = The image scaled.

% Check params:
if nargin<2
    range=[0,1];
end

% Transform the image type:
imgt = double(img);

% Obtain and appling the offset:
imgt = imgt-min(min(min(imgt)));

% Obtain and appling the scale:
scale = max(max(max(imgt)));
if scale>0
    imgt = imgt/scale;
end

% Generate the required image:
if not(abs(range(2)-range(1))==1)
    imgt = imgt*abs(range(2)-range(1));
end
if not(range(1)==0)
    imgt = imgt+range(1);
end