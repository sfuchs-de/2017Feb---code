% =========================================================================
% WRAPPER FOR ESTIMATION ROUTINE FOR TASTE SPACE
%
% INPUT:
%         
% OUTPUT:
%         Results, structure
%         
% USES:   
%
% =========================================================================
%% PRELIMS
clear all; clc;
cd('/Users/Lucks/Desktop/movie_project-master')
addpath('/Users/Lucks/Desktop/movie_project-master/functions/');

%% IMPORT DATA
load 'tempdata/simulatedData.mat'
Model.n= Setup.n;    % individuals per market
Model.nmarket = Setup.nmarket;
Model.nmovies = Setup.nmovies; 
Model.ntaste = Setup.ntaste; % dimension of taste space
n=Model.n;
nmarket=Model.nmarket;
nmovies=Model.nmovies;
ntaste=Model.ntaste;


Model.X_j=Setup.X_j; % Import movie data
Model.market_share=market_share;
% star to save the "true" values
betaparStar = Setup.betapar;
gammaparStar = Setup.gammapar;
zeta_jStar = Setup.zeta_j;
muStar = Setup.mu;
sigmaStar = Setup.sigma;
c_jStar = Setup.c_j;

%% CONFIGURATION 
Model.MaxIter=15000;                 % Optimizaiton Max Iterations
Model.MaxFunEvals=100000;             % Optimizaiton Max function evaluations
Model.TolFun=1e-14;                   % Optimizaiton Function step stopping crit
Model.TolX=1e-14;                     % Optimizaiton Control step stopping crit

% Setting up automatic differentiation

numparam=ntaste+nmovies*ntaste+2*nmarket*ntaste+3+nmovies;
setup.order = 1;
setup.numvar = numparam;
setup.objective  = 'GMMobjective';
setup.constraint = 'GMMconstraint';
setup.auxdata = Model;
adifuncs = adigatorGenFiles4Fmincon(setup);
Model.adifuncs=adifuncs;

%% INITIALIZATION

% initial guess
% ntaste gammaparams, nmovies*ntaste movie locations, nmarket*ntaste*2
% parameters for market specific consumer locations, 3 beta parameters
numparam=ntaste+nmovies*ntaste+2*nmarket*ntaste+3+nmovies;
moments=nmovies*nmarket;
dof=moments-numparam;
InitialParams=zeros(numparam,1);
lb=zeros(numparam,1);
ub=zeros(numparam,1);
start_pos=1;
end_pos=ntaste;
for i=start_pos:end_pos,
    InitialParams(i)=-rand(1); %Gamma guess
end
start_pos=end_pos+1;
end_pos=start_pos+nmovies*ntaste-1;
for i=start_pos:end_pos,
    InitialParams(i)=rand(1); %Movie location guess
end
start_pos=end_pos+1;
end_pos=start_pos+nmarket*ntaste-1;
for i=start_pos:end_pos,
    InitialParams(i)=rand(1); %Market specific consumer guess mean
end
start_pos=end_pos+1;
end_pos=start_pos+nmarket*ntaste-1;
for i=start_pos:end_pos,
    InitialParams(i)=rand(1); %Market specific consumer guess sigma
end
start_pos=end_pos+1;
end_pos=start_pos+3-1;
for i=start_pos:end_pos,
    InitialParams(i)=rand(1); %Beta Params 
end
start_pos=end_pos+1;
end_pos=start_pos+nmovies-1;
for i=start_pos:end_pos,
    InitialParams(i)=rand(1); %Unobservables Movie
end
for i=1:end_pos,
    lb(i)=0;
end
for i=1:end_pos,
    ub(i)=inf;
end


% Load automatic differentiation and set options
adifuncs=Model.adifuncs;
options = optimset('Algorithm','sqp');
options = optimset(options,'GradObj','on','GradConstr','on','Display','iter');
options = optimset(options,'MaxIter', Model.MaxIter, 'MaxFunEvals', Model.MaxFunEvals);
options = optimset(options,'Display', Model.MatlabDisp, 'TolFun', Model.TolFun, 'TolX', Model.TolX,'UseParallel',true);

%% GMM Step 1: Identity weighting matrix
[Params, Fval, Exitflag] = fmincon(adifuncs.objgrd,InitialParams,[],[],[],[],lb,ub,...
    adifuncs.congrd,options);


% optimization settings
options = optimset('Display','iter');
options = optimset(options,'MaxIter', Model.MaxIter, 'MaxFunEvals', Model.MaxFunEvals);
options = optimset(options,'TolFun', Model.TolFun, 'TolX', Model.TolX);
%options = optimoptions(@lsqnonlin,'Algorithm','trust-region-reflective','Display','iter');
%x = lsqnonlin(fun,x0,[],[],options)
%optimization
%[x,fval,exitflag,output,grad] = fminunc(@(Params)GMMobjective(Params, Model),InitialParams,options);

[Params, Fval, Exitflag] =  lsqnonlin(@(Params)GMMobjective(Params, Model),InitialParams,lb,ub,options);