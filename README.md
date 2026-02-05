# MATLAB Toolbox Skills for Claude

These skills address a practical problem: Claude is helpful for coding, but when it comes to MATLAB—especially newer APIs—it often suggests deprecated functions, incorrect syntax, or recommends third-party toolboxes when MATLAB already has built-in support.

These skills provide Claude with accurate, up-to-date knowledge about specific MATLAB toolboxes, resulting in code suggestions that actually work with current MATLAB releases.

**Verified against MATLAB R2025b.**

---

## Evaluation

I tested each skill by asking Claude the same question with and without the skill loaded. Below are the results.

### MedSAM Tumor Segmentation

*"How do I use MedSAM to segment a tumor from a CT volume in MATLAB?"*

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Approach | Python bridge required | **Native MATLAB** |
| Code complexity | 100+ lines (Python + MATLAB) | **~40 lines pure MATLAB** |
| Key function | Doesn't know it exists | `medicalSegmentAnythingModel` |
| Workflow | Temp files, subprocess calls | `extractEmbeddings` → `segmentObjectsFromEmbeddings` |
| 3D handling | "Loop over slices" (vague) | **Full propagation strategy** |
| Spatial referencing | Lost | **Preserved with medicalVolume** |

**With the skill:**

```matlab
model = medicalSegmentAnythingModel;
V = medicalVolume('ct_scan.nii');

slice = extractSlice(V, 45, 'transverse');
embeddings = extractEmbeddings(model, mat2gray(double(slice)));
mask = segmentObjectsFromEmbeddings(model, embeddings, 'BoundingBox', [120, 90, 80, 70]);

volshow(V, OverlayData=mask);
```

---

### 3D Volume Visualization

*"How do I visualize a 3D medical volume with a segmentation overlay?"*

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Approach | Workarounds (isosurface, loops) | **`OverlayData` parameter** |
| Code | 30+ lines | **3 lines** |
| Key syntax | Doesn't know it | `volshow(V, OverlayData=L.Voxels)` |
| labelvolshow | Not mentioned | **Notes REMOVED in R2025b** |
| Colormap control | Not shown | `OverlayColormap`, `OverlayAlphamap` |

**With the skill:**

```matlab
V = medicalVolume('ct_scan.nii');
L = medicalVolume('segmentation.nii');

volshow(V, OverlayData=L.Voxels);
```

---

### Cell Segmentation (Image Processing)

*"How do I segment overlapping cells in a microscopy image?"*

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Approach | Basic watershed | **Production-ready watershed** |
| Preprocessing | Simple threshold | `imtophat` for background correction |
| Edge handling | Not addressed | `imclearborder` for edge cases |
| Parameters | Generic values | Specific values with explanations |
| References | None | Academic citations included |

---

### U-Net Architecture (Deep Learning)

*"How do I create a U-Net for image segmentation in MATLAB?"*

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| API used | `unetLayers`, `trainNetwork` (deprecated) | **Both legacy and modern APIs** |
| Modern functions | Not mentioned | `unet`, `trainnet` (R2024b+) |
| Custom architecture | Not shown | Manual construction code included |
| Class imbalance | Not addressed | Guidance provided |

**With the skill:**

```matlab
% Legacy (pre-R2024b):
lgraph = unetLayers(imageSize, numClasses, 'EncoderDepth', 4);

% Modern (R2024b+):
net = unet(imageSize, numClasses, 'EncoderDepth', 4);
```

---

### Shearlet Transforms (Wavelet Toolbox)

*"How do I use shearlets for directional texture analysis?"*

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Approach | Third-party toolbox (ShearLab 3D) | **Native MATLAB Wavelet Toolbox** |
| Setup required | Download from shearlab.org | **None — built-in** |
| System creation | `SLgetShearletSystem2D` | `shearletSystem` |
| Forward transform | `SLsheardec2D` | `sheart2` |
| Inverse transform | `SLshearrec2D` | `isheart2` |
| External dependencies | Yes | **No** |

**With the skill:**

```matlab
sh = shearletSystem('ImageSize', size(img), 'NumScales', 4);
coeffs = sheart2(sh, img);
imgRec = isheart2(sh, coeffs);
```

---

## Available Skills

| Skill | Coverage |
|-------|----------|
| **matlab-medical-imaging-toolbox** | DICOM/NIfTI I/O, MedSAM, Cellpose, radiomics, 3D visualization, coordinate systems |
| **matlab-image-processing-toolbox** | Filtering, segmentation, morphology, watershed, regionprops |
| **matlab-deep-learning** | U-Net, semantic segmentation, custom training, transfer learning |
| **matlab-stats-ml** | Classification, regression, survival analysis, Bayesian methods, clustering |
| **matlab-wavelet-toolbox** | 2D transforms, denoising, lifting schemes, shearlets |

---

## Installation

### Claude Desktop

1. Download or clone this repository
2. Create a zip file for the skill you want (e.g., `zip -r matlab-medical-imaging-toolbox.zip matlab-medical-imaging-toolbox`)
3. Open Claude Desktop → Settings → Skills → Add Skill
4. Upload the zip file
5. Toggle the skill on when needed

**Note:** Start a new conversation after enabling a skill for it to take effect.

### Claude.ai (Web)

Follow the same process: go to Settings → Skills and upload the zip file.

### Claude Code (CLI)

```bash
claude mcp add-skill /path/to/matlab-medical-imaging-toolbox
```

To verify installed skills:
```bash
claude /skills
```

---

## Choosing Skills

Install only the skills relevant to your work:

- **Medical imaging** (CT, MRI, DICOM) → `matlab-medical-imaging-toolbox`
- **Image processing** → `matlab-image-processing-toolbox`
- **Deep learning** → `matlab-deep-learning`
- **Statistics and machine learning** → `matlab-stats-ml`
- **Wavelet analysis** → `matlab-wavelet-toolbox`

Each skill is independent; install only what you need.

---

## Verification

All skills were verified against a live MATLAB R2025b installation:
- Function existence confirmed
- Signatures validated
- Code examples tested

253 functions verified across all skills.

Issues identified and corrected during verification:
- `logrank` does not exist (use `coxphfit` for survival comparison)
- `nrrdwrite` does not exist (NRRD is read-only in MATLAB)
- `labelvolshow` was removed in R2025b
- `dldwt` returns 2 outputs, not 4

---

## Background

As a biomedical engineering PhD student, I use MATLAB daily for medical image analysis. I created these skills because I was tired of Claude suggesting Python workarounds for things MATLAB can do natively, or recommending functions that were deprecated two versions ago.

These skills are shared in the hope that they may be useful to other researchers facing similar challenges.

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.
