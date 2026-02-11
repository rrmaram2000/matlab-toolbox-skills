---
name: matlab-deep-learning
description: "MATLAB Deep Learning Toolbox. Functions - trainNetwork, trainnet, trainingOptions, unetLayers, unet, deeplabv3plusLayers, deeplabv3plus, semanticseg, yolov4ObjectDetector, fasterRCNNObjectDetector, maskrcnn, resnet50, vgg16, efficientnetb0, dlarray, dlfeval, dlgradient, adamupdate, dlnetwork, imageDatastore, augmentedImageDatastore, minibatchqueue. Tasks - train a deep learning model, classify medical images, build a CNN classifier, segment tumors or organs, detect objects or nodules in images, fine-tune a pretrained network, set up transfer learning, create a U-Net for segmentation, train with custom loss function, augment training data, deploy model to ONNX, run training on GPU, build a 3D volumetric network, compare model architectures, improve training accuracy, reduce overfitting, handle class imbalance. Domains - MRI, CT, X-ray, PET, histopathology, dermatology, retinal imaging, cell detection, medical image classification, lesion segmentation, nodule detection, pathology grading."
---

# MATLAB Deep Learning Toolbox

Expert skill for deep learning in MATLAB, focused on medical image analysis workflows.

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

| Task | Knowledge Card | Key Functions |
|------|----------------|---------------|
| **Classify images** | `cards/classification.md` | `trainNetwork`, `classify`, pretrained nets |
| **Transfer learning** | `cards/classification.md` | `resnet50`, `layerGraph`, replace layers |
| **Semantic segmentation** | `cards/segmentation-semantic.md` | `unetLayers`, `deeplabv3plusLayers`, `semanticseg` |
| **Instance segmentation** | `cards/segmentation-instance.md` | `maskrcnn`, Mask R-CNN |
| **Object detection** | `cards/object-detection.md` | `yolov4ObjectDetector`, `fasterRCNNObjectDetector` |
| **Custom training** | `cards/custom-training.md` | `dlarray`, `dlfeval`, `dlgradient`, `adamupdate` |
| **Data pipelines** | `cards/data-pipeline.md` | `imageDatastore`, `augmentedImageDatastore`, `minibatchqueue` |
| **Network layers** | `cards/network-architecture.md` | `dlnetwork`, `layerGraph`, custom layers |
| **GPU/parallel** | `cards/gpu-parallel.md` | `gpuArray`, `'ExecutionEnvironment'`, multi-GPU |
| **Deploy models** | `cards/deployment.md` | `exportONNXNetwork`, GPU Coder |
| **Medical workflows** | `cards/medical-imaging.md` | 3D networks, DICOM pipelines |

## ⚠️ IMPORTANT: API Changes in R2024b+

Several functions shown in this skill are **deprecated** in R2024b and later. Use the modern equivalents for new projects:

| Deprecated Function | Modern Replacement | Notes |
|---------------------|-------------------|-------|
| `trainNetwork` | `trainnet` | Returns `dlnetwork` instead of `DAGNetwork` |
| `unetLayers` | `unet` | Returns `dlnetwork` directly |
| `unet3dLayers` | `unet3d` | Returns `dlnetwork` directly |
| `deeplabv3plusLayers` | `deeplabv3plus` | Returns `dlnetwork` directly |
| `classificationLayer` | Use `trainnet` with `"crossentropy"` loss | Loss specified at training time |
| `pixelClassificationLayer` | Use `trainnet` with `"crossentropy"` loss | For segmentation |

**Modern pattern:**
```matlab
net = dlnetwork(lgraph);           % Create dlnetwork
net = trainnet(ds, net, "crossentropy", opts);  % Train with loss function
```

The examples below use the legacy API for compatibility with pre-R2024b code.

---

## Critical Rules

### Rule 1: Data Type and Normalization

```matlab
% WRONG: Using uint8 directly
net = trainNetwork(uint8Images, labels, layers, options);  % Poor convergence

% CORRECT: Normalize to [0,1] or [-1,1]
images = im2single(uint8Images);  % Now [0,1]
% Or for pretrained networks expecting specific preprocessing:
images = (im2single(uint8Images) - 0.485) / 0.229;  % ImageNet normalization
```

### Rule 2: Match Input Sizes

```matlab
% Check network input size
inputSize = net.Layers(1).InputSize;  % e.g., [224 224 3]

% Resize images to match
augDs = augmentedImageDatastore(inputSize(1:2), imds);
% Or
images = imresize(images, inputSize(1:2));
```

### Rule 3: dlarray Format Strings

```matlab
% Format: S=Spatial, C=Channel, B=Batch, T=Time, U=Unspecified
x = dlarray(data, 'SSCB');    % H×W×C×B (standard image batch)
x = dlarray(data, 'SSSCB');   % H×W×D×C×B (3D volume batch)
x = dlarray(data, 'CBT');     % C×B×T (sequence)

% Common error: wrong format causes dimension mismatch
% WRONG: x = dlarray(data, 'BCSS');  % Batch and Channel swapped
```

### Rule 4: Gradient Computation

```matlab
% Gradients only flow through dlarray operations
% WRONG: Using non-differentiable ops
mask = Y > 0.5;  % Thresholding breaks gradient flow

% CORRECT: Use soft operations
mask = sigmoid((Y - 0.5) * 10);  % Differentiable approximation
```

### Rule 5: GPU Memory Management

```matlab
% Check available GPU memory before training
gpu = gpuDevice;
fprintf('Available: %.2f GB\n', gpu.AvailableMemory/1e9);

% Reduce batch size if OOM
options = trainingOptions('adam', 'MiniBatchSize', 8);  % Start small

% Clear GPU memory between experiments
reset(gpuDevice);
```

## Transform Selection

```
Task?
├── Image Classification
│   ├── Binary/Multiclass → trainNetwork + softmax + crossentropy
│   └── Multi-label → trainNetwork + sigmoid + binary crossentropy
├── Segmentation
│   ├── Semantic (pixel labels) → unetLayers/deeplabv3plusLayers + semanticseg
│   ├── Instance (object masks) → Mask R-CNN
│   └── 3D volumetric → unet3dLayers
├── Object Detection
│   ├── Real-time → YOLO v4 (yolov4ObjectDetector)
│   ├── High accuracy → Faster R-CNN (fasterRCNNObjectDetector)
│   └── Small objects → RetinaNet
├── Custom Architecture
│   └── dlnetwork + custom training loop + dlfeval/dlgradient
└── Generative
    ├── Image synthesis → GAN (generator + discriminator)
    └── Variational → VAE with reparameterization
```

## Quick Patterns

### Transfer Learning (Classification)

```matlab
% Load pretrained network
net = resnet50;
lgraph = layerGraph(net);

% Replace final layers for your classes
numClasses = 4;  % e.g., Normal, Pneumonia, COVID, TB
lgraph = removeLayers(lgraph, {'fc1000', 'fc1000_softmax', 'ClassificationLayer_fc1000'});
newLayers = [
    fullyConnectedLayer(numClasses, 'Name', 'fc_new')
    softmaxLayer('Name', 'softmax_new')
    classificationLayer('Name', 'output')];
lgraph = addLayers(lgraph, newLayers);
lgraph = connectLayers(lgraph, 'avg_pool', 'fc_new');

% Train
options = trainingOptions('adam', ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-4, ...
    'ValidationData', valDs, ...
    'Plots', 'training-progress');
trainedNet = trainNetwork(trainDs, lgraph, options);  % Legacy API
% Modern: net = trainnet(trainDs, dlnetwork(lgraph), "crossentropy", options);
```

### U-Net Segmentation

```matlab
% Create U-Net for medical image segmentation
imageSize = [256 256 1];
numClasses = 2;  % Background + Lesion

% Legacy API (deprecated in R2024b+, use unet() instead):
lgraph = unetLayers(imageSize, numClasses, ...
    'EncoderDepth', 4, ...
    'NumFirstEncoderFilters', 64);  % Default is 64, not 32

% Modern API (R2024b+):
% net = unet(imageSize, numClasses, EncoderDepth=4);

% Prepare pixel label datastore
classNames = ["Background", "Lesion"];
pixelLabelIDs = [0, 1];
pxds = pixelLabelDatastore('masks/', classNames, pixelLabelIDs);
ds = combine(imageDatastore('images/'), pxds);

% Train with dice loss
options = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-3);
net = trainNetwork(ds, lgraph, options);  % Legacy API
% Modern: net = trainnet(ds, dlnetwork(lgraph), "crossentropy", options);

% Inference
mask = semanticseg(testImage, net);
```

### Custom Training Loop

```matlab
% For advanced control: custom loss, metrics, logging
net = dlnetwork(lgraph);
numEpochs = 50;
learnRate = 1e-3;
[avgGrad, avgSqGrad] = deal([]);

for epoch = 1:numEpochs
    shuffle(mbq);
    while hasdata(mbq)
        [X, Y] = next(mbq);

        % Forward + backward
        [loss, gradients, state] = dlfeval(@modelLoss, net, X, Y);
        net.State = state;

        % Update with Adam
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

### Object Detection (YOLO)

```matlab
% Create YOLO v4 detector
detector = yolov4ObjectDetector('csp-darknet53-coco');

% For custom classes, create from scratch
name = "nodule_detector";
classes = ["nodule"];
anchorBoxes = {[32 32; 64 64]; [128 128; 256 256]};  % Multi-scale
detector = yolov4ObjectDetector(name, classes, anchorBoxes, ...
    'InputSize', [416 416 3]);

% Train
options = trainingOptions('adam', ...
    'MaxEpochs', 80, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-3);
[detector, info] = trainYOLOv4ObjectDetector(trainData, detector, options);

% Detect
[bboxes, scores, labels] = detect(detector, testImage);
```

## Function Quick Reference

### Network Training

| Function | Purpose | Example |
|----------|---------|---------|
| `trainNetwork` | Train from layers/lgraph | `net = trainNetwork(ds, layers, opts)` |
| `trainnet` | Train dlnetwork with loss | `net = trainnet(ds, net, lossFcn, opts)` |
| `trainingOptions` | Configure training | `opts = trainingOptions('adam', ...)` |

### Network Architecture

| Function | Purpose | Example |
|----------|---------|---------|
| `dlnetwork` | Create trainable network | `net = dlnetwork(lgraph)` |
| `layerGraph` | Network with branches | `lgraph = layerGraph(net)` |
| `addLayers` | Add layers to graph | `lgraph = addLayers(lgraph, newLayers)` |
| `connectLayers` | Connect layer outputs | `lgraph = connectLayers(lgraph, src, dst)` |
| `removeLayers` | Remove layers | `lgraph = removeLayers(lgraph, names)` |

### Segmentation

| Function | Purpose | Example |
|----------|---------|---------|
| `unetLayers` | Create U-Net | `lgraph = unetLayers([256 256 1], 2)` |
| `unet3dLayers` | Create 3D U-Net | `lgraph = unet3dLayers([128 128 128 1], 2)` |
| `deeplabv3plusLayers` | Create DeepLabv3+ | `lgraph = deeplabv3plusLayers(...)` |
| `semanticseg` | Pixel classification | `mask = semanticseg(img, net)` |
| `pixelLabelDatastore` | Label datastore | `pxds = pixelLabelDatastore(...)` |

### Object Detection

| Function | Purpose | Example |
|----------|---------|---------|
| `yolov4ObjectDetector` | YOLO v4 detector | `det = yolov4ObjectDetector(...)` |
| `fasterRCNNObjectDetector` | Faster R-CNN | `det = fasterRCNNObjectDetector(...)` |
| `ssdObjectDetector` | SSD detector | `det = ssdObjectDetector(...)` |
| `detect` | Run detection | `[bboxes, scores] = detect(det, img)` |
| `trainYOLOv4ObjectDetector` | Train YOLO | `det = trainYOLOv4ObjectDetector(...)` |

### Custom Training

| Function | Purpose | Example |
|----------|---------|---------|
| `dlarray` | Differentiable array | `x = dlarray(data, 'SSCB')` |
| `dlfeval` | Evaluate with gradients | `[loss, grad] = dlfeval(@fn, net, x)` |
| `dlgradient` | Compute gradients | `grad = dlgradient(loss, params)` |
| `adamupdate` | Adam optimizer step | `[net, ag, asg] = adamupdate(...)` |
| `sgdmupdate` | SGD with momentum | `[net, vel] = sgdmupdate(...)` |
| `forward` | Forward pass | `[y, state] = forward(net, x)` |
| `predict` | Inference (no gradients) | `y = predict(net, x)` |

### Data Handling

| Function | Purpose | Example |
|----------|---------|---------|
| `imageDatastore` | Image folder datastore | `imds = imageDatastore(folder)` |
| `augmentedImageDatastore` | With augmentation | `augDs = augmentedImageDatastore(...)` |
| `imageDataAugmenter` | Define augmentations | `aug = imageDataAugmenter(...)` |
| `minibatchqueue` | Custom batching | `mbq = minibatchqueue(ds, ...)` |
| `transform` | Apply function | `tds = transform(ds, @myFcn)` |
| `combine` | Combine datastores | `cds = combine(imds, labelds)` |

### Pretrained Networks

| Network | Function | Input Size | Use Case |
|---------|----------|------------|----------|
| ResNet-50 | `resnet50` | 224×224 | General classification |
| ResNet-101 | `resnet101` | 224×224 | Higher capacity |
| VGG-16 | `vgg16` | 224×224 | Feature extraction |
| EfficientNet-B0 | `efficientnetb0` | 224×224 | Efficient inference |
| Inception-v3 | `inceptionv3` | 299×299 | Fine details |
| DenseNet-201 | `densenet201` | 224×224 | Feature reuse |

## Knowledge Cards Summary

~2,400 lines of curated content:

| Card | Lines | Focus |
|------|-------|-------|
| `classification.md` | ~300 | Transfer learning, pretrained networks |
| `segmentation-semantic.md` | ~350 | U-Net, DeepLabv3+, loss functions |
| `segmentation-instance.md` | ~200 | Mask R-CNN |
| `object-detection.md` | ~300 | YOLO, Faster R-CNN, anchor boxes |
| `custom-training.md` | ~350 | dlarray, gradients, optimizers |
| `data-pipeline.md` | ~250 | Datastores, augmentation |
| `network-architecture.md` | ~200 | Layers, custom layers |
| `gpu-parallel.md` | ~150 | GPU, multi-GPU training |
| `deployment.md` | ~150 | ONNX, code generation |
| `medical-imaging.md` | ~300 | Medical-specific workflows |

See `knowledge/INDEX.md` for full navigation.

## Cross-Toolbox Integration

**For preprocessing → matlab-image-processing-toolbox**
```matlab
% Before DL: enhance, denoise, normalize
img = adapthisteq(img);                    % CLAHE
img = imgaussfilt(img, 1.5);               % Denoise
img = im2single(img);                       % Normalize
```

**For wavelet features → matlab-wavelet-toolbox**
```matlab
% Multi-scale features as network input
[C, S] = wavedec2(img, 3, 'db4');
features = cat(3, appcoef2(C,S,'db4'), ...
    detcoef2('h',C,S,1), detcoef2('v',C,S,1), detcoef2('d',C,S,1));
```

**For medical I/O → matlab-medical-imaging-toolbox**
```matlab
% Load with spatial referencing
V = medicalVolume('brain.nii');
% Process slices for DL
for k = 1:V.NumTransverseSlices
    slice = extractSlice(V, k, 'transverse');
    prediction = semanticseg(slice, net);
end
```

---
*Source: MathWorks Deep Learning Toolbox Documentation (R2025b)*
*Note: Legacy API examples (trainNetwork, unetLayers) shown for compatibility. Use trainnet and unet for new projects.*
