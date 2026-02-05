# Deployment & Export

> ⚠️ **R2024b+ API Changes:** `trainNetwork` → `trainnet`. See SKILL.md for modern syntax.

Deploy trained models to production environments including ONNX export, code generation, and embedded systems.

## ONNX Export/Import

### Exporting to ONNX

```matlab
% Export trained network to ONNX
net = resnet50;  % Or your trained network

% Basic export
exportONNXNetwork(net, 'model.onnx');

% With specified opset version
exportONNXNetwork(net, 'model.onnx', 'OpsetVersion', 13);

% Export dlnetwork
dlnet = dlnetwork(layerGraph(net));
exportONNXNetwork(dlnet, 'model.onnx');
```

### Importing from ONNX

```matlab
% Import ONNX model
net = importONNXNetwork('model.onnx', ...
    'OutputLayerType', 'classification', ...
    'ClassNames', ["cat", "dog", "bird"]);

% For regression
net = importONNXNetwork('model.onnx', ...
    'OutputLayerType', 'regression');

% As dlnetwork (for custom training)
net = importONNXNetwork('model.onnx', ...
    'TargetNetwork', 'dlnetwork');

% Import as layer graph (for modifications)
lgraph = importONNXLayers('model.onnx');
analyzeNetwork(lgraph);
```

### ONNX Compatibility

```matlab
% Check exportability
layers = net.Layers;
unsupported = [];
for i = 1:numel(layers)
    try
        % Test export of single layer type
        testNet = dlnetwork([
            imageInputLayer([1 1 1])
            layers(i)]);
    catch
        unsupported = [unsupported; {class(layers(i))}];
    end
end

if ~isempty(unsupported)
    fprintf('Unsupported layers for ONNX:\n');
    disp(unique(unsupported));
end
```

## TensorFlow/PyTorch Import

### Import TensorFlow Models

```matlab
% Import SavedModel format
net = importTensorFlowNetwork('saved_model/', ...
    'OutputLayerType', 'classification');

% Import Keras H5
net = importKerasNetwork('model.h5', ...
    'OutputLayerType', 'classification', ...
    'ClassNames', categories);

% As layer graph for modifications
lgraph = importKerasLayers('model.h5');
lgraph = removeLayers(lgraph, 'old_output');
lgraph = addLayers(lgraph, fullyConnectedLayer(10, 'Name', 'new_fc'));
```

### Import PyTorch via ONNX

```matlab
% In Python: export PyTorch model to ONNX
% torch.onnx.export(model, dummy_input, 'model.onnx')

% In MATLAB: import ONNX
net = importONNXNetwork('model.onnx', ...
    'TargetNetwork', 'dlnetwork');
```

## GPU Coder

### Generate CUDA Code

```matlab
% Requires GPU Coder
cfg = coder.gpuConfig('lib');
cfg.TargetLang = 'C++';
cfg.GenerateReport = true;

% Define entry-point function
% myPredict.m:
% function Y = myPredict(X)
%     persistent net;
%     if isempty(net)
%         net = coder.loadDeepLearningNetwork('model.mat');
%     end
%     Y = predict(net, X);
% end

% Generate code
codegen -config cfg myPredict -args {ones(224,224,3,'single')}
```

### TensorRT Integration

```matlab
% Generate TensorRT-optimized code
cfg = coder.gpuConfig('lib');
cfg.DeepLearningConfig = coder.DeepLearningConfig('tensorrt');
cfg.DeepLearningConfig.DataType = 'int8';  % Quantization

% Calibration for INT8
cfg.DeepLearningConfig.CalibrationResultFile = 'calibration.mat';

% Generate
codegen -config cfg myPredict -args {ones(224,224,3,'single')}
```

### cuDNN Code Generation

```matlab
% Use cuDNN for inference
cfg = coder.gpuConfig('lib');
cfg.DeepLearningConfig = coder.DeepLearningConfig('cudnn');

% Specify compute capability
cfg.GpuConfig.ComputeCapability = '8.6';  % RTX 30xx

codegen -config cfg myPredict -args {ones(224,224,3,'single')}
```

## MATLAB Coder (CPU)

### Generate Standalone Executable

```matlab
% Create configuration
cfg = coder.config('exe');
cfg.TargetLang = 'C++';
cfg.GenerateReport = true;

% Entry-point function
% predict_image.m:
% function label = predict_image(imagePath)
%     persistent net;
%     if isempty(net)
%         net = coder.loadDeepLearningNetwork('model.mat');
%     end
%     img = imread(imagePath);
%     img = imresize(img, [224 224]);
%     label = classify(net, img);
% end

% Generate executable
codegen -config cfg predict_image -args {coder.typeof('a', [1 256])}
```

### Generate Shared Library (DLL/SO)

```matlab
cfg = coder.config('dll');
cfg.TargetLang = 'C++';

% Add Intel MKL-DNN for CPU acceleration
cfg.DeepLearningConfig = coder.DeepLearningConfig('mkldnn');

codegen -config cfg myPredict -args {ones(224,224,3,'single')}
```

## Quantization

### Post-Training Quantization

```matlab
% Calibration data
calibrationData = imageDatastore('calibration_images/');

% Create quantized network
quantizedNet = quantize(net, calibrationData, ...
    'Precision', 'int8', ...
    'ExecutionEnvironment', 'gpu');

% Evaluate accuracy loss
YPred_fp32 = classify(net, testData);
YPred_int8 = classify(quantizedNet, testData);

fprintf('FP32 Accuracy: %.2f%%\n', mean(YPred_fp32 == testLabels) * 100);
fprintf('INT8 Accuracy: %.2f%%\n', mean(YPred_int8 == testLabels) * 100);
```

### Quantization-Aware Training

```matlab
% Enable quantization during training
options = trainingOptions('adam', ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 32, ...
    'Quantization', 'int8');

% Train with quantization
quantizedNet = trainNetwork(trainDs, lgraph, options);
```

## Model Optimization

### Pruning (Remove Unimportant Weights)

```matlab
% Analyze weight magnitudes
for i = 1:numel(net.Layers)
    layer = net.Layers(i);
    if isprop(layer, 'Weights')
        weights = layer.Weights;
        sparsity = sum(abs(weights(:)) < 0.01) / numel(weights);
        fprintf('%s: %.1f%% near-zero weights\n', layer.Name, sparsity*100);
    end
end

% Manual pruning (zero out small weights)
function net = pruneNetwork(net, threshold)
    lgraph = layerGraph(net);
    for i = 1:numel(lgraph.Layers)
        layer = lgraph.Layers(i);
        if isprop(layer, 'Weights')
            weights = layer.Weights;
            mask = abs(weights) >= threshold;
            layer.Weights = weights .* mask;
            lgraph = replaceLayer(lgraph, layer.Name, layer);
        end
    end
    net = dlnetwork(lgraph);
end
```

### Knowledge Distillation

```matlab
% Teacher network (large, accurate)
teacher = resnet101;

% Student network (small, fast)
studentLayers = [
    imageInputLayer([224 224 3])
    convolution2dLayer(3, 32, 'Padding', 'same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)
    % ... smaller architecture
    fullyConnectedLayer(1000)
    softmaxLayer];

student = dlnetwork(studentLayers);

% Distillation loss
function loss = distillationLoss(studentOutput, teacherOutput, targets, temperature, alpha)
    % Soft targets from teacher
    softTeacher = softmax(teacherOutput / temperature);
    softStudent = softmax(studentOutput / temperature);

    % KL divergence between soft outputs
    kl = sum(softTeacher .* log(softTeacher ./ (softStudent + 1e-8)), 1);
    kl = mean(kl, 'all');

    % Hard target loss
    ce = crossentropy(softmax(studentOutput), targets);

    % Combined loss
    loss = alpha * temperature^2 * kl + (1 - alpha) * ce;
end

% Train student with distillation
function [loss, gradients] = studentLoss(student, teacher, X, T, temp, alpha)
    % Teacher inference (no gradients)
    teacherOut = predict(teacher, X);

    % Student forward
    studentOut = forward(student, X);

    % Distillation loss
    loss = distillationLoss(studentOut, teacherOut, T, temp, alpha);

    % Gradients only for student
    gradients = dlgradient(loss, student.Learnables);
end
```

## Embedded Deployment

### ARM Deployment (Raspberry Pi, Jetson)

```matlab
% Generate ARM code
cfg = coder.config('lib');
cfg.TargetLang = 'C++';
cfg.Hardware = coder.hardware('Raspberry Pi');

% Or for Jetson
cfg.Hardware = coder.hardware('NVIDIA Jetson');
cfg.DeepLearningConfig = coder.DeepLearningConfig('tensorrt');

codegen -config cfg myPredict -args {ones(224,224,3,'single')}
```

### FPGA Deployment

```matlab
% Requires Deep Learning HDL Toolbox
hTarget = dlhdl.Target('Xilinx', 'Interface', 'Ethernet');

% Create workflow
hW = dlhdl.Workflow('Network', net, 'Bitstream', 'zcu102_single', ...
    'Target', hTarget);

% Compile
hW.compile;

% Deploy
hW.deploy;

% Run inference
[YPred, speed] = hW.predict(testImage);
fprintf('Prediction: %s, Speed: %.2f ms\n', YPred, speed);
```

## Serving Models

### REST API with MATLAB Production Server

```matlab
% Create deployable archive
mcc -W CTF:myModel -T link:lib predict_function.m

% Deploy to MATLAB Production Server
% Use MATLAB Web App Server for HTTP endpoint

% Client code (from any language)
% POST /myModel/predict
% Body: {"image": base64_encoded_image}
```

### Docker Container

```matlab
% Create container with MATLAB Runtime
% Dockerfile:
% FROM mathworks/matlab-runtime:R2024b
% COPY predict_function.ctf /app/
% CMD ["./run_predict.sh"]

% Generate CTF archive
mcc -m predict_function.m -d ./deploy
```

## Complete Deployment Example

```matlab
%% Train and Export Model for Production

% 1. Train network
net = trainNetwork(trainDs, lgraph, options);

% 2. Save network
save('trained_model.mat', 'net');

% 3. Create prediction function
% predict_wrapper.m:
function [label, score] = predict_wrapper(img)
    persistent net;
    if isempty(net)
        data = coder.load('trained_model.mat');
        net = data.net;
    end

    % Preprocess
    img = imresize(img, [224 224]);
    img = im2single(img);
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end

    % Predict
    [label, score] = classify(net, img);
end

% 4. Generate code
cfg = coder.gpuConfig('lib');
cfg.DeepLearningConfig = coder.DeepLearningConfig('tensorrt');
cfg.DeepLearningConfig.DataType = 'fp16';

codegen -config cfg predict_wrapper -args {ones(512,512,3,'uint8')}

% 5. Export to ONNX for cross-platform deployment
exportONNXNetwork(net, 'model.onnx', 'OpsetVersion', 13);

%% Verify deployment
% Test original
[label1, score1] = classify(net, testImg);

% Test ONNX reimport
netOnnx = importONNXNetwork('model.onnx', 'TargetNetwork', 'dlnetwork');
scores = predict(netOnnx, dlarray(im2single(testImg), 'SSC'));
[~, idx] = max(scores);

fprintf('Original: %s (%.2f)\n', label1, max(score1));
fprintf('ONNX: class %d (%.2f)\n', idx, max(extractdata(scores)));
```

## Performance Benchmarking

```matlab
% Benchmark inference speed
function benchmarkInference(net, inputSize, numIterations)
    X = randn(inputSize, 'single');
    X_gpu = gpuArray(X);

    % Warmup
    for i = 1:10
        predict(net, X_gpu);
    end

    % Benchmark
    times = zeros(numIterations, 1);
    for i = 1:numIterations
        tic;
        Y = predict(net, X_gpu);
        wait(gpuDevice);  % Ensure completion
        times(i) = toc;
    end

    fprintf('Input size: %s\n', mat2str(inputSize));
    fprintf('Mean inference time: %.2f ms\n', mean(times) * 1000);
    fprintf('Std: %.2f ms\n', std(times) * 1000);
    fprintf('Throughput: %.1f images/sec\n', 1 / mean(times));
end

% Usage
benchmarkInference(net, [224 224 3 1], 100);    % Single image
benchmarkInference(net, [224 224 3 32], 100);   % Batch of 32
```

---

*Source: Deep Learning Toolbox Documentation - Deployment (R2025b)*
