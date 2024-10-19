%DEMO_BARBELL_2
%
% Define a polygonal "barbell" shaped domain with 
% prescribed constant boundary data on each edge. 
% Solves the corresponding Helmholtz Dirichlet problem
% using corner rounding and smoothing the boundary data 
% across the rounded corners
%

% profile clear
% profile on

clearvars; close all;
iseed = 8675309;
rng(iseed,'twister');
addpaths_loc();

% planewave vec

kvec = 10*[1;-1.5];

%

zk = norm(kvec);

% define geometry and boundary conditions
% (vertices defined by another function)
verts = chnk.demo.barbell(2.0,2.0,1.0,1.0);
nv = size(verts,2);
edgevals = randn(1,nv);

% parameters for curve rounding/chunking routine to oversample boundary
cparams = [];
cparams.widths = 0.1*ones(size(verts,2),1);% width to cut about each corner
cparams.eps = 1e-12; % tolerance at which to resolve curve
cparams.rounded = true;

% call smoothed-polygon chunking routine
% a smoothed version of edgevals is returned in 
% chnkr.data
chnkr = chunkerpoly(verts,cparams,[],edgevals);
chnkr = refine(chnkr,struct('nover',1));
%
% plot smoothed geometry and data

figure(1)
clf
plot(chnkr,'-x')
hold on
quiver(chnkr)
axis equal

figure(2)
clf
nchplot = 1:chnkr.nch;
plot3(chnkr,1)

% solve and visualize the solution

% build laplace dirichlet matrix

% fkern = kernel('laplace','d');
fkern = kernel('helmholtz','c',zk,[1.5,-2i]);
opts = [];
start = tic; C = chunkermat(chnkr,fkern,opts);
t1 = toc(start);

fprintf('%5.2e s : time to assemble matrix\n',t1)

%

sys = -0.5*eye(chnkr.npt) + C;

% rhs = chnkr.data(1,:); rhs = rhs(:);
rhs = besselh(0,zk*abs((1+1.25*1i)-(chnkr.r(1,:)+1i*chnkr.r(2,:)))); rhs = rhs(:);
start = tic; sol = gmres(sys,rhs,[],1e-14,100); t1 = toc(start);

fprintf('%5.2e s : time for dense gmres\n',t1)

% evaluate at targets and plot

rmin = min(chnkr); rmax = max(chnkr);
nplot = 300;
hx = (rmax(1)-rmin(1))/nplot;
hy = (rmax(2)-rmin(2))/nplot;
xtarg = linspace(rmin(1)+hx/2,rmax(1)-hx/2,nplot); 
ytarg = linspace(rmin(2)+hy/2,rmax(2)-hy/2,nplot);
[xxtarg,yytarg] = meshgrid(xtarg,ytarg);
targets = zeros(2,length(xxtarg(:)));
targets(1,:) = xxtarg(:); targets(2,:) = yytarg(:);

start = tic; in = chunkerinterior(chnkr,targets); t1 = toc(start);
fprintf('%5.2e s : time to find points in domain\n',t1)

% compute layer potential at interior points
opts.forcepquad = true; 
opts.side = 'i'; % 'i' for interior, 'e' for exterior, for positively oriented curve.
start = tic;
Csolpquad = chunkerkerneval(chnkr,fkern,sol,targets(:,in),opts); 
% below check slp and dlp
% fkernd = kernel('helmholtz','d',zk);
% fkerns = kernel('helmholtz','s',zk);
% Ssolpquad = chunkerkerneval(chnkr,fkerns,sol,targets(:,in),opts); 
% Dsolpquad = chunkerkerneval(chnkr,fkernd,sol,targets(:,in),opts); 
% Csolpquad = Dsolpquad + (-zk*1i)*Ssolpquad;
t1 = toc(start);
fprintf('%5.2e s : time for kerneval (Helsing-Ojala for near)\n',t1);

start = tic;
Csol = chunkerkerneval(chnkr,fkern,sol,targets(:,in)); t1 = toc(start);
fprintf('%5.2e s : time for kerneval (adaptive for near)\n',t1);

% Compare with reference solution Dsol
error = max(abs(Csol-Csolpquad))/max(abs(Csol));
fprintf('%5.2e : Relative max error\n',error);
% 

assert(error < 1e-10)
% profile viewer