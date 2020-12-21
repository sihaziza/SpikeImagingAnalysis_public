filename='m83_d201124_s08dualColorSlidePulsingLEDs-fps781-cR_moco_artefacts_1osc.h5';
path='F:\GEVI_Spike\Preprocessed\Whiskers\m83\20201124\meas08';

data=h5read(fullfile(path, filename),'/mov');
h5info(fullfile(path, filename))
plot(squeeze(mean(data,[1 2])));

movFilt=bpFilter2D(data,20,2,'parallel',false);

%%
fixed1=movFilt(:,:,1);
fixed2=movFilt(:,:,50);

moving1=movFilt(:,:,120);
moving2=movFilt(:,:,134);

imshowpair(fixed,moving1);
imshowpair(moving1,moving2);

nFrame=size(data,3);
FIXED=movFilt(:,:,1);
% Default spatial referencing objects
fixedRefObj = imref2d(size(FIXED));
parfor iFrame=1:nFrame
    MOVING=movFilt(:,:,iFrame);
    movingRefObj = imref2d(size(MOVING));
    [output] = registerImagesSurfNonRigid_v3(MOVING,FIXED);
    tempMovReg(:,:,iFrame)=output.RegisteredImage;
    movReg(:,:,iFrame) = imwarp(data(:,:,iFrame), movingRefObj, output.Transformation, 'OutputView', fixedRefObj, 'SmoothEdges', true);
end

%%
d=size(data);
% % grid=round(min(d(1),d(2))/10);
%     'grid_size          ' % size of non-overlapping regions (default: [d1,d2,d3])
%     'overlap_pre        ' % size of overlapping region (default: [32,32,16])
%     'min_patch_size     ' % minimum size of patch (default: [32,32,16])    
%     'min_diff           ' % minimum difference between patches (default: [16,16,5])
% 
%%
d=size(movie_dns);

normcorre_options = NoRMCorreSetParms('d1',d(1),'d2',d(2),...
    'grid_size',[20,20,1],'overlap_pre',[10,10,1],'min_patch_size',[10,10,1],'min_diff',[5,5,1],... 
    'max_shift',50,...
    'us_fac',20,'correct_bidir',false,'upd_template',false,'boundary','nan','shifts_method','fft');

template=movie_dns(:,:,1);

    [~,normcorre_shifts] = normcorre_batch(movie_dns,normcorre_options,template);
    disp('done')
    mov_corrected = apply_shifts_normcorre(movie_dns,normcorre_shifts,normcorre_options);
        disp('done')

    [movMoco, ~] = postcropping(mov_corrected);
    disp('done')
    %%
  [info] = h5save(fullfile(path, 'm83_d201124_s08dualColorSlidePulsingLEDs-fps781-cR_moco_artefacts_1osc_moco_dns-40Rank-0.02regul_moco.h5'),bpFilter2D(movMoco,max(size(movMoco)),1),'mov');
  
  [movie_dns]=denoising1Movie(fullfile(path, 'm83_d201124_s08dualColorSlidePulsingLEDs-fps781-cR_moco_artefacts_1osc_moco.h5'));

cond=@(x) squeeze(mean(x,[1 2]))-mean(squeeze(mean(x,[1 2])));

[~,rect]=imcrop(mat2gray(movMoco(:,:,1)));
A=[];B=[];
parfor iFrame=1:nFrame
A(:,:,iFrame)=imcrop(data(:,:,iFrame),rect);
B(:,:,iFrame)=imcrop(movMoco(:,:,iFrame),rect);
end
A=bpFilter2D(A,min(size(A)),1);
B=bpFilter2D(B,min(size(B)),1);

% implay(mat2gray([data mov_corrected]))
implay(mat2gray([A B]))
% imshowpair(data(:,:,1),movMoco(:,:,1))
figure(2)
plot(cond(A));
hold on
plot(cond(B));
hold off
% conclusion: fft does not bring more noise here strangely enough.
% grid_size allow a better non-rigid correction. but oscillation artefact
% is still present
% minimal low-pass filtering to remove DC component removes the oscillation
% try denoising?