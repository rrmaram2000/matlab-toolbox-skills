# MATLAB Toolbox Skills for Claude

<p align="center">
  <a href="LICENSE"><img src="https://licensebuttons.net/l/by/4.0/88x31.png" alt="CC BY 4.0"></a>
  <img src="https://img.shields.io/badge/MATLAB-R2025b-orange.svg" alt="MATLAB R2025b">
  <img src="https://img.shields.io/badge/version-2.0-blue.svg" alt="v2.0">
</p>

As a biomedical engineering PhD student, I use MATLAB daily for medical image analysis. These skills give Claude specialized knowledge for MATLAB's medical imaging toolboxes — including **54 runnable template scripts** for common biomedical workflows, edge-case API knowledge the model doesn't have on its own, and medical-specific best practices.

> **New to Claude Skills?** Skills are knowledge packages that extend Claude's capabilities. [Learn more →](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)

### What's New in v2.0

- **54 biomedical template scripts** (`.m` files) — runnable code for workflows like U-Net segmentation, radiomics extraction, survival analysis, and MRI denoising
- **Right-sized knowledge cards** — trimmed based on Skill Creator 2.0 evals (removed content the model already knows, strengthened edge cases it gets wrong)
- **Modern API only** — all code uses R2025b functions (`trainnet`, `unet`, `unet3d`), no legacy examples

<br>

## See the Difference

I tested each skill by asking Claude the same question with and without the skill loaded.

<br>

<table>
<tr>
<td colspan="3">

**How do I use MedSAM to segment a tumor from a CT volume in MATLAB?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Python bridge required</td><td><strong>Native MATLAB</strong></td></tr>
<tr><td>Code complexity</td><td>100+ lines across two languages</td><td><strong>~40 lines pure MATLAB</strong></td></tr>
<tr><td>Key function</td><td>Doesn't know it exists</td><td><code>medicalSegmentAnythingModel</code></td></tr>
<tr><td>Workflow</td><td>Temp files, subprocess calls</td><td><code>extractEmbeddings</code> → <code>segmentObjectsFromEmbeddings</code></td></tr>
<tr><td>3D handling</td><td>"Loop over slices" (vague)</td><td><strong>Seed-and-propagate workflow for 3D</strong></td></tr>
</table>

<br>

<table>
<tr>
<td colspan="3">

**How do I visualize a 3D medical volume with a segmentation overlay?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Workarounds (isosurface, loops)</td><td><strong><code>OverlayData</code> parameter</strong></td></tr>
<tr><td>Code</td><td>30+ lines</td><td><strong>3 lines</strong></td></tr>
<tr><td>Key syntax</td><td>Doesn't know it</td><td><code>volshow(V, OverlayData=L.Voxels)</code></td></tr>
</table>

<br>

---

## Installation

#### Claude Desktop

1. Download or clone this repository
2. Zip the skill folder you want:
   ```
   zip -r matlab-medical-imaging-toolbox.zip matlab-medical-imaging-toolbox
   ```
3. Go to **Settings → Capabilities → Skills → Customize** and upload the zip
4. Toggle the skill on and start a new conversation

#### Claude.ai (Web)

Go to **Settings → Capabilities → Skills → Customize** and upload the zip file.

#### Claude Code

Copy the skill folder to your skills directory:

```bash
# For all your projects (personal)
cp -r matlab-medical-imaging-toolbox ~/.claude/skills/

# Or for a specific project only
cp -r matlab-medical-imaging-toolbox .claude/skills/
```

See the [Claude Code skills documentation](https://code.claude.com/docs/en/skills) for more details.

---

## Use with MathWorks MATLAB MCP Server

These skills work great alongside the official [MATLAB MCP Core Server](https://github.com/matlab/matlab-mcp-core-server) from MathWorks:

|   | What It Provides |
|:--|:-----------------|
| **MCP Server** | Code execution, syntax checking, toolbox detection |
| **These Skills** | Toolbox-specific knowledge for accurate suggestions |

See [MathWorks AI resources](https://github.com/matlab) for more tools.

---

## Available Skills

| Skill | What It Covers | Templates |
|:------|:---------------|:---------:|
| `matlab-medical-imaging-toolbox` | DICOM/NIfTI I/O, MedSAM, Cellpose, radiomics, 3D visualization, coordinate transforms | 12 |
| `matlab-image-processing-toolbox` | MRI preprocessing, CT windowing, cell counting, histology, watershed, fluorescence | 10 |
| `matlab-deep-learning` | U-Net, 3D U-Net, DeepLabv3+, Mask R-CNN, YOLO, custom training, ONNX export | 10 |
| `matlab-stats-ml` | SVM, random forest, Cox survival, PCA, k-means, Bayesian optimization, SHAP | 12 |
| `matlab-wavelet-toolbox` | MRI denoising, CT denoising, speckle reduction, shearlets, dual-tree, deep learning wavelets | 10 |

---

<details>
<summary><h2>More Examples</h2></summary>

<br>

<table>
<tr>
<td colspan="3">

**How do I segment overlapping cells in a microscopy image?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Basic watershed</td><td><strong>Production-ready watershed</strong></td></tr>
<tr><td>Preprocessing</td><td>Simple threshold</td><td><code>imtophat</code> for background correction</td></tr>
<tr><td>Edge handling</td><td>Not addressed</td><td><code>imclearborder</code> for edge cases</td></tr>
<tr><td>Parameters</td><td>Generic values</td><td>Specific values with explanations</td></tr>
</table>

<br>

<table>
<tr>
<td colspan="3">

**How do I set up 3D volumetric segmentation for CT lung scans?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>3D U-Net</td><td>Manually builds layerGraph (doesn't know <code>unet3d</code>)</td><td><strong><code>unet3d(inputSize, numClasses)</code></strong></td></tr>
<tr><td>Code</td><td>80+ lines of manual architecture</td><td><strong>1 line + training options</strong></td></tr>
<tr><td>Template</td><td>None</td><td><strong>Runnable <code>template_3d_volumetric_segmentation.m</code></strong></td></tr>
</table>

<br>

<table>
<tr>
<td colspan="3">

**How do I use shearlets for directional texture analysis?**

</td>
</tr>
<tr>
<th width="25%">Aspect</th>
<th width="37%">Without Skill</th>
<th width="38%">With Skill</th>
</tr>
<tr><td>Approach</td><td>Third-party toolbox (ShearLab 3D)</td><td><strong>Native MATLAB Wavelet Toolbox</strong></td></tr>
<tr><td>Setup required</td><td>Download from shearlab.org</td><td><strong>None — built-in</strong></td></tr>
<tr><td>Forward transform</td><td><code>SLsheardec2D</code></td><td><code>sheart2</code></td></tr>
<tr><td>External dependencies</td><td>Yes</td><td><strong>No</strong></td></tr>
</table>

</details>

---

## Template Scripts

Each skill includes 8-12 biomedical-focused `.m` template scripts that are ready to run after filling in TODO sections with your data paths. Templates follow R2025b APIs exactly.

<details>
<summary><strong>Deep Learning (10 templates)</strong></summary>

| Template | Workflow |
|:---------|:---------|
| `template_transfer_learning_classification.m` | Fine-tune ResNet-50/EfficientNet for medical image classification |
| `template_unet_segmentation.m` | 2D U-Net for organ/tumor segmentation |
| `template_deeplabv3plus_segmentation.m` | DeepLabv3+ for histopathology |
| `template_3d_volumetric_segmentation.m` | 3D U-Net for CT/MRI volumes |
| `template_object_detection_yolov4.m` | YOLOv4 for nodule/lesion detection |
| `template_custom_training_loop.m` | dlarray-based custom training with Dice+CE loss |
| `template_data_augmentation_pipeline.m` | Medical image augmentation (2D and 3D) |
| `template_model_export_onnx.m` | Export to ONNX for deployment |
| `template_class_imbalance_handling.m` | Weighted loss, oversampling, focal loss |
| `template_maskrcnn_instance_seg.m` | Mask R-CNN for cell/nuclei instance segmentation |

</details>

<details>
<summary><strong>Image Processing (10 templates)</strong></summary>

| Template | Workflow |
|:---------|:---------|
| `template_mri_preprocessing.m` | Bias correction + CLAHE + brain masking |
| `template_ct_windowing.m` | CT window/level presets for different tissues |
| `template_cell_counting.m` | Automated cell counting with watershed separation |
| `template_histology_stain_normalization.m` | H&E Macenko stain normalization |
| `template_watershed_segmentation.m` | Standard + marker-controlled watershed |
| `template_morphological_cleanup.m` | Binary mask cleanup pipeline |
| `template_adaptive_thresholding.m` | Multi-level thresholding for tissue |
| `template_large_image_blockproc.m` | Block processing for whole-slide images |
| `template_edge_detection_pipeline.m` | Edge detection + active contour refinement |
| `template_fluorescence_quantification.m` | Multi-channel fluorescence analysis |

</details>

<details>
<summary><strong>Medical Imaging (12 templates)</strong></summary>

| Template | Workflow |
|:---------|:---------|
| `template_dicom_series_loader.m` | Load and organize DICOM series |
| `template_nifti_volume_processing.m` | NIfTI load, process, save pipeline |
| `template_volume_visualization.m` | 3D volume rendering with overlays |
| `template_rigid_registration.m` | Rigid registration of pre/post scans |
| `template_deformable_registration.m` | Non-rigid registration pipeline |
| `template_radiomics_extraction.m` | IBSI-compliant radiomics features |
| `template_medsam_segmentation.m` | MedSAM interactive segmentation |
| `template_cellpose_segmentation.m` | Cellpose cell/nuclei detection |
| `template_pacs_query_retrieve.m` | PACS server integration |
| `template_coordinate_transform.m` | Patient-voxel coordinate transforms |
| `template_multimodal_fusion.m` | PET/CT or multi-sequence fusion |
| `template_labeling_workflow.m` | Ground truth creation pipeline |

</details>

<details>
<summary><strong>Statistics & ML (12 templates)</strong></summary>

| Template | Workflow |
|:---------|:---------|
| `template_svm_classification.m` | SVM for patient classification |
| `template_random_forest_ensemble.m` | Random forest for biomarker prediction |
| `template_cox_survival_analysis.m` | Cox regression + Kaplan-Meier curves |
| `template_pca_feature_reduction.m` | PCA for high-dimensional biodata |
| `template_kmeans_patient_clustering.m` | K-means patient stratification |
| `template_bayesopt_hyperparameter.m` | Bayesian hyperparameter optimization |
| `template_cross_validation_pipeline.m` | k-fold CV with comprehensive metrics |
| `template_distribution_fitting.m` | Fit distributions to clinical data |
| `template_hypothesis_testing.m` | t-test / ANOVA for treatment comparison |
| `template_shapley_interpretability.m` | SHAP values for model explanation |
| `template_glm_regression.m` | GLM for clinical outcome prediction |
| `template_missing_data_handling.m` | KNN + multiple imputation strategies |

</details>

<details>
<summary><strong>Wavelet (10 templates)</strong></summary>

| Template | Workflow |
|:---------|:---------|
| `template_mri_denoising.m` | Rician noise removal from MRI |
| `template_ct_denoising.m` | Low-dose CT denoising |
| `template_ultrasound_speckle.m` | Speckle reduction in ultrasound |
| `template_wavelet_feature_extraction.m` | Multi-scale texture features |
| `template_dual_tree_directional.m` | Directional analysis (vessels/fibers) |
| `template_shearlet_curvilinear.m` | Shearlet for curvilinear structures |
| `template_custom_lifting_wavelet.m` | Custom wavelet via lifting scheme |
| `template_image_fusion.m` | Multi-modal image fusion |
| `template_deep_learning_wavelet.m` | Differentiable DWT in neural networks |
| `template_multiresolution_analysis.m` | Multi-level decomposition analysis |

</details>

---

## Contributing

Found an error? Have a suggestion? Contributions are welcome.

- **Report issues** — Open an [issue](../../issues) to report bugs or suggest improvements
- **Submit fixes** — See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines

All feedback is appreciated.

## License

<a href="https://creativecommons.org/licenses/by/4.0/"><img src="https://licensebuttons.net/l/by/4.0/88x31.png" alt="CC BY 4.0"></a>

This work is licensed under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).
