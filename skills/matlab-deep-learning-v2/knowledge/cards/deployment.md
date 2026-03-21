# Deployment & Export -- Brief Reference

Quick reference for model export, code generation, and deployment. See `scripts/template_model_export_onnx.m` for a complete ONNX export template.

## ONNX Export/Import

```matlab
% Export dlnetwork to ONNX
exportONNXNetwork(net, 'model.onnx', 'OpsetVersion', 13);

% Import ONNX model
net = importONNXNetwork('model.onnx', 'TargetNetwork', 'dlnetwork');

% Import as layer graph for modifications
lgraph = importONNXLayers('model.onnx');
```

## TensorFlow/PyTorch Import

```matlab
net = importTensorFlowNetwork('saved_model/', 'OutputLayerType', 'classification');
net = importKerasNetwork('model.h5', 'OutputLayerType', 'classification');
% PyTorch: export to ONNX first, then importONNXNetwork
```

## GPU Coder (CUDA/TensorRT)

```matlab
cfg = coder.gpuConfig('lib');
cfg.DeepLearningConfig = coder.DeepLearningConfig('tensorrt');
cfg.DeepLearningConfig.DataType = 'fp16';  % or 'int8'
codegen -config cfg myPredict -args {ones(224,224,3,'single')}
```

## Quantization

```matlab
calibrationData = imageDatastore('calibration_images/');
quantizedNet = quantize(net, calibrationData, 'Precision', 'int8');
```

## Embedded Targets

```matlab
% Raspberry Pi
cfg.Hardware = coder.hardware('Raspberry Pi');
% NVIDIA Jetson
cfg.Hardware = coder.hardware('NVIDIA Jetson');
% FPGA (Deep Learning HDL Toolbox)
hW = dlhdl.Workflow('Network', net, 'Bitstream', 'zcu102_single', 'Target', hTarget);
```

## Inference Benchmarking

```matlab
function benchmarkInference(net, inputSize, numIterations)
    X_gpu = gpuArray(randn(inputSize, 'single'));
    for i = 1:10, predict(net, X_gpu); end  % Warmup
    times = zeros(numIterations, 1);
    for i = 1:numIterations
        tic; predict(net, X_gpu); wait(gpuDevice); times(i) = toc;
    end
    fprintf('Mean: %.2f ms, Throughput: %.1f img/s\n', mean(times)*1000, 1/mean(times));
end
```

---

*Verified against MATLAB R2025b*
