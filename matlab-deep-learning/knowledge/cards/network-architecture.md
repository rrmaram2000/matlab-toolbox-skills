# Network Architecture

> ⚠️ **R2024b+ API Changes:** `trainNetwork` → `trainnet`, `classificationLayer` → use `trainnet` with appropriate loss. See SKILL.md for modern syntax.

Understanding layer types, network construction, and custom layers is essential for building and modifying deep learning models.

## Layer Types Reference

### Input Layers

| Layer | Function | Use Case |
|-------|----------|----------|
| `imageInputLayer` | Image input | Classification, segmentation |
| `sequenceInputLayer` | Sequence input | Time series, NLP |
| `featureInputLayer` | Feature vector | Tabular data |
| `image3dInputLayer` | 3D volume input | CT, MRI volumes |

```matlab
% Image input
inputLayer = imageInputLayer([224 224 3], ...
    'Name', 'input', ...
    'Normalization', 'zscore', ...  % 'none', 'zerocenter', 'zscore', 'rescale-symmetric'
    'Mean', [0.485 0.456 0.406], ...
    'StandardDeviation', [0.229 0.224 0.225]);

% 3D volume input
input3D = image3dInputLayer([128 128 64 1], ...
    'Name', 'input3d', ...
    'Normalization', 'none');

% Sequence input
seqInput = sequenceInputLayer(256, ...  % Feature dimension
    'Name', 'seq_input', ...
    'MinLength', 10);
```

### Convolution Layers

```matlab
% 2D Convolution
conv2d = convolution2dLayer(3, 64, ...      % 3×3 kernel, 64 filters
    'Padding', 'same', ...                   % Keep spatial size
    'Stride', 1, ...
    'DilationFactor', 1, ...
    'Name', 'conv1');

% Depthwise separable convolution (efficient)
depthwise = groupedConvolution2dLayer(3, 1, ...  % 3×3, 1 filter per group
    'NumGroups', 'channel-wise', ...             % Depthwise
    'Padding', 'same', ...
    'Name', 'depthwise');

% 3D Convolution (for volumes)
conv3d = convolution3dLayer([3 3 3], 32, ...
    'Padding', 'same', ...
    'Name', 'conv3d');

% Transposed convolution (upsampling)
transConv = transposedConv2dLayer(4, 64, ...
    'Stride', 2, ...                        % Upsamples by 2×
    'Cropping', 'same', ...
    'Name', 'upsample');
```

### Pooling Layers

```matlab
% Max pooling
maxPool = maxPooling2dLayer(2, ...
    'Stride', 2, ...                        % Downsample by 2×
    'Padding', 0, ...
    'Name', 'maxpool');

% Average pooling
avgPool = averagePooling2dLayer(2, ...
    'Stride', 2, ...
    'Name', 'avgpool');

% Global average pooling (before FC for classification)
globalAvgPool = globalAveragePooling2dLayer('Name', 'gap');

% 3D pooling
maxPool3d = maxPooling3dLayer([2 2 2], ...
    'Stride', [2 2 2], ...
    'Name', 'maxpool3d');
```

### Normalization Layers

```matlab
% Batch normalization (most common)
bn = batchNormalizationLayer('Name', 'bn1');

% Group normalization (works with small batches)
gn = groupNormalizationLayer(32, ...        % 32 groups
    'Name', 'gn1');

% Layer normalization (for sequences)
ln = layerNormalizationLayer('Name', 'ln1');

% Instance normalization (style transfer)
in = instanceNormalizationLayer('Name', 'in1');
```

### Activation Layers

```matlab
% ReLU (most common)
relu = reluLayer('Name', 'relu');

% Leaky ReLU (prevents dying neurons)
leakyRelu = leakyReluLayer(0.01, 'Name', 'lrelu');

% ELU (smooth negative region)
elu = eluLayer(1.0, 'Name', 'elu');

% Swish/SiLU (modern, used in EfficientNet)
swish = swishLayer('Name', 'swish');

% GELU (transformers)
gelu = geluLayer('Name', 'gelu');

% Sigmoid (output for binary)
sigmoid = sigmoidLayer('Name', 'sigmoid');

% Softmax (output for multi-class)
softmax = softmaxLayer('Name', 'softmax');
```

### Dropout & Regularization

```matlab
% Standard dropout
dropout = dropoutLayer(0.5, 'Name', 'dropout');

% Spatial dropout (for conv layers)
spatialDropout = dropoutLayer(0.2, ...
    'Name', 'spatial_dropout');  % Apply to feature maps

% L2 regularization (in training options)
options = trainingOptions('adam', ...
    'L2Regularization', 1e-4);
```

### Fully Connected Layers

```matlab
% Dense layer
fc = fullyConnectedLayer(1024, ...
    'Name', 'fc1', ...
    'WeightLearnRateFactor', 1, ...
    'BiasLearnRateFactor', 1);

% Output layer for classification
outputFC = fullyConnectedLayer(numClasses, ...
    'Name', 'fc_output');

% With weight initialization
fc = fullyConnectedLayer(512, ...
    'Name', 'fc', ...
    'WeightsInitializer', 'he', ...     % 'glorot', 'he', 'narrow-normal'
    'BiasInitializer', 'zeros');
```

### Skip Connections & Merging

```matlab
% Addition (residual connection)
addLayer = additionLayer(2, 'Name', 'add');

% Concatenation (U-Net style)
concatLayer = concatenationLayer(3, 2, 'Name', 'concat');  % Along dimension 3

% Depth concatenation (channel-wise)
depthConcat = depthConcatenationLayer(2, 'Name', 'depth_concat');
```

## Network Construction

### Layer Array (Sequential)

```matlab
% Simple sequential network
layers = [
    imageInputLayer([28 28 1])
    convolution2dLayer(3, 8, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)
    convolution2dLayer(3, 16, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(10)
    softmaxLayer
    classificationLayer];

% Create network
net = trainNetwork(trainDs, layers, options);
```

### layerGraph (Branches & Connections)

```matlab
% Create layer graph for complex architectures
lgraph = layerGraph;

% Add layers
lgraph = addLayers(lgraph, imageInputLayer([224 224 3], 'Name', 'input'));
lgraph = addLayers(lgraph, convolution2dLayer(7, 64, 'Stride', 2, ...
    'Padding', 3, 'Name', 'conv1'));
lgraph = addLayers(lgraph, batchNormalizationLayer('Name', 'bn1'));
lgraph = addLayers(lgraph, reluLayer('Name', 'relu1'));

% Connect layers
lgraph = connectLayers(lgraph, 'input', 'conv1');
lgraph = connectLayers(lgraph, 'conv1', 'bn1');
lgraph = connectLayers(lgraph, 'bn1', 'relu1');

% Add residual block
lgraph = addResidualBlock(lgraph, 'relu1', 64, 'res1');

% Visualize
plot(lgraph);
```

### Residual Block

```matlab
function lgraph = addResidualBlock(lgraph, inputName, filters, blockName)
    % Main path
    layers = [
        convolution2dLayer(3, filters, 'Padding', 'same', ...
            'Name', [blockName '_conv1'])
        batchNormalizationLayer('Name', [blockName '_bn1'])
        reluLayer('Name', [blockName '_relu1'])
        convolution2dLayer(3, filters, 'Padding', 'same', ...
            'Name', [blockName '_conv2'])
        batchNormalizationLayer('Name', [blockName '_bn2'])];

    lgraph = addLayers(lgraph, layers);

    % Skip connection
    lgraph = addLayers(lgraph, additionLayer(2, 'Name', [blockName '_add']));
    lgraph = addLayers(lgraph, reluLayer('Name', [blockName '_relu2']));

    % Connect
    lgraph = connectLayers(lgraph, inputName, [blockName '_conv1']);
    lgraph = connectLayers(lgraph, [blockName '_bn2'], [blockName '_add/in1']);
    lgraph = connectLayers(lgraph, inputName, [blockName '_add/in2']);
    lgraph = connectLayers(lgraph, [blockName '_add'], [blockName '_relu2']);
end
```

## dlnetwork

### Creating dlnetwork

```matlab
% From layer graph
lgraph = layerGraph(resnet50);
% Remove classification layers for custom head
lgraph = removeLayers(lgraph, {'fc1000', 'fc1000_softmax', ...
    'ClassificationLayer_fc1000'});

% Convert to dlnetwork
net = dlnetwork(lgraph);

% Analyze
analyzeNetwork(net);
```

### Accessing Network Properties

```matlab
% Get learnable parameters
learnables = net.Learnables;
disp(learnables);  % Table with Layer, Parameter, Value

% Get network state (batch norm statistics)
state = net.State;

% Get layer names
layerNames = {net.Layers.Name};

% Get specific layer
convLayer = net.Layers(5);
weights = convLayer.Weights;
```

### Modifying Networks

```matlab
% Replace a layer
lgraph = layerGraph(net);
newFC = fullyConnectedLayer(100, 'Name', 'fc_new');
lgraph = replaceLayer(lgraph, 'fc1000', newFC);
net = dlnetwork(lgraph);

% Add layers
lgraph = addLayers(lgraph, dropoutLayer(0.5, 'Name', 'dropout'));
lgraph = connectLayers(lgraph, 'relu', 'dropout');
lgraph = connectLayers(lgraph, 'dropout', 'fc');

% Remove layers
lgraph = removeLayers(lgraph, {'unwanted_layer'});

% Disconnect layers
lgraph = disconnectLayers(lgraph, 'layer1', 'layer2');
```

### Freezing Layers

```matlab
% Freeze pretrained layers (set learn rate to 0)
lgraph = layerGraph(net);
layers = lgraph.Layers;

for i = 1:numel(layers)-3  % Keep last few layers trainable
    if isprop(layers(i), 'WeightLearnRateFactor')
        layers(i).WeightLearnRateFactor = 0;
        layers(i).BiasLearnRateFactor = 0;
    end
end

lgraph = layerGraph(layers);
% Reconnect (required after modifying layers array)
```

## Custom Layers

### Basic Custom Layer

```matlab
classdef myCustomLayer < nnet.layer.Layer
    % Custom layer template

    properties
        % Learnable parameters (empty if none)
    end

    properties (Learnable)
        % Learnable parameters
        Weights
        Bias
    end

    methods
        function layer = myCustomLayer(numInputs, numOutputs, name)
            layer.Name = name;
            layer.NumInputs = numInputs;
            layer.NumOutputs = numOutputs;

            % Initialize learnables
            layer.Weights = randn(numOutputs, numInputs, 'single') * 0.01;
            layer.Bias = zeros(numOutputs, 1, 'single');
        end

        function Z = predict(layer, X)
            % Forward pass (inference)
            Z = layer.Weights * X + layer.Bias;
        end

        function [Z, memory] = forward(layer, X)
            % Forward pass (training) - can store activations
            Z = layer.Weights * X + layer.Bias;
            memory = X;  % Store for backward pass if needed
        end
    end
end
```

### Squeeze-and-Excitation Block

```matlab
classdef seBlock < nnet.layer.Layer
    % Squeeze-and-Excitation block

    properties
        Ratio = 16
    end

    properties (Learnable)
        FC1Weights
        FC1Bias
        FC2Weights
        FC2Bias
    end

    methods
        function layer = seBlock(numChannels, name)
            layer.Name = name;
            reducedChannels = floor(numChannels / layer.Ratio);

            % Initialize FC layers
            layer.FC1Weights = randn(reducedChannels, numChannels, 'single') * ...
                sqrt(2/numChannels);
            layer.FC1Bias = zeros(reducedChannels, 1, 'single');
            layer.FC2Weights = randn(numChannels, reducedChannels, 'single') * ...
                sqrt(2/reducedChannels);
            layer.FC2Bias = zeros(numChannels, 1, 'single');
        end

        function Z = predict(layer, X)
            % Global average pooling
            squeeze = mean(X, [1 2]);  % [1×1×C×B]
            squeeze = reshape(squeeze, size(squeeze, 3), size(squeeze, 4));

            % Excitation
            excite = relu(layer.FC1Weights * squeeze + layer.FC1Bias);
            excite = sigmoid(layer.FC2Weights * excite + layer.FC2Bias);

            % Scale
            excite = reshape(excite, 1, 1, [], size(X, 4));
            Z = X .* excite;
        end
    end
end
```

### Attention Layer

```matlab
classdef selfAttentionLayer < nnet.layer.Layer
    % Self-attention for spatial features

    properties
        NumHeads = 8
        HeadDim
    end

    properties (Learnable)
        QueryWeights
        KeyWeights
        ValueWeights
        OutputWeights
    end

    methods
        function layer = selfAttentionLayer(numChannels, numHeads, name)
            layer.Name = name;
            layer.NumHeads = numHeads;
            layer.HeadDim = numChannels / numHeads;

            % Initialize projection weights
            scale = sqrt(2 / numChannels);
            layer.QueryWeights = randn(numChannels, numChannels, 'single') * scale;
            layer.KeyWeights = randn(numChannels, numChannels, 'single') * scale;
            layer.ValueWeights = randn(numChannels, numChannels, 'single') * scale;
            layer.OutputWeights = randn(numChannels, numChannels, 'single') * scale;
        end

        function Z = predict(layer, X)
            [H, W, C, B] = size(X);

            % Reshape to sequence: [C×(H*W)×B]
            X = reshape(X, H*W, C, B);
            X = permute(X, [2 1 3]);  % [C×N×B]

            % Project Q, K, V
            Q = pagemtimes(layer.QueryWeights, X);
            K = pagemtimes(layer.KeyWeights, X);
            V = pagemtimes(layer.ValueWeights, X);

            % Attention
            scores = pagemtimes(Q, 'transpose', K, 'none') / sqrt(layer.HeadDim);
            attn = softmax(scores, 'DataFormat', 'SCB');

            % Apply attention to values
            out = pagemtimes(attn, V, 'transpose');

            % Project output
            out = pagemtimes(layer.OutputWeights, out);

            % Reshape back
            out = permute(out, [2 1 3]);
            Z = reshape(out, H, W, C, B);
        end
    end
end
```

## Architecture Patterns

### Encoder-Decoder (U-Net Style)

```matlab
function lgraph = createEncoderDecoder(inputSize, numClasses, depth)
    lgraph = layerGraph;

    % Input
    lgraph = addLayers(lgraph, imageInputLayer(inputSize, 'Name', 'input'));

    filters = 64;
    prevName = 'input';
    skipNames = cell(depth, 1);

    % Encoder
    for d = 1:depth
        [lgraph, outName] = addEncoderBlock(lgraph, prevName, filters, d);
        skipNames{d} = outName;
        prevName = [outName '_pool'];
        filters = filters * 2;
    end

    % Bottleneck
    lgraph = addLayers(lgraph, [
        convolution2dLayer(3, filters, 'Padding', 'same', 'Name', 'bottleneck_conv1')
        batchNormalizationLayer('Name', 'bottleneck_bn1')
        reluLayer('Name', 'bottleneck_relu1')]);
    lgraph = connectLayers(lgraph, prevName, 'bottleneck_conv1');
    prevName = 'bottleneck_relu1';

    % Decoder
    for d = depth:-1:1
        filters = filters / 2;
        [lgraph, outName] = addDecoderBlock(lgraph, prevName, skipNames{d}, filters, d);
        prevName = outName;
    end

    % Output
    lgraph = addLayers(lgraph, [
        convolution2dLayer(1, numClasses, 'Name', 'output_conv')
        softmaxLayer('Name', 'softmax')
        pixelClassificationLayer('Name', 'output')]);
    lgraph = connectLayers(lgraph, prevName, 'output_conv');
end
```

### Feature Pyramid Network (FPN)

```matlab
function lgraph = addFPN(lgraph, backboneOutputs, numFilters)
    % backboneOutputs: cell array of layer names at different scales

    numLevels = numel(backboneOutputs);

    % Top-down pathway
    for i = numLevels:-1:1
        % Lateral connection
        lateralName = sprintf('fpn_lateral_%d', i);
        lgraph = addLayers(lgraph, ...
            convolution2dLayer(1, numFilters, 'Name', lateralName));
        lgraph = connectLayers(lgraph, backboneOutputs{i}, lateralName);

        if i < numLevels
            % Upsample and add
            upsampleName = sprintf('fpn_upsample_%d', i);
            addName = sprintf('fpn_add_%d', i);

            lgraph = addLayers(lgraph, [
                resize2dLayer('Scale', 2, 'Name', upsampleName)
                additionLayer(2, 'Name', addName)]);

            lgraph = connectLayers(lgraph, sprintf('fpn_out_%d', i+1), upsampleName);
            lgraph = connectLayers(lgraph, lateralName, [addName '/in1']);
            lgraph = connectLayers(lgraph, upsampleName, [addName '/in2']);

            prevName = addName;
        else
            prevName = lateralName;
        end

        % Output convolution
        outName = sprintf('fpn_out_%d', i);
        lgraph = addLayers(lgraph, ...
            convolution2dLayer(3, numFilters, 'Padding', 'same', 'Name', outName));
        lgraph = connectLayers(lgraph, prevName, outName);
    end
end
```

---

*Source: Deep Learning Toolbox Documentation - Network Architecture (R2025b)*
