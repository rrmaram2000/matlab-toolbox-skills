# Knowledge Card Index

Quick reference to all Deep Learning Toolbox knowledge cards.

## Classification & Transfer Learning (1 card)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`classification.md`](cards/classification.md) | Pretrained networks, transfer learning, fine-tuning strategies, feature extraction | `resnet50`, `vgg16`, `trainNetwork`, `layerGraph` |

## Segmentation (2 cards)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`segmentation-semantic.md`](cards/segmentation-semantic.md) | U-Net, DeepLabv3+, SegNet, pixel labeling, dice loss, medical segmentation | `unetLayers`, `deeplabv3plusLayers`, `semanticseg` |
| [`segmentation-instance.md`](cards/segmentation-instance.md) | Mask R-CNN for instance segmentation, cell/nuclei detection | `maskrcnn`, instance masks |

## Object Detection (1 card)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`object-detection.md`](cards/object-detection.md) | YOLO v2/v3/v4, Faster R-CNN, SSD, RetinaNet, anchor boxes, NMS | `yolov4ObjectDetector`, `fasterRCNNObjectDetector`, `detect` |

## Custom Training (1 card)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`custom-training.md`](cards/custom-training.md) | dlarray, automatic differentiation, custom loss functions, optimizers, training loops | `dlarray`, `dlfeval`, `dlgradient`, `adamupdate` |

## Data & Pipelines (1 card)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`data-pipeline.md`](cards/data-pipeline.md) | Datastores, augmentation, minibatch queues, DICOM/NIfTI integration | `imageDatastore`, `augmentedImageDatastore`, `minibatchqueue` |

## Network Architecture (1 card)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`network-architecture.md`](cards/network-architecture.md) | Layer types, dlnetwork, custom layers, attention mechanisms | `dlnetwork`, `layerGraph`, `nnet.layer.Layer` |

## GPU & Deployment (2 cards)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`gpu-parallel.md`](cards/gpu-parallel.md) | GPU acceleration, multi-GPU training, memory management | `gpuArray`, `'ExecutionEnvironment'`, `parpool` |
| [`deployment.md`](cards/deployment.md) | ONNX export/import, GPU Coder, TensorRT, embedded deployment | `exportONNXNetwork`, `importONNXNetwork` |

## Medical Imaging (1 card)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`medical-imaging.md`](cards/medical-imaging.md) | 3D volumetric networks, DICOM workflows, modality-specific preprocessing | `unet3dLayers`, `medicalVolume`, cross-toolbox |

---

## Card Selection Guide

### By Task

| Task | Cards to Read |
|------|---------------|
| Classify X-rays/CT/MRI | `classification.md` |
| Segment organs/lesions | `segmentation-semantic.md`, `medical-imaging.md` |
| Detect cells/nodules | `object-detection.md` |
| Custom loss function | `custom-training.md` |
| Prepare training data | `data-pipeline.md` |
| Design network architecture | `network-architecture.md` |
| Optimize GPU usage | `gpu-parallel.md` |
| Deploy to production | `deployment.md` |

### By Experience Level

**Beginner:**
1. Start with `classification.md` - transfer learning is the easiest path
2. Then `data-pipeline.md` for data preparation
3. Then `segmentation-semantic.md` for pixel-level tasks

**Intermediate:**
- Add `custom-training.md` for custom loss functions
- Add `network-architecture.md` for modifying networks
- Add `gpu-parallel.md` for performance optimization

**Advanced:**
- `object-detection.md` for detection tasks
- `segmentation-instance.md` for Mask R-CNN
- `deployment.md` for production deployment

### By Medical Modality

| Modality | Recommended Cards |
|----------|-------------------|
| **X-ray** | `classification.md`, `segmentation-semantic.md` |
| **CT** | `medical-imaging.md`, `segmentation-semantic.md`, `object-detection.md` |
| **MRI** | `medical-imaging.md`, `segmentation-semantic.md` |
| **Histopathology** | `classification.md`, `segmentation-instance.md` |
| **Ultrasound** | `segmentation-semantic.md`, `data-pipeline.md` |

---

## Cross-References to Other Skills

| Need | Skill | Reason |
|------|-------|--------|
| Image preprocessing | **matlab-image-processing-toolbox** | Filtering, CLAHE, morphology before DL |
| Medical file I/O | **matlab-medical-imaging-toolbox** | DICOM/NIfTI reading with spatial referencing |
| Wavelet features | **matlab-wavelet-toolbox** | Multi-scale features for DL input |
| Statistical evaluation | **matlab-stats-ml** | ROC curves, cross-validation metrics |

---

## Function Quick Reference by Category

### Training
| Function | Purpose |
|----------|---------|
| `trainNetwork` | Standard training |
| `trainnet` | dlnetwork with custom loss |
| `trainingOptions` | Configure optimizer/scheduler |
| `trainingProgressMonitor` | Custom progress display |

### Architecture
| Function | Purpose |
|----------|---------|
| `dlnetwork` | Trainable network object |
| `layerGraph` | Network with branches |
| `addLayers` / `removeLayers` | Modify graph |
| `connectLayers` | Wire layer outputs |

### Segmentation
| Function | Purpose |
|----------|---------|
| `unetLayers` | Create 2D U-Net |
| `unet3dLayers` | Create 3D U-Net |
| `deeplabv3plusLayers` | Create DeepLabv3+ |
| `semanticseg` | Pixel classification inference |
| `evaluateSemanticSegmentation` | Compute IoU, accuracy |

### Detection
| Function | Purpose |
|----------|---------|
| `yolov4ObjectDetector` | YOLO v4 |
| `fasterRCNNObjectDetector` | Faster R-CNN |
| `detect` | Run detection |
| `evaluateObjectDetection` | Compute mAP |

### Custom Training
| Function | Purpose |
|----------|---------|
| `dlarray` | Differentiable array |
| `dlfeval` | Evaluate with gradients |
| `dlgradient` | Compute gradients |
| `adamupdate` | Adam optimizer |
| `sgdmupdate` | SGD with momentum |

### Data
| Function | Purpose |
|----------|---------|
| `imageDatastore` | Load images from folder |
| `pixelLabelDatastore` | Load segmentation masks |
| `boxLabelDatastore` | Load detection annotations |
| `augmentedImageDatastore` | On-the-fly augmentation |
| `minibatchqueue` | Custom batching for dlarray |

---

*Navigation: Return to [SKILL.md](../SKILL.md) for overview*
