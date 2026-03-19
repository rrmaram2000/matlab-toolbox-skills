# Network Architecture -- Custom Layers & Attention

Advanced network architecture patterns: custom layers, attention mechanisms, residual blocks, and encoder-decoder construction. For basic layer types (conv, pool, BN, FC, dropout) and layerGraph/dlnetwork usage, the model already has foundational knowledge.

## Custom Layer Template

```matlab
classdef myCustomLayer < nnet.layer.Layer

    properties (Learnable)
        Weights
        Bias
    end

    methods
        function layer = myCustomLayer(numInputs, numOutputs, name)
            layer.Name = name;
            layer.NumInputs = numInputs;
            layer.NumOutputs = numOutputs;
            layer.Weights = randn(numOutputs, numInputs, 'single') * 0.01;
            layer.Bias = zeros(numOutputs, 1, 'single');
        end

        function Z = predict(layer, X)
            Z = layer.Weights * X + layer.Bias;
        end

        function [Z, memory] = forward(layer, X)
            Z = layer.Weights * X + layer.Bias;
            memory = X;  % Store for backward pass if needed
        end
    end
end
```

## Squeeze-and-Excitation Block

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

    % Output (modern API -- no pixelClassificationLayer)
    lgraph = addLayers(lgraph, [
        convolution2dLayer(1, numClasses, 'Name', 'output_conv')
        softmaxLayer('Name', 'softmax')]);
    lgraph = connectLayers(lgraph, prevName, 'output_conv');
    % Train with: trainnet(ds, dlnetwork(lgraph), "crossentropy", opts)
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
