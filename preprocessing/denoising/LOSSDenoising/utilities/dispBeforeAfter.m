function dispBeforeAfter(before, after, roiPosition)
figure;
[nx, ny, nz] = size(before);

funReshape = @(x) reshape(double(x),[],nz,1);

beforeROI = before(roiPosition(2):roiPosition(2)+roiPosition(4)-1,roiPosition(1):roiPosition(1)+roiPosition(3)-1,:);
X = funReshape(beforeROI);
traceX = mean(X);
afterROI = after(roiPosition(2):roiPosition(2)+roiPosition(4)-1,roiPosition(1):roiPosition(1)+roiPosition(3)-1,:);
Y = funReshape(afterROI);
traceY = mean(Y);

subplot(3,2,[1,2]); plot(traceX);
subplot(3,2,[3,4]); plot(traceY);

for i=1:nz
% title(['Frame ' num2str(i)]);
subplot(3,2,5); imshow(before(:,:,i),[]);
hold on;
rectangle('Position',roiPosition,'EdgeColor','red');
subplot(3,2,6); imshow(after(:,:,i),[]);
hold on;
rectangle('Position',roiPosition,'EdgeColor','red');

drawnow;
end

set(gcf,'color','w');

end
