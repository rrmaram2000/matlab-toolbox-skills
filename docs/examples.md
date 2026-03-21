# Flagship Examples — Skill vs No Skill

Five side-by-side comparisons showing how skills prevent hallucinations and add domain expertise. Each example was tested against MATLAB R2025b runtime.

---

## 1. MedSAM Tumor Segmentation
**Toolbox:** Medical Imaging

**Prompt:** *"Use MedSAM to segment a tumor from a CT volume in MATLAB. Interactively mark points on one slice, then propagate to the full 3D volume."*

### What the LLM generates without the skill:

```diff
- medsam = medicalSAM;
+ model = medicalSegmentAnythingModel('ExecutionEnvironment', 'gpu');

- embeddings = imageEmbeddings(medsam, seedRGB);
+ embeddings = extractEmbeddings(model, seedImg);

- Vwin = mat2clim(V, [minHU maxHU]);
+ seedImg = mat2gray(double(extractSlice(V, seedSlice, 'transverse')));
```

**3 hallucinated functions** — `medicalSAM`, `imageEmbeddings`, and `mat2clim` do not exist in MATLAB R2025b. The script crashes immediately.

**With the skill:** Uses `medicalVolume` for spatial referencing, correct MedSAM API, seed-and-propagate 3D workflow, and saves output with preserved geometry.

> Full scripts: [`test-results/medsam-example/`](../test-results/medsam-example/)

---

## 2. Mask R-CNN Cell Nuclei Instance Segmentation
**Toolbox:** Deep Learning

**Prompt:** *"Train a Mask R-CNN to detect and segment individual cell nuclei in H&E histopathology images."*

### What the LLM generates without the skill:

```diff
- trainedDetector = trainMaskRCNNObjectDetector(trainData, backbone, options);
+ detector = maskrcnn("resnet50-coco", classNames, InputSize=inputSize);
+ [trainedDetector, info] = trainMaskRCNN(trainData, detector, options);
```

`trainMaskRCNNObjectDetector` does not exist — the name sounds plausible (similar to the old `trainRCNNObjectDetector`) but Mask R-CNN in R2025b uses a two-step workflow: `maskrcnn()` to create the detector, then `trainMaskRCNN()` to train it.

The without-skill version also uses `detect()` instead of `segmentObjects()` and gets the output argument order wrong.

> Full scripts: [`test-results/maskrcnn-example/`](../test-results/maskrcnn-example/)

---

## 3. MRI + CT Wavelet Image Fusion
**Toolbox:** Wavelet

**Prompt:** *"Fuse MRI and CT images using wavelet-based fusion with proper coefficient-level rules."*

### What the LLM generates without the skill:

```diff
- [wt_mri] = modwt2(mriImg, 'sym4', decompLevel);
- fused_modwt = imodwt2(wt_fused, 'sym4');
+ [C1, S1] = wavedec2(img1, decompLevel, waveletName);
+ fused = waverec2(C_fused, S1, waveletName);

- mriImg = double(mriImg);          % gives [0, 255] — wrong scaling
+ mriImg = im2double(mriImg);       % gives [0, 1] — correct
```

**2 hallucinated functions** — `modwt2` and `imodwt2` do not exist. MODWT is strictly 1D in MATLAB; the correct 2D multi-level transform is `wavedec2`.

**Domain gap:** Beyond the hallucinations, the without-skill version uses single-level `dwt2` with naive averaging of all coefficients. The skill guides multi-level decomposition with separate fusion rules: mean for approximation (shared anatomy), max-absolute for details (preserves edges from both modalities).

> Full scripts: [`test-results/wavelet-fusion-example/`](../test-results/wavelet-fusion-example/)

---

## 4. Clinical Trial Survival Pipeline
**Toolbox:** Stats-ML

**Prompt:** *"Write a clinical trial survival pipeline with KNN imputation, log-rank test, and parametric model comparison."*

### What the LLM generates without the skill:

```diff
- numericData = knnimpute(numericData', 5)';
+ T.Age = fillmissing(T.Age, 'knn');

- [h, p, stats] = logrank(T.Time(idxA), T.Event(idxA), T.Time(idxB), T.Event(idxB));
+ [b, logl, H, stats] = coxphfit(T.Treatment, T.Time, 'Censoring', ~logical(T.Event));

- nll = pd.NegLogLikelihood;
+ nll = negloglik(pd);
```

**3 hallucinated APIs in one script:**
- `knnimpute` requires the Bioinformatics Toolbox — use `fillmissing(X, 'knn')` instead
- `logrank()` does not exist in MATLAB — use `coxphfit` with a group covariate (the Wald test is equivalent)
- `pd.NegLogLikelihood` is not a property on distribution objects — use the `negloglik(pd)` function

The script cannot execute past Step 2.

> Full scripts: [`test-results/survival-pipeline-example/`](../test-results/survival-pipeline-example/)

---

## 5. Macenko Stain Normalization for Histology
**Toolbox:** Image Processing

**Prompt:** *"Implement Macenko stain normalization for H&E histology with OD-space conversion, SVD-based stain vectors, and concentration normalization."*

### What the LLM generates without the skill:

Despite the prompt explicitly requesting the Macenko method, the LLM implements **histogram matching** (`imhistmatch`) and Lab-space mean/std transfer — neither of which performs stain deconvolution.

| Macenko Step | Without Skill | With Skill |
|:-------------|:--------------|:-----------|
| OD-space conversion | Not implemented | `-log10(I/255 + eps)` |
| Background masking | Not implemented | `mean(OD, 3) > 0.15` |
| PCA stain vectors | Not implemented | `pca(tissuePixels)` + percentile angles |
| Stain separation | Not implemented | Matrix deconvolution |
| Concentration normalization | Not implemented | Percentile matching |

No hallucinations here — the code runs fine. But it implements the **wrong algorithm entirely**. For computational pathology pipelines (nuclei detection, tissue classification), proper stain separation is essential.

> Full scripts: [`test-results/stain-normalization-example/`](../test-results/stain-normalization-example/)

---

## Summary

| Example | Toolbox | Issue Type | Hallucinations |
|:--------|:--------|:-----------|:--------------:|
| MedSAM Tumor Segmentation | Medical Imaging | API hallucination | 3 |
| Mask R-CNN Nuclei Segmentation | Deep Learning | API hallucination | 1 |
| MRI + CT Wavelet Fusion | Wavelet | Hallucination + domain gap | 2 |
| Clinical Trial Survival | Stats-ML | API hallucination | 3 |
| Macenko Stain Normalization | Image Processing | Wrong algorithm | 0 |

**Total: 8 hallucinated APIs** caught by skills, plus 2 examples where the skill provides critical domain methodology that the base model lacks.

See [validation.md](validation.md) for the full evaluation methodology.
