# Image Processing Toolbox Skill - Test Results

**Test Date:** 2026-02-04
**Skill:** matlab-image-processing-toolbox
**Platform:** Claude Desktop with skill toggle

---

## Test 1: Overlapping Cell Segmentation

**Question:**
```
How do I segment overlapping cells in a microscopy image in MATLAB?
```

### Without Skill

Claude provides a working marker-controlled watershed pipeline:

```matlab
% Preprocessing
img = imread('cells.tif');
gray = im2gray(img);
enhanced = adapthisteq(gray);

% Binarization
bw = imbinarize(enhanced, 'adaptive', 'Sensitivity', 0.6);
bw = imfill(bw, 'holes');
bw = imopen(bw, strel('disk', 3));

% Distance transform + watershed
D = -bwdist(~bw);
D = imhmin(D, 2);
markers = imregionalmin(D);
markers = imdilate(markers, strel('disk', 1));

D2 = imimposemin(D, markers | ~bw);
L = watershed(D2);
L(~bw) = 0;

% Visualization
rgb = label2rgb(L, 'jet', 'k', 'shuffle');
imshow(rgb);
```

Also mentions:
- regionprops for post-processing
- Cellpose as Python-based alternative
- General tuning tips for imhmin

### With Skill

Claude provides a complete, production-ready script with extensive documentation:

```matlab
%% 1. Load and preprocess
img = imread('cells.tif');
gray = im2double(rgb2gray(img));

% Background correction via top-hat transform
% SE radius should be larger than the largest cell
se_bg = strel('disk', 50);
corrected = imtophat(gray, se_bg);

% Denoise with Gaussian
smoothed = imgaussfilt(corrected, 1.5);

%% 2. Binarize with adaptive thresholding
bw = imbinarize(smoothed, 'adaptive', ...
    'Sensitivity', 0.5, ...
    'ForegroundPolarity', 'bright');

%% 3. Morphological cleanup
se = strel('disk', 3);
bw = imopen(bw, se);
bw = imfill(bw, 'holes');
bw = bwareaopen(bw, 100);
bw = imclearborder(bw);  % Remove border-touching objects

%% 4. Distance transform + watershed
D = -bwdist(~bw);
h = 2;  % Suppress shallow minima (2-5 for most cells)
D = imhmin(D, h);

%% 5. Marker-controlled watershed
markers = imregionalmax(smoothed);
markers = markers & bw;
D_imposed = imimposemin(D, ~bw | markers);
L = watershed(D_imposed);

segmented = bw;
segmented(L == 0) = 0;

%% 6. Measure region properties
stats = regionprops('table', segmented, gray, ...
    'Area', 'Centroid', 'Eccentricity', 'Circularity', ...
    'MeanIntensity', 'MajorAxisLength', 'MinorAxisLength');

valid = stats.Area >= 100 & stats.Area <= 10000 & ...
        stats.Circularity >= 0.3;
stats = stats(valid, :);
```

Additional features:
- Academic references (Meyer 1994, Vincent & Soille 1991)
- Detailed parameter tuning guidance
- Complete visualization with centroid overlay
- Mentions native alternatives (activecontour, semanticseg)

### Comparison Summary

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Background correction | `adapthisteq` | **`imtophat`** (more robust) |
| Border handling | Not included | **`imclearborder`** |
| Parameter guidance | General tips | **Specific values with ranges** |
| regionprops fields | 3 fields | **7 fields including Circularity** |
| Academic references | None | **Meyer 1994, Vincent & Soille 1991** |
| Code documentation | Basic | **Production-ready with full comments** |
| Alternative methods | Cellpose (Python) | **Native MATLAB options** |

### Verdict

**Good improvement.** The skill transforms a working solution into a production-ready, well-documented pipeline with:
- More robust preprocessing (top-hat vs CLAHE)
- Comprehensive morphological cleanup
- Specific parameter tuning guidance
- Academic references for methodology
- Native MATLAB alternatives instead of Python dependencies

The improvement is practical and adds real value for researchers implementing cell segmentation workflows.

---

## Overall Assessment

The Image Processing Toolbox skill shows **good improvement** in:
- Code quality and documentation
- Preprocessing robustness
- Parameter guidance specificity
- Academic rigor (citations)

The skill elevates responses from "working code" to "production-ready pipelines."
