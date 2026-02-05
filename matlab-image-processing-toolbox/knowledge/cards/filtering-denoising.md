# Filtering: Noise Reduction

Techniques for removing noise while preserving image features. Choose the filter based on noise type.

## Filter Selection Guide

| Noise Type | Characteristics | Recommended Filter | Function |
|------------|-----------------|-------------------|----------|
| Gaussian | Additive, normally distributed | Gaussian smoothing | `imgaussfilt` |
| Salt-and-pepper | Random black/white pixels | Median filter | `medfilt2` |
| Speckle | Multiplicative (ultrasound, SAR) | Wiener filter | `wiener2` |
| Poisson | Signal-dependent (low-light) | Variance-stabilizing + Gaussian | Anscombe transform* → `imgaussfilt` |
| Mixed/Unknown | Combination | Bilateral or Non-local means | `imbilatfilt`, `imnlmfilt` |

> **\*** The Anscombe transform is NOT a built-in MATLAB function. Implement manually: `y = 2*sqrt(x + 3/8)` (forward), `x = (y/2).^2 - 3/8` (inverse).

## Gaussian Smoothing: `imgaussfilt`

Best for Gaussian (additive white) noise. Implements separable Gaussian convolution for efficiency.

**Syntax:**
```matlab
B = imgaussfilt(A, sigma)                    % 2D isotropic
B = imgaussfilt(A, [sigmaY sigmaX])          % 2D anisotropic
B = imgaussfilt3(A, sigma)                   % 3D volumes
B = imgaussfilt(A, sigma, 'Padding', 'replicate')  % Boundary handling
```

**Key Parameters:**
- `sigma`: Standard deviation of Gaussian kernel (larger = more smoothing)
- `FilterSize`: Kernel size (default: `2*ceil(2*sigma)+1`)
- `Padding`: `'replicate'` (recommended), `'symmetric'`, `'circular'`, or numeric

**Sigma Selection Rule:**
- For noise with standard deviation σ_noise, use filter sigma ≈ 1.0-2.0
- Too small: noise remains
- Too large: edges blur

```matlab
% Example: Denoise MRI with Gaussian filter
mri = dicomread('brain.dcm');
mri = im2double(mri);

% Estimate noise level (from background region)
bg_region = mri(1:50, 1:50);
noise_std = std(bg_region(:));

% Apply Gaussian filter with appropriate sigma
denoised = imgaussfilt(mri, 1.5, 'Padding', 'replicate');

% Compare SNR improvement
snr_before = mean(mri(:)) / noise_std;
snr_after = mean(denoised(:)) / std(denoised(1:50, 1:50), [], 'all');
```

## Median Filter: `medfilt2`

Best for salt-and-pepper (impulse) noise. Non-linear filter that preserves edges while removing outliers.

**Syntax:**
```matlab
J = medfilt2(I)                    % Default 3x3 neighborhood
J = medfilt2(I, [m n])             % Custom neighborhood size
J = medfilt2(I, [m n], 'symmetric') % Symmetric padding
```

**From MathWorks Documentation (Ref p.721):**
> "Median filtering is a nonlinear operation often used in image processing to reduce salt-and-pepper noise. The median filter is more effective than convolution when the goal is to simultaneously reduce noise and preserve edges."

**Neighborhood Size Selection:**
- Salt-and-pepper: Start with [3 3], increase if needed
- Rule: Neighborhood should be larger than largest noise feature
- Odd dimensions required

```matlab
% Example: Remove salt-and-pepper noise
I = imread('cameraman.tif');
noisy = imnoise(I, 'salt & pepper', 0.05);

% Median filter (3x3 is usually sufficient)
cleaned = medfilt2(noisy, [3 3]);

% For heavier noise, use larger neighborhood
heavy_noise = imnoise(I, 'salt & pepper', 0.20);
cleaned_heavy = medfilt2(heavy_noise, [5 5]);
```

## Wiener Filter: `wiener2`

Adaptive filter that adjusts based on local statistics. Optimal for spatially varying noise.

**Syntax:**
```matlab
J = wiener2(I, [m n], noise)       % Known noise variance
[J, noise_out] = wiener2(I, [m n]) % Estimate noise variance
```

**From MathWorks Documentation (Ref p.3681):**
> "wiener2 uses a pixelwise adaptive Wiener method based on statistics estimated from a local neighborhood of each pixel. Where the variance is large, wiener2 performs little smoothing. Where the variance is small, wiener2 performs more smoothing."

**How It Works:**
1. Estimates local mean μ and variance σ² in each [m n] neighborhood
2. Computes filter output: `J(x,y) = μ + max(0, σ² - ν²)/σ² × (I(x,y) - μ)`
3. Where ν² is the noise variance

```matlab
% Example: Adaptive denoising
I = imread('saturn.png');
I = im2double(rgb2gray(I));
noisy = imnoise(I, 'gaussian', 0, 0.01);

% Wiener filter - estimates noise automatically
[denoised, noise_est] = wiener2(noisy, [5 5]);
fprintf('Estimated noise variance: %.6f\n', noise_est);

% With known noise variance (better results)
denoised2 = wiener2(noisy, [5 5], 0.01);
```

## Bilateral Filter: `imbilatfilt`

Edge-preserving smoothing using both spatial and intensity distance.

```matlab
B = imbilatfilt(A)                           % Default parameters
B = imbilatfilt(A, DegreeOfSmoothing)        % Control smoothing
B = imbilatfilt(A, DegreeOfSmoothing, SpatialSigma)
```

**When to Use:**
- When Gaussian blurs edges too much
- For texture-preserving denoising
- For non-Gaussian noise with edge preservation needed

```matlab
% Example: Edge-preserving denoising
I = imread('peppers.png');
noisy = imnoise(I, 'gaussian', 0, 0.01);

% Bilateral filter preserves edges better than Gaussian
bilateral_result = imbilatfilt(noisy, 0.1, 2);
gaussian_result = imgaussfilt(noisy, 2);
```

## Non-Local Means: `imnlmfilt`

State-of-the-art denoising using patch similarity. Best quality but computationally expensive.

```matlab
B = imnlmfilt(A)
B = imnlmfilt(A, 'DegreeOfSmoothing', value)
B = imnlmfilt(A, 'SearchWindowSize', size)
```

## Medical Imaging: Denoising Pipeline

```matlab
function denoised = denoise_medical(img, modality)
    % Convert to double for processing
    img = im2double(img);

    switch lower(modality)
        case 'mri'
            % MRI: Rician noise → use non-local means or bilateral
            denoised = imnlmfilt(img, 'DegreeOfSmoothing', 0.05);

        case 'ct'
            % CT: Poisson + electronic noise → Wiener or Gaussian
            denoised = wiener2(img, [5 5]);

        case 'ultrasound'
            % Ultrasound: Speckle noise → log transform + Wiener
            img_log = log1p(img);
            denoised_log = wiener2(img_log, [7 7]);
            denoised = expm1(denoised_log);
            denoised = mat2gray(denoised);

        case 'xray'
            % X-ray: Quantum noise → Gaussian or bilateral
            denoised = imgaussfilt(img, 1.5, 'Padding', 'replicate');

        otherwise
            % Default: adaptive Wiener
            denoised = wiener2(img, [5 5]);
    end
end
```

## Common Pitfalls

### 1. Wrong Filter for Noise Type
```matlab
% WRONG: Gaussian filter on salt-and-pepper noise
noisy = imnoise(I, 'salt & pepper', 0.05);
bad = imgaussfilt(noisy, 2);  % Spreads the noise!

% CORRECT: Median filter for salt-and-pepper
good = medfilt2(noisy, [3 3]);
```

### 2. Forgetting Boundary Handling (imfilter vs imgaussfilt)
```matlab
% NOTE: imgaussfilt defaults to 'replicate' padding - NO change needed!
filtered = imgaussfilt(I, 2);  % Already uses 'replicate' by default

% BUT: imfilter defaults to zero-padding - this creates dark borders!
h = fspecial('gaussian', [5 5], 2);
bad = imfilter(I, h);  % Zero-padding by default - dark borders!

% CORRECT for imfilter: Use replicate padding
good = imfilter(I, h, 'replicate');
```

### 3. Over-smoothing
```matlab
% WRONG: Excessive sigma destroys features
over_smoothed = imgaussfilt(I, 10);

% CORRECT: Start small, increase until noise acceptable
sigma = 1;
while noise_measure(filtered) > threshold && sigma < 5
    filtered = imgaussfilt(I, sigma);
    sigma = sigma + 0.5;
end
```

### 4. Data Type Issues
```matlab
% WRONG: Applying filter to uint8 can cause precision loss
I_uint8 = imread('image.png');
filtered = wiener2(I_uint8, [5 5]);  % May have reduced precision

% CORRECT: Convert to double, process, convert back
I_double = im2double(I_uint8);
filtered = wiener2(I_double, [5 5]);
result = im2uint8(filtered);
```

## Performance Comparison

| Filter | Speed | Edge Preservation | Best For |
|--------|-------|-------------------|----------|
| `imgaussfilt` | Fast | Low | Gaussian noise, preprocessing |
| `medfilt2` | Fast | Medium | Salt-and-pepper |
| `wiener2` | Medium | Medium | Adaptive, unknown noise |
| `imbilatfilt` | Slow | High | Edge-critical applications |
| `imnlmfilt` | Very slow | Very high | Maximum quality needed |

---
*Source: MathWorks IPT Reference (R2025b). Note: imgaussfilt defaults to 'replicate' padding; imfilter defaults to 0.*
