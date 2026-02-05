# NIfTI and NRRD File I/O

NIfTI (Neuroimaging Informatics Technology Initiative) and NRRD (Nearly Raw Raster Data) are research-oriented formats commonly used in neuroimaging and ITK/3D Slicer workflows.

## Format Comparison

| Feature | NIfTI (.nii, .nii.gz) | NRRD (.nrrd, .nhdr) |
|---------|----------------------|---------------------|
| Primary Use | Neuroimaging, fMRI | ITK, 3D Slicer |
| Compression | .nii.gz (gzip) | Gzip, bzip2, raw |
| Header | 348/540 bytes | ASCII text |
| Orientation | qform/sform matrices | Space directions |
| MATLAB Support | Full | Full |

## Key Functions

| Function | Purpose |
|----------|---------|
| `medicalVolume` | Load NIfTI/NRRD with spatial info (recommended) |
| `niftiread` | Read NIfTI voxel data only |
| `niftiwrite` | Write NIfTI file |
| `niftiinfo` | Read NIfTI header/metadata |
| `nrrdread` | Read NRRD file |
| `nrrdinfo` | Read NRRD header |

> ⚠️ **Note:** MATLAB supports **reading** NRRD files but does NOT have a built-in `nrrdwrite` function. To save NRRD data, convert to NIfTI format using `medicalVolume.write()`, or use third-party File Exchange tools.

## Reading NIfTI Files

### Using medicalVolume (Recommended)

```matlab
% Load NIfTI with full spatial referencing
V = medicalVolume('brain.nii');

% Works with compressed files too
V = medicalVolume('brain.nii.gz');

% Key properties
disp(V.Voxels);           % 3D numeric array
disp(V.VolumeGeometry);   % medicalref3d spatial reference
disp(V.VoxelSpacing);     % [x, y, z] in mm
disp(V.SpatialUnits);     % 'mm'
disp(V.Orientation);      % 'transverse', 'sagittal', 'coronal'

% Note: NIfTI doesn't store modality, so:
disp(V.Modality);         % Usually 'unknown' for NIfTI
```

### Using niftiread (Low-Level)

```matlab
% Read voxel data only (no spatial info)
data = niftiread('brain.nii');

% Get header information separately
info = niftiinfo('brain.nii');

% Key header fields
disp(info.ImageSize);        % [512, 512, 128]
disp(info.PixelDimensions);  % [1.0, 1.0, 1.2] mm
disp(info.Datatype);         % 'int16', 'single', etc.
disp(info.SpaceUnits);       % 'Millimeter'
disp(info.TimeUnits);        % For 4D data
disp(info.Transform);        % affine3d transformation
```

### Understanding NIfTI Transformations

NIfTI files contain transformation matrices (qform and sform):

```matlab
info = niftiinfo('brain.nii');

% The Transform property contains the affine transformation
T = info.Transform;  % affine3d object

% Transform voxel indices to world coordinates
voxel_point = [100, 100, 50, 1];  % Homogeneous coords
world_point = voxel_point * T.T;  % Apply transform

% Or use medicalVolume for cleaner API
V = medicalVolume('brain.nii');
world = intrinsicToWorld(V.VolumeGeometry, [100, 100, 50]);
```

## Writing NIfTI Files

### From medicalVolume

```matlab
% Load, process, write
V = medicalVolume('input.nii');

% Process (using IPT - see cross-toolbox-ipt.md)
V.Voxels = imgaussfilt3(double(V.Voxels), 1.5);

% Write to NIfTI (preserves spatial info)
write(V, 'output.nii');

% Write compressed
write(V, 'output.nii.gz');
```

### Using niftiwrite

```matlab
% Create new NIfTI from scratch
data = rand(256, 256, 128, 'single');

% Minimal write (uses defaults)
niftiwrite(data, 'random_volume.nii');

% With custom header
info = niftiinfo('template.nii');  % Copy from template
info.ImageSize = size(data);
info.PixelDimensions = [1.0, 1.0, 2.0];  % 1x1x2 mm
info.Datatype = 'single';

niftiwrite(data, 'custom_volume.nii', info);

% Write compressed
niftiwrite(data, 'custom_volume.nii', info, 'Compressed', true);
```

### Creating NIfTI from DICOM

```matlab
% Load DICOM
V_dicom = medicalVolume('dicom_folder');

% Write as NIfTI (loses some DICOM-specific metadata)
write(V_dicom, 'converted.nii');

% Verify conversion
V_nifti = medicalVolume('converted.nii');
fprintf('DICOM size: %s\n', mat2str(size(V_dicom.Voxels)));
fprintf('NIfTI size: %s\n', mat2str(size(V_nifti.Voxels)));
fprintf('Spacing preserved: %s\n', ...
    mat2str(V_dicom.VoxelSpacing == V_nifti.VoxelSpacing));
```

## Reading NRRD Files

### Using medicalVolume

```matlab
% Load NRRD with spatial info
V = medicalVolume('scan.nrrd');

% Same API as NIfTI
disp(V.Voxels);
disp(V.VoxelSpacing);
```

### Using nrrdread (Low-Level)

```matlab
% Read voxel data
data = nrrdread('scan.nrrd');

% Read header
info = nrrdinfo('scan.nrrd');

% Key fields
disp(info.Sizes);           % Dimensions
disp(info.SpaceDirections); % Axis vectors
disp(info.SpaceOrigin);     % Origin point
disp(info.Encoding);        % 'raw', 'gzip', etc.
```

## Writing NRRD Files

> ⚠️ **Important:** MATLAB does NOT have a built-in `nrrdwrite` function. NRRD support is **read-only**.

**Workarounds for saving NRRD data:**

```matlab
% Option 1: Convert to NIfTI format (recommended)
V = medicalVolume('input.nrrd');
write(V, 'output.nii');  % Save as NIfTI instead

% Option 2: Use third-party tools from File Exchange
% Search for "nrrdWriter" on MATLAB File Exchange

% Option 3: Export to ITK/Python for NRRD writing
% Save as NIfTI, then use external tools to convert
```

## Format Conversion

### NIfTI to NRRD

> ⚠️ **Note:** MATLAB cannot write NRRD files natively. Use external tools for conversion.

```matlab
% Load NIfTI
V = medicalVolume('brain.nii');

% Option 1: Save as NIfTI and convert externally
% Many tools (3D Slicer, ITK-SNAP, Python nibabel) can convert NIfTI to NRRD
write(V, 'brain.nii');

% Option 2: Use File Exchange nrrdWriter (if available)
% data = V.Voxels;
% nrrdWriter('brain.nrrd', data, struct('spacing', V.VoxelSpacing));
```

### NRRD to NIfTI

```matlab
% Load NRRD
V = medicalVolume('scan.nrrd');

% Write NIfTI (medicalVolume handles conversion)
write(V, 'scan.nii');
```

### DICOM to NIfTI (Common Workflow)

```matlab
function dicom2nifti(dicomFolder, niftiFile)
    % Load DICOM series
    V = medicalVolume(dicomFolder);

    % Optional: reorient to standard orientation
    % (Many tools expect RAS+ orientation)

    % Write NIfTI
    write(V, niftiFile);

    fprintf('Converted: %s -> %s\n', dicomFolder, niftiFile);
    fprintf('Size: %s, Spacing: %s mm\n', ...
        mat2str(size(V.Voxels)), mat2str(V.VoxelSpacing));
end
```

## 4D NIfTI (Time Series)

For fMRI and dynamic imaging:

```matlab
% Read 4D NIfTI
info = niftiinfo('fmri.nii');
fprintf('Dimensions: %s\n', mat2str(info.ImageSize));
% e.g., [64, 64, 32, 200] = 200 time points

data = niftiread('fmri.nii');

% Process time series
for t = 1:size(data, 4)
    volume_t = data(:,:,:,t);
    % Process each time point
end

% Or extract single timepoint
first_volume = squeeze(data(:,:,:,1));

% Note: medicalVolume currently handles 3D
% For 4D, use niftiread directly
```

## Label Maps and Segmentations

```matlab
% Read label volume
labels = niftiread('segmentation.nii');
info = niftiinfo('segmentation.nii');

% Common label formats:
% - Integer labels (0=background, 1=tissue1, 2=tissue2, ...)
% - Binary masks (0 or 1)

% Create labeled medicalVolume
V_labels = medicalVolume(uint8(labels), geometry);
V_labels.Modality = 'SEG';  % Mark as segmentation

% Display with volshow (labelvolshow REMOVED in R2025b)
V_image = medicalVolume('scan.nii');
volshow(V_image.Voxels, OverlayData=V_labels.Voxels);
```

## Common Patterns

### Batch Convert DICOM Folders to NIfTI

```matlab
function batchDicom2Nifti(inputDir, outputDir)
    % Find all DICOM folders
    folders = dir(inputDir);
    folders = folders([folders.isdir] & ~startsWith({folders.name}, '.'));

    for i = 1:length(folders)
        dicomPath = fullfile(inputDir, folders(i).name);
        niftiPath = fullfile(outputDir, [folders(i).name '.nii.gz']);

        try
            V = medicalVolume(dicomPath);
            write(V, niftiPath);
            fprintf('[%d/%d] Converted: %s\n', i, length(folders), folders(i).name);
        catch ME
            fprintf('[%d/%d] FAILED: %s - %s\n', i, length(folders), folders(i).name, ME.message);
        end
    end
end
```

### Resample NIfTI to Isotropic Resolution

```matlab
V = medicalVolume('anisotropic.nii');
fprintf('Original spacing: %s mm\n', mat2str(V.VoxelSpacing));

% Resample to 1mm isotropic
V_iso = resample(V, [1, 1, 1]);
fprintf('Isotropic spacing: %s mm\n', mat2str(V_iso.VoxelSpacing));

write(V_iso, 'isotropic.nii');
```

### Load and Overlay Segmentation on Image

```matlab
% Load image and segmentation (must be registered)
V_image = medicalVolume('scan.nii');
V_seg = medicalVolume('segmentation.nii');

% Verify same geometry
assert(isequal(size(V_image.Voxels), size(V_seg.Voxels)), ...
    'Image and segmentation must have same dimensions');

% Display overlay (labelvolshow REMOVED in R2025b - use volshow)
volshow(V_image.Voxels, OverlayData=V_seg.Voxels, ...
    BackgroundColor='black', OverlayAlphamap=0.5);
```

## Troubleshooting

### Issue: "Unable to read NIfTI file"

**Cause:** File may be corrupted or non-standard.

```matlab
% Check if file is valid gzip
try
    gunzip('file.nii.gz', tempdir);
catch
    error('File is not valid gzip');
end

% Try reading uncompressed
niftiread(fullfile(tempdir, 'file.nii'));
```

### Issue: Orientation mismatch with other software

**Cause:** Different interpretation of NIfTI transforms.

```matlab
info = niftiinfo('file.nii');

% Check qform/sform codes
fprintf('TransformType: %s\n', info.TransformType);
% 'Qform' or 'Sform'

% Some software expects specific orientation (RAS+, LPS+)
% May need to reorient data
```

### Issue: Data type mismatch

**Cause:** NIfTI stored in unexpected type.

```matlab
info = niftiinfo('file.nii');
fprintf('Datatype: %s\n', info.Datatype);

% Convert if needed
data = niftiread('file.nii');
data = single(data);  % Convert to single precision

% Or specify on write
info.Datatype = 'single';
niftiwrite(single(data), 'output.nii', info);
```

### Issue: Large file causes memory error

```matlab
info = niftiinfo('large_file.nii');
bytes = prod(info.ImageSize) * getBytesPerVoxel(info.Datatype);
fprintf('File size: %.2f GB\n', bytes / 1e9);

% For very large files, process slice-by-slice using niftiread with region
% (if supported) or use memory-mapped files
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 2*
*See also: `file-io-dicom.md` for clinical DICOM workflows*
