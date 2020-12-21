function [movie_out,E_out, Info] = denoisingLOSS(movie_in, varargin)
% Denoising the movie by learning
%  Two steps are included:
%       1 - decompose the original movie resulting in a clean low-rank
%       layer (L) and residual layer (R);
%       2 - the residual is further modeled as a low-rank matrix
%       factorization problem, R = UV + N
%
%  By removing the noise N, we can reconstruct the true signal by adding different parts L + UV
%
% SYNTAX:
% movie_out = denoisingLOSS(movie_in); % automatically determine the rank
%
% HISTORY
% - 2020-08-14 23:12:60 - created by Jizhou Li (hijizhou@gmail.com)
%
% ISSUES
% #1 -
%
% TODO
% *1 -Options

% addpath('utilities');

options.windowsize = 1000;
options.prereg = 0;
options.postreg = 0;
options.rescale = 0;
options.regMethod = "normcorre"; % matlab OR normcorre
options.useGPU = 0;
options.ranks = 40;
options.lambda = 0.05;
options.tau = 0.05;
options.gridsize = -1;
options.noSpatial = false;

%% VARIABLE CHECK
if nargin>=3
    options = getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
end


prereg = options.prereg;
postreg = options.postreg;
rescale = options.rescale;
regMethod = options.regMethod; % matlab OR normcorre

[nx, ny, nz] = size(movie_in);
windowsize = min(nz, options.windowsize);

if options.gridsize<0
    gridsizeX = nx;
    gridsizeY = ny;
else
    gridsizeX = min([nx,ny,options.gridsize]);
    gridsizeY = gridsizeX;
end

startno = [1:windowsize:nz];
startgridX = [1:gridsizeX:nx];
startgridY = [1:gridsizeY:ny];

movie_out = zeros(size(movie_in));
% E_out = zeros(size(movie_in));
E_out = [];

if prereg
    if regMethod=="normcorre"
        template = movie_in(:,:,end);
        normcorre_options = NoRMCorreSetParms('d1',nx,'d2',ny,...
            'max_shift',5,'us_fac',20,'correct_bidir',false,'upd_template',false);
        disp(['=== Motion correction before denoising...']);
        [movie_in,~,~,~] = normcorre_batch(movie_in,normcorre_options, template);
        
    end
    
    if regMethod=="matlab"
        template = mean(movie_in,3);
        parfor i=1:nz
            movie_in(:,:,i) = registerImages(movie_in(:,:,i),template);
        end
    end
    
end

tic;

%% split the original movie into small movies
w = 0;
for k = 1:numel(startgridX)
    for j = 1:numel(startgridY)
        for i=1:numel(startno)
            w = w+1;
            disp(['=== splitting [' num2str(k) ' / ' num2str(numel(startgridX)) 'th] [' num2str(j) ' / ' num2str(numel(startgridY)) 'th] [' num2str(i) ' / ' num2str(numel(startno)) 'th] submovie...']);
             positionX = [startgridX(k):min(startgridX(k)+gridsizeX-1,nx)];
            positionY = [startgridY(j):min(startgridY(j)+gridsizeY-1,ny)];
            positionZ = [startno(i):min(startno(i)+windowsize-1,nz)];
            movie= movie_in(positionX,positionY, positionZ);
            
            movieCollection{w} = movie;
            
        end
    end
end
disp(['in total: ' num2str(w) ' submovies']);
           
Output = cell(w,1);
% E_out = cell(w);

parfor wi = 1:w
    disp(['=== processing [' num2str(wi) ' / ' num2str(w) ' th] submovie...']);
           
    [output, ~, info] = LOSSDenoising(movieCollection{wi},'options',options);
    
    Output{wi} = output;
%     E_out{wi} = E;
    
    Info{wi} = info;
end

% reorganizing
 
w = 1;
for k = 1:numel(startgridX)
    for j = 1:numel(startgridY)
        for i=1:numel(startno)
            positionX = [startgridX(k):min(startgridX(k)+gridsizeX-1,nx)];
            positionY = [startgridY(j):min(startgridY(j)+gridsizeY-1,ny)];
            positionZ = [startno(i):min(startno(i)+windowsize-1,nz)];
            movie_out(positionX,positionY, positionZ) = Output{w};
            w = w+1;
        end
    end
end


if postreg
    disp(['=== begin registration...']);
     if regMethod=="normcorre"
        template = movie_out(:,:,end);
        normcorre_options = NoRMCorreSetParms('d1',nx,'d2',ny,...
            'max_shift',5,'us_fac',20,'correct_bidir',false,'upd_template',false);
        disp(['=== Motion correction before denoising...']);
        [movie_out,~,~,~] = normcorre_batch(movie_out,normcorre_options, template);
        
    end
    
    if regMethod=="matlab"
        template = movie_out(:,:,end);
        parfor i=1:nz
            movie_out(:,:,i) = registerImages(movie_out(:,:,i),template);
        end
    end
end

if rescale
    movie_out = aux_imscale(movie_out, [min(movie_in(:)) max(movie_in(:))]);
end

time_whole = toc;
disp(['Finished all, running time: ' num2str(time_whole) ' sec']);

end


