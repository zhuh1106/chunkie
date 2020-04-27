function nrm = normal2d(ptinfo)
%CHNKR.NORMAL2D normal vector to curve for 2D curves
% 
% Syntax: nrm = chnkr.normal2d(ptinfo)
%
% Input:
%   ptinfo - curve point info struct, with entries
%       ptinfo.r - positions (2,:) array
%       ptinfo.d - first derivative in underlying parameterization (2,:)
%       ptinfo.d2 - second derivative in underlying parameterization (2,:)
%
% Output:
%   nrm - (2,:) array containing corresponding normal information
%
% see also CHNKR.CURVATURE2D

d = ptinfo.d;
dnrm = sqrt(sum(d.^2,1));
nrm = bsxfun(@rdivide,[d(2,:);-d(1,:)],dnrm);