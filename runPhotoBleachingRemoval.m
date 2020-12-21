function [dataCorr]=runPhotoBleachingRemoval(data)

% data is 3d matrix - fit each pixel with 2 term exponential and output the
% residual 

d=size(data);
temp=reshape(data,d(1)*d(2),d(3));
tempCorr=zeros(size(temp));

tic;
parfor iPixel=1:d(1)*d(2)
[~, ~,outputExp] = createFitExp(temp(iPixel,:));
tempCorr(iPixel,:)=outputExp.residuals;
end
toc;

dataCorr=reshape(tempCorr,d(1),d(2),d(3));

end
