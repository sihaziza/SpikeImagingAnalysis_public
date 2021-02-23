function trace=getPointProjection(movie)
% perform point projection of a movie and return the time trace
% trace=pointProjection(movie)
dim=size(movie);
temp=reshape(movie,dim(1)*dim(2),dim(3));
trace=mean(temp,1);
trace=trace'; % to be a row vector
end