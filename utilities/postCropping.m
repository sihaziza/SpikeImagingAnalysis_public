
function [cropMovie, corn] = postCropping(movie,corn)

[movie_pad]=padarray(movie,[1 1],0,'both');

if nargin<2
    % needs to compute corn
    
    % to get mask with 1 in the overlapping area
    maskNAN = isnan(movie); % detect any nan value
    % maskZERO=~movie; % detect any zero value
    mask3d=maskNAN;%+maskZERO; % intersection of both
    mask2d=min(~mask3d,[],3);
    [AugmentedMask]=padarray(mask2d,[1 1],0,'both');
    % imshow(AugmentedMask,[])
    % imshow(mask2d,[])
    
    % corn = pre_crop_nan(1-mask);
    %registeredimage =  registeredimage(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));
    %fixedframe =  fixed_frame(round(corn(2,1)): round(corn(2,2)), round(corn(1,1)): round(corn(1,3)));
    
    LRout = LargestRectangle(AugmentedMask,1,0,0,0,0);%small rotation angles allowed
    corn = [LRout(2:end,1) LRout(2:end,2)];
    
    % test =  AugmentedMask(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)));
    % mask = ~isnan(test);
    % imshow(mask,[])
end
% Corner as:
% 1st row: x,y of top corner of largest rectangle
% 2sc row: x,y of right corner of largest rectangle
% 3rd row: x,y of bottom corner of largest rectangle
% 4th row: x,y of left corner of largest rectangle
cropMovie =  movie_pad(round(corn(1,2)): round(corn(3,2)), round(corn(1,1)):round(corn(2,1)),:);

end


