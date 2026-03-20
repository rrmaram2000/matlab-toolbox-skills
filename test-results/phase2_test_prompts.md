# Phase 2: Blind A/B Test Prompts

## Rubric (5 dimensions, 1-5 scale each)

| Dimension | 1 (Poor) | 5 (Excellent) |
|-----------|----------|---------------|
| **Accuracy** | Uses deprecated/wrong APIs | All APIs verified against R2025b |
| **Completeness** | Missing steps, incomplete | End-to-end pipeline with error handling |
| **Groundedness** | Invents functions/params | Every claim verifiable in R2025b PDFs |
| **Interpretability** | Opaque, no comments | Self-documenting with clear sections |
| **Usefulness** | Needs heavy editing | Copy-paste ready after filling TODOs |

---

## Deep Learning (4 prompts)

### DL-1: 3D U-Net for Volumetric Segmentation
> Write MATLAB code to train a 3D U-Net for brain tumor segmentation from MRI volumes. Use NIfTI files as input, create a randomPatchExtractionDatastore for training, and train with a custom Dice loss function. Use the R2025b API.

**Assertions:**
- Uses `unet3d` (not manual layerGraph)
- Uses `trainnet` with custom loss (not trainNetwork)
- Uses `randomPatchExtractionDatastore` for patch extraction
- Returns `dlnetwork`

### DL-2: Transfer Learning with imagePretrainedNetwork
> Write MATLAB code to fine-tune a pretrained ResNet-50 for classifying dermoscopy images into 7 skin lesion categories. Handle severe class imbalance using weighted loss. Show how to freeze early layers and only train the last few.

**Assertions:**
- Uses `imagePretrainedNetwork("resnet50", NumClasses=7)`
- Uses `trainnet` with weighted cross-entropy
- Demonstrates layer freezing via `net.Learnables`
- No `trainNetwork` or `classificationLayer`

### DL-3: DeepLabv3+ Semantic Segmentation
> Write MATLAB code to segment glandular structures in H&E histopathology images using DeepLabv3+ with a ResNet-50 backbone. Include data augmentation, class-weighted loss, and evaluation with Dice score.

**Assertions:**
- Uses `deeplabv3plus` (not `deeplabv3plusLayers`)
- Returns `dlnetwork` directly (no `dlnetwork(lgraph)` wrapper)
- Uses `trainnet` with appropriate loss
- Includes `semanticseg` for prediction

### DL-4: Mask R-CNN Instance Segmentation
> Write MATLAB code to detect and segment individual cell nuclei in fluorescence microscopy images using Mask R-CNN. Include training data preparation, model configuration, and inference with NMS.

**Assertions:**
- Uses `maskrcnn` function
- Uses `trainnet` (not trainNetwork)
- Proper bounding box and mask output handling

---

## Image Processing (3 prompts)

### IPT-1: Cell Counting Pipeline
> Write MATLAB code for an automated cell counting pipeline for fluorescence microscopy images. Include background subtraction, adaptive thresholding, morphological cleanup, watershed for touching cells, and regionprops for measurements.

**Assertions:**
- Uses `imbinarize` with `adaptthresh`
- Uses `watershed` for separating touching cells
- Uses `regionprops` for measurements
- Correct use of `bwareaopen`, `imfill`

### IPT-2: Whole Slide Image Block Processing
> Write MATLAB code to process a large whole-slide histology image (too large to fit in memory) using block processing. Apply stain normalization to each block and count cells.

**Assertions:**
- Uses `blockproc` with function handle
- Handles block padding correctly
- Uses `bigimage` or blockedImage for WSI

### IPT-3: MRI Preprocessing Pipeline
> Write MATLAB code for a complete MRI preprocessing pipeline: bias field correction, noise removal (Rician noise), intensity normalization, and skull stripping preparation. Note the difference between imgaussfilt and imfilter padding defaults.

**Assertions:**
- Mentions `imgaussfilt` uses 'replicate' padding (not zero)
- Mentions `imfilter` uses zero-padding (dark borders)
- Uses `adapthisteq` for contrast enhancement
- Handles Rician noise characteristics

---

## Medical Imaging (4 prompts)

### MED-1: Radiomics Feature Extraction
> Write MATLAB code to extract a comprehensive set of radiomics features from a tumor ROI in a CT volume. Include intensity, shape, and texture features using the Medical Imaging Toolbox radiomics API.

**Assertions:**
- Creates `radiomics(data, roi)` object first
- Calls `intensityFeatures`, `shapeFeatures`, `textureFeatures` as methods
- Does NOT use non-existent function signatures
- Uses `medicalVolume` for loading

### MED-2: MedSAM Segmentation
> Write MATLAB code to segment a liver lesion in a CT slice using the Medical Segment Anything Model (MedSAM). Include image embedding, point/box prompts, and mask refinement.

**Assertions:**
- Uses `medicalSegmentAnythingModel` to load model
- Uses `segmentObjectsFromEmbeddings` with `imageSize` parameter
- Correct prompt format (points, boxes)

### MED-3: Coordinate Transform and Volume Processing
> Write MATLAB code to convert between patient coordinates and voxel indices for a NIfTI brain MRI volume. Show how to extract a VOI at specific patient coordinates and resample to isotropic spacing.

**Assertions:**
- Uses `intrinsicToWorld(R, I, J, K)` returning `[X, Y, Z]` (3 separate outputs)
- Uses `worldToIntrinsic` for reverse
- Uses `medicalref3d` for spatial referencing
- Correct coordinate system handling

### MED-4: Volume Visualization with Segmentation Overlay
> Write MATLAB code to display a 3D CT volume with a tumor segmentation overlay using R2025b visualization. Include multiple views and colormap configuration.

**Assertions:**
- Uses `volshow(V, OverlayData=labels)` (NOT `labelvolshow`)
- Correct R2025b API for overlay visualization
- Uses `sliceViewer` for 2D review

---

## Stats-ML (3 prompts)

### STAT-1: Cox Survival Analysis
> Write MATLAB code to perform Cox proportional hazards regression for analyzing patient survival time based on clinical covariates. Include Kaplan-Meier curves, hazard ratio computation, and model diagnostics. Note: there is no logrank function in MATLAB.

**Assertions:**
- Uses `coxphfit` (NOT logrank)
- Correct parameter format for coxphfit
- Uses `ecdf` with 'function','survivor' for KM curves
- Computes hazard ratios from coefficients

### STAT-2: Distribution Fitting with Model Selection
> Write MATLAB code to fit multiple probability distributions to biomarker data, compare them using information criteria, and select the best fit. Include Q-Q plots and goodness-of-fit tests.

**Assertions:**
- Uses `fitdist` for fitting
- Uses `negloglik(pd)` function (NOT .NegLogLikelihood property)
- Uses `kstest` for GoF
- Computes AIC/BIC correctly

### STAT-3: Missing Data Imputation
> Write MATLAB code to handle missing data in a clinical dataset using multiple imputation strategies. Compare KNN, regression, and iterative methods. Show the R2025b approach.

**Assertions:**
- Uses `fillmissing(X, 'knn')` (NOT `knnimpute`)
- Shows multiple strategies
- Validates imputation quality

---

## Wavelet (3 prompts)

### WAV-1: MRI Denoising with wdenoise2
> Write MATLAB code to denoise a brain MRI image using wavelet denoising. Compare multiple wdenoise2 methods (SURE, Bayes, Minimax) and show which is best for Rician noise. List valid denoising methods.

**Assertions:**
- Valid wdenoise2 methods: SURE, Bayes, Minimax, UniversalThreshold, FDR
- Does NOT use 'BlockJS' (invalid)
- Uses 'sym8' or medical-appropriate wavelet
- Handles Rician noise characteristics (log-domain)

### WAV-2: Shearlet-Based Vessel Detection
> Write MATLAB code to detect blood vessels in retinal fundus images using the shearlet transform. Extract directional features and enhance curvilinear structures.

**Assertions:**
- Uses `shearletSystem` + `sheart2`/`isheart2` (NOT `shearletTransform`)
- Correct shearlet coefficient manipulation
- Direction-selective filtering

### WAV-3: Deep Learning Wavelet Integration
> Write MATLAB code to integrate wavelet decomposition into a deep learning pipeline using dldwt. Create a network that processes wavelet subbands for texture classification.

**Assertions:**
- Uses `dldwt` returning `[A, D]` (2 outputs, NOT 4)
- Uses `dlidwt` for inverse
- Correct `dlarray` format handling

---

**Total: 17 test prompts × 2 variants (with/without skill) = 34 eval runs**
