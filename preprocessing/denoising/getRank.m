function [ranknum] = getRank(input)
% function to estimate the optimal rank for denoising
% Adapted from LESS denoising, Jizhou Li

[nx, ny, B] = size(input);
Y = reshape(input, nx*ny, B)';

[~,~,V]= svd(Y,'econ');
Vt=V';
rankindx = getRankIndex(Vt);
realindex = find(rankindx==1);
ranknum = numel(realindex);

end