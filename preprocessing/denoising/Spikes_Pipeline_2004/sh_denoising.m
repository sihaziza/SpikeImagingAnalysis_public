function movie_in = sh_denoising(movie_in, options)

% update the movie in place to save the memory

windowsize = options.windowsize;

[m,n,p]=size(movie_in);
startno = 1:windowsize:p;
tau = 0.015; % why?
lambda =20/sqrt(m*n); % why?
rank = 10; % why jsut the 10 first components?

tic;
for i=1:numel(startno)
    disp(['processing ' num2str(i) ' th submovie...']);
    %non-overlap
    movie= movie_in(:,:,startno(i):min(startno(i)+windowsize-1,p));
    
    [ output] = PMF(movie, tau,lambda, rank);
    
    %output=aux_imscale(output,[min(meanI(:)) max(meanI(:))]);
    
    movie_in(:,:,startno(i):min(startno(i)+windowsize-1,p))=output;
end

toc

end

function [output_movie] = PMF(movie, tau,lambda, r)
% tau is a Regularization parameter
% lambda is a threshold cutoff parameters (?)
% r: number of singular values to consider
[M, N, P] = size(movie);
D = zeros(M*N,P);
% from 3D to 2D = Space x  Time
parfor i=1:P
    bandp  = movie(:,:,i);
    D(:,i) = bandp(:);
end
[d, P] = size(D);
d_norm = norm(D, 'fro');
% initialize
% b_norm = norm(D, 'fro');
tol = 1e-6;
tol1 = tol;
tol2 = tol1;
maxIter = 100;

rho = 1.5;
max_mu1 = 1e6;
mu1 = 1e-2;
mu2  = mu1;

sv =100;
%% Initializing optimization variables
% intialize
% L = zeros(d,p);
% X = zeros(d,p);
% TM = zeros(d,p);
% X >  random initialization
X = rand(d,P);
E = sparse(d,P); % save memory to not store zeros

Y1 = zeros(d,P);
Y2 = zeros(d,P);

% for the TV norm (Total Variation)
param2.max_iter=20;
param2.verbose = 0;
% g1.prox=@(x, T) prox_TV(x, T*mu1/(2*tau), param2);
% g1.norm=@(x) tau*TV_norm(x);

% main loop
iter = 0;
while iter<maxIter
    iter = iter + 1;
    %%%%%%%%%%%%
    % Update L %
    %%%%%%%%%%%%
    % what is that? 
    % X: random 2d
    % D: raw movie in 2D > SxT
    % E: sparse 2d
    temp = (mu1*X +mu2* (D-E) + (Y1+Y2))/(mu1+mu2);
    % mu1=mu2:   temp=0.5*(X + (D-E) + (Y1+Y2)/mu1);
% more efficient. Compute only the sv's largest SV
     [U, sigma, V] = lansvd(temp, sv, 'L'); % use this one by default
    sigma = diag(sigma);
    svp = min(length(find(sigma>1/(mu1+mu2))),r);
    if svp<sv
        sv = min(svp + 1, P);
    else
        sv = min(svp + round(0.05*P), P);        
    end
    % L is a low-rank matrix of the residual
    L = U(:, 1:svp) * diag(sigma(1:svp) - 1/(mu1+mu2)) * V(:, 1:svp)';
    
    %%%%%%%%%%%%
    % Update X %
    %%%%%%%%%%%%
    temp = L - Y1/mu1;
%     X = L;
    
    param2.maxit = param2.max_iter;
    param2.useGPU = 1;
        
    parfor i =1:P
        z = prox_tv(reshape(temp(:,i),[M,N]),2*tau/mu1,param2);
        X(:,i) = z(:);
    end
    
    %%%%%%%%%%%%
    % Update E %
    %%%%%%%%%%%%
    temp_E = D - (L - Y2/mu2);
    E_hat = max(temp_E - lambda/mu2, 0);
    E = E_hat+min(temp_E + lambda/mu2, 0);
    
    leq1 = X - L; % output of proxTV versus input > residual?
    leq2 = D -L -E ;
    %% stop criterion
    %     stopC = max(max(max(abs(leq1))),max(max(abs(leq2))));
    
    stopC1 = max(max(abs(leq1)));
    stopC2 = norm(leq2, 'fro') / d_norm;
    disp(['iter ' num2str(iter) ',stopALM=' num2str(stopC2,'%2.3e')...
        ',stopE=' num2str(stopC1,'%2.3e')]);
    
    if stopC1<tol  && stopC2<tol2
        break;
    else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Update Y1, Y2, mu1 & mu2 %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        Y1 = Y1 + mu1*leq1;
        Y2 = Y2 + mu2*leq2;
        mu1 = min(max_mu1,mu1*rho); % why 1e6 vs 1.5*1e-2? kick mu up?
        mu2 = min(max_mu1,mu2*rho);
    end
end
output_movie = reshape(L,[M,N,P]);
end

