---
name: matlab-deep-learning
description: "MATLAB Deep Learning Toolbox (R2025b). Functions - trainnet, trainingOptions, unet, unet3d, deeplabv3plus, semanticseg, yolov4ObjectDetector, fasterRCNNObjectDetector, maskrcnn, resnet50, efficientnetb0, dlarray, dlfeval, dlgradient, adamupdate, dlnetwork, imageDatastore, augmentedImageDatastore, minibatchqueue. Tasks - train a deep learning model, classify medical images, build a CNN classifier, segment tumors or organs, detect objects or nodules, fine-tune a pretrained network, transfer learning, create a U-Net, train with custom loss, augment training data, deploy model to ONNX, run training on GPU, build a 3D volumetric network, handle class imbalance. Domains - MRI, CT, X-ray, histopathology, dermatology, retinal imaging, cell detection, lesion segmentation, nodule detection."
---

# MATLAB Deep Learning Toolbox (v2.0 -- R2025b)

Expert skill for deep learning in MATLAB, focused on medical image analysis workflows. All examples use the modern R2025b API (`trainnet`, `unet`, `unet3d`, `deeplabv3plus`).

**Cross-Toolbox Note:** For image preprocessing (filtering, morphology), see **matlab-image-processing-toolbox**. For medical I/O (DICOM, NIfTI), see **matlab-medical-imaging-toolbox**. For wavelet features, see **matlab-wavelet-toolbox**.

## When to Use This Skill

- Building CNN classifiers for medical diagnosis (X-ray, dermatology, histopathology)
- Semantic segmentation (U-Net, DeepLabv3+ for organ/lesion segmentation)
- Object detection (YOLO, Faster R-CNN for nodule/cell detection)
- Transfer learning with pretrained networks (ResNet, VGG, EfficientNet)
- Custom training loops with `dlarray` and automatic differentiation
- 3D volumetric deep learning for CT/MRI
- GPU-accelerated training and multi-GPU workflows
- Model deployment (ONNX export, GPU Coder)

## Read Before Coding

| Task | Knowledge Card | Template Script |
|------|----------------|-----------------|
| **Classify images / transfer learning** | `cards/classification-segmentation.md` | `scripts/template_transfer_learning_classification.m` |
| **Semantic segmentation (U-Net)** | `cards/classification-segmentation.md` | `scripts/template_unet_segmentation.m` |
| **DeepLabv3+ segmentation** | `cards/classification-segmentation.md` | `scripts/template_deeplabv3plus_segmentation.m` |
| **3D volumetric segmentation** | `cards/medical-imaging.md` **(CRITICAL)** | `scripts/template_3d_volumetric_segmentation.m` |
| **Object detection** | `cards/detection-instance-seg.md` | `scripts/template_object_detection_yolov4.m` |
| **Instance segmentation** | `cards/detection-instance-seg.md` | `scripts/template_maskrcnn_instance_seg.m` |
| **Custom training loop** | `cards/custom-training.md` | `scripts/template_custom_training_loop.m` |
| **Data augmentation** | `cards/data-pipeline.md` | `scripts/template_data_augmentation_pipeline.m` |
| **Class imbalance** | `cards/classification-segmentation.md` | `scripts/template_class_imbalance_handling.m` |
| **Custom layers / attention** | `cards/network-architecture.md` | -- |
| **GPU / parallel** | `cards/gpu-parallel.md` | -- |
| **Deploy / export** | `cards/deployment.md` | `scripts/template_model_export_onnx.m` |
| **Medical DL workflows** | `cards/medical-imaging.md` **(CRITICAL)** | `scripts/template_3d_volumetric_segmentation.m` |

---

## Critical Rules

### Rule 1: Data Type and Normalization

```matlab
% WRONG: Using uint8 directly -- poor convergence
% CORRECT: Normalize to [0,1] or [-1,1]
images = im2single(uint8Images);  % Now [0,1]
% For pretrained networks expecting ImageNet normalization:
meanRGB = [0.485, 0.456, 0.406];
stdRGB = [0.229, 0.224, 0.225];
images = (im2single(uint8Images) - reshape(meanRGB,1,1,3)) ./ reshape(stdRGB,1,1,3);
```

### Rule 2: Match Input Sizes

```matlab
inputSize = net.Layers(1).InputSize;  % e.g., [224 224 3]
augDs = augmentedImageDatastore(inputSize(1:2), imds);
```

### Rule 3: dlarray Format Strings

```matlab
% Format: S=Spatial, C=Channel, B=Batch, T=Time
x = dlarray(data, 'SSCB');    % H*W*C*B (standard image batch)
x = dlarray(data, 'SSSCB');   % H*W*D*C*B (3D volume batch)
x = dlarray(data, 'CBT');     % C*B*T (sequence)
% Common error: wrong format causes dimension mismatch
```

### Rule 4: Gradient Computation

```matlab
% Gradients only flow through dlarray operations
% WRONG: mask = Y > 0.5;       % Thresholding breaks gradient flow
% CORRECT: mask = sigmoid((Y - 0.5) * 10);  % Differentiable approximation
```

### Rule 5: GPU Memory Management

```matlab
gpu = gpuDevice;
fprintf('Available: %.2f GB\n', gpu.AvailableMemory/1e9);
% Reduce batch size if OOM; clear GPU memory between experiments
reset(gpuDevice);
```

---

## 3D Volumetric Networks (CRITICAL Knowledge)

The `unet3d` function builds a 3D U-Net and returns a `dlnetwork`. This is CRITICAL for CT/MRI volumetric segmentation.

```matlab
% 3D U-Net for volumetric segmentation
imageSize = [128 128 64 1];  % H*W*D*C
numClasses = 3;

% Modern API (R2024b+) -- returns dlnetwork directly
net = unet3d(imageSize, numClasses, ...
    EncoderDepth=3, ...             % Shallower for GPU memory
    NumFirstEncoderFilters=32);     % Fewer filters for 3D

% CRITICAL: Default NumFirstEncoderFilters is 64 (not 32!)
% For 3D, reduce to 32 to fit in GPU memory

% Train with modern API
opts = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 2, ...         % Small batch for 3D
    'InitialLearnRate', 1e-4, ...
    'ExecutionEnvironment', 'gpu');
net = trainnet(ds, net, "crossentropy", opts);
```

### Patch-Based 3D Training (Large Volumes)

```matlab
% Volumes too large for GPU -> extract patches
patchSize = [64 64 64];
stride = [32 32 32];  % 50% overlap

% Use randomPatchExtractionDatastore for efficient training
patchDs = randomPatchExtractionDatastore(imds, pxds, patchSize, ...
    'PatchesPerImage', 16);
```

### 2.5D Approach (Multi-Slice)

```matlab
% Use adjacent slices as channels (compromise between 2D and 3D)
imageSize = [256 256 5];  % 5 adjacent slices as channels
net = unet(imageSize, 2, EncoderDepth=4);
```

---

## Quick Patterns

### Transfer Learning (Classification)

```matlab
net = resnet50;
lgraph = layerGraph(net);

% Replace final layers (modern API -- no classificationLayer)
numClasses = 4;
lgraph = removeLayers(lgraph, {'fc1000', 'fc1000_softmax', 'ClassificationLayer_fc1000'});
newLayers = [
    fullyConnectedLayer(numClasses, 'Name', 'fc_new')
    softmaxLayer('Name', 'softmax_new')];
lgraph = addLayers(lgraph, newLayers);
lgraph = connectLayers(lgraph, 'avg_pool', 'fc_new');

opts = trainingOptions('adam', ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-4, ...
    'ValidationData', valDs, ...
    'Plots', 'training-progress');
net = trainnet(trainDs, dlnetwork(lgraph), "crossentropy", opts);
```

### U-Net Segmentation

```matlab
imageSize = [256 256 1];
numClasses = 2;  % Background + Lesion

% Modern API -- returns dlnetwork directly
% IMPORTANT: Default NumFirstEncoderFilters = 64 (not 32)
net = unet(imageSize, numClasses, EncoderDepth=4);

% Prepare data
classNames = ["Background", "Lesion"];
pixelLabelIDs = [0, 1];
pxds = pixelLabelDatastore('masks/', classNames, pixelLabelIDs);
ds = combine(imageDatastore('images/'), pxds);

% Train
opts = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-3);
net = trainnet(ds, net, "crossentropy", opts);

% Inference
mask = semanticseg(testImage, net);
```

### Custom Training Loop

```matlab
net = dlnetwork(lgraph);
numEpochs = 50;
learnRate = 1e-3;
[avgGrad, avgSqGrad] = deal([]);
iteration = 0;

for epoch = 1:numEpochs
    shuffle(mbq);
    while hasdata(mbq)
        iteration = iteration + 1;
        [X, Y] = next(mbq);
        [loss, gradients, state] = dlfeval(@modelLoss, net, X, Y);
        net.State = state;
        [net, avgGrad, avgSqGrad] = adamupdate(net, gradients, ...
            avgGrad, avgSqGrad, iteration, learnRate);
    end
end

function [loss, gradients, state] = modelLoss(net, X, Y)
    [Ypred, state] = forward(net, X);
    loss = crossentropy(Ypred, Y);
    gradients = dlgradient(loss, net.Learnables);
end
```

---

## Transform Selection

```
Task?
+-- Image Classification
|   +-- Binary/Multiclass -> trainnet + softmax + "crossentropy"
|   +-- Multi-label -> custom loop + sigmoid + binary crossentropy
+-- Segmentation
|   +-- Semantic (pixel labels) -> unet / deeplabv3plus + semanticseg
|   +-- Instance (object masks) -> Mask R-CNN (maskrcnn)
|   +-- 3D volumetric -> unet3d
+-- Object Detection
|   +-- Real-time -> YOLO v4 (yolov4ObjectDetector)
|   +-- High accuracy -> Faster R-CNN (fasterRCNNObjectDetector)
|   +-- Small objects -> RetinaNet
+-- Custom Architecture
|   +-- dlnetwork + custom training loop + dlfeval/dlgradient
+-- Generative
    +-- GAN / VAE with custom training loop
```

## Function Quick Reference

### Core Training

| Function | Purpose |
|----------|---------|
| `trainnet` | Train dlnetwork with loss function string |
| `trainingOptions` | Configure optimizer, scheduler, GPU |
| `trainingProgressMonitor` | Custom progress display |

### Segmentation Networks

| Function | Purpose | Notes |
|----------|---------|-------|
| `unet` | Create 2D U-Net (dlnetwork) | Default `NumFirstEncoderFilters` = **64** |
| `unet3d` | Create 3D U-Net (dlnetwork) | Use `NumFirstEncoderFilters=32` for GPU memory |
| `deeplabv3plus` | Create DeepLabv3+ (dlnetwork) | Backbone: `'resnet50'` |
| `semanticseg` | Pixel classification inference | Works on images or datastores |

### Detection

| Function | Purpose |
|----------|---------|
| `yolov4ObjectDetector` | YOLO v4 detector |
| `fasterRCNNObjectDetector` | Faster R-CNN |
| `maskrcnn` | Mask R-CNN (instance segmentation) |
| `detect` / `segmentObjects` | Run detection / instance seg |

## Template Scripts

Complete, ready-to-adapt template scripts in `scripts/`:

| Script | Description |
|--------|-------------|
| `template_transfer_learning_classification.m` | Fine-tune ResNet-50 or EfficientNet-b0 for medical image classification |
| `template_unet_segmentation.m` | 2D U-Net for organ/tumor segmentation from CT/MRI slices |
| `template_deeplabv3plus_segmentation.m` | DeepLabv3+ with ResNet-50 backbone for histopathology segmentation |
| `template_3d_volumetric_segmentation.m` | 3D U-Net for volumetric CT/MRI segmentation with patch-based training |
| `template_object_detection_yolov4.m` | YOLOv4 for nodule/lesion detection with bounding boxes |
| `template_maskrcnn_instance_seg.m` | Mask R-CNN for cell/nuclei instance segmentation |
| `template_custom_training_loop.m` | Manual training loop with Dice + CE loss, gradient clipping, early stopping |
| `template_data_augmentation_pipeline.m` | Medical augmentation for 2D and 3D data |
| `template_class_imbalance_handling.m` | Weighted CE, oversampling, and focal loss for imbalanced datasets |
| `template_model_export_onnx.m` | Export dlnetwork to ONNX for cross-platform deployment |

## Knowledge Cards Summary

| Card | Priority | Focus |
|------|----------|-------|
| `medical-imaging.md` | **CRITICAL** | 3D volumetric networks, DICOM pipelines, modality preprocessing |
| `classification-segmentation.md` | Reference | Transfer learning, U-Net config, loss functions, evaluation |
| `detection-instance-seg.md` | Reference | YOLO, Faster R-CNN, Mask R-CNN, anchor boxes |
| `custom-training.md` | Reference | Advanced patterns: LR scheduling, gradient accumulation, multi-loss |
| `data-pipeline.md` | Reference | Custom datastores, medical preprocessing, advanced augmentation |
| `network-architecture.md` | Reference | Custom layers, attention, SE blocks |
| `gpu-parallel.md` | Reference | GPU memory management, multi-GPU training |
| `deployment.md` | Reference | ONNX export, GPU Coder, quantization |

See `knowledge/INDEX.md` for full navigation.

## Cross-Toolbox Integration

**For preprocessing -> matlab-image-processing-toolbox**
```matlab
img = adapthisteq(img);         % CLAHE
img = imgaussfilt(img, 1.5);    % Denoise
img = im2single(img);           % Normalize
```

**For wavelet features -> matlab-wavelet-toolbox**
```matlab
[C, S] = wavedec2(img, 3, 'db4');
features = cat(3, appcoef2(C,S,'db4'), ...
    detcoef2('h',C,S,1), detcoef2('v',C,S,1), detcoef2('d',C,S,1));
```

**For medical I/O -> matlab-medical-imaging-toolbox**
```matlab
V = medicalVolume('brain.nii');
for k = 1:V.NumTransverseSlices
    slice = extractSlice(V, k, 'transverse');
    prediction = semanticseg(slice, net);
end
```

---
*Source: MathWorks Deep Learning Toolbox Documentation (R2025b)*
