# Radiomics Feature Extraction

Radiomics extracts quantitative features from medical images for machine learning, treatment planning, and outcome prediction. MATLAB's radiomics functions are IBSI-compliant (Image Biomarker Standardisation Initiative).

## Feature Categories

| Category | Function | Description | Count |
|----------|----------|-------------|-------|
| **Intensity** | `intensityFeatures` | Histogram-based statistics | 18 features |
| **Shape** | `shapeFeatures` | 3D morphology descriptors | 22 features |
| **Texture** | `textureFeatures` | GLCM, GLRLM, GLSZM, NGTDM, GLDM | 92 features |

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

% Extract features
intensity = intensityFeatures(V.Voxels, binaryMask);
shape = shapeFeatures(binaryMask, V.VoxelSpacing);
texture = textureFeatures(V.Voxels, binaryMask);

% Combine into single table
features = [intensity, shape, texture];
disp(features);
```

## intensityFeatures - Histogram-Based

First-order statistics of voxel intensities within ROI:

```matlab
V = medicalVolume('scan.nii');
mask = logical(medicalVolume('mask.nii').Voxels);

% Extract intensity features
intensity = intensityFeatures(V.Voxels, mask);

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

### Options

```matlab
% Specify bin count for discretization
intensity = intensityFeatures(V.Voxels, mask, 'NumBins', 64);

% Or use bin width
intensity = intensityFeatures(V.Voxels, mask, 'BinWidth', 25);
```

## shapeFeatures - 3D Morphology

Geometric descriptors of the ROI:

```matlab
mask = logical(medicalVolume('mask.nii').Voxels);
spacing = [1, 1, 2];  % Voxel spacing in mm

% Extract shape features
shape = shapeFeatures(mask, spacing);

% Key features (22 total):
disp(shape.Volume);             % Volume in mm³
disp(shape.SurfaceArea);        % Surface area in mm²
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
| Volume | Voxel count × voxel volume | mm³ |
| SurfaceArea | Triangulated surface mesh | mm² |
| Sphericity | (36π V²)^(1/3) / A | 0-1 (1=sphere) |
| Compactness | V / (π^(1/2) A^(3/2)) | 0-1 |
| Elongation | MinorAxis / MajorAxis | 0-1 |

## textureFeatures - Spatial Patterns

Higher-order statistics capturing spatial relationships:

```matlab
V = medicalVolume('scan.nii');
mask = logical(medicalVolume('mask.nii').Voxels);

% Extract all texture features (92 total)
texture = textureFeatures(V.Voxels, mask);

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

### Texture Options

```matlab
% Specify discretization
texture = textureFeatures(V.Voxels, mask, ...
    'NumBins', 32, ...           % Number of gray levels
    'UseSymmetricGLCM', true);   % Symmetric GLCM (IBSI)

% Or use bin width
texture = textureFeatures(V.Voxels, mask, 'BinWidth', 25);
```

## IBSI Compliance

IBSI (Image Biomarker Standardisation Initiative) ensures reproducibility:

```matlab
% MATLAB radiomics functions follow IBSI naming and computation
% Feature names match IBSI standard

% Example: IBSI intensity feature names
intensity = intensityFeatures(V.Voxels, mask);
% intensity.Mean matches IBSI "Mean"
% intensity.RobustMeanAbsoluteDeviation matches IBSI "Robust Mean Absolute Deviation"

% For full IBSI compliance, use recommended settings
texture = textureFeatures(V.Voxels, mask, ...
    'NumBins', 32, ...
    'UseSymmetricGLCM', true);
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

% Extract features
features = extractRadiomicsFeatures(V_iso.Voxels, mask_iso.Voxels, V_iso.VoxelSpacing);
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

    % Extract features
    intensity = intensityFeatures(V.Voxels, mask, 'NumBins', 32);
    shape = shapeFeatures(mask, targetSpacing);
    texture = textureFeatures(V.Voxels, mask, 'NumBins', 32);

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
        mask = M.Voxels == label;

        % Skip small regions
        if sum(mask(:)) < 50
            continue;
        end

        % Extract features for this label
        intensity = intensityFeatures(V.Voxels, mask);
        shape = shapeFeatures(mask, V.VoxelSpacing);
        texture = textureFeatures(V.Voxels, mask);

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
config.numBins = 32;
config.useSymmetricGLCM = true;

features = textureFeatures(V.Voxels, mask, ...
    'NumBins', config.numBins, ...
    'UseSymmetricGLCM', config.useSymmetricGLCM);
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 6 (IBSI Standard and Radiomics)*
*See also: `segmentation-medsam.md` for creating segmentation masks*
