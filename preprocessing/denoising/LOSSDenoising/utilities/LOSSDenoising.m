function [movie_out, movie_sparse, info] = LOSSDenoising(movie_in, varargin)
% [X, S, Info] = LOSSDenoising(Y, options)
% Video denoising by Learning rObust SubSpace (LOSS)
%
% Syntax:
% movie_out = LOSSDenoising(movie_in); % automatically determine the rank
% movie_out = LOSSDenoising(movie_in, 'options', options); % specify the rank
%
% Model:
%    min ||X||_* + \lambda||S||_2,1 + \tau||X||_TV
%    s.t. ||Y-X-S||_F^2 <= epsilon, and rank(X) <= r
%
% Inputs:
%   - movie_in: Input matrix nx x ny x nz
%   - options:
%       - lambda - regularization parameter for the sparse term
%       - tau - regularization parameter for the TV term
%       - ranks - the maximum rank of X
%
% Outputs:
%   - movie_out: Denoised video nx x ny x nz
%   - movie_sparse: The sparse noise matrix nx x ny x nz
%   - info: statistical info of the run algorithm (if any)
%       info.iters: number of iterations run
%       info.stop: value of the stopping criterion.
%       info.loss: the objective function values w.r.t iterations
%       info.options: all options used
%
% History:
%   - 2020-05-29 23:12:60 - created by Jizhou Li (hijizhou@gmail.com)

%% estimate noise level from the last 100 frames
% noiseVar = estimation_noise_variance(Y(:,end-99:end));

%% parameters
% critical parameters
options.lambda = 0.2;
options.tau = 0.2;
options.ranks = 40; %magic number...

options.useGPU = 0;
options.noSpatial = false;

%% VARIABLE CHECK

if nargin>=3
    options = getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end


[nx,ny,nz] = size(movie_in);

funReshape = @(x) reshape(double(x),[],nz,1);
funReshapeBack = @(x, nt) reshape(x, nx, ny, nt);
Y = funReshape(movie_in);

tol = 1e-6;
maxIter = 20;
beta = 1.5;
rhoMax = 1e6;
rho = 1e-2;
tau = options.tau;
lambda = options.lambda;
ranks = options.ranks;
useGPU = options.useGPU;

Ynorm = norm(Y, 'fro');

X = rand(nx*ny,nz);
A = X;
S = sparse(nx*ny,nz);

L1 = zeros(nx*ny,nz);
L2 = zeros(nx*ny,nz);

iter = 0;

if useGPU
    disps(['Using GPU...']);
    gpuDevice(); % reset GPU
end

if useGPU
    Y = gpuArray(Y);
end

while iter<maxIter
    iter = iter + 1;
    
    disps(['iteration: ' num2str(iter)]);
    % Update X
    temp = 0.5*(Y + A -S + (L1+L2)/rho);
    
    disps(['...updating X']);
    if useGPU
        [U, sigma, V] = svds(temp, ranks);
        X = U * (sigma - 0.5*1./rho) *V';
    else
        %                 [U, sigma, V] = rSVD(temp, ranks, 10);
        %                 X = U * diag(sigma - 0.5*1./rho) *V';
        [U, sigma, V] = svdsecon(temp, ranks);
        X = U * (sigma - 0.5*1./rho) *V';
        
    end
    
    disps(['...updating A']);
    % Updata A
    temp = X - L1/rho;
    A = X;
    
    if options.noSpatial
        A = temp;
    else
        
        %     Temp = funReshapeBack(temp, nz);
        parfor i =1:nz
            imageframe = reshape(temp(:,i),[nx, ny]);
            %         imageframe = Temp(:,:,i);
            
            z = prox_tv(imageframe,tau/rho,[]);
            A(:,i) = z(:);
            %         AA(:,:,i) = z;
        end
        %     A = funReshape(AA);
    end
    
    disps(['...updating S']);
    % updata S
    tempS = Y - X + L2/rho;
    
    columnNorm = vecnorm(tempS);
    selectIndex = columnNorm<lambda/rho;
    S = bsxfun(@times,(columnNorm - lambda/rho)./columnNorm, tempS);
    S(selectIndex) = 0;
    
    
    L1update = Y -X -S ;
    L2update = A - X;
    
    info.loss(iter) = norm(L1update, 'fro');
    %% stop criterion
    if norm(L1update, 'fro') / Ynorm < tol & max(max(abs(L2update)))< tol
        break;
    else
        L1 = L1 + rho*L2update;
        L2 = L2 + rho*L1update;
        rho = min(rhoMax,rho*beta);
    end
    
end

if useGPU
    X = gather(X);
    S = gather(S);
end

info.options = options;
info.iters = iter;
info.stop = max(max(abs(L2update)));

movie_out = funReshapeBack(X, nz);
movie_sparse = funReshapeBack(S, nz);

    function disps(string) %overloading disp for this function
        fprintf('%s: %s\n', datetime('now'),string);
    end

end


