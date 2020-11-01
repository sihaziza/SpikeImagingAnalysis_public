function play(movie,varargin)
% EXAMPLE USE WITH ARGUMENTS
%[options]= play(movie) - use 1
%[options]= play(movie,movie2) - use 1
%
% HELP
% Simple player for movies, inspired by 'playMovie' by Biafra.
% Just provide 3D matrix of the movie and terminate by pressing a character 'e'
% speed up or slow down with keyboard characters "+" or "-";
%
% HISTORY
% - 20-05-18 15:13:58 - created by Radek Chrapkiewicz (radekch@stanford.edu)
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


FUNCTION_AUTHOR='Radek Chrapkiewicz (radekch@stanford.edu)';

%% OPTIONS (Biafra style, type 'help getOptions' for details)
options.contact=FUNCTION_AUTHOR;

%% VARIABLE CHECK 
if nargin>=2
    movie2=varargin{1};
else
    movie2=[];
end

% if nargin>=2
% options=getOptions(options,varargin(1:end)); % CHECK IF NUMBER OF THE OPTION ARGUMENT OK!
% end
input_options=options; % saving orginally passed options to output them in the original form for potential next use

%% CORE
%The core of the function should just go here.
keyIn=0;

hF=figure(7);
clf
set(hF,'WindowKeyPressFcn',@KeyPressFcn);
hA=axes;

frame_increment=1;

while 1
    iframe=1;
    while iframe<size(movie,3)
        if isempty(movie2)
            imagesc(hA,movie(:,:,iframe))
        else
            imshowpair(movie(:,:,iframe),movie2(:,:,iframe),'montage')
        end
            axis equal
            axis tight
            axis off
            title(sprintf('Frame %i/%i\n"e" to terminate, "+/-" speed up/slow down',iframe,size(movie,3)),'FontWeight','normal');
%             colorbar
        if strcmpi(keyIn,'e'); break; end
        if strcmpi(keyIn,'add')
            frame_increment=frame_increment+1; 
            frame_increment=min(frame_increment,round(size(movie,3)/10));
        end
        if strcmpi(keyIn,'subtract')
            frame_increment=frame_increment-1;
            frame_increment=max(frame_increment,1);
        end       
        iframe=iframe+frame_increment;
        drawnow
    end
    if strcmpi(keyIn,'e')
        break
    end
end


%% CLOSING
options.input_options=input_options; % passing input options separately so they can be used later to feed back to function input.




	function KeyPressFcn(~,event)
		keyIn = event.Key;
		% drawnow
		% keyIn
	end




end  %%% END PLAY

% 
% function KeyPressFcn(~,evnt)
% fprintf('key event is: %s\n',evnt.Key);
% end
