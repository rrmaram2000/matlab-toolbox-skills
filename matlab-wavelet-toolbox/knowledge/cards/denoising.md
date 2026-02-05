# Wavelet Denoising

## Quick Start

```matlab
% Automatic denoising (recommended starting point)
denoised = wdenoise2(noisyImg, ...
    'Wavelet', 'db4', ...
    'DenoisingMethod', 'Bayes', ...  % 'Bayes' is reliable for most images
    'Level', 4);
```

## Denoising Methods

Valid DenoisingMethod values (verified R2025b):

| Method | Best For | Theory |
|--------|----------|--------|
| `'SURE'` | Known noise level | Stein's Unbiased Risk Estimate |
| `'Bayes'` | Smooth images, general use | Bayesian shrinkage |
| `'Minimax'` | Conservative | Minimax threshold |
| `'UniversalThreshold'` | Simple cases | σ√(2 log n) |
| `'FDR'` | Sparse signals | False Discovery Rate |

**Note:** `'BlockJS'` is NOT a valid method in MATLAB Wavelet Toolbox.

## Threshold Selection

```matlab
% Manual threshold selection
[C, S] = wavedec2(noisyImg, 4, 'db4');

% Estimate noise from finest detail (MAD estimator)
cD1 = detcoef2('d', C, S, 1);
sigma = median(abs(cD1(:))) / 0.6745;

% Universal threshold
thr = sigma * sqrt(2 * log(numel(noisyImg)));

% Apply threshold
C_denoised = wthresh(C, 's', thr);  % 's' = soft
denoised = waverec2(C_denoised, S, 'db4');
```

## Soft vs Hard Thresholding

| Type | Formula | When to Use |
|------|---------|-------------|
| Soft (`'s'`) | sign(x)·max(|x|-T, 0) | Smooth results, medical |
| Hard (`'h'`) | x if |x|>T, 0 otherwise | Edge preservation |

```matlab
% Soft thresholding (smoother)
y_soft = wthresh(x, 's', threshold);

% Hard thresholding (sharper edges)
y_hard = wthresh(x, 'h', threshold);
```

## Level-Dependent Thresholding

```matlab
% Different threshold per level (often better)
[C, S] = wavedec2(noisyImg, 4, 'db4');

for lev = 1:4
    % Get detail coefficients
    [cH, cV, cD] = detcoef2('all', C, S, lev);

    % Level-dependent threshold
    sigma_lev = median(abs(cD(:))) / 0.6745;
    thr_lev = sigma_lev * sqrt(2 * log(numel(cD)));

    % Apply threshold
    cH = wthresh(cH, 's', thr_lev);
    cV = wthresh(cV, 's', thr_lev);
    cD = wthresh(cD, 's', thr_lev);

    % Update coefficients in C (use proper indexing)
end
```

## Quality Metrics

```matlab
% Before/after comparison
psnr_before = psnr(noisyImg, originalImg);
psnr_after = psnr(denoised, originalImg);

ssim_before = ssim(noisyImg, originalImg);
ssim_after = ssim(denoised, originalImg);

fprintf('PSNR: %.2f -> %.2f dB\n', psnr_before, psnr_after);
fprintf('SSIM: %.4f -> %.4f\n', ssim_before, ssim_after);
```

## Wavelet Selection for Denoising

| Image Type | Recommended Wavelet |
|------------|---------------------|
| Medical (MRI, CT) | 'db4' to 'db8' |
| Photographs | 'sym4' to 'sym8' |
| Sharp edges | 'db2', 'db3' |
| Smooth regions | 'sym6', 'sym8', 'coif3' |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Over-smoothing | Reduce threshold or use fewer levels |
| Artifacts at edges | Use soft thresholding, symmetric extension |
| Threshold too high | Use SURE or Bayes for adaptive selection |
| Wrong noise model | Log-transform for multiplicative noise |
