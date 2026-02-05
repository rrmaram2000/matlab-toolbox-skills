# MATLAB Toolbox Skills for Claude

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![MATLAB R2025b](https://img.shields.io/badge/MATLAB-R2025b-orange.svg)](https://www.mathworks.com/products/matlab.html)

As a biomedical engineering PhD student, I use MATLAB daily for medical image analysis. I created these skills because I was tired of Claude suggesting Python workarounds for things MATLAB can do natively, or recommending functions that were deprecated several versions ago.

These skills give Claude accurate, up-to-date knowledge about specific MATLAB toolboxes, resulting in code suggestions that actually work with current releases.

> **What are Claude Skills?** Knowledge packages that extend Claude's capabilities in specific domains. See the [official documentation](https://docs.anthropic.com/en/docs/claude-ai/skills).

---

## Evaluation

I tested each skill by asking Claude the same question with and without the skill loaded.

<br>

### MedSAM Tumor Segmentation

> *How do I use MedSAM to segment a tumor from a CT volume in MATLAB?*

| Aspect | Without Skill | With Skill |
|:-------|:--------------|:-----------|
| Approach | Python bridge required | **Native MATLAB** |
| Code complexity | 100+ lines across two languages | **~40 lines pure MATLAB** |
| Key function | Doesn't know it exists | `medicalSegmentAnythingModel` |
| Workflow | Temp files, subprocess calls | `extractEmbeddings` → `segmentObjectsFromEmbeddings` |
| 3D handling | "Loop over slices" (vague) | **Full propagation strategy** |
| Spatial referencing | Lost | **Preserved with medicalVolume** |

<br>

### 3D Volume Visualization

> *How do I visualize a 3D medical volume with a segmentation overlay?*

| Aspect | Without Skill | With Skill |
|:-------|:--------------|:-----------|
| Approach | Workarounds (isosurface, loops) | **`OverlayData` parameter** |
| Code | 30+ lines | **3 lines** |
| Key syntax | Doesn't know it | `volshow(V, OverlayData=L.Voxels)` |
| labelvolshow | Not mentioned | **Notes it was removed in R2025b** |
| Colormap control | Not shown | `OverlayColormap`, `OverlayAlphamap` |

---

## Installation

**Claude Desktop**
1. Download or clone this repository
2. Zip the skill folder: `zip -r matlab-medical-imaging-toolbox.zip matlab-medical-imaging-toolbox`
3. Go to Settings → Skills → Add Skill → Upload the zip
4. Toggle on and start a new conversation

**Claude.ai** — Settings → Skills → Upload zip

**Claude Code** — `claude mcp add-skill /path/to/matlab-medical-imaging-toolbox`

---

## Use with MathWorks MATLAB MCP Server

These skills complement the official [MATLAB MCP Core Server](https://github.com/matlab/matlab-mcp-core-server) from MathWorks.

| | What It Provides |
|:--|:-----------------|
| **MCP Server** | Code execution, syntax checking, toolbox detection |
| **These Skills** | Toolbox-specific knowledge for accurate suggestions |

Use both together for the best experience. See [MathWorks AI resources](https://github.com/matlab) for more.

---

## Available Skills

| Skill | Coverage |
|:------|:---------|
| `matlab-medical-imaging-toolbox` | DICOM/NIfTI I/O, MedSAM, Cellpose, radiomics, 3D visualization |
| `matlab-image-processing-toolbox` | Filtering, segmentation, morphology, watershed, regionprops |
| `matlab-deep-learning` | U-Net, semantic segmentation, custom training, transfer learning |
| `matlab-stats-ml` | Classification, regression, survival analysis, Bayesian methods |
| `matlab-wavelet-toolbox` | 2D transforms, denoising, lifting schemes, shearlets |

---

<details>
<summary><strong>Additional Examples</strong></summary>

<br>

### Cell Segmentation (Image Processing)

> *How do I segment overlapping cells in a microscopy image?*

| Aspect | Without Skill | With Skill |
|:-------|:--------------|:-----------|
| Approach | Basic watershed | **Production-ready watershed** |
| Preprocessing | Simple threshold | `imtophat` for background correction |
| Edge handling | Not addressed | `imclearborder` for edge cases |
| Parameters | Generic values | Specific values with explanations |
| References | None | Academic citations included |

<br>

### U-Net Architecture (Deep Learning)

> *How do I create a U-Net for image segmentation in MATLAB?*

| Aspect | Without Skill | With Skill |
|:-------|:--------------|:-----------|
| Functions used | `unetLayers`, `trainNetwork` (deprecated) | **Both legacy and modern functions** |
| Modern syntax | Not mentioned | `unet`, `trainnet` (R2024b+) |
| Custom architecture | Not shown | Manual construction code included |
| Class imbalance | Not addressed | Guidance provided |

<br>

### Shearlet Transforms (Wavelet Toolbox)

> *How do I use shearlets for directional texture analysis?*

| Aspect | Without Skill | With Skill |
|:-------|:--------------|:-----------|
| Approach | Third-party toolbox (ShearLab 3D) | **Native MATLAB Wavelet Toolbox** |
| Setup required | Download from shearlab.org | **None — built-in** |
| System creation | `SLgetShearletSystem2D` | `shearletSystem` |
| Forward transform | `SLsheardec2D` | `sheart2` |
| Inverse transform | `SLshearrec2D` | `isheart2` |
| External dependencies | Yes | **No** |

</details>

---

## Contributing

Contributions welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT License](LICENSE)
