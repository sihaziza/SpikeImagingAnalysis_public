function sol = prox_tv(b, gamma, param)
% Start the time counter
if ~isfield(param, 'tol'), param.tol = 10e-4; end
if ~isfield(param, 'verbose'), param.verbose = 0; end
if ~isfield(param, 'maxit'), param.maxit = 50; end
if ~isfield(param, 'weights'), param.weights = [1, 1]; end

[r, s] = gradient_op(b*0);
pold = r; qold = s;
told = 1; prev_obj = 0;
tol=param.tol;

wx = param.weights(1);
wy = param.weights(2);
mt = max(param.weights);

for iter = 1:param.maxit
    
    % Current solution
    sol = b - gamma*div_op(r, s, wx, wy);
    
    % Objective function value
    tmp = gamma * sum(norm_tv(sol, wx, wy));
    obj = .5*norm(b(:)-sol(:), 2)^2 + tmp;
    rel_obj = abs(obj-prev_obj)/obj;
    prev_obj = obj;
    
    if rel_obj < tol
        crit = 'TOL_EPS'; break;
    end
    
    % Udpate divergence vectors and project
    [dx, dy] = gradient_op(sol, wx, wy);
    
    r = r - 1/(8*gamma)/mt^2 * dx;
    s = s - 1/(8*gamma)/mt^2 * dy;
    
    weights = max(1, sqrt(abs(r).^2+abs(s).^2));
    
    p = r./weights;
    q = s./weights;
    
    % FISTA update
    t = (1+sqrt(4*told.^2))/2;
    r = p + (told-1)/t * (p - pold); pold = p;
    s = q + (told-1)/t * (q - qold); qold = q;
    told = t;
    
end

end

function I = div_op(dx, dy, wx, wy)
%DIV_OP Divergence operator in 2 dimensions
%   Usage:  I = div_op(dx, dy)
%           I = div_op(dx, dy, wx, wy)
%
%   Input parameters:
%         dx    : Gradient along x
%         dy    : Gradient along y
%         wx    : Weights along x
%         wy    : Weights along y
%
%   Output parameters:
%         I     : Output divergence image
%
%   Compute the 2-dimensional divergence of an image. If a cube is given,
%   it will compute the divergence of all images in the cube.
%
%   Warning: computes the divergence operator defined as minus the adjoint
%   of the gradient
%
%   ..      div  = - grad'
%
%   .. math:: \text{div} = - \nabla^*
%
%   See also: gradient_op div_op3d div_op1d laplacian_op prox_tv

% Author: Nathanael Perraudin
% Date:   1 February 2014

if nargin > 2
    dx = dx .* conj(wx);
    dy = dy .* conj(wy);
end

I = [dx(1, :,:) ; ...
    dx(2:end-1, :,:)-dx(1:end-2, :,:) ;...
    -dx(end-1, :,:)];
I = I + [dy(:, 1,:) ,...
    dy(:, 2:end-1,:)-dy(:, 1:end-2,:) ,...
    -dy(:, end-1,:)];

end

function y = norm_tv(I,wx,wy)
%NORM_TV 2 Dimentional TV norm
%   Usage:  y = norm_tv(x);
%           y = norm_tv(I,wx,wy);
%
%   Input parameters:
%         I     : Input data
%         wx    : Weights along x
%         wy    : Weights along y
%   Output parameters:
%         y     : Norm
%
%   Compute the 2-dimentional TV norm of I. If the input I is a cube. This
%   function will compute the norm of all image and return a vector of
%   norms.
%
%   See also: norm_tv3d norm_tvnd

% Author: Nathanael Perraudin
% Date:   1 February 2014

if nargin>1
    [dx, dy] = gradient_op(I,wx, wy);
else
    [dx, dy] = gradient_op(I);
end
temp = sqrt(abs(dx).^2 + abs(dy).^2);

%y = sum(temp(:));
y = reshape(sum(sum(temp,1),2),[],1);

end

function [dx, dy] = gradient_op(I, wx, wy)
%GRADIENT_OP 2 Dimensional gradient operator
%   Usage:  [dx, dy] = gradient_op(I)
%           [dx, dy] = gradient_op(I, wx, wy)
%
%   Input parameters:
%         I     : Input data
%         wx    : Weights along x
%         wy    : Weights along y
%
%   Output parameters:
%         dx    : Gradient along x
%         dy    : Gradient along y
%
%   Compute the 2-dimensional gradient of I. If the input I is a cube. This
%   function will compute the gradient of all image and return two cubes.
%
%   See also: gradient_op3d gradient_op1d div_op laplacian_op

% Author: Nathanael Perraudin
% Date:   1 February 2014

dx = [I(2:end, :,:)-I(1:end-1, :,:) ; zeros(1, size(I, 2),size(I, 3))];
dy = [I(:, 2:end,:)-I(:, 1:end-1,:) , zeros(size(I, 1), 1,size(I, 3))];

if nargin>1
    dx = dx .* wx;
    dy = dy .* wy;
end

end



