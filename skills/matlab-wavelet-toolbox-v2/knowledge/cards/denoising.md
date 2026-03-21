# Wavelet Denoising - Recipes and Guidance

## Method Selection Guide

| Your Scenario | Method | Why |
|---------------|--------|-----|
| General / unknown noise | `'Bayes'` | Robust, estimates signal variance automatically |
| Known noise level, textured images | `'SURE'` | Minimizes MSE without ground truth |
| Conservative (preserve weak features) | `'Minimax'` | Lower threshold, less signal loss |
| Quick/simple denoising | `'UniversalThreshold'` | One formula, but tends to over-smooth |
| Sparse coefficient images | `'FDR'` | Controls false discovery rate |

## Medical Denoising Recipes

### Wavelet Selection by Image Type

| Image Type | Wavelet | Levels | Rationale |
|------------|---------|--------|-----------|
| MRI (Rician) | sym4-sym6 | 4 | Near-linear phase, smooth structures |
| CT (Poisson) | db4-db6 | 3-4 | Good edge preservation |
| Ultrasound (speckle) | sym4 | 4 | Log-domain processing required |
| Sharp edges (bone/calcium) | db2-db3 | 3 | Short filters preserve edges |

### Key Gotchas

- **Multiplicative noise** (ultrasound speckle): Must log-transform first, denoise, then exp-transform back. Applying `wdenoise2` directly is wrong.
- **Soft vs hard thresholding**: Use soft (`'Soft'`) for medical -- hard thresholding introduces ringing near edges.
- **Level-dependent thresholding**: Often better than a single global threshold. Estimate noise separately at each level using the MAD estimator: `sigma = median(abs(cD(:))) / 0.6745`.
- **Over-smoothing**: If fine structures vanish, reduce levels or switch from `'UniversalThreshold'` to `'Bayes'`.
- **Quality metrics**: Always compare PSNR and SSIM before/after. Include edge preservation via gradient correlation.
