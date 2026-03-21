# Custom Training -- Advanced Patterns

Advanced custom training loop patterns. Covers gradient accumulation, multi-loss training, learning rate scheduling, and early stopping. For basic dlarray/dlfeval/dlgradient/adamupdate usage, the model already has foundational knowledge.

## Learning Rate Scheduling

```matlab
% Cosine annealing (preferred for medical DL)
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
```

## Gradient Clipping

```matlab
% Threshold L2 norm (prevents exploding gradients)
gradients = dlupdate(@(g) thresholdL2Norm(g, 1.0), gradients);

function g = thresholdL2Norm(g, threshold)
    normG = sqrt(sum(g(:).^2));
    if normG > threshold
        g = g * threshold / normG;
    end
end
```

## Gradient Accumulation (Large Effective Batch)

```matlab
% For larger effective batch size with limited GPU memory
accumSteps = 4;

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

## Multi-Loss Training

```matlab
function [totalLoss, gradients] = multiLossGradients(net, X, T, lambda)
    Y = forward(net, X);
    classLoss = crossentropy(Y.class, T.class);
    regLoss = mse(Y.reg, T.reg);
    totalLoss = classLoss + lambda * regLoss;
    gradients = dlgradient(totalLoss, net.Learnables);
end
```

## Auxiliary Outputs

```matlab
function [loss, gradients, state] = auxLossGradients(net, X, T)
    [Ymain, Yaux, state] = forward(net, X);
    mainLoss = crossentropy(Ymain, T);
    auxLoss = crossentropy(Yaux, T);
    loss = mainLoss + 0.4 * auxLoss;
    gradients = dlgradient(loss, net.Learnables);
end
```

## Early Stopping Pattern

```matlab
bestValLoss = Inf;
patienceCounter = 0;
patience = 10;

for epoch = 1:numEpochs
    % ... training loop ...

    valLoss = computeValidationLoss(net, valDs);

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
end
net = bestNet;
```

## Validation Loss Helper

```matlab
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
```

## Regression Losses (Not Well Known)

```matlab
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

---

*Verified against MATLAB R2025b*
