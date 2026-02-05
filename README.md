# MATLAB Toolbox Skills for Claude

I created these skills to help Claude give better answers when working with MATLAB — particularly for medical imaging, image processing, and machine learning workflows that I use in my research.

The problem: Claude's general knowledge of MATLAB is decent for basic tasks, but it often suggests deprecated functions, incorrect syntax, or unnecessarily complex workarounds for newer APIs. These skills fix that by providing Claude with accurate, up-to-date knowledge about specific MATLAB toolboxes.

**Verified against MATLAB R2025b.**

---

## What's the difference?

I tested each skill by asking Claude the same question with and without the skill loaded. Here are real examples.

### Example 1: MedSAM Tumor Segmentation (Medical Imaging)

**Question:** *"How do I use MedSAM to segment a tumor from a CT volume in MATLAB?"*

**Without the skill**, Claude thinks MedSAM is Python-only and suggests a 100+ line workflow involving temporary files, a separate Python script with PyTorch, and subprocess calls to bridge between MATLAB and Python.

**With the skill**, Claude knows MATLAB has native MedSAM support (R2024b+):

```matlab
% Setup
model = medicalSegmentAnythingModel;
V = medicalVolume('ct_scan.nii');

% Segment a slice
slice = extractSlice(V, 45, 'transverse');
embeddings = extractEmbeddings(model, mat2gray(double(slice)));
mask = segmentObjectsFromEmbeddings(model, embeddings, 'BoundingBox', [120, 90, 80, 70]);

% Visualize
volshow(V, OverlayData=mask);
```

That's a significant difference — native MATLAB code instead of a multi-language workaround.

---

### Example 2: 3D Volume Visualization (Medical Imaging)

**Question:** *"How do I visualize a 3D medical volume with a segmentation overlay in MATLAB?"*

**Without the skill**, Claude suggests complex workarounds using `isosurface`, `patch`, slice-by-slice RGB loops with `labeloverlay`, and manual colormap handling. About 30 lines of code.

**With the skill**, Claude knows the modern syntax:

```matlab
V = medicalVolume('ct_scan.nii');
L = medicalVolume('segmentation.nii');

volshow(V, OverlayData=L.Voxels, ...
    OverlayColormap=[0 0 0; 0.2 0.8 0.3; 1 0.2 0.2], ...
    OverlayAlphamap=[0, 0.3, 0.5]);
```

Three lines instead of thirty. The skill also notes that `labelvolshow` was removed in R2025b — something Claude wouldn't know otherwise.

---

### Example 3: Overlapping Cell Segmentation (Image Processing)

**Question:** *"How do I segment overlapping cells in a microscopy image in MATLAB?"*

Both responses use marker-controlled watershed (the standard approach), but the quality differs.

**Without the skill**, Claude gives a working pipeline with `adapthisteq` for preprocessing and basic `regionprops`.

**With the skill**, Claude provides production-ready code with:
- `imtophat` for background correction (more robust than CLAHE for uneven illumination)
- `imclearborder` to remove edge-touching objects
- Specific parameter guidance (e.g., "h = 2–5 for imhmin, increase if over-segmented")
- Academic references (Meyer 1994, Vincent & Soille 1991)
- Comprehensive `regionprops` including `Circularity` and `MeanIntensity`

The improvement here is practical — the code goes from "this should work" to "this is ready for a real project."

---

### Example 4: U-Net Architecture (Deep Learning)

**Question:** *"How do I create a U-Net architecture for image segmentation in MATLAB?"*

**Without the skill**, Claude shows only `unetLayers` (the legacy API) and `trainNetwork` (deprecated in R2024b+).

**With the skill**, Claude mentions both options:

```matlab
% Legacy API (pre-R2024b):
lgraph = unetLayers(imageSize, numClasses, 'EncoderDepth', 4);

% Modern API (R2024b+):
net = unet(imageSize, numClasses, 'EncoderDepth', 4);
```

The skill also provides complete manual construction code for when you need custom architectures, plus guidance on class imbalance handling and proper mask augmentation (always use nearest-neighbor interpolation).

This improvement is moderate — Claude becomes aware of the API evolution but doesn't fully switch to the modern `trainnet` workflow. Still useful for researchers who need to know both options exist.

---

## What's included

| Skill | What it covers |
|-------|----------------|
| **matlab-medical-imaging-toolbox** | DICOM/NIfTI I/O, `medicalVolume`, coordinate systems, MedSAM, Cellpose, radiomics, 3D visualization |
| **matlab-image-processing-toolbox** | Filtering, segmentation, morphology, watershed, `regionprops`, deep learning segmentation |
| **matlab-deep-learning** | U-Net, semantic segmentation, custom training loops, transfer learning, data augmentation |
| **matlab-stats-ml** | Classification, regression, survival analysis, Bayesian methods, clustering, distributions |
| **matlab-wavelet-toolbox** | 2D transforms, denoising, lifting schemes, shearlets, deep learning integration |

---

## Installation

These skills work with Claude Desktop, Claude.ai (web), and Claude Code (CLI). Choose the method that matches how you use Claude.

### Option 1: Claude Desktop (Recommended for interactive use)

Claude Desktop lets you toggle skills on/off easily, which is great for testing or when you only need MATLAB help sometimes.

**Step 1: Download the skill**

Clone this repository or download the ZIP:
```bash
git clone https://github.com/yourusername/matlab-toolbox-skills.git
```

**Step 2: Create a ZIP file for each skill you want**

Each skill folder needs to be zipped separately:
```bash
cd matlab-toolbox-skills
zip -r matlab-medical-imaging-toolbox.zip matlab-medical-imaging-toolbox
zip -r matlab-image-processing-toolbox.zip matlab-image-processing-toolbox
zip -r matlab-deep-learning.zip matlab-deep-learning
zip -r matlab-stats-ml.zip matlab-stats-ml
zip -r matlab-wavelet-toolbox.zip matlab-wavelet-toolbox
```

**Step 3: Add to Claude Desktop**

1. Open Claude Desktop
2. Click the **Settings** icon (gear) in the bottom left
3. Go to **Skills** in the sidebar
4. Click **Add Skill**
5. Select the `.zip` file you created
6. The skill will appear in your list

**Step 4: Enable the skill**

- Toggle the skill **ON** when you want Claude to use it
- Toggle it **OFF** when you don't need it (keeps responses focused)
- You can enable multiple skills at once

**Tip:** Start a new conversation after enabling a skill to ensure Claude loads the knowledge fresh.

---

### Option 2: Claude.ai (Web)

Claude.ai also supports skills through the same mechanism as Claude Desktop.

1. Go to [claude.ai](https://claude.ai)
2. Click on your profile → **Settings**
3. Navigate to **Skills**
4. Upload the skill ZIP file
5. Toggle on the skills you need

The web interface works the same as Desktop — you can enable/disable skills per conversation.

---

### Option 3: Claude Code (CLI)

If you use Claude Code in your terminal, you can add skills directly from the folder path.

**Add a skill:**
```bash
claude mcp add-skill /path/to/matlab-toolbox-skills/matlab-medical-imaging-toolbox
```

**Add all skills at once:**
```bash
cd /path/to/matlab-toolbox-skills
claude mcp add-skill matlab-medical-imaging-toolbox
claude mcp add-skill matlab-image-processing-toolbox
claude mcp add-skill matlab-deep-learning
claude mcp add-skill matlab-stats-ml
claude mcp add-skill matlab-wavelet-toolbox
```

**Verify installed skills:**
```bash
claude /skills
```

**Remove a skill:**
```bash
claude mcp remove-skill matlab-medical-imaging-toolbox
```

---

### Which skills should I install?

Install based on what you work with:

| If you work with... | Install these skills |
|---------------------|---------------------|
| Medical images (CT, MRI, DICOM, NIfTI) | `matlab-medical-imaging-toolbox` |
| General image processing | `matlab-image-processing-toolbox` |
| Deep learning / neural networks | `matlab-deep-learning` |
| Statistics, ML, classification | `matlab-stats-ml` |
| Wavelet analysis, denoising | `matlab-wavelet-toolbox` |

You don't need all five — just install what's relevant to your work.

---

### Troubleshooting

**Skill not loading?**
- Make sure you zipped the folder correctly (the ZIP should contain the folder, not just its contents)
- Start a new conversation after adding the skill
- Check that the skill is toggled ON in settings

**Claude not using the skill knowledge?**
- Be specific in your question (e.g., mention "MATLAB" explicitly)
- Try starting your question with context: "Using MATLAB's Medical Imaging Toolbox..."
- Start a fresh conversation — skills load at conversation start

**Want to verify it's working?**
- Ask a question like "How do I use MedSAM in MATLAB?"
- If Claude mentions `medicalSegmentAnythingModel`, the skill is loaded
- If Claude suggests a Python bridge, the skill isn't active

---

### References

- [Claude Desktop Documentation](https://docs.anthropic.com/en/docs/claude-desktop)
- [Claude Code CLI Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Skills Overview](https://docs.anthropic.com/en/docs/skills)

---

## How these were verified

I ran verification agents against a live MATLAB R2025b instance to check that:
- Every function mentioned actually exists
- Function signatures are correct
- Code examples run without errors
- Deprecated functions are marked as such

**253 functions verified across all skills.**

Some things I caught and fixed during verification:
- `logrank` doesn't exist in MATLAB (use `coxphfit` for survival group comparisons)
- `nrrdwrite` doesn't exist (NRRD is read-only in MATLAB)
- `labelvolshow` was removed in R2025b (use `volshow` with `OverlayData`)
- `dldwt` returns 2 outputs `[A, D]`, not 4 (this is the R2025a differentiable wavelet function)

---

## Honest assessment

**Where the skills help most:**
- Modern APIs that Claude doesn't know (MedSAM, `volshow` OverlayData, `unet`)
- Functions that were removed or deprecated in recent MATLAB versions
- Detailed parameter guidance and production-ready code patterns

**Where improvement is moderate:**
- Topics where Claude's base MATLAB knowledge is already decent (like basic watershed segmentation)
- Deep learning training workflows — Claude is aware of `trainnet` but doesn't always use it

**What the skills don't do:**
- They don't make Claude run MATLAB code — they just improve the quality of code suggestions
- They don't guarantee perfect answers — Claude can still make mistakes

---

## Background

I'm a biomedical engineering PhD student working on medical image analysis. I built these skills because I got tired of Claude suggesting Python bridges for things MATLAB can do natively, or using deprecated functions that would fail on my R2025b installation.

The skills are structured following Claude Code best practices: a main `SKILL.md` file with an overview, an `INDEX.md` router, and detailed knowledge cards (300–800 lines each) for specific topics.

If you find issues or want to contribute improvements, feel free to open an issue or PR.

---

## License

MIT — use however you like.
