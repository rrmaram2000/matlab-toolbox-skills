# Wavelet + Deep Learning Integration

## Available Approaches by MATLAB Version

| Feature | Minimum Version | Description |
|---------|-----------------|-------------|
| `cwtLayer` | R2022b | CWT as network layer |
| `modwtLayer` | R2023a | MODWT as network layer |
| `dldwt`/`dlidwt` | R2025a | Differentiable 2D DWT |
| Manual gradients | Any | Custom wavelet layers |

## CWT Layer for Signal Classification (R2022b+)

```matlab
% CWT layer converts 1D signal to 2D scalogram
cwtlayer = cwtLayer('SignalLength', 1024, ...
    'Wavelet', 'amor', ...            % Analytic Morlet
    'VoicesPerOctave', 12, ...
    'FrequencyLimits', [1 500]);      % Hz range

% Build classification network
layers = [
    sequenceInputLayer(1, Name="input")
    cwtlayer
    convolution2dLayer([5 5], 32, Padding="same")
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer([2 2], Stride=2)
    convolution2dLayer([3 3], 64, Padding="same")
    batchNormalizationLayer
    reluLayer
    globalAveragePooling2dLayer
    fullyConnectedLayer(numClasses)
    softmaxLayer
];

% Train
options = trainingOptions('adam', ...
    'MaxEpochs', 30, ...
    'MiniBatchSize', 32);
net = trainnet(XTrain, YTrain, layers, "crossentropy", options);
```

## Differentiable DWT (R2025a+)

```matlab
% Forward pass with gradient tracking
x = dlarray(img, 'SSCB');  % Spatial-Spatial-Channel-Batch
[A, D] = dldwt(x, Wavelet='db4');  % A=approx, D=detail (H,V,D concatenated)

% Process coefficients (example: learnable enhancement)
% For 2D: D(:,:,1,:)=H, D(:,:,2,:)=V, D(:,:,3,:)=D subbands
D_enhanced = D .* learnableScale;

% Inverse pass
xRec = dlidwt(A, D_enhanced, Wavelet='db4');

% Gradients flow through automatically
loss = mse(xRec, target);
gradients = dlgradient(loss, learnableScale);
```

## Custom Wavelet Layer (Any Version)

```matlab
classdef waveletLayer < nnet.layer.Layer
    properties
        Wavelet = 'db4'
        Level = 3
    end

    methods
        function layer = waveletLayer(name, wavelet, level)
            layer.Name = name;
            layer.Wavelet = wavelet;
            layer.Level = level;
        end

        function Z = predict(layer, X)
            % X: H x W x C x B (spatial-spatial-channel-batch)
            [H, W, C, B] = size(X);

            % Process each image in batch
            for b = 1:B
                for c = 1:C
                    img = extractdata(X(:,:,c,b));
                    [C_coeffs, S] = wavedec2(img, layer.Level, layer.Wavelet);
                    % Reshape coefficients to feature maps
                    % ... implementation depends on use case
                end
            end
        end
    end
end
```

## GPU Acceleration

```matlab
% Move data to GPU
imgGPU = gpuArray(double(img));

% DWT on GPU (transparent)
[C, S] = wavedec2(imgGPU, 4, 'db4');

% All operations stay on GPU
C_processed = C .* gpuArray(weights);

% Reconstruct on GPU
imgRecGPU = waverec2(C_processed, S, 'db4');

% Transfer to CPU only when needed
imgRec = gather(imgRecGPU);
```

## Wavelet Feature Preprocessing for CNNs

```matlab
function features = waveletPreprocess(img, wname, levels)
    % Create multi-channel input from wavelet subbands
    [C, S] = wavedec2(double(img), levels, wname);

    % Stack subbands as channels
    features = [];
    for lev = 1:levels
        cH = imresize(detcoef2('h', C, S, lev), size(img));
        cV = imresize(detcoef2('v', C, S, lev), size(img));
        cD = imresize(detcoef2('d', C, S, lev), size(img));
        features = cat(3, features, cH, cV, cD);
    end

    % Add approximation
    cA = imresize(appcoef2(C, S, wname), size(img));
    features = cat(3, features, cA);
end

% Usage: Create (H, W, 3*levels+1) input for CNN
X = waveletPreprocess(img, 'db4', 3);  % 10 channels
```

## Learnable Wavelet Filters

```matlab
% Define filter as learnable parameter
filterLen = 8;
loFilter = dlarray(randn(1, filterLen)/filterLen, 'TC');

% Constraint: sum to sqrt(2) for orthonormality
loFilter = loFilter / sum(loFilter) * sqrt(2);

% High-pass from low-pass (QMF relation)
hiFilter = loFilter .* ((-1).^(0:filterLen-1));

% Use in custom layer with gradient descent
```

## Best Practices

1. **Preprocessing**: Use wavelets before CNN for multi-scale features
2. **Data augmentation**: Apply wavelet denoising to training data
3. **Feature fusion**: Combine CNN features with wavelet features
4. **GPU**: Keep data on GPU for entire pipeline
5. **Batch processing**: Process full batches, not individual images
