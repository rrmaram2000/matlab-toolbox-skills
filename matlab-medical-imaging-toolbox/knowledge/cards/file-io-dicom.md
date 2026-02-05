# DICOM File I/O

DICOM (Digital Imaging and Communications in Medicine) is the standard for clinical medical imaging. This card covers reading, writing, and managing DICOM files and series.

## Key Functions

| Function | Purpose |
|----------|---------|
| `medicalVolume` | Load DICOM series as 3D volume with spatial info |
| `medicalImage` | Load DICOM as 2D image series (ultrasound, video) |
| `dicomread` | Read single DICOM file (raw pixel data) |
| `dicominfo` | Read DICOM metadata (tags, patient info) |
| `dicomCollection` | Catalog DICOM folder structure |
| `dicomwrite` | Write DICOM file |
| `dicomanon` | Anonymize DICOM files |

## Reading DICOM Series

### Using medicalVolume (Recommended)

The `medicalVolume` object automatically handles series loading and spatial referencing:

```matlab
% From directory of DICOM files (e.g., CT scan)
V = medicalVolume('path/to/dicom_folder');

% Properties available:
disp(V.Voxels);           % 3D array of voxel intensities
disp(V.VolumeGeometry);   % Spatial reference (medicalref3d)
disp(V.Modality);         % 'CT', 'MR', 'PT', etc.
disp(V.VoxelSpacing);     % [x, y, z] spacing in mm
disp(V.SpatialUnits);     % Usually 'mm'
disp(V.Orientation);      % 'transverse', 'sagittal', 'coronal'
disp(V.WindowCenters);    % Display window centers per slice
disp(V.WindowWidths);     % Display window widths per slice
```

### Using dicomCollection for Multi-Series

When a folder contains multiple DICOM series:

```matlab
% Catalog all DICOM files in folder (and subfolders)
coll = dicomCollection('patient_folder', 'IncludeSubfolders', true);

% Display collection table
disp(coll);
% Shows: SeriesDescription, Modality, NumInstances, PatientID, etc.

% Load specific series by row number
V1 = medicalVolume(coll, 'Rows', 1);  % First series
V2 = medicalVolume(coll, 'Rows', 3);  % Third series

% Filter by modality
ctRows = coll.Modality == "CT";
ctColl = coll(ctRows, :);

% Filter by series description
t1Rows = contains(coll.SeriesDescription, 'T1');
t1Coll = coll(t1Rows, :);
```

### Reading Single DICOM Files

For low-level access to individual files:

```matlab
% Read pixel data
img = dicomread('slice001.dcm');

% Read metadata
info = dicominfo('slice001.dcm');

% Common metadata fields:
fprintf('Patient Name: %s\n', info.PatientName.FamilyName);
fprintf('Modality: %s\n', info.Modality);
fprintf('Image Size: %d x %d\n', info.Rows, info.Columns);
fprintf('Pixel Spacing: %.3f x %.3f mm\n', info.PixelSpacing);
fprintf('Slice Thickness: %.3f mm\n', info.SliceThickness);
fprintf('Series Description: %s\n', info.SeriesDescription);

% Rescale to proper units (e.g., Hounsfield units for CT)
slope = info.RescaleSlope;
intercept = info.RescaleIntercept;
img_hu = double(img) * slope + intercept;
```

## DICOM Metadata Navigation

### Important DICOM Tags

| Tag | Description | Access |
|-----|-------------|--------|
| PatientID | Unique patient identifier | `info.PatientID` |
| PatientName | Patient name structure | `info.PatientName` |
| Modality | CT, MR, PT, US, etc. | `info.Modality` |
| StudyDate | Date of study | `info.StudyDate` |
| SeriesDescription | Series label | `info.SeriesDescription` |
| PixelSpacing | In-plane resolution | `info.PixelSpacing` |
| SliceThickness | Through-plane resolution | `info.SliceThickness` |
| ImagePositionPatient | 3D position of first pixel | `info.ImagePositionPatient` |
| ImageOrientationPatient | Row/column direction cosines | `info.ImageOrientationPatient` |
| RescaleSlope | Pixel value scaling | `info.RescaleSlope` |
| RescaleIntercept | Pixel value offset | `info.RescaleIntercept` |
| WindowCenter | Display window center | `info.WindowCenter` |
| WindowWidth | Display window width | `info.WindowWidth` |

### Handling Private Tags

```matlab
info = dicominfo('file.dcm');

% List all fields
fieldnames(info)

% Access private tags (manufacturer-specific)
if isfield(info, 'Private_0019_10xx')
    privateData = info.Private_0019_10xx;
end

% Search for specific content
fields = fieldnames(info);
for i = 1:length(fields)
    val = info.(fields{i});
    if ischar(val) && contains(val, 'keyword')
        fprintf('%s: %s\n', fields{i}, val);
    end
end
```

## Writing DICOM Files

### Basic DICOM Write

```matlab
% Read original for metadata template
originalInfo = dicominfo('original.dcm');

% Create modified image
img = dicomread('original.dcm');
img_processed = medfilt2(img);  % Example processing

% Write with same metadata
dicomwrite(img_processed, 'processed.dcm', originalInfo);
```

### Creating New DICOM Files

```matlab
% Minimal metadata for new DICOM
info = struct();
info.PatientName = 'Anonymous';
info.PatientID = 'ANON001';
info.Modality = 'OT';  % Other
info.SeriesDescription = 'Processed Image';
info.PixelSpacing = [1.0, 1.0];
info.BitsAllocated = 16;
info.BitsStored = 16;
info.HighBit = 15;
info.PixelRepresentation = 0;  % Unsigned

% Write
img = uint16(rand(512, 512) * 65535);
dicomwrite(img, 'new_image.dcm', info);
```

### Writing from medicalVolume

```matlab
V = medicalVolume('input.nii');

% Note: medicalVolume.write() only supports NIfTI format
% For DICOM output, extract slices and write individually:

for k = 1:size(V.Voxels, 3)
    slice = V.Voxels(:,:,k);
    filename = sprintf('output/slice_%03d.dcm', k);

    % Create metadata from volume geometry
    info = struct();
    info.Modality = char(V.Modality);
    info.PixelSpacing = V.VoxelSpacing(1:2);
    info.SliceThickness = V.VoxelSpacing(3);
    info.ImagePositionPatient = intrinsicToWorld(V.VolumeGeometry, [1, 1, k]);

    dicomwrite(int16(slice), filename, info);
end
```

## DICOM Anonymization

```matlab
% Anonymize single file
dicomanon('original.dcm', 'anonymized.dcm');

% Anonymize with custom rules
dicomanon('original.dcm', 'anonymized.dcm', ...
    'keep', {'PatientAge', 'PatientSex'}, ...  % Keep these
    'update', {'PatientID', 'ANON001'});        % Replace these

% Batch anonymization
files = dir('input/*.dcm');
for i = 1:length(files)
    infile = fullfile(files(i).folder, files(i).name);
    outfile = fullfile('output', files(i).name);
    dicomanon(infile, outfile);
end
```

## CT Windowing (Hounsfield Units)

CT images are stored in Hounsfield Units (HU). Common window settings:

| Tissue | Window Center (HU) | Window Width (HU) |
|--------|-------------------|-------------------|
| Lung | -600 | 1500 |
| Mediastinum | 40 | 400 |
| Soft Tissue | 40 | 350 |
| Liver | 60 | 150 |
| Bone | 300 | 1500 |
| Brain | 40 | 80 |

```matlab
% Apply windowing for display
function windowed = applyWindow(img_hu, center, width)
    lower = center - width/2;
    upper = center + width/2;
    windowed = (img_hu - lower) / width;
    windowed = max(0, min(1, windowed));
end

% Example: Lung window
V = medicalVolume('ct_scan');
lung_view = applyWindow(V.Voxels, -600, 1500);
sliceViewer(lung_view);
```

## Common Patterns

### Load and Display CT Scan

```matlab
% Load
V = medicalVolume('CT_folder');

% Check it's CT
assert(V.Modality == "CT", 'Expected CT scan');

% Apply soft tissue window
center = 40;
width = 350;
windowed = (double(V.Voxels) - center + width/2) / width;
windowed = max(0, min(1, windowed));

% Display
sliceViewer(windowed);
```

### Sort DICOM Files by Instance Number

```matlab
folder = 'unsorted_dicom';
files = dir(fullfile(folder, '*.dcm'));

% Read instance numbers
instances = zeros(length(files), 1);
for i = 1:length(files)
    info = dicominfo(fullfile(folder, files(i).name));
    instances(i) = info.InstanceNumber;
end

% Sort
[~, sortIdx] = sort(instances);
sortedFiles = files(sortIdx);

% Load in order
volume = [];
for i = 1:length(sortedFiles)
    img = dicomread(fullfile(folder, sortedFiles(i).name));
    volume = cat(3, volume, img);
end
```

### Extract Specific Series from Multi-Study DICOM

```matlab
% Catalog folder
coll = dicomCollection('patient_data', 'IncludeSubfolders', true);

% Find T2-weighted MRI series
t2Mask = contains(coll.SeriesDescription, 'T2', 'IgnoreCase', true) & ...
         coll.Modality == "MR";

if any(t2Mask)
    t2Coll = coll(t2Mask, :);
    V_t2 = medicalVolume(t2Coll, 'Rows', 1);
    fprintf('Loaded T2 series: %s\n', t2Coll.SeriesDescription{1});
else
    error('No T2 series found');
end
```

## Troubleshooting

### Issue: DICOM files not loading as volume

**Cause:** Files may be from different series or have inconsistent spacing.

```matlab
% Check consistency
coll = dicomCollection('folder');
disp(coll(:, {'SeriesDescription', 'NumInstances', 'Rows', 'Columns'}));

% If multiple series exist, load specific one
V = medicalVolume(coll, 'Rows', 1);
```

### Issue: Pixel values seem wrong

**Cause:** Rescale slope/intercept not applied.

```matlab
% Raw read doesn't apply rescaling
img = dicomread('ct_slice.dcm');

% Apply manually
info = dicominfo('ct_slice.dcm');
img_hu = double(img) * info.RescaleSlope + info.RescaleIntercept;

% Or use medicalVolume (auto-rescales)
V = medicalVolume('ct_folder');  % Already in HU
```

### Issue: Orientation mismatch between volumes

**Cause:** Different patient positions or slice orderings.

```matlab
V1 = medicalVolume('series1');
V2 = medicalVolume('series2');

fprintf('V1 Orientation: %s\n', V1.Orientation);
fprintf('V2 Orientation: %s\n', V2.Orientation);
fprintf('V1 Normal: [%.3f, %.3f, %.3f]\n', V1.NormalVector);
fprintf('V2 Normal: [%.3f, %.3f, %.3f]\n', V2.NormalVector);

% May need to resample to common geometry before comparison
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 2*
*See also: `pacs-integration.md` for PACS server access*
