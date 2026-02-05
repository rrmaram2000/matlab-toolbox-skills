# MedSAM - Medical Segment Anything Model

MedSAM is an AI model for interactive medical image segmentation. It uses prompts (points, boxes) to segment objects, adapting the Segment Anything Model (SAM) for medical imaging.

## Prerequisites

```matlab
% Install support package (one-time)
% MATLAB Add-Ons > Get Add-Ons > "Medical Segment Anything Model"
% Or via command:
matlab.addons.install('Medical Imaging Toolbox Model for Segment Anything')
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `medicalSegmentAnythingModel` | Load MedSAM model |
| `extractEmbeddings` | Compute image embeddings |
| `segmentObjectsFromEmbeddings` | Segment using prompts |

## Basic Workflow

### 1. Load Model

```matlab
% Load pretrained MedSAM
model = medicalSegmentAnythingModel;

% Check model properties
disp(model);
```

### 2. Prepare Image

```matlab
V = medicalVolume('ct_scan.nii');

% Extract a 2D slice for segmentation
slice_idx = round(V.NumTransverseSlices / 2);
slice = extractSlice(V, slice_idx, 'transverse');

% Convert to appropriate format
% MedSAM expects grayscale or RGB
slice = mat2gray(double(slice));
```

### 3. Extract Embeddings

```matlab
% Compute image embeddings (cached for multiple prompts)
embeddings = extractEmbeddings(model, slice);
```

### 4. Segment with Prompts

```matlab
% Using bounding box prompt
bbox = [100, 100, 150, 120];  % [x, y, width, height]
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'BoundingBox', bbox);

% Using point prompts
foreground_point = [175, 160];  % Point inside object
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', foreground_point);

% Combining foreground and background points
fg_points = [175, 160; 180, 155];  % Inside object
bg_points = [50, 50; 250, 200];    % Outside object
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', fg_points, ...
    'BackgroundPoints', bg_points);
```

## Prompt Types

### Bounding Box

Rectangular region containing the object:

```matlab
% Define bounding box [x, y, width, height]
% x, y are top-left corner
bbox = [xmin, ymin, width, height];

mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'BoundingBox', bbox);

% Visualize
figure;
imshow(slice);
hold on;
rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
contour(mask, [0.5 0.5], 'g', 'LineWidth', 2);
hold off;
```

### Point Prompts

Click-based interaction:

```matlab
% Single foreground point
fg = [150, 120];  % [x, y] inside object
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', fg);

% Multiple foreground points (for complex shapes)
fg_points = [150, 120;   % Point 1
             160, 130;   % Point 2
             140, 140];  % Point 3
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', fg_points);

% With background points (to exclude regions)
bg_points = [50, 50;     % Point outside
             200, 30];   % Another outside point
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', fg_points, ...
    'BackgroundPoints', bg_points);
```

### Interactive Point Selection

```matlab
function mask = interactiveMedSAM(slice, model)
    % Extract embeddings once
    embeddings = extractEmbeddings(model, mat2gray(slice));

    % Display image
    figure('Name', 'MedSAM Interactive Segmentation');
    imshow(slice, []);
    title('Left-click: foreground, Right-click: background, Enter: done');

    fg_points = [];
    bg_points = [];

    while true
        [x, y, button] = ginput(1);

        if isempty(button)
            break;  % Enter pressed
        end

        if button == 1  % Left click - foreground
            fg_points = [fg_points; x, y];
            hold on;
            plot(x, y, 'go', 'MarkerSize', 10, 'LineWidth', 2);
        elseif button == 3  % Right click - background
            bg_points = [bg_points; x, y];
            hold on;
            plot(x, y, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
        end

        % Update segmentation
        if ~isempty(fg_points)
            mask = segmentObjectsFromEmbeddings(model, embeddings, ...
                'ForegroundPoints', fg_points, ...
                'BackgroundPoints', bg_points);

            % Display current mask
            hold on;
            contour(mask, [0.5 0.5], 'c', 'LineWidth', 1);
            drawnow;
        end
    end

    hold off;
end
```

## Segmenting 3D Volumes

MedSAM processes 2D slices. For 3D volumes, segment slice-by-slice:

### Propagate from Single Slice

```matlab
function volume_mask = segment3DFromSeed(V, model, seed_slice, prompt)
    % Segment seed slice
    slice = extractSlice(V, seed_slice, 'transverse');
    slice = mat2gray(double(slice));
    embeddings = extractEmbeddings(model, slice);

    if isstruct(prompt) && isfield(prompt, 'BoundingBox')
        seed_mask = segmentObjectsFromEmbeddings(model, embeddings, ...
            'BoundingBox', prompt.BoundingBox);
    else
        seed_mask = segmentObjectsFromEmbeddings(model, embeddings, ...
            'ForegroundPoints', prompt.ForegroundPoints);
    end

    % Initialize volume mask
    volume_mask = false(size(V.Voxels));
    volume_mask(:,:,seed_slice) = seed_mask;

    % Propagate upward
    for k = seed_slice+1:V.NumTransverseSlices
        slice = mat2gray(double(extractSlice(V, k, 'transverse')));
        embeddings = extractEmbeddings(model, slice);

        % Use previous mask centroid as prompt
        prev_mask = volume_mask(:,:,k-1);
        if ~any(prev_mask(:))
            break;  % Lost object
        end

        props = regionprops(prev_mask, 'Centroid', 'BoundingBox');
        if ~isempty(props)
            fg = props(1).Centroid;
            mask = segmentObjectsFromEmbeddings(model, embeddings, ...
                'ForegroundPoints', fg);
            volume_mask(:,:,k) = mask;
        end
    end

    % Propagate downward
    for k = seed_slice-1:-1:1
        slice = mat2gray(double(extractSlice(V, k, 'transverse')));
        embeddings = extractEmbeddings(model, slice);

        prev_mask = volume_mask(:,:,k+1);
        if ~any(prev_mask(:))
            break;
        end

        props = regionprops(prev_mask, 'Centroid');
        if ~isempty(props)
            fg = props(1).Centroid;
            mask = segmentObjectsFromEmbeddings(model, embeddings, ...
                'ForegroundPoints', fg);
            volume_mask(:,:,k) = mask;
        end
    end

    fprintf('Segmented %d slices\n', sum(any(any(volume_mask, 1), 2)));
end
```

### Batch Process All Slices

```matlab
function masks = batchMedSAM(V, model, prompts)
    % prompts is a struct array with fields for each slice
    % prompts(k).ForegroundPoints or prompts(k).BoundingBox

    masks = false(size(V.Voxels));

    for k = 1:V.NumTransverseSlices
        if ~isempty(prompts(k).ForegroundPoints) || ~isempty(prompts(k).BoundingBox)
            slice = mat2gray(double(extractSlice(V, k, 'transverse')));
            embeddings = extractEmbeddings(model, slice);

            if ~isempty(prompts(k).BoundingBox)
                mask = segmentObjectsFromEmbeddings(model, embeddings, ...
                    'BoundingBox', prompts(k).BoundingBox);
            else
                mask = segmentObjectsFromEmbeddings(model, embeddings, ...
                    'ForegroundPoints', prompts(k).ForegroundPoints);
            end

            masks(:,:,k) = mask;
        end
    end
end
```

## MedSAM in Medical Image Labeler

Interactive GUI-based usage:

```matlab
% Open Medical Image Labeler
medicalImageLabeler

% Steps:
% 1. Load volume
% 2. Create label definition
% 3. Select MedSAM tool
% 4. Draw bounding box or click points
% 5. Accept or refine segmentation
% 6. Export labels
```

## Performance Tips

### Reuse Embeddings

```matlab
% Embedding extraction is slow, segmentation is fast
% Extract once, segment multiple times

slice = mat2gray(extractSlice(V, 50, 'transverse'));
embeddings = extractEmbeddings(model, slice);  % Slow (~1 sec)

% Multiple segmentations with different prompts (fast)
mask1 = segmentObjectsFromEmbeddings(model, embeddings, 'BoundingBox', bbox1);
mask2 = segmentObjectsFromEmbeddings(model, embeddings, 'BoundingBox', bbox2);
mask3 = segmentObjectsFromEmbeddings(model, embeddings, 'ForegroundPoints', pts);
```

### GPU Acceleration

```matlab
% Check GPU availability
if canUseGPU()
    model = medicalSegmentAnythingModel('ExecutionEnvironment', 'gpu');
    fprintf('Using GPU: %s\n', gpuDevice().Name);
else
    model = medicalSegmentAnythingModel('ExecutionEnvironment', 'cpu');
end
```

### Batch Embeddings

```matlab
% Pre-compute embeddings for all slices
embeddings_all = cell(1, V.NumTransverseSlices);

for k = 1:V.NumTransverseSlices
    slice = mat2gray(double(extractSlice(V, k, 'transverse')));
    embeddings_all{k} = extractEmbeddings(model, slice);

    if mod(k, 10) == 0
        fprintf('Embeddings: %d/%d\n', k, V.NumTransverseSlices);
    end
end

% Now segmentation is fast
for k = 1:V.NumTransverseSlices
    if hasPrompt(k)
        mask = segmentObjectsFromEmbeddings(model, embeddings_all{k}, ...
            'ForegroundPoints', prompts(k).fg);
    end
end
```

## Complete Example: Liver Segmentation

```matlab
% Load CT scan
V = medicalVolume('abdomen_ct.nii');
model = medicalSegmentAnythingModel;

% Find middle slice (liver visible)
slice_idx = 60;
slice = mat2gray(double(extractSlice(V, slice_idx, 'transverse')));

% Extract embeddings
embeddings = extractEmbeddings(model, slice);

% Interactive selection (or define programmatically)
figure;
imshow(slice);
title('Click inside liver, then press Enter');
[x, y] = ginput(1);

% Segment
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', [x, y]);

% Visualize
figure;
imshow(slice);
hold on;
contour(mask, [0.5 0.5], 'r', 'LineWidth', 2);
plot(x, y, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
title('Liver Segmentation');

% Propagate to 3D (using function above)
prompt.ForegroundPoints = [x, y];
liver_mask = segment3DFromSeed(V, model, slice_idx, prompt);

% Post-process with IPT (see cross-toolbox-ipt.md)
liver_mask = imopen(liver_mask, strel('sphere', 3));
liver_mask = imfill(liver_mask, 'holes');

% Save
V_seg = medicalVolume(uint8(liver_mask), V.VolumeGeometry);
V_seg.Modality = 'SEG';
write(V_seg, 'liver_segmentation.nii');
```

## Common Issues

### Issue: Segmentation includes unwanted regions

Use background points to exclude:

```matlab
fg = [150, 120];  % Inside target
bg = [100, 80;    % In unwanted region 1
      200, 150];  % In unwanted region 2

mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', fg, ...
    'BackgroundPoints', bg);
```

### Issue: Segmentation too small/large

Adjust prompts or post-process:

```matlab
% Add more foreground points
fg_points = [150, 120; 160, 130; 155, 140];

% Or expand with morphology (IPT)
mask = imdilate(mask, strel('disk', 5));
```

### Issue: Memory error on large images

```matlab
% Resize before processing
scale = 0.5;
slice_small = imresize(slice, scale);
embeddings = extractEmbeddings(model, slice_small);

% Scale prompt coordinates
fg_small = fg_points * scale;
mask_small = segmentObjectsFromEmbeddings(model, embeddings, ...
    'ForegroundPoints', fg_small);

% Resize mask back
mask = imresize(mask_small, 1/scale, 'nearest') > 0.5;
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 6 (MedSAM sections)*
*See also: `labeling-workflow.md` for Medical Image Labeler integration*
