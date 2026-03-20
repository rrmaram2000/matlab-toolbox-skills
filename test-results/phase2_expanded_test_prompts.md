# Phase 2 Expanded Test Suite — 40 Prompts

## Rubric (same 5-dimension, 1-5 scale)
| Dimension | What It Measures |
|-----------|-----------------|
| **Accuracy** | Correct R2025b function names, signatures, defaults |
| **Completeness** | Full pipeline coverage, handles edge cases |
| **Groundedness** | Claims traceable to R2025b, no hallucination |
| **Interpretability** | Code is clear, well-commented |
| **Usefulness** | Would a MATLAB engineer trust and use this? |

---

## Deep Learning (8 prompts)

### DL-1: 3D U-Net Volumetric Segmentation
> Write MATLAB code to train a 3D U-Net for brain tumor segmentation from MRI volumes. Use NIfTI files as input, create a randomPatchExtractionDatastore for training, and train with a custom Dice loss function. Use the R2025b API.

**Key assertions:** `unet3d` (not `unet3dLayers`), `trainnet` (not `trainNetwork`), `randomPatchExtractionDatastore`, returns `dlnetwork`

### DL-2: Transfer Learning with imagePretrainedNetwork
> Write MATLAB code to fine-tune a pretrained ResNet-50 for classifying dermoscopy images into 7 skin lesion categories. Handle severe class imbalance using weighted loss.

**Key assertions:** `imagePretrainedNetwork("resnet50", NumClasses=7)`, `trainnet`, no `classificationLayer`

### DL-3: DeepLabv3+ Semantic Segmentation
> Write MATLAB code to segment glandular structures in H&E histopathology images using DeepLabv3+ with a ResNet-50 backbone. Include evaluation with Dice score.

**Key assertions:** `deeplabv3plus` (not `deeplabv3plusLayers`), returns `dlnetwork` directly, `trainnet`, `semanticseg`

### DL-4: Mask R-CNN Instance Segmentation
> Write MATLAB code to detect and segment individual cell nuclei in fluorescence microscopy images using Mask R-CNN.

**Key assertions:** `maskrcnn` function, proper bbox+mask output

### DL-5: Custom Training Loop with Dice Loss
> Write a MATLAB custom training loop using dlarray and automatic differentiation for a U-Net segmentation model. Include Dice loss, learning rate scheduling, and validation after each epoch.

**Key assertions:** `dlarray` with `'SSCB'`, `dlfeval`, `dlgradient`, `adamupdate`, differentiable Dice loss

### DL-6: Data Augmentation for Medical Images
> Write MATLAB code to create a comprehensive data augmentation pipeline for medical image segmentation. Include geometric transforms (rotation, flipping, elastic deformation) and intensity transforms (jitter, noise). Ensure labels are transformed consistently with images.

**Key assertions:** Uses `imageDataAugmenter` or custom `transform`, handles label transforms, mentions elastic deformation

### DL-7: YOLOv4 Object Detection
> Write MATLAB code to train a YOLOv4 object detector for detecting lung nodules in chest CT slices. Include anchor box estimation and evaluation with mAP.

**Key assertions:** `yolov4ObjectDetector`, proper anchor estimation, `trainnet` or specific detector training function

### DL-8: ONNX Model Export
> Write MATLAB code to export a trained dlnetwork to ONNX format, verify by reimporting, and compare inference outputs between original and reimported models.

**Key assertions:** `exportONNXNetwork` (with ONNX converter add-on requirement noted), `importONNXNetwork`, output comparison

---

## Image Processing (7 prompts)

### IPT-1: Cell Counting Pipeline
> Write MATLAB code for an automated cell counting pipeline for fluorescence microscopy images. Include background subtraction, adaptive thresholding, morphological cleanup, watershed for touching cells, and regionprops for measurements.

**Key assertions:** `imbinarize`+`adaptthresh`, `watershed`, `regionprops`, `bwareaopen`+`imfill`

### IPT-2: Whole Slide Image Block Processing
> Write MATLAB code to process a very large whole-slide histology image using block processing since it won't fit in memory. Apply stain normalization per block.

**Key assertions:** `blockproc` with function handle, `BorderSize` for overlap, file-based I/O

### IPT-3: MRI Preprocessing Pipeline
> Write MATLAB code for a complete MRI preprocessing pipeline with bias field correction, Rician noise removal, and intensity normalization. What is the difference between imgaussfilt and imfilter padding defaults?

**Key assertions:** `imgaussfilt` padding = 'replicate', `imfilter` padding = 0 (zero), `adapthisteq`

### IPT-4: CT Windowing for Multiple Tissues
> Write MATLAB code to apply CT windowing to display bone, soft tissue, and lung windows from the same CT DICOM slice. Include proper HU conversion from stored values.

**Key assertions:** Uses window center/width correctly, `dicomread`+`dicominfo`, `RescaleSlope`/`RescaleIntercept` for HU conversion

### IPT-5: Histology Stain Normalization
> Write MATLAB code to separate hematoxylin and eosin channels from an H&E stained histology image, then normalize staining to match a reference image.

**Key assertions:** `rgb2hed` or color deconvolution matrix, handles optical density conversion, reference-based normalization

### IPT-6: Morphological Cleanup Pipeline
> Write MATLAB code to clean up a noisy binary segmentation mask — fill holes, remove small objects, separate touching objects, smooth jagged boundaries. Show each step with before/after visualization.

**Key assertions:** `imfill('holes')`, `bwareaopen`, `imopen`/`imclose`, `strel`, proper structuring element choices

### IPT-7: Fluorescence Quantification
> Write MATLAB code to quantify fluorescence intensity in a multi-channel microscopy image. Segment nuclei in the DAPI channel, measure mean intensity in the GFP and RFP channels within each nucleus, and generate a summary table.

**Key assertions:** Multi-channel handling, `regionprops` with intensity image, proper channel separation

---

## Medical Imaging (9 prompts)

### MED-1: Radiomics Feature Extraction
> Write MATLAB code to extract a comprehensive set of radiomics features from a tumor ROI in a CT volume using the object-oriented radiomics API.

**Key assertions:** `radiomics(data, roi)` object first, methods `intensityFeatures`, `shapeFeatures`, `textureFeatures`

### MED-2: MedSAM Segmentation
> Write MATLAB code to segment a liver lesion in a CT slice using MedSAM with bounding box prompts.

**Key assertions:** `medicalSegmentAnythingModel`, `segmentObjectsFromEmbeddings` with `imageSize` parameter

### MED-3: Coordinate Transform
> Write MATLAB code to convert between patient coordinates (mm) and voxel indices for a NIfTI brain MRI volume. Extract a VOI at specific patient coordinates.

**Key assertions:** `[X,Y,Z] = intrinsicToWorld(R,I,J,K)` with 3 separate outputs, `worldToIntrinsic`, `medicalref3d`

### MED-4: Volume Visualization with Overlay
> Write MATLAB code to display a 3D CT volume with a tumor segmentation overlay. I heard labelvolshow was removed in R2025b?

**Key assertions:** `volshow(V, OverlayData=labels)` NOT `labelvolshow`, `sliceViewer`

### MED-5: DICOM Series Loading and Sorting
> Write MATLAB code to load a folder of DICOM files, sort them into series, handle multi-frame DICOMs, and create a medicalVolume for each series.

**Key assertions:** `dicomCollection`, `medicalVolume(sourceTable)`, proper series sorting

### MED-6: Deformable Registration
> Write MATLAB code to perform deformable registration between pre-treatment and post-treatment brain MRI volumes. Visualize the displacement field and check for folding.

**Key assertions:** `imregdeform`, `GridSpacing` parameter, displacement field visualization, Jacobian check

### MED-7: NIfTI Volume Resampling
> Write MATLAB code to load a NIfTI brain MRI, resample it to isotropic 1mm spacing, and save back to NIfTI format.

**Key assertions:** `medicalVolume`, `medicalref3d`, resampling with correct spatial referencing, `niftiwrite`

### MED-8: Multi-Modal PET/CT Fusion
> Write MATLAB code to register and fuse a PET scan with a CT volume for combined visualization. The PET needs to be registered to the CT coordinate space.

**Key assertions:** Registration before fusion, `volshow` with overlay, proper intensity scaling

### MED-9: Ground Truth Labeling Setup
> Write MATLAB code to set up a medical image labeling workflow using groundTruthMedical for creating training data for a 3D segmentation model.

**Key assertions:** `groundTruthMedical`, `trainnet` (not `trainNetwork`), proper label export

---

## Statistics & ML (8 prompts)

### STAT-1: Cox Survival Analysis
> Write MATLAB code to perform Cox proportional hazards regression for analyzing patient survival time. Include Kaplan-Meier curves and hazard ratios.

**Key assertions:** `coxphfit` NOT `logrank`, `ecdf` with 'function','survivor', `exp(b)` for HR

### STAT-2: Distribution Fitting
> Write MATLAB code to fit multiple probability distributions to biomarker data and select the best using AIC/BIC.

**Key assertions:** `fitdist`, `negloglik(pd)` function NOT `.NegLogLikelihood` property, `kstest`

### STAT-3: Missing Data Imputation
> Write MATLAB code to handle missing data in a clinical dataset. Compare KNN, regression, and iterative methods.

**Key assertions:** `fillmissing(X, 'knn')` NOT `knnimpute`, multiple strategies

### STAT-4: SVM Classification with Cross-Validation
> Write MATLAB code to train an SVM classifier for cancer diagnosis from gene expression data (20,000 features, 200 samples). Include feature selection, cross-validation, and ROC analysis.

**Key assertions:** `fitcsvm`, `cvpartition`, `perfcurve`, feature selection with high-dimensional data

### STAT-5: SHAP Interpretability
> Write MATLAB code to train a random forest for predicting ICU readmission, then use SHAP values to interpret which features matter most.

**Key assertions:** `shapley` function, `fitcensemble` for RF, `fit` and `plot` methods on shapley object

### STAT-6: Bayesian Hyperparameter Optimization
> Write MATLAB code to optimize hyperparameters of an SVM classifier using bayesopt. Define the search space for BoxConstraint, KernelScale, and KernelFunction.

**Key assertions:** `bayesopt`, `optimizableVariable`, proper objective function

### STAT-7: GLM for Binary Outcomes
> Write MATLAB code to build a logistic regression model predicting hospital readmission from patient demographics. Include odds ratios, confidence intervals, and model diagnostics.

**Key assertions:** `fitglm` with 'Distribution','binomial', odds ratios from `exp(Coefficients.Estimate)`, deviance

### STAT-8: K-Means Patient Clustering
> Write MATLAB code to cluster a patient cohort into subgroups using k-means on lab values. Determine the optimal k using silhouette analysis and visualize with PCA.

**Key assertions:** `kmeans`, `evalclusters` or silhouette, `pca` for visualization

---

## Wavelet (8 prompts)

### WAV-1: MRI Denoising with wdenoise2
> Write MATLAB code to denoise a brain MRI using wavelet denoising. Compare wdenoise2 methods and list all valid ones. Which works best for Rician noise?

**Key assertions:** Valid methods: SURE, Bayes, Minimax, UniversalThreshold, FDR. NOT BlockJS. Log-domain for Rician.

### WAV-2: Shearlet Vessel Detection
> Write MATLAB code to detect blood vessels in retinal fundus images using shearlets.

**Key assertions:** `shearletSystem` + `sheart2`/`isheart2` NOT `shearletTransform`, direction-selective filtering

### WAV-3: Deep Learning Wavelet Integration
> Write MATLAB code to integrate dldwt into a deep learning pipeline for texture classification.

**Key assertions:** `dldwt` returns `[A, D]` (2 outputs NOT 4), `dlidwt`, proper `dlarray` format

### WAV-4: Custom Lifting Wavelet Design
> Write MATLAB code to design a custom wavelet using lifting schemes in MATLAB. Create a predict-update lifting scheme and apply it with lwt2.

**Key assertions:** `liftingStep`, `liftingScheme`, `lwt2`/`ilwt2`, proper predict/update structure

### WAV-5: Multi-Modal Image Fusion
> Write MATLAB code to fuse PET and CT images using wavelet decomposition. Keep high-frequency details from CT and metabolic information from PET.

**Key assertions:** `wavedec2`/`waverec2`, proper coefficient manipulation (not `detcoef2('compact',...)`), mean for approx + max-abs for detail

### WAV-6: Dual-Tree Complex Wavelet Transform
> Write MATLAB code to use the dual-tree complex wavelet transform for shift-invariant texture analysis on fabric defect images.

**Key assertions:** `dualtree2`/`idualtree2`, complex-valued coefficients, 6 directional subbands per level

### WAV-7: CT Denoising with Multiple Methods
> Write MATLAB code to reduce quantum noise in low-dose CT images. Compare SURE, Minimax, and UniversalThreshold methods in wdenoise2. Include edge preservation analysis.

**Key assertions:** All three methods valid, proper comparison metrics (PSNR, SSIM, edge preservation)

### WAV-8: Wavelet Feature Extraction for Classification
> Write MATLAB code to extract multi-scale wavelet features from medical images for texture classification. Use wavedec2 to decompose and compute energy, entropy, and statistical features per subband.

**Key assertions:** `wavedec2`, `detcoef2` with valid modes ('h','v','d','all'), proper feature computation per subband

---

**Total: 40 prompts × 2 (with/without skill) = 80 evaluation runs**
