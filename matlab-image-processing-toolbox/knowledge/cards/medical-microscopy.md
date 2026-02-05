# Medical Imaging: Microscopy & Histology

Image analysis for microscopy images including cell counting, histology analysis, and immunofluorescence quantification.

## Microscopy Image Characteristics

| Modality | Characteristics | Common Tasks |
|----------|-----------------|--------------|
| Brightfield | Cells appear dark on light background | Cell counting, morphometry |
| Phase contrast | Halo artifacts around cells | Live cell tracking |
| Fluorescence | Bright objects on dark background | Protein localization, quantification |
| H&E Histology | Pink (eosin) and blue (hematoxylin) staining | Tissue classification, cell detection |

## Standard Preprocessing

### Background Correction
```matlab
function corrected = correct_background(img, method)
    % Correct uneven illumination common in microscopy
    %
    % Methods:
    % 'rolling_ball' - Rolling ball algorithm
    % 'gaussian'     - Large Gaussian blur
    % 'polynomial'   - Fit polynomial surface

    arguments
        img double
        method = 'gaussian'
    end

    switch method
        case 'gaussian'
            % Estimate background with large Gaussian
            sigma = max(size(img)) / 10;
            background = imgaussfilt(img, sigma);
            corrected = img - background;

        case 'morphological'
            % Top-hat transform
            se = strel('disk', 50);
            corrected = imtophat(img, se);

        case 'rolling_ball'
            % Morphological opening approximates rolling ball
            se = strel('disk', 30);
            background = imopen(img, se);
            corrected = img - background;
    end

    % Normalize to [0, 1]
    corrected = mat2gray(corrected);
end
```

### Color Deconvolution (H&E Staining)
```matlab
function [hematoxylin, eosin] = color_deconvolve_he(rgb)
    % Separate hematoxylin and eosin channels
    % Based on Ruifrok and Johnston (2001)

    % Standard H&E stain vectors (can be calibrated)
    % Columns: [Hematoxylin, Eosin, Background]
    stain_matrix = [
        0.644, 0.093, 0.0;   % R
        0.717, 0.954, 0.0;   % G
        0.267, 0.283, 0.0    % B
    ];

    % Normalize stain vectors
    for i = 1:3
        stain_matrix(:,i) = stain_matrix(:,i) / norm(stain_matrix(:,i));
    end

    % Convert to optical density
    rgb_double = im2double(rgb);
    rgb_double(rgb_double == 0) = 1e-6;  % Avoid log(0)
    od = -log10(rgb_double);

    % Reshape for matrix multiplication
    [rows, cols, ~] = size(od);
    od_reshaped = reshape(od, rows*cols, 3)';

    % Deconvolve
    stain_inv = pinv(stain_matrix);
    concentrations = stain_inv * od_reshaped;

    % Reshape back
    hematoxylin = reshape(concentrations(1,:), rows, cols);
    eosin = reshape(concentrations(2,:), rows, cols);

    % Normalize
    hematoxylin = mat2gray(hematoxylin);
    eosin = mat2gray(eosin);
end
```

## Cell Counting Pipeline

### Automated Cell Detection
```matlab
function [count, stats, labeled] = count_cells(img, options)
    % Automated cell counting
    %
    % Returns:
    % count   - Number of cells detected
    % stats   - Table of cell measurements
    % labeled - Label image for visualization

    arguments
        img
        options.min_area = 50          % Minimum cell area (pixels)
        options.max_area = 5000        % Maximum cell area
        options.min_circularity = 0.4  % Minimum circularity
        options.sensitivity = 0.5      % Threshold sensitivity
        options.foreground = 'bright'  % 'bright' or 'dark'
    end

    % Convert to grayscale if needed
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = im2double(img);

    % Background correction
    img = correct_background(img, 'gaussian');

    % Adaptive thresholding
    bw = imbinarize(img, 'adaptive', ...
        'Sensitivity', options.sensitivity, ...
        'ForegroundPolarity', options.foreground);

    % Morphological cleanup
    se = strel('disk', 3);
    bw = imopen(bw, se);    % Remove noise
    bw = imfill(bw, 'holes');

    % Size filtering
    bw = bwareaopen(bw, options.min_area);

    % Separate touching cells with watershed
    bw = separate_touching_cells(bw);

    % Remove objects touching border
    bw = imclearborder(bw);

    % Measure properties
    stats = regionprops('table', bw, img, ...
        'Area', 'Centroid', 'Eccentricity', 'Circularity', ...
        'MeanIntensity', 'PerimeterOld', 'MajorAxisLength', 'MinorAxisLength');

    % Filter by criteria
    valid = stats.Area >= options.min_area & ...
            stats.Area <= options.max_area & ...
            stats.Circularity >= options.min_circularity;

    stats = stats(valid, :);
    count = height(stats);

    % Create labeled image
    [labeled, ~] = bwlabel(bw);

    fprintf('Detected %d cells\n', count);
end
```

### Separate Touching Cells (Watershed)
```matlab
function separated = separate_touching_cells(bw)
    % Use watershed to separate touching/overlapping cells

    % Distance transform
    D = -bwdist(~bw);

    % Suppress shallow minima (avoid over-segmentation)
    D = imhmin(D, 2);

    % Watershed
    L = watershed(D);

    % Combine with original mask
    separated = bw;
    separated(L == 0) = 0;
end
```

### Marker-Controlled Watershed
```matlab
function separated = watershed_marker_controlled(bw, img)
    % More robust watershed using intensity-based markers

    % Find regional maxima as cell centers
    img_smooth = imgaussfilt(img, 2);
    markers = imregionalmax(img_smooth);
    markers = markers & bw;  % Only markers inside cells

    % Distance transform
    D = -bwdist(~bw);

    % Impose minima at marker locations
    D = imimposemin(D, ~bw | markers);

    % Watershed
    L = watershed(D);

    % Apply to original mask
    separated = bw;
    separated(L == 0) = 0;
end
```

## Fluorescence Image Analysis

### Multi-Channel Fluorescence
```matlab
function results = analyze_fluorescence(blue, green, red, options)
    % Analyze multi-channel fluorescence microscopy
    %
    % Typical channels:
    % Blue (DAPI)  - Nuclei
    % Green (FITC) - Protein of interest
    % Red (TRITC)  - Second marker

    arguments
        blue double   % DAPI channel
        green double  % Green fluorescence
        red double    % Red fluorescence
        options.dapi_thresh = 'auto'
    end

    % 1. Segment nuclei from DAPI
    if strcmp(options.dapi_thresh, 'auto')
        nuclei = imbinarize(blue, 'adaptive', 'Sensitivity', 0.6);
    else
        nuclei = imbinarize(blue, options.dapi_thresh);
    end
    nuclei = bwareaopen(nuclei, 50);
    nuclei = imfill(nuclei, 'holes');
    nuclei = separate_touching_cells(nuclei);

    % 2. Measure each nucleus
    stats = regionprops('table', nuclei, ...
        'Area', 'Centroid', 'PixelIdxList');

    % 3. Quantify fluorescence per cell
    n_cells = height(stats);
    green_intensity = zeros(n_cells, 1);
    red_intensity = zeros(n_cells, 1);

    for i = 1:n_cells
        pixels = stats.PixelIdxList{i};
        green_intensity(i) = mean(green(pixels));
        red_intensity(i) = mean(red(pixels));
    end

    % 4. Compile results
    results.cell_count = n_cells;
    results.nuclei_mask = nuclei;
    results.stats = stats;
    results.stats.GreenMean = green_intensity;
    results.stats.RedMean = red_intensity;
    results.stats.GreenRedRatio = green_intensity ./ (red_intensity + eps);

    % 5. Summary statistics
    results.summary.mean_green = mean(green_intensity);
    results.summary.std_green = std(green_intensity);
    results.summary.mean_red = mean(red_intensity);
    results.summary.std_red = std(red_intensity);
end
```

### Colocalization Analysis
```matlab
function coloc = analyze_colocalization(ch1, ch2, mask)
    % Analyze colocalization between two channels
    %
    % Returns Pearson's correlation, Manders' coefficients

    if nargin < 3
        mask = true(size(ch1));
    end

    % Get pixels within mask
    px1 = ch1(mask);
    px2 = ch2(mask);

    % Pearson's correlation coefficient
    coloc.pearson = corr(px1(:), px2(:));

    % Manders' coefficients
    % M1: fraction of ch1 overlapping with ch2
    % M2: fraction of ch2 overlapping with ch1
    ch2_thresh = graythresh(ch2);
    ch1_thresh = graythresh(ch1);

    ch1_in_ch2 = px1(px2 > ch2_thresh * max(px2));
    ch2_in_ch1 = px2(px1 > ch1_thresh * max(px1));

    coloc.manders_m1 = sum(ch1_in_ch2) / sum(px1);
    coloc.manders_m2 = sum(ch2_in_ch1) / sum(px2);

    % Overlap coefficient
    coloc.overlap = sum(px1 .* px2) / sqrt(sum(px1.^2) * sum(px2.^2));
end
```

## Histology Analysis

### Nuclei Detection in H&E
```matlab
function [nuclei_mask, stats] = detect_nuclei_he(rgb_image)
    % Detect nuclei in H&E stained histology images

    % Color deconvolution
    [hematoxylin, ~] = color_deconvolve_he(rgb_image);

    % Hematoxylin stains nuclei blue/purple
    nuclei_enhanced = adapthisteq(hematoxylin, 'ClipLimit', 0.02);

    % Threshold
    nuclei_mask = imbinarize(nuclei_enhanced, 'adaptive', ...
        'Sensitivity', 0.6, 'ForegroundPolarity', 'bright');

    % Cleanup
    nuclei_mask = bwareaopen(nuclei_mask, 20);
    nuclei_mask = imfill(nuclei_mask, 'holes');
    nuclei_mask = separate_touching_cells(nuclei_mask);

    % Measure
    gray = rgb2gray(rgb_image);
    stats = regionprops('table', nuclei_mask, im2double(gray), ...
        'Area', 'Centroid', 'Eccentricity', 'MeanIntensity');
end
```

### Tissue Classification
```matlab
function tissue_map = classify_tissue_he(rgb_image)
    % Simple tissue classification in H&E
    % Classes: background, stroma, epithelium, necrosis

    % Convert to Lab color space
    lab = rgb2lab(rgb_image);

    % Extract features
    features = cat(3, ...
        lab(:,:,1), ...  % L (lightness)
        lab(:,:,2), ...  % a (green-red)
        lab(:,:,3));     % b (blue-yellow)

    % Reshape for clustering
    [rows, cols, ~] = size(features);
    X = reshape(features, rows*cols, 3);

    % K-means clustering (4 clusters)
    [idx, ~] = kmeans(X, 4, 'Replicates', 3);
    tissue_map = reshape(idx, rows, cols);

    % Note: Clusters need to be mapped to tissue types
    % based on color characteristics
end
```

## Batch Processing

### Process Multiple Images
```matlab
function results = batch_count_cells(image_folder, options)
    % Process all images in a folder

    arguments
        image_folder char
        options.pattern = '*.tif'
        options.output_folder = ''
    end

    files = dir(fullfile(image_folder, options.pattern));
    n_files = length(files);

    results = table('Size', [n_files, 4], ...
        'VariableTypes', {'string', 'double', 'double', 'double'}, ...
        'VariableNames', {'Filename', 'CellCount', 'MeanArea', 'MeanIntensity'});

    for i = 1:n_files
        filepath = fullfile(image_folder, files(i).name);
        fprintf('Processing %d/%d: %s\n', i, n_files, files(i).name);

        img = imread(filepath);
        [count, stats, ~] = count_cells(img);

        results.Filename(i) = files(i).name;
        results.CellCount(i) = count;
        results.MeanArea(i) = mean(stats.Area);
        results.MeanIntensity(i) = mean(stats.MeanIntensity);
    end

    % Summary
    fprintf('\n=== Summary ===\n');
    fprintf('Total images: %d\n', n_files);
    fprintf('Mean cells per image: %.1f\n', mean(results.CellCount));
    fprintf('Total cells counted: %d\n', sum(results.CellCount));
end
```

## Common Pitfalls

### 1. Over-segmentation with Watershed
```matlab
% PROBLEM: Too many small segments
D = -bwdist(~bw);
L = watershed(D);  % Over-segmented!

% FIX: Suppress shallow minima
D = imhmin(D, 3);  % Merge minima < 3 pixels deep
L = watershed(D);
```

### 2. Background Fluorescence
```matlab
% PROBLEM: High background affects quantification
mean_signal = mean(fluorescence(mask));  % Includes background!

% FIX: Subtract local background
local_bg = imgaussfilt(fluorescence, 50);
corrected = fluorescence - local_bg;
mean_signal = mean(corrected(mask));
```

### 3. Out-of-Focus Cells
```matlab
% Detect out-of-focus regions using variance
local_var = stdfilt(img, ones(21));
in_focus_mask = local_var > threshold;

% Only analyze in-focus cells
cells_in_focus = cells & in_focus_mask;
```

---
*Source: MathWorks IPT Documentation (R2024b), Image Processing examples, Cell counting tutorials*
