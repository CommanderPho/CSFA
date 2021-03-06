function modelRefit = projectCSFA(xFft,origModel,s,trainOpts,initScores)
% projectCSFA
%   Projects a dataset onto the space of factors for a
%   cross-spectral factor analysis (CSFA) model
%   INPUTS
%   xFft: fourier transform of preprocessed data. NxAxW array. A is
%     the # of channels. N=number of frequency points per
%     window. W=number of time windows.
%   origModel: CSFA model containing factors onto which you desire
%     to project the dataset (xFft)
%   s: frequency space (Hz) labels of fourier transformed data
%   trainOpts: (optional) structure of options for the learning algorithm. All
%       non-optional fields not included in the structure passed in will be
%       filled with a default value. See the fillDefaultTopts function for
%       default values.
%     FIELDS
%     iters: maximum number of training iterations
%     evalInterval: interval at which to evaluate objective.
%     convThresh, convClock: convergence criterion parameters. training stops if
%         the objective function does not increase by 'convThresh' after
%         'convClock' evaluations of the objective function.
%     algorithm: function handle to the desired gradient descent
%         algorithm for model learning. 
%         Example: [evals,trainModels] = trainOpts.algorithm(labels.s,...
%                        xFft(:,:,sets.train),model,trainOpts,chkptFile);
%   initScores: (optional) LxW of scores to initialize
%     projection. L = number of factors. W = last dimension of
%     xFft. NaN entries in initScores will be replaced with a
%     random initialization.

if nargin < 4
  trainOpts = [];
end
trainOpts = fillDefaultTopts(trainOpts);

% adjust training options to be appropriate for score projection
if isequal(trainOpts.algorithm,@algorithms.noisyAdam)
  trainOpts.algorithm = @algorithms.adam;
end
trainOpts.saveInterval = trainOpts.iters + 1;
trainOpts.stochastic = false;
trainOpts.evalInterval = trainOpts.evalInterval2;
trainOpts.convThresh = trainOpts.convThresh2;
trainOpts.convClock = trainOpts.convClock2;

% model parameters
modelRefitOpts = extractModelOpts(origModel);
modelRefitOpts.W = size(xFft,3);
modelRefitOpts.maxW = min(1e3,modelRefitOpts.W);

% initialize new model
kernels = origModel.LMCkernels;
modelRefit = GP.CSFA(modelRefitOpts,kernels);
modelRefit.updateKernels = false;
if nargin >= 5
  scoresGiven = ~isnan(initScores);
  modelRefit.scores(scoresGiven) = initScores(scoresGiven);
end

% project new data onto factors
trainOpts.algorithm(s,xFft,modelRefit,trainOpts);
end

function modelOpts = extractModelOpts(model)
  modelOpts.L = model.L;
  modelOpts.Q = model.Q;
  modelOpts.C = model.C;
  modelOpts.R = model.LMCkernels{1}.coregs.B{1}.R;
  modelOpts.eta = model.eta;
  modelOpts.lowFreq = model.freqBounds(1);
  modelOpts.highFreq = model.freqBounds(2);
end