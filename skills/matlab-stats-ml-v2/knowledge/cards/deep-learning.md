# Deep Learning Integration (Stats & ML Toolbox)

The model already knows `fitcnet` and `fitrnet` syntax, architecture configuration, activation functions, regularization, cross-validation, and hyperparameter optimization. This card covers only the integration patterns between Stats & ML Toolbox neural networks and the Deep Learning Toolbox.

> **For CNNs, RNNs, segmentation, and custom architectures:** Use the Deep Learning Toolbox (`trainnet`, `unet`, `dlnetwork`).

## When to Use fitcnet/fitrnet vs Deep Learning Toolbox

| Scenario | Use | Reason |
|----------|-----|--------|
| Tabular clinical data | `fitcnet` / `fitrnet` | Simpler API, integrated with Stats & ML workflow |
| Image classification | Deep Learning Toolbox | Requires CNNs |
| Sequence/time-series | Deep Learning Toolbox | Requires RNN/LSTM |
| Custom loss functions | Deep Learning Toolbox | fitcnet has fixed loss |
| GPU acceleration | Deep Learning Toolbox | fitcnet is CPU-only |
| Ensemble with traditional ML | `fitcnet` + `fitcsvm` + `fitcensemble` | Same predict() interface |

## Combining Deep Features with Traditional Classifiers

```matlab
% Extract features from pre-trained CNN (requires Deep Learning Toolbox)
% Then use Stats & ML classifiers on those features

% Deep features already extracted to 'features' matrix
% Compare traditional classifiers on deep features
cv = cvpartition(labels, 'KFold', 5);

models = {
    'SVM', @() fitcsvm(features, labels, 'KernelFunction', 'rbf', 'CVPartition', cv)
    'RF', @() fitcensemble(features, labels, 'Method', 'Bag', 'CVPartition', cv)
    'NN', @() fitcnet(features, labels, 'LayerSizes', [64 32], 'CVPartition', cv)
};

for i = 1:size(models, 1)
    Mdl = models{i, 2}();
    acc = 1 - kfoldLoss(Mdl);
    fprintf('%s on deep features: %.2f%%\n', models{i, 1}, acc * 100);
end
```

## Architecture Guide for Clinical Tabular Data

```
Dataset size → Architecture
├── < 500 samples   → [32] or [64], Lambda=0.01
├── 500-2000        → [64 32], Lambda=0.001
├── 2000-10000      → [128 64 32], Lambda=0.001
└── > 10000         → Consider Deep Learning Toolbox for GPU
```

## Model Deployment

```matlab
% Compact model for deployment (removes training data, reduces size)
Mdl_compact = compact(Mdl);
save('diagnostic_model.mat', 'Mdl_compact');

% Load and predict
load('diagnostic_model.mat', 'Mdl_compact');
YPred = predict(Mdl_compact, Xnew);
```

---

*For CNNs, segmentation, and advanced architectures, see the Deep Learning Toolbox documentation.*
