# Morphology: Medical-Specific Cleanup Recipes

The model knows standard morphological operations. This card provides medical-specific cleanup recipes with tuned parameters.

## Medical Cleanup Recipes

### Cell Segmentation Cleanup
```matlab
function cells = segment_and_clean_cells(img)
    bw = imbinarize(im2double(img), 'adaptive');

    % Use TWO SE sizes: small for noise, large for holes
    se_small = strel('disk', 2);
    se_large = strel('disk', 5);

    bw = imopen(bw, se_small);   % Remove noise spots
    bw = imclose(bw, se_large);  % Fill holes in cells
    bw = imfill(bw, 'holes');
    cells = bwareaopen(bw, 100); % Remove debris
end
```

### Vessel Segmentation Enhancement
```matlab
function vessels = enhance_vessels(bw_vessels)
    % Connect broken vessel segments
    vessels = imdilate(bw_vessels, strel('disk', 2));
    vessels = bwareaopen(vessels, 50);

    % Thin to centerlines for measurement
    centerlines = bwmorph(vessels, 'thin', Inf);
end
```

### Bone Mask Refinement (CT)
```matlab
function bone = refine_bone_mask(bw_bone)
    % Fill internal holes (trabecular bone has internal porosity)
    bone = imfill(bw_bone, 'holes');

    se = strel('disk', 3);
    bone = imclose(bone, se);  % Smooth boundaries
    bone = imopen(bone, se);
    bone = bwareaopen(bone, 200);  % Remove fragments
end
```

### Brain Mask Smoothing (MRI)
```matlab
function mask = smooth_brain_mask(bw)
    % After skull stripping, smooth jagged mask edges
    se = strel('disk', 5);
    mask = imclose(bw, se);    % Fill CSF spaces at surface
    mask = imopen(mask, se);   % Remove non-brain protrusions
    mask = imfill(mask, 'holes');
    mask = bwareafilt(mask, 1); % Keep largest component only
end
```

## Key Gotcha: SE Sizing for Medical Images

**SE radius must be smaller than the smallest feature you want to KEEP.**

```matlab
% WRONG: SE larger than cell radius removes cells
se = strel('disk', 15);  % Cells ~20px diameter
gone = imopen(cells, se);  % Cells disappear!

% CORRECT: SE radius < smallest feature / 2
se = strel('disk', 5);  % 5 < 20/2 = 10
preserved = imopen(cells, se);
```

## Operation Order Matters

```matlab
% Open THEN close (standard medical cleanup)
% 1. Open removes noise without changing object size
% 2. Close fills gaps after noise is removed
bw = imclose(imopen(bw, se), se);

% Close then open can fill noise gaps, then fail to remove them
```

---
*Source: MathWorks IPT Reference (R2025a)*
