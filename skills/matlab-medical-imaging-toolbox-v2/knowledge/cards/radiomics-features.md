# Radiomics Feature Extraction

Radiomics extracts quantitative features from medical images for machine learning, treatment planning, and outcome prediction. MATLAB's radiomics functions are IBSI-compliant (Image Biomarker Standardisation Initiative).

> **CRITICAL: Object-Oriented API Required.** You MUST create a `radiomics` object first, then call feature methods on that object. Do NOT call `intensityFeatures(data, mask)`, `shapeFeatures(mask, spacing)`, or `textureFeatures(data, mask)` as standalone functions -- they will error or produce wrong results. Always follow the pattern: `R = radiomics(data, roi);` then `intensityFeatures(R);`.

## Feature Categories

| Category | Method | Description | Count |
|----------|--------|-------------|-------|
| **Intensity** | `intensityFeatures(R)` | Histogram-based statistics | 18 features |
| **Shape** | `shapeFeatures(R)` | 3D morphology descriptors | 22 features |
| **Texture** | `textureFeatures(R)` | GLCM, GLRLM, GLSZM, NGTDM, GLDM | 92 features |

## Basic Workflow

```matlab
% Load image and segmentation
V = medicalVolume('scan.nii');
mask = medicalVolume('tumor_mask.nii');

% Ensure same size
assert(isequal(size(V.Voxels), size(mask.Voxels)), ...
    'Image and mask must have same dimensions');

% Binary mask
binaryMask = mask.Voxels > 0;

% STEP 1: Create radiomics object FIRST (REQUIRED)
R = radiomics(V.Voxels, binaryMask);

% STEP 2: Call feature methods ON the radiomics object
intensity = intensityFeatures(R);
shape = shapeFeatures(R);
texture = textureFeatures(R);

% Combine into single table
features = [intensity, shape, texture];
disp(features);
```

> **WRONG -- do NOT do this:**
> ```matlab
> % These standalone calls are INCORRECT:
> intensity = intensityFeatures(V.Voxels, binaryMask);   % WRONG
> shape = shapeFeatures(binaryMask, V.VoxelSpacing);      % WRONG
> texture = textureFeatures(V.Voxels, binaryMask);        % WRONG
> ```

## intensityFeatures - Histogram-Based

First-order statistics of voxel intensities within ROI:

```matlab
V = medicalVolume('scan.nii');
mask = logical(medicalVolume('mask.nii').Voxels);

% Create radiomics object first
R = radiomics(V.Voxels, mask);

% Extract intensity features from the object
intensity = intensityFeatures(R);

% Key features (18 total):
disp(intensity.Mean);           % Mean intensity
disp(intensity.Variance);       % Variance
disp(intensity.Skewness);       % Distribution asymmetry
disp(intensity.Kurtosis);       % Distribution peakedness
disp(intensity.Energy);         % Sum of squared intensities
disp(intensity.Entropy);        % Randomness measure
disp(intensity.Minimum);        % Min value in ROI
disp(intensity.Maximum);        % Max value in ROI
disp(intensity.Range);          % Max - Min
disp(intensity.RootMeanSquare); % RMS intensity
```

## shapeFeatures - 3D Morphology

Geometric descriptors of the ROI:

```matlab
mask = logical(medicalVolume('mask.nii').Voxels);

% Create radiomics object -- shape uses the ROI from the object
R = radiomics(zeros(size(mask)), mask);  % data can be zeros for shape-only

shape = shapeFeatures(R);

% Key features (22 total):
disp(shape.Volume);             % Volume in mm^3
disp(shape.SurfaceArea);        % Surface area in mm^2
disp(shape.Sphericity);         % How spherical (0-1)
disp(shape.Compactness);        % Shape compactness
disp(shape.MajorAxisLength);    % Longest principal axis
disp(shape.MinorAxisLength);    % Shortest principal axis
disp(shape.Elongation);         % Ratio of axes
disp(shape.Flatness);           % How flat
```

### Computed Properties

| Feature | Formula/Meaning | Range |
|---------|-----------------|-------|
| Volume | Voxel count x voxel volume | mm^3 |
| SurfaceArea | Triangulated surface mesh | mm^2 |
| Sphericity | (36*pi*V^2)^(1/3) / A | 0-1 (1=sphere) |
| Compactness | V / (pi^(1/2) * A^(3/2)) | 0-1 |
| Elongation | MinorAxis / MajorAxis | 0-1 |

## textureFeatures - Spatial Patterns

Higher-order statistics capturing spatial relationships:

```matlab
V = medicalVolume('scan.nii');
mask = logical(medicalVolume('mask.nii').Voxels);

% Create radiomics object first
R = radiomics(V.Voxels, mask);

% Extract all texture features (92 total) from the object
texture = textureFeatures(R);

% GLCM (Gray Level Co-occurrence Matrix) features
disp(texture.GLCM_Contrast);
disp(texture.GLCM_Correlation);
disp(texture.GLCM_Energy);
disp(texture.GLCM_Homogeneity);

% GLRLM (Gray Level Run Length Matrix) features
disp(texture.GLRLM_ShortRunEmphasis);
disp(texture.GLRLM_LongRunEmphasis);
disp(texture.GLRLM_RunLengthNonUniformity);

% GLSZM (Gray Level Size Zone Matrix) features
disp(texture.GLSZM_SmallZoneEmphasis);
disp(texture.GLSZM_LargeZoneEmphasis);

% NGTDM (Neighborhood Gray Tone Difference Matrix) features
disp(texture.NGTDM_Coarseness);
disp(texture.NGTDM_Contrast);
disp(texture.NGTDM_Busyness);

% GLDM (Gray Level Dependence Matrix) features
disp(texture.GLDM_SmallDependenceEmphasis);
disp(texture.GLDM_LargeDependenceEmphasis);
```

## IBSI Compliance

IBSI (Image Biomarker Standardisation Initiative) ensures reproducibility:

```matlab
% Create radiomics object with IBSI-recommended settings
R = radiomics(V.Voxels, mask);

% Feature names match IBSI standard
intensity = intensityFeatures(R);
% intensity.Mean matches IBSI "Mean"
% intensity.RobustMeanAbsoluteDeviation matches IBSI "Robust Mean Absolute Deviation"

texture = textureFeatures(R);
```

## Preprocessing for Radiomics

### Resample to Isotropic

Many texture features are sensitive to anisotropy:

```matlab
V = medicalVolume('scan.nii');
mask = medicalVolume('mask.nii');

% Check spacing
fprintf('Original spacing: %s mm\n', mat2str(V.VoxelSpacing));

% Resample to isotropic (e.g., 1mm)
V_iso = resample(V, [1, 1, 1]);
mask_iso = resample(mask, [1, 1, 1]);

% Re-binarize mask after resampling
mask_iso.Voxels = mask_iso.Voxels > 0.5;

% Create radiomics object, then extract features
R = radiomics(V_iso.Voxels, mask_iso.Voxels > 0);
intensity = intensityFeatures(R);
shape = shapeFeatures(R);
texture = textureFeatures(R);
features = [intensity, shape, texture];
```

### Intensity Normalization

```matlab
% Z-score normalization within ROI
voxels = double(V.Voxels);
roi_values = voxels(mask);
mu = mean(roi_values);
sigma = std(roi_values);
voxels_normalized = (voxels - mu) / sigma;

% Or histogram matching to reference
reference = medicalVolume('reference.nii');
voxels_matched = imhistmatch(voxels, reference.Voxels);
```

## Complete Radiomics Pipeline

```matlab
function featureTable = extractRadiomicsFeatures(imageFile, maskFile)
    % Load data
    V = medicalVolume(imageFile);
    M = medicalVolume(maskFile);

    % Preprocessing
    % 1. Resample to isotropic
    targetSpacing = [1, 1, 1];  % 1mm isotropic
    V = resample(V, targetSpacing);
    M = resample(M, targetSpacing);

    % 2. Binarize mask
    mask = M.Voxels > 0.5;

    % 3. Check sufficient voxels
    numVoxels = sum(mask(:));
    if numVoxels < 100
        warning('ROI has only %d voxels - features may be unreliable', numVoxels);
    end

    % STEP 1: Create radiomics object (REQUIRED)
    R = radiomics(V.Voxels, mask);

    % STEP 2: Extract features as methods of the radiomics object
    intensity = intensityFeatures(R);
    shape = shapeFeatures(R);
    texture = textureFeatures(R);

    % Combine
    featureTable = [intensity, shape, texture];

    % Add metadata
    featureTable.Properties.UserData.SourceImage = imageFile;
    featureTable.Properties.UserData.SourceMask = maskFile;
    featureTable.Properties.UserData.NumVoxels = numVoxels;
    featureTable.Properties.UserData.ExtractedDate = datetime('now');

    fprintf('Extracted %d features from %d voxels\n', ...
        width(featureTable), numVoxels);
end
```

## Multi-ROI Feature Extraction

```matlab
function allFeatures = extractMultiROI(imageFile, maskFile)
    V = medicalVolume(imageFile);
    M = medicalVolume(maskFile);

    % Get unique labels (excluding background)
    labels = unique(M.Voxels(:));
    labels = labels(labels > 0);

    allFeatures = table();

    for i = 1:length(labels)
        label = labels(i);
        roi = M.Voxels == label;

        % Skip small regions
        if sum(roi(:)) < 50
            continue;
        end

        % Create radiomics object for this ROI
        R = radiomics(V.Voxels, roi);

        % Extract features as methods of the object
        intensity = intensityFeatures(R);
        shape = shapeFeatures(R);
        texture = textureFeatures(R);

        features = [intensity, shape, texture];
        features.LabelID = label;

        allFeatures = [allFeatures; features];
    end

    fprintf('Extracted features for %d regions\n', height(allFeatures));
end
```

## Feature Selection

### Remove Highly Correlated Features

```matlab
function selected = removeCorrelatedFeatures(featureTable, threshold)
    if nargin < 2
        threshold = 0.9;  % Remove if correlation > 0.9
    end

    % Get numeric features
    numericCols = varfun(@isnumeric, featureTable, 'OutputFormat', 'uniform');
    data = table2array(featureTable(:, numericCols));
    names = featureTable.Properties.VariableNames(numericCols);

    % Compute correlation matrix
    corrMatrix = abs(corr(data, 'Rows', 'pairwise'));

    % Find features to remove
    toRemove = false(1, length(names));
    for i = 1:length(names)
        for j = i+1:length(names)
            if corrMatrix(i,j) > threshold && ~toRemove(j)
                toRemove(j) = true;  % Remove second feature
            end
        end
    end

    % Select non-correlated features
    keepCols = numericCols;
    keepCols(numericCols) = ~toRemove;
    selected = featureTable(:, keepCols);

    fprintf('Removed %d correlated features (threshold=%.2f)\n', ...
        sum(toRemove), threshold);
end
```

### Feature Importance

```matlab
% Train random forest and get feature importance
X = table2array(featureTable);
y = labels;  % Classification labels

mdl = TreeBagger(100, X, y, 'OOBPredictorImportance', 'on');
importance = mdl.OOBPermutedPredictorDeltaError;

% Sort by importance
[~, idx] = sort(importance, 'descend');
topFeatures = featureTable.Properties.VariableNames(idx(1:10));
fprintf('Top 10 features:\n');
disp(topFeatures');
```

## Clinical Application Example

### Tumor Classification

```matlab
% Load dataset
patients = dir('data/patient*.mat');
allFeatures = table();

for i = 1:length(patients)
    load(fullfile(patients(i).folder, patients(i).name), 'imageFile', 'maskFile', 'diagnosis');

    features = extractRadiomicsFeatures(imageFile, maskFile);
    features.PatientID = i;
    features.Diagnosis = diagnosis;  % 'benign' or 'malignant'

    allFeatures = [allFeatures; features];
end

% Split data
cv = cvpartition(allFeatures.Diagnosis, 'HoldOut', 0.3);
trainData = allFeatures(training(cv), :);
testData = allFeatures(test(cv), :);

% Train classifier (excluding non-numeric columns)
numericCols = varfun(@isnumeric, trainData, 'OutputFormat', 'uniform');
X_train = table2array(trainData(:, numericCols));
y_train = trainData.Diagnosis;

mdl = fitcsvm(X_train, y_train, 'Standardize', true, 'KernelFunction', 'rbf');

% Evaluate
X_test = table2array(testData(:, numericCols));
y_pred = predict(mdl, X_test);
accuracy = mean(y_pred == testData.Diagnosis);
fprintf('Classification accuracy: %.1f%%\n', accuracy * 100);
```

## API Summary

The radiomics API is **object-oriented**. Every workflow follows this two-step pattern:

```matlab
% Step 1: Create the radiomics object
R = radiomics(data, roi);

% Step 2: Call methods on the object
intensity = intensityFeatures(R);   % R is the object, NOT raw data
shape     = shapeFeatures(R);       % R is the object, NOT a mask
texture   = textureFeatures(R);     % R is the object, NOT raw data
```

Never pass raw data arrays directly to `intensityFeatures`, `shapeFeatures`, or `textureFeatures`. They are methods that operate on a `radiomics` object.

## Common Issues

### Issue: NaN or Inf in features

```matlab
features = extractRadiomicsFeatures(image, mask);

% Check for issues
nanCols = any(isnan(table2array(features)), 1);
infCols = any(isinf(table2array(features)), 1);

if any(nanCols) || any(infCols)
    problemCols = features.Properties.VariableNames(nanCols | infCols);
    warning('Problem features: %s', strjoin(problemCols, ', '));

    % Remove or impute
    features(:, nanCols | infCols) = [];
end
```

### Issue: Features not reproducible

Ensure consistent preprocessing:

```matlab
% Use fixed parameters
config.targetSpacing = [1, 1, 1];

% Create radiomics object, then extract
R = radiomics(V.Voxels, mask);
intensity = intensityFeatures(R);
shape = shapeFeatures(R);
texture = textureFeatures(R);
```

---

*Verified against MATLAB R2025b*
*See also: `segmentation-medsam.md` for creating segmentation masks*
