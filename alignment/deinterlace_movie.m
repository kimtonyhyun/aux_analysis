function [Md, M1, M2] = deinterlace_movie(M)
% Rearrange the movie so that the even and odd lines (in the first
% dimension of the movie M) are grouped together.

M1 = M(1:2:end,:,:);
M2 = M(2:2:end,:,:);
Md = cat(1, M1, M2);