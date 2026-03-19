# NIfTI and NRRD File I/O

Edge cases and gotchas for NIfTI/NRRD workflows. For basic `medicalVolume('file.nii')`, `niftiread`, `niftiwrite` usage, see SKILL.md.

## Key Gotchas

- MATLAB does **NOT** have a built-in `nrrdwrite`. NRRD is **read-only**. Convert to NIfTI via `write(medicalVolume('input.nrrd'), 'output.nii')`.
- NIfTI files do not store modality: `V.Modality` returns `'unknown'`. Set manually: `V.Modality = 'MR';`
- Use `niftiwrite(data, file, info, 'Compressed', true)` for `.nii.gz` output via `niftiwrite`.

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

## Batch Convert DICOM to NIfTI

```matlab
function batchDicom2Nifti(inputDir, outputDir)
    folders = dir(inputDir);
    folders = folders([folders.isdir] & ~startsWith({folders.name}, '.'));
    for i = 1:length(folders)
        dicomPath = fullfile(inputDir, folders(i).name);
        niftiPath = fullfile(outputDir, [folders(i).name '.nii.gz']);
        try
            V = medicalVolume(dicomPath);
            write(V, niftiPath);
        catch ME
            fprintf('FAILED: %s - %s\n', folders(i).name, ME.message);
        end
    end
end
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
