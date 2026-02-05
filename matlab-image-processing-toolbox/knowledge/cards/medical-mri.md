# Medical Imaging: MRI Processing

Magnetic Resonance Imaging processing pipelines for brain, cardiac, and musculoskeletal analysis.

## MRI Characteristics

| Property | Details |
|----------|---------|
| Data type | Typically uint16 or int16 (DICOM), single/double (NIfTI) |
| Dynamic range | High (12-16 bits) |
| Noise type | Rician (magnitude images), Gaussian (phase) |
| Artifacts | Bias field (intensity inhomogeneity), motion, aliasing |
| Typical tasks | Tissue segmentation, lesion detection, volumetry |

## Reading MRI Data

### DICOM Format
```matlab
% Single slice
info = dicominfo('slice001.dcm');
img = dicomread('slice001.dcm');

% Display key metadata
fprintf('Patient: %s\n', info.PatientName.FamilyName);
fprintf('Modality: %s\n', info.Modality);
fprintf('Sequence: %s\n', info.SequenceName);
fprintf('TR/TE: %.1f/%.1f ms\n', info.RepetitionTime, info.EchoTime);
fprintf('Pixel spacing: %.2f x %.2f mm\n', info.PixelSpacing);
fprintf('Slice thickness: %.2f mm\n', info.SliceThickness);

% Read entire series
folder = 'path/to/dicom/series';
files = dir(fullfile(folder, '*.dcm'));
volume = zeros(info.Rows, info.Columns, length(files), 'like', img);
for i = 1:length(files)
    volume(:,:,i) = dicomread(fullfile(folder, files(i).name));
end
```

### NIfTI Format
```matlab
% NIfTI (common for processed MRI)
info = niftiinfo('brain.nii');
V = niftiread('brain.nii');

% Metadata
fprintf('Dimensions: %s\n', mat2str(info.ImageSize));
fprintf('Voxel size: %s mm\n', mat2str(info.PixelDimensions));
fprintf('Data type: %s\n', info.Datatype);
```

## Standard Preprocessing Pipeline

```matlab
function [preprocessed, brain_mask] = preprocess_mri(mri, options)
    % MRI preprocessing pipeline
    %
    % Steps:
    % 1. Intensity normalization
    % 2. Bias field correction
    % 3. Denoising
    % 4. Brain extraction (optional)
    % 5. Contrast enhancement

    arguments
        mri
        options.denoise = true
        options.bias_correct = true
        options.extract_brain = true
        options.enhance_contrast = true
    end

    % Convert to double [0,1]
    mri = im2double(mri);

    % 1. Bias field correction (intensity inhomogeneity)
    if options.bias_correct
        mri = correct_bias_field(mri);
    end

    % 2. Denoising (Rician noise in MRI)
    if options.denoise
        % Non-local means is best for MRI
        if exist('imnlmfilt', 'file')
            mri = imnlmfilt(mri, 'DegreeOfSmoothing', 0.02);
        else
            % Fallback to Wiener
            mri = wiener2(mri, [5 5]);
        end
    end

    % 3. Brain extraction
    brain_mask = [];
    if options.extract_brain
        brain_mask = extract_brain_mask(mri);
        % Apply mask (set background to 0)
        mri_masked = mri;
        mri_masked(~brain_mask) = 0;
    else
        mri_masked = mri;
    end

    % 4. Contrast enhancement within brain
    if options.enhance_contrast
        if ~isempty(brain_mask)
            % Enhance only brain region
            brain_pixels = mri_masked(brain_mask);
            enhanced_pixels = adapthisteq(brain_pixels, ...
                'NumTiles', [8 8], 'ClipLimit', 0.02);
            mri_masked(brain_mask) = enhanced_pixels;
        else
            mri_masked = adapthisteq(mri_masked, 'ClipLimit', 0.02);
        end
    end

    preprocessed = mri_masked;
end
```

## Bias Field Correction

Intensity inhomogeneity from RF coil sensitivity variations.

```matlab
function corrected = correct_bias_field(mri)
    % Simple homomorphic filtering approach
    % For production, use N4ITK or SPM's bias correction

    % Log transform (converts multiplicative bias to additive)
    mri_log = log1p(mri);

    % Estimate bias field (low-frequency component)
    bias_log = imgaussfilt(mri_log, 30);  % Large sigma

    % Subtract bias in log domain
    corrected_log = mri_log - bias_log;

    % Back to linear domain
    corrected = expm1(corrected_log);

    % Normalize to [0, 1]
    corrected = mat2gray(corrected);
end
```

## Brain Extraction (Skull Stripping)

```matlab
function brain_mask = extract_brain_mask(mri)
    % Simple brain extraction using morphology
    % For production, use BET (FSL) or more sophisticated methods

    % Initial threshold (brain + some non-brain)
    level = graythresh(mri);
    bw = imbinarize(mri, level * 0.5);  % Lower threshold

    % Fill holes
    bw = imfill(bw, 'holes');

    % Keep largest connected component (brain)
    bw = bwareafilt(bw, 1);

    % Morphological smoothing
    se = strel('disk', 5);
    brain_mask = imopen(bw, se);
    brain_mask = imclose(brain_mask, se);
    brain_mask = imfill(brain_mask, 'holes');
end
```

## Tissue Segmentation

### Three-Tissue Segmentation (CSF, GM, WM)

```matlab
function [csf, gm, wm] = segment_brain_tissues(mri, brain_mask)
    % Segment brain into CSF, gray matter, white matter
    %
    % Assumes T1-weighted MRI where:
    % - CSF: dark (low intensity)
    % - Gray matter: medium intensity
    % - White matter: bright (high intensity)

    % Apply brain mask
    brain_only = mri;
    brain_only(~brain_mask) = NaN;

    % Get brain intensities
    brain_pixels = mri(brain_mask);

    % Multi-level Otsu for 3 classes
    [thresh, em] = multithresh(brain_pixels, 2);
    fprintf('Threshold effectiveness: %.2f\n', em);

    % Quantize
    seg = imquantize(mri, thresh);
    seg(~brain_mask) = 0;

    % Extract masks
    csf = (seg == 1) & brain_mask;
    gm = (seg == 2) & brain_mask;
    wm = (seg == 3) & brain_mask;

    % Cleanup each tissue
    csf = morphological_cleanup(csf, 20, 2);
    gm = morphological_cleanup(gm, 50, 2);
    wm = morphological_cleanup(wm, 50, 2);
end

function bw = morphological_cleanup(bw, min_area, se_radius)
    se = strel('disk', se_radius);
    bw = imopen(bw, se);
    bw = imclose(bw, se);
    bw = bwareaopen(bw, min_area);
end
```

### White Matter Lesion Detection

```matlab
function lesion_mask = detect_wm_lesions(t2_flair, wm_mask)
    % Detect white matter lesions in FLAIR images
    % Lesions appear hyperintense (bright) on FLAIR

    % Normalize within WM
    wm_intensities = t2_flair(wm_mask);
    wm_mean = mean(wm_intensities);
    wm_std = std(wm_intensities);

    % Threshold: voxels > 2.5 SD above mean
    threshold = wm_mean + 2.5 * wm_std;
    lesion_mask = (t2_flair > threshold) & wm_mask;

    % Cleanup
    lesion_mask = bwareaopen(lesion_mask, 3);  % Min 3 voxels

    % Optional: Region growing from seeds
    % lesion_mask = region_growing(t2_flair, lesion_mask, wm_mask);
end
```

## Volumetric Analysis

```matlab
function volumes = calculate_brain_volumes(csf, gm, wm, voxel_size)
    % Calculate tissue volumes in mL
    %
    % voxel_size: [x, y, z] in mm (from DICOM PixelSpacing + SliceThickness)

    voxel_volume_mm3 = prod(voxel_size);
    voxel_volume_ml = voxel_volume_mm3 / 1000;  % mm³ to mL

    volumes.csf_ml = sum(csf(:)) * voxel_volume_ml;
    volumes.gm_ml = sum(gm(:)) * voxel_volume_ml;
    volumes.wm_ml = sum(wm(:)) * voxel_volume_ml;
    volumes.total_brain_ml = volumes.gm_ml + volumes.wm_ml;
    volumes.intracranial_ml = volumes.csf_ml + volumes.total_brain_ml;

    % Brain parenchymal fraction
    volumes.bpf = volumes.total_brain_ml / volumes.intracranial_ml;

    fprintf('CSF: %.1f mL\n', volumes.csf_ml);
    fprintf('Gray matter: %.1f mL\n', volumes.gm_ml);
    fprintf('White matter: %.1f mL\n', volumes.wm_ml);
    fprintf('Brain parenchymal fraction: %.2f\n', volumes.bpf);
end
```

## Complete MRI Analysis Pipeline

```matlab
function results = analyze_brain_mri(dicom_folder, options)
    % Complete brain MRI analysis pipeline

    arguments
        dicom_folder char
        options.output_folder = 'results'
        options.save_masks = true
    end

    % 1. Load DICOM series
    fprintf('Loading DICOM series...\n');
    [volume, info] = load_dicom_series(dicom_folder);

    % Get voxel size
    voxel_size = [info(1).PixelSpacing; info(1).SliceThickness]';

    % 2. Process each slice
    fprintf('Preprocessing...\n');
    preprocessed = zeros(size(volume));
    brain_masks = false(size(volume));

    for z = 1:size(volume, 3)
        [preprocessed(:,:,z), brain_masks(:,:,z)] = ...
            preprocess_mri(volume(:,:,z));
    end

    % 3. 3D brain mask cleanup
    brain_mask_3d = brain_masks;
    brain_mask_3d = imfill(brain_mask_3d, 'holes');

    % 4. Tissue segmentation
    fprintf('Segmenting tissues...\n');
    [csf, gm, wm] = segment_3d_tissues(preprocessed, brain_mask_3d);

    % 5. Calculate volumes
    fprintf('Calculating volumes...\n');
    results.volumes = calculate_brain_volumes(csf, gm, wm, voxel_size);

    % 6. Save results
    if options.save_masks
        mkdir(options.output_folder);
        niftiwrite(single(preprocessed), ...
            fullfile(options.output_folder, 'preprocessed.nii'));
        niftiwrite(uint8(brain_mask_3d), ...
            fullfile(options.output_folder, 'brain_mask.nii'));
    end

    results.preprocessed = preprocessed;
    results.brain_mask = brain_mask_3d;
    results.csf = csf;
    results.gm = gm;
    results.wm = wm;
end

function [volume, info] = load_dicom_series(folder)
    files = dir(fullfile(folder, '*.dcm'));
    info = dicominfo(fullfile(folder, files(1).name));
    sample = dicomread(fullfile(folder, files(1).name));

    volume = zeros(size(sample, 1), size(sample, 2), length(files), 'like', sample);
    for i = 1:length(files)
        volume(:,:,i) = dicomread(fullfile(folder, files(i).name));
    end
end
```

## Common Issues and Solutions

### Issue 1: Inconsistent Intensity Across Slices
```matlab
% Normalize each slice independently
for z = 1:size(V, 3)
    V(:,:,z) = mat2gray(V(:,:,z));
end
```

### Issue 2: Motion Artifacts
```matlab
% Detect slices with motion (high variance in difference)
for z = 2:size(V, 3)
    diff_img = abs(V(:,:,z) - V(:,:,z-1));
    if std(diff_img(:)) > threshold
        fprintf('Possible motion artifact at slice %d\n', z);
    end
end
```

### Issue 3: Partial Volume Effects
```matlab
% At tissue boundaries, voxels contain multiple tissues
% Use probability maps instead of hard segmentation for quantification
% Or use higher resolution acquisition
```

---
*Source: MathWorks IPT Documentation (R2024b), Medical Image Processing examples*
