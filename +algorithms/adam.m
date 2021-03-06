function [evals,trainModels] = adam(x,yAll,model,opts,chkptfile)
% adam : adam stochastic gradient descent (ascent)
% Inputs
%    x - function inputs
%    yAll - function outputs
%    model - model of the function between x and y; must contain methods
%            'gradient', 'evaluate', 'getParams', 'setParams',
%            and 'getBounds'
%    opts - options, incluoding 'iters', 'evalInterval', and any model opts
%       FIELDS
%       iters: total number of iteration
%       evalInterval: interval at which to evaluate likelihood and save a
%           checkpoint
%       saveInterval: interval at which to save intermediate models during
%           training
%       convThresh: convergence threshold (average gradient magnitude)
%    chkptfile (optional) - path to file where checkpoint models will be
%        saved
%
% Output
%    evals - function evaluations every 'evalInterval' iterations
%    trainModels - intermediate models saved during training
BETA2 = 0.999;
EPS = 1e-8;
BETA1 = 0.9;
LEARN_RATE = 1e-2;

nParams = numel(model.getParams);
algVars.moment1 = zeros(nParams,1);
algVars.moment2 = zeros(nParams,1);
algVars.iter = 1;
algVars.calcStep = @(g,av) calcStep(g,av,BETA1,BETA2,EPS,LEARN_RATE);

if nargin > 4
  [evals,trainModels] = algorithms.descent(x,yAll,model,opts,algVars,chkptfile);
else
  [evals,trainModels] = algorithms.descent(x,yAll,model,opts,algVars);
end
end

function [step, av] = calcStep(g,av,beta1,beta2,eps,learnRate)
av.moment1 = beta1*av.moment1 + (1-beta1)*g;
av.moment2 = beta2*av.moment2 + (1-beta2)*g.^2;
adjM1 = av.moment1./(1-beta1.^av.iter);
adjM2 = av.moment2./(1-beta2.^av.iter);
step = adjM1./(eps + sqrt(adjM2));
step = learnRate*step;
av.iter = av.iter + 1;
end