# Medical Image Labeling Workflow

Ground truth labels are essential for training deep learning models and validating algorithms. This card covers the Medical Image Labeler app and programmatic labeling workflows.

## Medical Image Labeler App

### Launch App

```matlab
% Open app
medicalImageLabeler

% Or with specific data
V = medicalVolume('scan.nii');
medicalImageLabeler(V)

% Or with ground truth session
medicalImageLabeler('labeling_session.mat')
```

### App Workflow

1. **Create/Open Session**
   - New Session: Start fresh
   - Open Session: Resume previous work

2. **Load Data**
   - Add medicalVolume or medicalImage
   - Supports DICOM, NIfTI, NRRD

3. **Define Labels**
   - Create label definitions (e.g., "Tumor", "Liver")
   - Specify label type: Semantic (per-pixel) or Instance

4. **Label Images**
   - Draw ROIs using tools (brush, polygon, threshold)
   - Use AI assistants (MedSAM, MONAI Label)
   - Navigate through slices

5. **Export Results**
   - Export as groundTruthMedical object
   - Export as NIfTI/NRRD files
   - Export for deep learning datastores

## Label Definition Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Semantic** | Each pixel belongs to one class | Organ segmentation |
| **Instance** | Each object gets unique ID | Cell counting |
| **Polygon** | Vector ROI on single slice | 2D annotation |
| **Cuboid** | 3D bounding box | Object detection |

## Programmatic Labeling

### Create Ground Truth Object

```matlab
% Define data sources
dataSources = {
    medicalVolume('scan1.nii');
    medicalVolume('scan2.nii');
    medicalVolume('scan3.nii')
};

% Define label definitions
labelDefs = table(...
    {'Liver'; 'Tumor'; 'Background'}, ...          % Names
    {'Semantic'; 'Semantic'; 'Semantic'}, ...       % Types
    {[1 0 0]; [0 1 0]; [0 0 1]}, ...               % Colors (RGB)
    'VariableNames', {'Name', 'Type', 'Color'});

% Create ground truth object
gTruth = groundTruthMedical(dataSources, labelDefs);
```

### Add Labels Programmatically

```matlab
% Load image and create mask
V = medicalVolume('scan.nii');
liver_mask = V.Voxels > threshold;  % Example segmentation

% Add to ground truth
gTruth = addLabel(gTruth, 1, 'Liver', liver_mask);  % Source 1, label "Liver"

% Add another label
tumor_mask = createTumorMask(V);
gTruth = addLabel(gTruth, 1, 'Tumor', tumor_mask);
```

### Export Labels

```matlab
% Export as NIfTI files
exportLabels(gTruth, 'output_folder', 'FileFormat', 'nifti');

% Export as label matrices
labels = getLabelData(gTruth, 1);  % Get labels for source 1
disp(labels);  % Cell array of label masks
```

## MONAI Label Integration

MONAI Label provides pretrained medical imaging models:

### Setup MONAI Label Server

```bash
# In terminal (Python environment)
pip install monailabel
monailabel start_server --app radiology --studies /path/to/data
```

### Use in Medical Image Labeler

1. Open Medical Image Labeler
2. Load your volume
3. Go to **Labeling > MONAI Label**
4. Enter server URL (default: http://localhost:8000)
5. Select model (e.g., "segmentation_spleen")
6. Run inference
7. Edit results as needed
8. Submit for active learning

### Available MONAI Label Models

| App | Models |
|-----|--------|
| **radiology** | Spleen, liver, kidney segmentation |
| **pathology** | Nuclei segmentation |
| **endoscopy** | Polyp detection |

## Multi-Labeler Collaboration

For team-based annotation projects:

### Project Owner Setup

```matlab
% Create project with label definitions
labelDefs = createLabelDefinitions();

% Assign data to labelers
assignments = table(...
    {'scan1.nii'; 'scan2.nii'; 'scan3.nii'; 'scan4.nii'}, ...
    {'Alice'; 'Alice'; 'Bob'; 'Bob'}, ...
    'VariableNames', {'DataFile', 'Labeler'});

% Create session files for each labeler
for labeler = unique(assignments.Labeler)'
    files = assignments.DataFile(strcmp(assignments.Labeler, labeler));
    createLabelingSession(files, labelDefs, strcat(labeler{1}, '_session.mat'));
end
```

### Labeler Workflow

```matlab
% Labeler opens their assigned session
medicalImageLabeler('Alice_session.mat')

% Label images using app
% Save progress
% Export when complete
```

### Merge Labels

```matlab
% Project owner collects and merges
sessions = {'Alice_session.mat', 'Bob_session.mat'};
merged = mergeGroundTruth(sessions);

% Handle conflicts (if same image labeled by multiple)
merged = resolveConflicts(merged, 'Strategy', 'majority');
```

## Creating Training Datastores

For deep learning semantic segmentation:

```matlab
% Export ground truth
gTruth = groundTruthMedical('completed_session.mat');

% Create pixelLabelDatastore
pxds = pixelLabelDatastore(gTruth, {'Liver', 'Tumor'});

% Create imageDatastore for volumes
imds = imageDatastore(gTruth);

% Combine for training
trainDS = combine(imds, pxds);

% Use with trainNetwork or semanticseg
net = trainNetwork(trainDS, layers, options);
```

### For 3D Networks

```matlab
% Create 3D datastores
volDS = medicalImageDatastore('images/', 'FileExtensions', '.nii');
labelDS = medicalImageDatastore('labels/', 'FileExtensions', '.nii');

% Create training store
trainDS = randomPatchExtractionDatastore(volDS, labelDS, [64 64 64], ...
    'PatchesPerImage', 16);

% Train 3D network
net = trainNetwork(trainDS, layers3D, options);
```

## Label Quality Control

### Compute Labeling Metrics

```matlab
function metrics = evaluateLabels(predicted, groundTruth)
    % Both are binary masks

    % Dice coefficient
    intersection = sum(predicted(:) & groundTruth(:));
    metrics.dice = 2 * intersection / (sum(predicted(:)) + sum(groundTruth(:)));

    % Jaccard (IoU)
    union = sum(predicted(:) | groundTruth(:));
    metrics.jaccard = intersection / union;

    % Sensitivity (true positive rate)
    metrics.sensitivity = intersection / sum(groundTruth(:));

    % Specificity (true negative rate)
    tn = sum(~predicted(:) & ~groundTruth(:));
    metrics.specificity = tn / sum(~groundTruth(:));

    % Hausdorff distance (requires boundary extraction)
    bw1 = bwperim(predicted);
    bw2 = bwperim(groundTruth);
    [y1, x1] = find(bw1);
    [y2, x2] = find(bw2);
    if ~isempty(x1) && ~isempty(x2)
        d1 = min(pdist2([x1 y1], [x2 y2]), [], 2);
        d2 = min(pdist2([x2 y2], [x1 y1]), [], 2);
        metrics.hausdorff = max(max(d1), max(d2));
    else
        metrics.hausdorff = NaN;
    end

    fprintf('Dice: %.3f, IoU: %.3f, Sens: %.3f\n', ...
        metrics.dice, metrics.jaccard, metrics.sensitivity);
end
```

### Inter-Rater Agreement

```matlab
function kappa = computeKappa(labels1, labels2)
    % Cohen's Kappa for inter-rater reliability

    % Confusion matrix
    C = confusionmat(labels1(:), labels2(:));

    % Expected agreement
    n = sum(C(:));
    p_o = sum(diag(C)) / n;  % Observed agreement
    p_e = sum(sum(C,1) .* sum(C,2)') / n^2;  % Expected by chance

    kappa = (p_o - p_e) / (1 - p_e);

    fprintf('Cohen''s Kappa: %.3f\n', kappa);
    % Interpretation: <0.2 poor, 0.2-0.4 fair, 0.4-0.6 moderate, 0.6-0.8 good, >0.8 excellent
end
```

## Semi-Automatic Labeling

### Threshold-Based Initialization

```matlab
V = medicalVolume('scan.nii');

% Initial segmentation
level = graythresh(mat2gray(V.Voxels));
initial_mask = V.Voxels > level * max(V.Voxels(:));

% Clean up (using IPT - see cross-toolbox-ipt.md)
initial_mask = imopen(initial_mask, strel('sphere', 3));
initial_mask = imfill(initial_mask, 'holes');

% Load into labeler for manual refinement
gTruth = groundTruthMedical({V}, labelDefs);
gTruth = addLabel(gTruth, 1, 'Initial', initial_mask);

% Export for manual correction
save('initial_session.mat', 'gTruth');
medicalImageLabeler('initial_session.mat');
```

### Active Contour Refinement

```matlab
% Start with rough mask
rough_mask = getMask(gTruth, 1, 'Rough');

% Refine with active contours
slice = extractSlice(V, 50, 'transverse');
refined = activecontour(slice, rough_mask(:,:,50), 100, 'Chan-Vese');

% Replace in ground truth
gTruth = updateLabel(gTruth, 1, 'Refined', 50, refined);
```

## Best Practices

### Label Naming Conventions

```matlab
% Use consistent, descriptive names
labelDefs = table(...
    {'Background'; 'Liver_Parenchyma'; 'Liver_Tumor'; 'Liver_Vessel'}, ...
    {'Semantic'; 'Semantic'; 'Semantic'; 'Semantic'}, ...
    {[0 0 0]; [1 0.5 0]; [1 0 0]; [0 0 1]}, ...
    'VariableNames', {'Name', 'Type', 'Color'});

% Avoid: "Label1", "New Label", "asdf"
```

### Version Control

```matlab
% Save with timestamp
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = sprintf('labels_%s.mat', timestamp);
save(filename, 'gTruth');

% Or use notes
gTruth.Notes = 'Initial liver segmentation - reviewed by Dr. Smith';
```

### Backup Strategy

```matlab
% Auto-save during labeling
% Medical Image Labeler has auto-save, but also:

function autoBackup(gTruth, backupFolder)
    if ~exist(backupFolder, 'dir')
        mkdir(backupFolder);
    end

    filename = sprintf('backup_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));
    save(fullfile(backupFolder, filename), 'gTruth');

    % Keep only last 10 backups
    files = dir(fullfile(backupFolder, 'backup_*.mat'));
    if length(files) > 10
        [~, idx] = sort({files.date});
        delete(fullfile(backupFolder, files(idx(1)).name));
    end
end
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 5*
*See also: `segmentation-medsam.md` for AI-assisted labeling*
