function [traceX, traceY] =getTraces(beforeROI, afterROI, roiPosition)

if ~isempty(roiPosition)
beforeROI = beforeROI(roiPosition(2):roiPosition(2)+roiPosition(4)-1,roiPosition(1):roiPosition(1)+roiPosition(3)-1,:);
afterROI = afterROI(roiPosition(2):roiPosition(2)+roiPosition(4)-1,roiPosition(1):roiPosition(1)+roiPosition(3)-1,:);
end

funReshape = @(x) reshape(double(x),[],size(beforeROI,3),1);
X = funReshape(beforeROI);
traceX = zscore(mean(X));

Y = funReshape(afterROI);
traceY = zscore(mean(Y));

end