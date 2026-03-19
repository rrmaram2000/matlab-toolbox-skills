# Feature Extraction: Advanced regionprops Patterns

The model knows basic regionprops, bwconncomp, and bwlabel well. This card covers advanced medical measurement patterns and non-obvious gotchas.

## Medical Measurement Pipelines

### Tumor Measurement with Physical Units
```matlab
function tumor_stats = analyze_tumor(tumor_mask, ct_image, pixel_spacing)
    % Keep only largest connected component
    tumor_mask = bwareafilt(tumor_mask, 1);

    stats = regionprops('table', tumor_mask, ct_image, ...
        'Area', 'Perimeter', 'Centroid', ...
        'MajorAxisLength', 'MinorAxisLength', ...
        'Eccentricity', 'Solidity', 'EquivDiameter', ...
        'MeanIntensity', 'MaxIntensity', 'MinIntensity');

    % Convert pixel measurements to physical units
    tumor_stats.Area_mm2 = stats.Area * pixel_spacing^2;
    tumor_stats.Perimeter_mm = stats.Perimeter * pixel_spacing;
    tumor_stats.MajorAxis_mm = stats.MajorAxisLength * pixel_spacing;
    tumor_stats.MinorAxis_mm = stats.MinorAxisLength * pixel_spacing;
    tumor_stats.Diameter_mm = stats.EquivDiameter * pixel_spacing;

    % Shape descriptors for malignancy assessment
    tumor_stats.Roundness = stats.Circularity;
    tumor_stats.Irregularity = 1 - stats.Solidity;  % Higher = more irregular

    % Intensity features (HU for CT)
    tumor_stats.HU_mean = stats.MeanIntensity;
    tumor_stats.HU_max = stats.MaxIntensity;
end
```

### Cell Population Analysis with Classification
```matlab
function [summary, individual] = analyze_cell_population(cell_mask, fluorescence)
    stats = regionprops('table', cell_mask, fluorescence, ...
        'Area', 'Eccentricity', 'MeanIntensity', 'Centroid');

    % Filter valid cells by area range
    valid = stats.Area > 50 & stats.Area < 2000;
    individual = stats(valid, :);

    % Population statistics
    summary.cell_count = height(individual);
    summary.mean_area = mean(individual.Area);
    summary.std_area = std(individual.Area);

    % Shape-based classification
    summary.round_cells = sum(individual.Eccentricity < 0.5);
    summary.elongated_cells = sum(individual.Eccentricity > 0.7);
end
```

## Critical Gotchas

### Centroid is [x, y], NOT [row, col]
```matlab
stats = regionprops('table', bw, 'Centroid');
centroid = stats.Centroid(1, :);  % [x, y]

% For matrix indexing: swap order!
row = round(centroid(2));  % y → row
col = round(centroid(1));  % x → col
pixel_value = I(row, col);
```

### Intensity Properties Require Grayscale Image
```matlab
% WRONG: Error!
stats = regionprops(bw, 'MeanIntensity');

% CORRECT: Provide grayscale image as second argument
stats = regionprops(bw, I, 'MeanIntensity');
```

### Always Use 'table' Output for Medical Analysis
```matlab
% Struct output requires manual extraction
stats_struct = regionprops(bw, 'Area');
areas = [stats_struct.Area];  % Manual extraction

% Table output enables vectorized filtering (much better for analysis)
stats = regionprops('table', bw, 'Area', 'Eccentricity');
valid = stats(stats.Area > 100 & stats.Eccentricity < 0.8, :);
```

---
*Source: MathWorks IPT Reference (R2025a)*
