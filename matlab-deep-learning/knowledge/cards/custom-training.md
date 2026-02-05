# Custom Training with dlarray

Custom training loops provide full control over loss functions, optimizers, logging, and training dynamics.

## dlarray Basics

### Creating dlarray

```matlab
% dlarray wraps data with format information
% Format labels: S=Spatial, C=Channel, B=Batch, T=Time, U=Unspecified

% Image batch (H×W×C×B)
data = randn(224, 224, 3, 16, 'single');
X = dlarray(data, 'SSCB');

% 3D volume batch (H×W×D×C×B)
data3D = randn(128, 128, 64, 1, 4, 'single');
X3D = dlarray(data3D, 'SSSCB');

% Sequence data (C×B×T)
seqData = randn(256, 8, 100, 'single');
Xseq = dlarray(seqData, 'CBT');

% Move to GPU
if canUseGPU
    X = gpuArray(X);
end
```

### Format Strings

| Format | Dimension Order | Use Case |
|--------|-----------------|----------|
| `'SSCB'` | H×W×C×B | 2D images |
| `'SSSCB'` | H×W×D×C×B | 3D volumes |
| `'CBT'` | C×B×T | Sequences |
| `'CB'` | C×B | Feature vectors |
| `'SSC'` | H×W×C | Single image |

### Extracting Data

```matlab
% Get underlying data
data = extractdata(X);  % Returns numeric array

% Gather from GPU
data = gather(extractdata(X));

% Check dimensions
dims(X)      % Returns format string
size(X)      % Returns size
finddim(X, 'C')  % Returns channel dimension index
```

## dlnetwork

### Creating dlnetwork

```matlab
% From layer array
layers = [
    imageInputLayer([224 224 3], 'Normalization', 'none')
    convolution2dLayer(3, 32, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)
    fullyConnectedLayer(10)
    softmaxLayer];

net = dlnetwork(layers);

% From layerGraph (for complex architectures)
lgraph = layerGraph(resnet50);
lgraph = removeLayers(lgraph, {'fc1000', 'fc1000_softmax', 'ClassificationLayer_fc1000'});
lgraph = addLayers(lgraph, fullyConnectedLayer(10, 'Name', 'fc_new'));
lgraph = connectLayers(lgraph, 'avg_pool', 'fc_new');
lgraph = addLayers(lgraph, softmaxLayer('Name', 'softmax'));
lgraph = connectLayers(lgraph, 'fc_new', 'softmax');

net = dlnetwork(lgraph);
```

### Forward Pass

```matlab
% Inference (no gradients tracked)
Y = predict(net, X);

% Training (gradients tracked, state updated)
[Y, state] = forward(net, X);
net.State = state;  % Update batch norm statistics
```

## Automatic Differentiation

### Computing Gradients

```matlab
% dlgradient computes gradients with respect to learnable parameters
function [loss, gradients] = modelGradients(net, X, T)
    % Forward pass
    Y = forward(net, X);

    % Compute loss
    loss = crossentropy(Y, T);

    % Compute gradients
    gradients = dlgradient(loss, net.Learnables);
end

% Evaluate with gradient computation
[loss, gradients] = dlfeval(@modelGradients, net, X, T);
```

### Gradient Rules

```matlab
% 1. dlgradient must be inside a function called via dlfeval
% WRONG:
loss = crossentropy(Y, T);
grad = dlgradient(loss, net.Learnables);  % Error!

% CORRECT:
[loss, grad] = dlfeval(@computeLoss, net, X, T);

% 2. Differentiated variables must be dlarray
% 3. Operations must be differentiable

% Non-differentiable operations (break gradient flow):
mask = Y > 0.5;           % Comparison
idx = find(Y > 0.5);      % find
Y_sorted = sort(Y);       % sort

% Differentiable alternatives:
mask = sigmoid((Y - 0.5) * 20);  % Soft threshold
```

## Loss Functions

### Classification Losses

```matlab
% Cross-entropy (multi-class)
loss = crossentropy(Y, T);  % Y: softmax output, T: one-hot targets

% Binary cross-entropy
loss = crossentropy(Y, T, 'TargetCategories', 'independent');

% Weighted cross-entropy
weights = [1.0, 2.5];  % Class weights
loss = crossentropy(Y, T, 'Weights', weights);

% Focal loss (for imbalanced classes)
function loss = focalLoss(Y, T, gamma)
    pt = sum(Y .* T, 'DataFormat', 'CB');
    loss = -mean((1 - pt).^gamma .* log(pt + 1e-8), 'all');
end
```

### Segmentation Losses

```matlab
% Dice loss
function loss = diceLoss(Y, T)
    smooth = 1e-6;
    intersection = sum(Y .* T, [1 2]);
    cardinality = sum(Y.^2, [1 2]) + sum(T.^2, [1 2]);
    dice = (2 * intersection + smooth) ./ (cardinality + smooth);
    loss = 1 - mean(dice, 'all');
end

% Combined Dice + CE
function loss = combinedLoss(Y, T)
    ce = crossentropy(Y, T);
    dice = diceLoss(Y, T);
    loss = 0.5 * ce + 0.5 * dice;
end

% Tversky loss (control FP/FN trade-off)
function loss = tverskyLoss(Y, T, alpha, beta)
    % alpha: weight for false positives
    % beta: weight for false negatives
    smooth = 1e-6;
    TP = sum(Y .* T, [1 2]);
    FP = sum(Y .* (1 - T), [1 2]);
    FN = sum((1 - Y) .* T, [1 2]);
    tversky = (TP + smooth) ./ (TP + alpha*FP + beta*FN + smooth);
    loss = 1 - mean(tversky, 'all');
end
```

### Regression Losses

```matlab
% Mean Squared Error
loss = mse(Y, T);

% Mean Absolute Error (L1)
loss = mean(abs(Y - T), 'all');

% Huber loss (robust to outliers)
function loss = huberLoss(Y, T, delta)
    diff = abs(Y - T);
    quadratic = min(diff, delta);
    linear = diff - quadratic;
    loss = mean(0.5 * quadratic.^2 + delta * linear, 'all');
end

% Smooth L1 loss
function loss = smoothL1Loss(Y, T)
    diff = abs(Y - T);
    loss = mean(ifelse(diff < 1, 0.5 * diff.^2, diff - 0.5), 'all');
end
```

## Optimizers

### Adam (Adaptive Moment Estimation)

```matlab
% Initialize state
avgGrad = [];      % First moment (mean)
avgSqGrad = [];    % Second moment (variance)

% In training loop
iteration = 0;
for epoch = 1:numEpochs
    while hasdata(mbq)
        iteration = iteration + 1;
        [X, T] = next(mbq);

        [loss, gradients] = dlfeval(@modelGradients, net, X, T);

        % Adam update
        [net, avgGrad, avgSqGrad] = adamupdate(net, gradients, ...
            avgGrad, avgSqGrad, iteration, learnRate);
    end
end
```

### SGD with Momentum

```matlab
velocity = [];  % Momentum term

[net, velocity] = sgdmupdate(net, gradients, velocity, learnRate, momentum);
% Default momentum: 0.9
```

### RMSprop

```matlab
avgSqGrad = [];

[net, avgSqGrad] = rmspropupdate(net, gradients, avgSqGrad, learnRate);
```

### Learning Rate Scheduling

```matlab
% Step decay
function lr = stepDecay(epoch, initialLR, dropFactor, dropPeriod)
    lr = initialLR * dropFactor^floor(epoch / dropPeriod);
end

% Cosine annealing
function lr = cosineAnnealing(iteration, maxIter, initialLR, minLR)
    lr = minLR + 0.5 * (initialLR - minLR) * (1 + cos(pi * iteration / maxIter));
end

% Warmup + decay
function lr = warmupDecay(epoch, warmupEpochs, initialLR, totalEpochs)
    if epoch <= warmupEpochs
        lr = initialLR * epoch / warmupEpochs;
    else
        lr = initialLR * (1 - (epoch - warmupEpochs) / (totalEpochs - warmupEpochs));
    end
end

% Use in training loop
learnRate = cosineAnnealing(iteration, maxIterations, 1e-3, 1e-6);
```

## Complete Custom Training Loop

```matlab
% Full training loop with all features

%% Setup
net = dlnetwork(lgraph);
numEpochs = 100;
initialLearnRate = 1e-3;
miniBatchSize = 16;

% Create minibatch queue
mbq = minibatchqueue(trainDs, ...
    'MiniBatchSize', miniBatchSize, ...
    'MiniBatchFormat', {'SSCB', 'CB'}, ...
    'OutputAsDlarray', [true, true], ...
    'OutputEnvironment', 'gpu');

% Initialize optimizer state
[avgGrad, avgSqGrad] = deal([]);

% Initialize tracking
losses = [];
valLosses = [];
bestValLoss = Inf;
patienceCounter = 0;
patience = 10;

%% Training Loop
iteration = 0;
for epoch = 1:numEpochs

    % Shuffle data
    shuffle(mbq);
    epochLoss = 0;
    numBatches = 0;

    % Mini-batch loop
    while hasdata(mbq)
        iteration = iteration + 1;
        numBatches = numBatches + 1;
        [X, T] = next(mbq);

        % Learning rate schedule
        learnRate = cosineAnnealing(epoch, numEpochs, initialLearnRate, 1e-6);

        % Compute gradients and loss
        [loss, gradients, state] = dlfeval(@modelLossWithState, net, X, T);
        net.State = state;

        % Gradient clipping (optional)
        gradients = dlupdate(@(g) thresholdL2Norm(g, 1.0), gradients);

        % Update parameters
        [net, avgGrad, avgSqGrad] = adamupdate(net, gradients, ...
            avgGrad, avgSqGrad, iteration, learnRate);

        epochLoss = epochLoss + extractdata(loss);
    end

    % Epoch statistics
    avgEpochLoss = epochLoss / numBatches;
    losses = [losses; avgEpochLoss];

    % Validation
    valLoss = computeValidationLoss(net, valDs);
    valLosses = [valLosses; valLoss];

    % Early stopping check
    if valLoss < bestValLoss
        bestValLoss = valLoss;
        bestNet = net;
        patienceCounter = 0;
    else
        patienceCounter = patienceCounter + 1;
        if patienceCounter >= patience
            fprintf('Early stopping at epoch %d\n', epoch);
            break;
        end
    end

    % Display progress
    fprintf('Epoch %d/%d | Loss: %.4f | Val Loss: %.4f | LR: %.2e\n', ...
        epoch, numEpochs, avgEpochLoss, valLoss, learnRate);
end

net = bestNet;  % Use best model

%% Helper Functions
function [loss, gradients, state] = modelLossWithState(net, X, T)
    [Y, state] = forward(net, X);
    loss = crossentropy(Y, T);
    gradients = dlgradient(loss, net.Learnables);
end

function valLoss = computeValidationLoss(net, valDs)
    mbqVal = minibatchqueue(valDs, 'MiniBatchSize', 32, ...
        'MiniBatchFormat', {'SSCB', 'CB'}, 'OutputAsDlarray', true);
    totalLoss = 0;
    numBatches = 0;
    while hasdata(mbqVal)
        [X, T] = next(mbqVal);
        Y = predict(net, X);
        totalLoss = totalLoss + extractdata(crossentropy(Y, T));
        numBatches = numBatches + 1;
    end
    valLoss = totalLoss / numBatches;
end

function g = thresholdL2Norm(g, threshold)
    normG = sqrt(sum(g(:).^2));
    if normG > threshold
        g = g * threshold / normG;
    end
end
```

## Minibatch Queue

### Creating Minibatch Queue

```matlab
% Basic usage
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32);

% Full control
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32, ...
    'MiniBatchFormat', {'SSCB', 'CB'}, ...     % Format for each output
    'OutputAsDlarray', [true, true], ...       % Convert to dlarray
    'OutputEnvironment', 'gpu', ...            % Send to GPU
    'PartialMiniBatch', 'discard', ...         % Discard incomplete batches
    'PreprocessingEnvironment', 'parallel');   % Parallel preprocessing
```

### Custom Preprocessing

```matlab
% Datastore with preprocessing
ds = combine(imds, labelDs);

% Transform function
ds = transform(ds, @preprocessMiniBatch);

function data = preprocessMiniBatch(data)
    img = data{1};
    label = data{2};

    % Augmentation
    if rand > 0.5
        img = fliplr(img);
    end

    % Normalize
    img = im2single(img);

    data = {img, label};
end

% Use in mbq
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32, ...
    'MiniBatchFormat', {'SSCB', ''});  % '' for non-dlarray
```

## Common Patterns

### Training with Multiple Losses

```matlab
function [totalLoss, gradients] = multiLossGradients(net, X, T, lambda)
    Y = forward(net, X);

    % Multiple losses
    classLoss = crossentropy(Y.class, T.class);
    regLoss = mse(Y.reg, T.reg);

    % Weighted combination
    totalLoss = classLoss + lambda * regLoss;

    gradients = dlgradient(totalLoss, net.Learnables);
end
```

### Training with Auxiliary Outputs

```matlab
% Network with main + auxiliary heads
function [loss, gradients, state] = auxLossGradients(net, X, T)
    [Ymain, Yaux, state] = forward(net, X);

    mainLoss = crossentropy(Ymain, T);
    auxLoss = crossentropy(Yaux, T);

    loss = mainLoss + 0.4 * auxLoss;  % Auxiliary weight
    gradients = dlgradient(loss, net.Learnables);
end
```

### Accumulating Gradients (Large Effective Batch)

```matlab
% For larger effective batch size with limited GPU memory
accumSteps = 4;
effectiveBatch = miniBatchSize * accumSteps;

accumulatedGrads = [];
for step = 1:accumSteps
    [X, T] = next(mbq);
    [~, grads] = dlfeval(@modelGradients, net, X, T);

    if isempty(accumulatedGrads)
        accumulatedGrads = grads;
    else
        accumulatedGrads = dlupdate(@plus, accumulatedGrads, grads);
    end
end

% Average and update
accumulatedGrads = dlupdate(@(g) g / accumSteps, accumulatedGrads);
[net, avgGrad, avgSqGrad] = adamupdate(net, accumulatedGrads, ...
    avgGrad, avgSqGrad, iteration, learnRate);
```

---

*Source: Deep Learning Toolbox Documentation - Custom Training (R2025b)*
