function [MOVINGREG] = registerImagesSurfNonRigid_v2(MOVING,FIXED)
%registerImages  Register grayscale images using auto-generated code from Registration Estimator app.
%  [MOVINGREG] = registerImages(MOVING,FIXED) Register grayscale images
%  MOVING and FIXED using auto-generated code from the Registration
%  Estimator app. The values for all registration parameters were set
%  interactively in the app and result in the registered image stored in the
%  structure array MOVINGREG.

% Auto-generated by registrationEstimator app on 04-Dec-2020
%-----------------------------------------------------------


% Feature-based techniques require license to Computer Vision Toolbox
checkLicense()

% Normalize FIXED image

% Get linear indices to finite valued data
finiteIdx = isfinite(FIXED(:));

% Replace NaN values with 0
FIXED(isnan(FIXED)) = 0;

% Replace Inf values with 1
FIXED(FIXED==Inf) = 1;

% Replace -Inf values with 0
FIXED(FIXED==-Inf) = 0;

% Normalize input data to range in [0,1].
FIXEDmin = min(FIXED(:));
FIXEDmax = max(FIXED(:));
if isequal(FIXEDmax,FIXEDmin)
    FIXED = 0*FIXED;
else
    FIXED(finiteIdx) = (FIXED(finiteIdx) - FIXEDmin) ./ (FIXEDmax - FIXEDmin);
end

% Normalize MOVING image

% Get linear indices to finite valued data
finiteIdx = isfinite(MOVING(:));

% Replace NaN values with 0
MOVING(isnan(MOVING)) = 0;

% Replace Inf values with 1
MOVING(MOVING==Inf) = 1;

% Replace -Inf values with 0
MOVING(MOVING==-Inf) = 0;

% Normalize input data to range in [0,1].
MOVINGmin = min(MOVING(:));
MOVINGmax = max(MOVING(:));
if isequal(MOVINGmax,MOVINGmin)
    MOVING = 0*MOVING;
else
    MOVING(finiteIdx) = (MOVING(finiteIdx) - MOVINGmin) ./ (MOVINGmax - MOVINGmin);
end

% Default spatial referencing objects
fixedRefObj = imref2d(size(FIXED));
movingRefObj = imref2d(size(MOVING));

% Detect SURF features
fixedPoints = detectSURFFeatures(FIXED,'MetricThreshold',515.625000,'NumOctaves',4,'NumScaleLevels',6);
movingPoints = detectSURFFeatures(MOVING,'MetricThreshold',515.625000,'NumOctaves',4,'NumScaleLevels',6);

% Extract features
[fixedFeatures,fixedValidPoints] = extractFeatures(FIXED,fixedPoints,'Upright',true);
[movingFeatures,movingValidPoints] = extractFeatures(MOVING,movingPoints,'Upright',true);

% Match features
indexPairs = matchFeatures(fixedFeatures,movingFeatures,'MatchThreshold',50.000000,'MaxRatio',0.500000);
fixedMatchedPoints = fixedValidPoints(indexPairs(:,1));
movingMatchedPoints = movingValidPoints(indexPairs(:,2));
MOVINGREG.FixedMatchedFeatures = fixedMatchedPoints;
MOVINGREG.MovingMatchedFeatures = movingMatchedPoints;

% Apply transformation - Results may not be identical between runs because of the randomized nature of the algorithm
tform = estimateGeometricTransform(movingMatchedPoints,fixedMatchedPoints,'affine');
MOVINGREG.Transformation = tform;
MOVINGREG.RegisteredImage = imwarp(MOVING, movingRefObj, tform, 'OutputView', fixedRefObj, 'SmoothEdges', true);

% Nonrigid registration
[MOVINGREG.DisplacementField,MOVINGREG.RegisteredImage] = imregdemons(MOVINGREG.RegisteredImage,FIXED,100,'AccumulatedFieldSmoothing',1.0,'PyramidLevels',3);

% Store spatial referencing object
MOVINGREG.SpatialRefObj = fixedRefObj;

end

function checkLicense()

% Check for license to Computer Vision Toolbox
CVSTStatus = license('test','Video_and_Image_Blockset');
if ~CVSTStatus
    error(message('images:imageRegistration:CVSTRequired'));
end

end

