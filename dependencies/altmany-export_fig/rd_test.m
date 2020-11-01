figure(10)
plot(cos(linspace(0, 7, 1000)));
xlabel('x (\mum)')
ylabel('sin(x)')
title('Test export')
set(gcf,'color','w')
% axis square
set(gcf, 'Position', [100 100 400 300]);
set(gca,'FontSize',10)
set(gca,'Fontname','Arial')
set(gca, 'TitleFontSizeMultiplier', 1)
%
xlhand = get(gca,'xlabel');
set(xlhand,'fontsize',10)
set(xlhand,'Fontname','Arial')
ylhand = get(gca,'ylabel');
set(ylhand,'fontsize',10)
set(ylhand,'Fontname','Arial')
    
% saveas(gcf, 'test.png');
name='rc_test';
export_fig(name,'-pdf','-jpg')