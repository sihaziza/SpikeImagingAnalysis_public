function [output] = DecompNMF_ALS(V, num)
if nargin<2
    num = 6;
end
[mx, my, ~] = size(V);
%%
funReshape = @(x) reshape(double(x),[],size(x,3),1);
V2d = funReshape(V);

options = [];
disp('Starting nnSVD')
[x_init.W, x_init.H] = NNDSVD(abs(V2d), num, 0);
options.x_init = x_init;
options.verbose = 2;
options.alg = 'hals';

disp('Starting ALS')
[w_nmf_hals, infos_nmf_hals] = nmf_als(V2d, num, options);

disp('Reassigning Spatial & Temporal')
for i=1:num
    spatial(:,:,i) = reshape(w_nmf_hals.W(:,i), mx, my); 
    temporal(:,i) = w_nmf_hals.H(i,:);
end

output.spatial=spatial;
output.temporal=temporal;
output.infos_nmf_hals=infos_nmf_hals;
end