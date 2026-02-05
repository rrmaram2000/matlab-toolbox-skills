# Deep Learning Integration (Statistics & ML Toolbox)

The Statistics and Machine Learning Toolbox provides `fitcnet` and `fitrnet` for neural network classification and regression without requiring the Deep Learning Toolbox. These functions offer a streamlined interface for fully-connected feedforward networks.

> **For advanced deep learning:** CNNs, RNNs, semantic segmentation, and custom architectures require the **matlab-deep-learning** skill. This card covers Stats & ML Toolbox neural networks only.

## Neural Network Classification (fitcnet)

### Basic Classification Network

```matlab
% Load data
load fisheriris
X = meas;
Y = species;

% Train neural network classifier
Mdl = fitcnet(X, Y);

% Predict
[YPred, scores] = predict(Mdl, X);

% Check accuracy
accuracy = mean(strcmp(YPred, Y));
fprintf('Training accuracy: %.2f%%\n', accuracy * 100);
```

### Architecture Configuration

```matlab
% Hidden layer sizes: vector specifying neurons per layer
% [100 50] = 2 hidden layers with 100 and 50 neurons

Mdl = fitcnet(X, Y, ...
    'LayerSizes', [128 64 32], ...   % 3 hidden layers
    'Activations', 'relu', ...        % Activation function
    'Standardize', true, ...          % Standardize inputs
    'Lambda', 0.001);                 % L2 regularization

% Activation options:
% 'relu'    - Rectified Linear Unit (default, recommended)
% 'tanh'    - Hyperbolic tangent
% 'sigmoid' - Logistic sigmoid
% 'none'    - Linear (no activation)
```

### Architecture Guide by Dataset Size

```
Dataset size (n samples) → Recommended architecture
├── Small (< 500)        → [32] or [64]
├── Medium (500-2000)    → [64 32] or [100 50]
├── Large (2000-10000)   → [128 64 32]
├── Very Large (> 10000) → [256 128 64] or use Deep Learning Toolbox
```

### Regularization and Dropout

```matlab
% L2 regularization (weight decay)
Mdl = fitcnet(X, Y, ...
    'LayerSizes', [100 50], ...
    'Lambda', 0.01, ...              % Strong regularization
    'Standardize', true);

% Note: Dropout not directly supported in fitcnet
% Use L2 regularization instead, or switch to Deep Learning Toolbox
```

### Training Options

```matlab
Mdl = fitcnet(X, Y, ...
    'LayerSizes', [100 50], ...
    'Activations', 'relu', ...
    'IterationLimit', 1000, ...      % Max training iterations
    'GradientTolerance', 1e-6, ...   % Convergence tolerance
    'LossTolerance', 1e-6, ...
    'Standardize', true, ...
    'Verbose', 1, ...                % Show training progress
    'VerboseFrequency', 50);         % Print every 50 iterations

% Check training info
disp(Mdl.TrainingHistory);
```

### Cross-Validation

```matlab
% K-fold cross-validation
cv = cvpartition(Y, 'KFold', 5);

Mdl = fitcnet(X, Y, ...
    'LayerSizes', [100 50], ...
    'CVPartition', cv, ...
    'Standardize', true);

% Get cross-validated loss
cvLoss = kfoldLoss(Mdl);
fprintf('5-fold CV loss: %.4f\n', cvLoss);

% Or use crossval
Mdl_trained = fitcnet(X, Y, 'LayerSizes', [100 50]);
Mdl_cv = crossval(Mdl_trained, 'KFold', 5);
cvAccuracy = 1 - kfoldLoss(Mdl_cv);
fprintf('5-fold CV accuracy: %.2f%%\n', cvAccuracy * 100);
```

### Hyperparameter Optimization

```matlab
% Automatic optimization with Bayesian search
Mdl = fitcnet(X, Y, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct(...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'MaxObjectiveEvaluations', 30, ...
        'ShowPlots', true, ...
        'Verbose', 1, ...
        'Kfold', 5));

% Optimize specific hyperparameters
Mdl = fitcnet(X, Y, ...
    'OptimizeHyperparameters', {'Lambda', 'LayerSizes'});

% Access best hyperparameters
disp(Mdl.HyperparameterOptimizationResults.XAtMinObjective);
```

### Class Probabilities and Confidence

```matlab
% Get posterior probabilities
[YPred, scores] = predict(Mdl, Xtest);

% scores: n_samples x n_classes matrix of probabilities
% Each row sums to 1

% Confidence: max probability
confidence = max(scores, [], 2);

% Predict with confidence threshold
threshold = 0.7;
highConfIdx = confidence >= threshold;

fprintf('High-confidence predictions: %d/%d (%.1f%%)\n', ...
    sum(highConfIdx), length(confidence), 100*mean(highConfIdx));
```

## Neural Network Regression (fitrnet)

### Basic Regression Network

```matlab
% Generate sample data
n = 500;
X = randn(n, 5);
y = X(:,1).^2 + 2*X(:,2) - X(:,3) + 0.5*randn(n,1);

% Train neural network regressor
Mdl = fitrnet(X, y);

% Predict
yPred = predict(Mdl, X);

% Evaluate
rmse = sqrt(mean((y - yPred).^2));
r2 = 1 - sum((y - yPred).^2) / sum((y - mean(y)).^2);

fprintf('RMSE: %.4f, R²: %.4f\n', rmse, r2);
```

### Regression Architecture

```matlab
Mdl = fitrnet(X, y, ...
    'LayerSizes', [64 32], ...
    'Activations', 'relu', ...
    'Standardize', true, ...
    'StandardizeResponse', true, ...  % Also standardize targets
    'Lambda', 0.001);

% View network structure
disp(Mdl.LayerSizes);
disp(Mdl.Activations);
```

### Training Visualization

```matlab
% Train with verbose output
Mdl = fitrnet(X, y, ...
    'LayerSizes', [100 50], ...
    'Verbose', 1, ...
    'VerboseFrequency', 20);

% Plot training loss
figure;
plot(Mdl.TrainingHistory.Iteration, Mdl.TrainingHistory.TrainingLoss, 'b-');
xlabel('Iteration');
ylabel('Training Loss');
title('Training Progress');
grid on;
```

### Multi-Output Regression

```matlab
% fitrnet supports single output only
% For multi-output, train separate models or use Deep Learning Toolbox

y1 = X(:,1) + X(:,2);
y2 = X(:,1) - X(:,2);

Mdl1 = fitrnet(X, y1, 'LayerSizes', [50 25]);
Mdl2 = fitrnet(X, y2, 'LayerSizes', [50 25]);

% Predict both outputs
yPred1 = predict(Mdl1, Xtest);
yPred2 = predict(Mdl2, Xtest);
```

## Feature Importance and Interpretation

### Permutation Importance

```matlab
function importance = permutationImportance(Mdl, X, Y, metric)
    % Compute permutation importance for neural network
    % metric: @(y,yhat) function handle (lower is better)

    if nargin < 4
        metric = @(y, yhat) mean((y - yhat).^2);  % MSE for regression
    end

    baseScore = metric(Y, predict(Mdl, X));
    p = size(X, 2);
    importance = zeros(p, 1);

    for j = 1:p
        X_perm = X;
        X_perm(:, j) = X(randperm(size(X,1)), j);  % Shuffle feature j
        permScore = metric(Y, predict(Mdl, X_perm));
        importance(j) = permScore - baseScore;  % Increase in error
    end

    % Normalize
    importance = importance / sum(importance);
end

% Usage for regression
Mdl = fitrnet(X, y, 'LayerSizes', [100 50]);
imp = permutationImportance(Mdl, X, y);

figure;
bar(imp);
xlabel('Feature');
ylabel('Importance');
title('Permutation Feature Importance');
```

### Learning Curves

```matlab
function [trainErrors, valErrors] = learningCurve(X, y, trainSizes)
    % Generate learning curves

    n = size(X, 1);
    nSizes = length(trainSizes);
    trainErrors = zeros(nSizes, 1);
    valErrors = zeros(nSizes, 1);

    % Fixed validation set
    cv = cvpartition(n, 'Holdout', 0.2);
    valIdx = test(cv);
    Xval = X(valIdx, :);
    yval = y(valIdx);

    for i = 1:nSizes
        nTrain = trainSizes(i);
        trainIdx = find(training(cv));
        trainIdx = trainIdx(1:min(nTrain, length(trainIdx)));

        Xtrain = X(trainIdx, :);
        ytrain = y(trainIdx);

        Mdl = fitrnet(Xtrain, ytrain, ...
            'LayerSizes', [64 32], ...
            'Standardize', true, ...
            'Verbose', 0);

        trainErrors(i) = loss(Mdl, Xtrain, ytrain);
        valErrors(i) = loss(Mdl, Xval, yval);
    end

    % Plot
    figure;
    plot(trainSizes, trainErrors, 'b-o', 'LineWidth', 2);
    hold on;
    plot(trainSizes, valErrors, 'r-s', 'LineWidth', 2);
    xlabel('Training Set Size');
    ylabel('Mean Squared Error');
    legend('Training', 'Validation');
    title('Learning Curves');
    grid on;
end

% Usage
trainSizes = round(linspace(50, 400, 10));
[trainErrors, valErrors] = learningCurve(X, y, trainSizes);
```

## Transfer Learning with Traditional ML

When deep features are available, combine with traditional classifiers.

```matlab
% Assuming features extracted from pre-trained network
% (requires Deep Learning Toolbox for feature extraction)

% Deep features + traditional classifier
features = ...; % Deep features from CNN
labels = ...; % Target labels

% SVM on deep features
Mdl_svm = fitcsvm(features, labels, ...
    'KernelFunction', 'rbf', ...
    'OptimizeHyperparameters', 'auto');

% Random Forest on deep features
Mdl_rf = fitcensemble(features, labels, ...
    'Method', 'Bag', ...
    'NumLearningCycles', 100);

% Neural network on deep features
Mdl_net = fitcnet(features, labels, ...
    'LayerSizes', [64 32], ...
    'Standardize', false);  % Features already normalized

% Ensemble of all three
[~, scores_svm] = predict(Mdl_svm, features_test);
[~, scores_rf] = predict(Mdl_rf, features_test);
[~, scores_net] = predict(Mdl_net, features_test);

% Average ensemble
ensemble_scores = (scores_svm + scores_rf + scores_net) / 3;
[~, ensemble_pred] = max(ensemble_scores, [], 2);
```

## Model Comparison

```matlab
function compareModels(X, Y)
    % Compare neural network with traditional classifiers

    cv = cvpartition(Y, 'KFold', 5);
    models = {
        'Neural Net', @() fitcnet(X, Y, 'LayerSizes', [100 50], 'CVPartition', cv)
        'SVM', @() fitcsvm(X, Y, 'KernelFunction', 'rbf', 'CVPartition', cv)
        'Random Forest', @() fitcensemble(X, Y, 'Method', 'Bag', 'CVPartition', cv)
        'KNN', @() fitcknn(X, Y, 'NumNeighbors', 5, 'CVPartition', cv)
    };

    fprintf('Model Comparison (5-fold CV):\n');
    fprintf('%-15s %10s\n', 'Model', 'Accuracy');
    fprintf('%s\n', repmat('-', 1, 30));

    for i = 1:size(models, 1)
        try
            Mdl = models{i, 2}();
            acc = 1 - kfoldLoss(Mdl);
            fprintf('%-15s %10.2f%%\n', models{i, 1}, acc * 100);
        catch ME
            fprintf('%-15s %10s\n', models{i, 1}, 'Error');
        end
    end
end

% Usage
compareModels(X, Y);
```

## GPU Acceleration

```matlab
% fitcnet/fitrnet do not directly support GPU
% For GPU acceleration, use Deep Learning Toolbox

% Check if parallel computing is available
if canUseParallelPool
    % Use parallel for hyperparameter optimization
    Mdl = fitcnet(X, Y, ...
        'OptimizeHyperparameters', 'auto', ...
        'HyperparameterOptimizationOptions', struct(...
            'UseParallel', true, ...
            'MaxObjectiveEvaluations', 50));
end
```

## Saving and Loading Models

```matlab
% Save trained model
Mdl = fitcnet(X, Y, 'LayerSizes', [100 50]);
save('neural_net_model.mat', 'Mdl');

% Load model
load('neural_net_model.mat', 'Mdl');
YPred = predict(Mdl, Xnew);

% Compact model for deployment (removes training data)
Mdl_compact = compact(Mdl);
save('neural_net_compact.mat', 'Mdl_compact');
```

## When to Use Deep Learning Toolbox Instead

| Feature | fitcnet/fitrnet | Deep Learning Toolbox |
|---------|-----------------|----------------------|
| Fully-connected networks | ✓ | ✓ |
| Convolutional networks (CNN) | ✗ | ✓ |
| Recurrent networks (RNN/LSTM) | ✗ | ✓ |
| Custom layers | ✗ | ✓ |
| GPU training | ✗ | ✓ |
| Transfer learning | Limited | ✓ |
| Image/sequence data | ✗ | ✓ |
| Custom loss functions | ✗ | ✓ |

## Best Practices

1. **Always standardize inputs** - Set `'Standardize', true`

2. **Start simple:**
   - Begin with 1-2 hidden layers
   - Increase complexity only if underfitting

3. **Use regularization:**
   - Add Lambda > 0 to prevent overfitting
   - Typical range: 0.0001 to 0.1

4. **Cross-validation:**
   - Always use CV for model selection
   - Report CV metrics, not training metrics

5. **Early stopping:**
   - Monitor validation loss
   - Stop when validation error increases

6. **Feature engineering matters:**
   - Neural networks benefit from feature engineering
   - Don't assume the network will learn everything

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Poor convergence | Increase IterationLimit, check data scaling |
| Overfitting | Add regularization (Lambda), reduce layers |
| Slow training | Use fewer layers/neurons, reduce data |
| Class imbalance | Use 'Prior' or 'Cost' parameters |
| Multiclass OvO slow | Use 'Learners' with simpler classifiers |

---

*For CNNs, segmentation, and advanced architectures, see the matlab-deep-learning skill.*
*See also: classification.md, bayesian.md for hyperparameter optimization*
