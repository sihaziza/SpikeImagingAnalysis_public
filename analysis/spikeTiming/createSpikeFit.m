function [fitresult, gof] = createSpikeFit(tsFit, toFit)
%CREATEFIT(TSFIT,TOFIT)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input : tsFit
%      Y Output: toFit
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  Auto-generated by MATLAB on 11-Apr-2021 18:47:45


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( tsFit, toFit );

% Set up fittype and options.
ft = fittype( 'exp2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Algorithm = 'Levenberg-Marquardt';
opts.Display = 'Off';
opts.Normalize = 'on';
opts.StartPoint = [0.00154513666019912 -1.65661707978161 -0.000192302327495417 -1.06506030822785];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% % Plot fit with data.
% figure( 'Name', 'untitled fit 1' );
% h = plot( fitresult, xData, yData );
% legend( h, 'toFit vs. tsFit', 'untitled fit 1', 'Location', 'NorthEast', 'Interpreter', 'none' );
% % Label axes
% xlabel( 'tsFit', 'Interpreter', 'none' );
% ylabel( 'toFit', 'Interpreter', 'none' );
% grid on


