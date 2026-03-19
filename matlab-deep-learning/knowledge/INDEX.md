# Knowledge Card Index (v2.0)

Quick reference to all Deep Learning Toolbox knowledge cards and template scripts.

## Knowledge Cards

### CRITICAL Cards (High-Value Knowledge)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`medical-imaging.md`](cards/medical-imaging.md) | **3D volumetric networks (unet3d), DICOM/NIfTI workflows, modality-specific preprocessing, patch-based training** | `unet3d`, `medicalVolume`, cross-toolbox |

### Reference Cards

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`classification-segmentation.md`](cards/classification-segmentation.md) | Transfer learning, U-Net/DeepLabv3+ configuration, loss functions (Dice, Tversky, Focal), class imbalance, evaluation | `unet`, `deeplabv3plus`, `trainnet`, `semanticseg` |
| [`detection-instance-seg.md`](cards/detection-instance-seg.md) | YOLO v4, Faster R-CNN, SSD, RetinaNet, Mask R-CNN, anchor box estimation, FROC analysis | `yolov4ObjectDetector`, `maskrcnn`, `detect` |
| [`custom-training.md`](cards/custom-training.md) | Advanced training patterns: LR scheduling, gradient accumulation, multi-loss, early stopping | `adamupdate`, `dlgradient`, `dlupdate` |
| [`data-pipeline.md`](cards/data-pipeline.md) | Custom datastores, medical preprocessing, elastic deformation, MixUp, large dataset strategies | `minibatchqueue`, `blockedImage`, custom datastores |
| [`network-architecture.md`](cards/network-architecture.md) | Custom layers, Squeeze-and-Excitation blocks, self-attention, encoder-decoder, FPN | `nnet.layer.Layer`, `layerGraph` |
| [`gpu-parallel.md`](cards/gpu-parallel.md) | GPU memory management, multi-GPU training, parallel data loading, profiling | `gpuDevice`, `gpuArray`, `parpool` |
| [`deployment.md`](cards/deployment.md) | ONNX export/import, GPU Coder, TensorRT, quantization, embedded deployment | `exportONNXNetwork`, `importONNXNetwork` |

---

## Template Scripts (in `scripts/`)

Ready-to-adapt MATLAB scripts using modern R2025b API.

| Script | Description |
|--------|-------------|
| [`template_transfer_learning_classification.m`](../scripts/template_transfer_learning_classification.m) | Fine-tune ResNet-50 or EfficientNet-b0 for medical image classification |
| [`template_unet_segmentation.m`](../scripts/template_unet_segmentation.m) | 2D U-Net for organ/tumor segmentation from CT/MRI slices |
| [`template_deeplabv3plus_segmentation.m`](../scripts/template_deeplabv3plus_segmentation.m) | DeepLabv3+ with ResNet-50 backbone for histopathology segmentation |
| [`template_3d_volumetric_segmentation.m`](../scripts/template_3d_volumetric_segmentation.m) | 3D U-Net for volumetric CT/MRI segmentation with patch-based training |
| [`template_object_detection_yolov4.m`](../scripts/template_object_detection_yolov4.m) | YOLOv4 for nodule/lesion detection with bounding boxes |
| [`template_maskrcnn_instance_seg.m`](../scripts/template_maskrcnn_instance_seg.m) | Mask R-CNN for cell/nuclei instance segmentation |
| [`template_custom_training_loop.m`](../scripts/template_custom_training_loop.m) | Manual training loop with Dice + CE loss, gradient clipping, early stopping |
| [`template_data_augmentation_pipeline.m`](../scripts/template_data_augmentation_pipeline.m) | Medical augmentation for 2D and 3D data |
| [`template_class_imbalance_handling.m`](../scripts/template_class_imbalance_handling.m) | Weighted CE, oversampling, and focal loss for imbalanced datasets |
| [`template_model_export_onnx.m`](../scripts/template_model_export_onnx.m) | Export dlnetwork to ONNX for cross-platform deployment |

---

## Card Selection Guide

### By Task

| Task | Cards to Read | Template Script |
|------|---------------|-----------------|
| Classify X-rays/CT/MRI | `classification-segmentation.md` | `template_transfer_learning_classification.m` |
| Segment organs/lesions (2D) | `classification-segmentation.md` | `template_unet_segmentation.m` |
| Segment volumes (3D) | `medical-imaging.md` **(CRITICAL)** | `template_3d_volumetric_segmentation.m` |
| Detect cells/nodules | `detection-instance-seg.md` | `template_object_detection_yolov4.m` |
| Instance segmentation | `detection-instance-seg.md` | `template_maskrcnn_instance_seg.m` |
| Custom loss function | `custom-training.md` | `template_custom_training_loop.m` |
| Prepare training data | `data-pipeline.md` | `template_data_augmentation_pipeline.m` |
| Design custom network | `network-architecture.md` | -- |
| Optimize GPU usage | `gpu-parallel.md` | -- |
| Deploy to production | `deployment.md` | `template_model_export_onnx.m` |

### By Medical Modality

| Modality | Recommended Cards |
|----------|-------------------|
| **CT** | `medical-imaging.md` **(CRITICAL)**, `classification-segmentation.md` |
| **MRI** | `medical-imaging.md` **(CRITICAL)**, `classification-segmentation.md` |
| **X-ray** | `classification-segmentation.md`, `data-pipeline.md` |
| **Histopathology** | `classification-segmentation.md`, `detection-instance-seg.md` |
| **Ultrasound** | `classification-segmentation.md`, `data-pipeline.md` |

---

## Cross-References to Other Skills

| Need | Skill | Reason |
|------|-------|--------|
| Image preprocessing | **matlab-image-processing-toolbox** | Filtering, CLAHE, morphology before DL |
| Medical file I/O | **matlab-medical-imaging-toolbox** | DICOM/NIfTI reading with spatial referencing |
| Wavelet features | **matlab-wavelet-toolbox** | Multi-scale features for DL input |
| Statistical evaluation | **matlab-stats-ml** | ROC curves, cross-validation metrics |

---

*Navigation: Return to [SKILL.md](../SKILL.md) for overview*
