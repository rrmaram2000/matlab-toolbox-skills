# Medical Imaging Wavelet Analysis

## Noise Models by Modality

### MRI: Rician Noise

MRI magnitude images have **Rician noise** (not Gaussian):
```
p(M|A,σ) = (M/σ²) exp(-(M² + A²)/(2σ²)) I₀(MA/σ²)
```
where A is true signal, M is measured magnitude, I₀ is modified Bessel function.

**Properties:**
- Signal-dependent: SNR varies across image
- Asymmetric: positive bias at low SNR
- Approaches Gaussian at high SNR (SNR > 3)

```matlab
% MRI denoising accounting for Rician bias
% For high-SNR regions, standard wavelet works
mriDenoised = wdenoise2(mri, ...
    'DenoisingMethod', 'Bayes', ...  % Good for smooth structures
    'Wavelet', 'sym6', ...              % Good for smooth structures
    'Level', 4, ...
    'ThresholdRule', 'Soft');

% For low-SNR regions, apply bias correction
% Rician bias: E[M] ≈ sqrt(A² + σ²) for low SNR
sigma_noise = estimateNoise(mri);  % MAD estimator
biasCorrection = max(0, mriDenoised.^2 - sigma_noise^2);
mriCorrected = sqrt(biasCorrection);
```

### CT: Poisson + Electronic Noise

CT follows a compound model:
```
y = Poisson(I₀ exp(-μx)) + N(0, σ_e²)
```
where I₀ is incident photon count, μ is attenuation, σ_e is electronic noise.

**Properties:**
- Variance proportional to signal (Poisson)
- Higher noise in low-attenuation (soft tissue) regions
- Streak artifacts from photon starvation

```matlab
% CT denoising with variance stabilization
% Anscombe transform: stabilizes Poisson variance
ct_anscombe = 2 * sqrt(ct + 3/8);

% Denoise in stabilized domain
ct_denoised_stab = wdenoise2(ct_anscombe, ...
    'DenoisingMethod', 'SURE', ...
    'Wavelet', 'db4', ...
    'Level', 3);

% Inverse Anscombe
ct_denoised = (ct_denoised_stab/2).^2 - 3/8;
ct_denoised = max(0, ct_denoised);  % Enforce non-negativity

% Alternative: Direct dual-tree for edge preservation
[a, d] = dualtree2(ct, Level=4);
for lev = 1:4
    for dir = 1:6
        c = d{lev}(:,:,dir);
        sigma = median(abs(c(:))) / 0.6745;
        thr = sigma * 2.5;  % Conservative threshold
        d{lev}(:,:,dir) = wthresh(c, 's', thr);
    end
end
ct_edges = idualtree2(a, d);
```

### Ultrasound: Multiplicative Speckle

Ultrasound has **multiplicative speckle** (Rayleigh-distributed):
```
y = x · n,  where n ~ Rayleigh(σ)
```

**Key insight:** Log-transform converts to additive noise:
```
log(y) = log(x) + log(n)
```

```matlab
% Complete ultrasound speckle reduction pipeline
us = double(us_raw);

% 1. Log transform (handles multiplicative noise)
us_log = log(us + 1);

% 2. Wavelet denoising in log domain
% Use Bayes estimator (optimal for unknown noise level)
us_denoised_log = wdenoise2(us_log, ...
    'DenoisingMethod', 'Bayes', ...
    'Wavelet', 'sym4', ...
    'Level', 4, ...
    'ThresholdRule', 'Soft');

% 3. Inverse transform
us_denoised = exp(us_denoised_log) - 1;

% 4. Post-processing: edge enhancement (speckle reduces edges)
[a, d] = dualtree2(us_denoised, Level=2);
d{1} = d{1} * 1.3;  % Enhance fine details
us_final = idualtree2(a, d);
```

### X-ray: Quantum Noise

X-ray follows Poisson statistics with Beer-Lambert attenuation:
```
I = I₀ exp(-∫μ(l)dl) + Poisson noise
```

```matlab
% X-ray denoising
xray_stab = 2 * sqrt(xray + 3/8);  % Anscombe
xray_denoised = wdenoise2(xray_stab, ...
    'DenoisingMethod', 'Bayes', ...
    'Wavelet', 'bior4.4', ...  % Symmetric for uniform processing
    'Level', 3);
xray_final = (xray_denoised/2).^2 - 3/8;
```

## Threshold Selection Theory

### Universal Threshold (VisuShrink)
```
λ = σ √(2 log n)
```
Guarantees asymptotic optimality, but often over-smooths.

### SURE (Stein's Unbiased Risk Estimate)
Minimizes MSE without knowing true signal:
```
SURE(λ) = n - 2·#{|wᵢ| ≤ λ} + Σmin(wᵢ², λ²)
```

```matlab
% Compute optimal SURE threshold
function thr = sureThreshold(coeffs)
    n = numel(coeffs);
    coeffs_sorted = sort(abs(coeffs(:)));

    risks = zeros(n, 1);
    for i = 1:n
        lambda = coeffs_sorted(i);
        num_below = sum(abs(coeffs(:)) <= lambda);
        risks(i) = n - 2*num_below + sum(min(coeffs(:).^2, lambda^2));
    end

    [~, idx] = min(risks);
    thr = coeffs_sorted(idx);
end
```

### BayesShrink
Estimates signal variance and sets threshold:
```
λ = σ²/σₓ,  where σₓ = sqrt(max(σᵧ² - σ², 0))
```

```matlab
function thr = bayesThreshold(coeffs, sigma_noise)
    sigma_y = std(coeffs(:));
    sigma_x = sqrt(max(sigma_y^2 - sigma_noise^2, 0));
    if sigma_x == 0
        thr = max(abs(coeffs(:)));  % Kill all coefficients
    else
        thr = sigma_noise^2 / sigma_x;
    end
end
```

## Multi-Modal Fusion

### Fusion Rules

| Rule | Approximation | Details | Best For |
|------|---------------|---------|----------|
| Mean | Average | Average | Balanced fusion |
| Max | Max | Max | Edge preservation |
| Min | Min | Min | Noise reduction |
| Weighted | Weighted avg | Weighted avg | Prior knowledge |
| PCA | Principal | Principal | Optimal variance |

### MRI + CT Fusion for Surgical Planning

```matlab
function fused = fuseMRI_CT(mri, ct, wname, level)
    % Register images first (assumed done)
    mri = double(mri);
    ct = double(ct);

    % Normalize to same range
    mri = (mri - min(mri(:))) / (max(mri(:)) - min(mri(:)));
    ct = (ct - min(ct(:))) / (max(ct(:)) - min(ct(:)));

    % Decompose
    [C_mri, S] = wavedec2(mri, level, wname);
    [C_ct, ~] = wavedec2(ct, level, wname);

    % Fusion coefficients
    nApprox = prod(S(1,:));

    % Approximation: weighted average
    % MRI better for soft tissue, CT for bone
    alpha = 0.6;  % MRI weight
    C_fused(1:nApprox) = alpha*C_mri(1:nApprox) + (1-alpha)*C_ct(1:nApprox);

    % Details: activity-based selection
    for i = nApprox+1:length(C_mri)
        % Higher magnitude = more informative
        if abs(C_mri(i)) > abs(C_ct(i))
            C_fused(i) = C_mri(i);
        else
            C_fused(i) = C_ct(i);
        end
    end

    fused = waverec2(C_fused, S, wname);
end
```

### PET/SPECT + CT Fusion

```matlab
function fused = fusePET_CT(pet, ct, level)
    % PET: low resolution, high functional info
    % CT: high resolution, anatomical info

    % Use SWT for shift-invariance (PET may be misaligned)
    [swa_pet, swh_pet, swv_pet, swd_pet] = swt2(pet, level, 'sym4');
    [swa_ct, swh_ct, swv_ct, swd_ct] = swt2(ct, level, 'sym4');

    % Approximation: primarily anatomical (CT)
    swa_fused = 0.3*swa_pet + 0.7*swa_ct;

    % Details: max absolute (preserve both structure and function)
    swh_fused = maxAbs(swh_pet, swh_ct);
    swv_fused = maxAbs(swv_pet, swv_ct);
    swd_fused = maxAbs(swd_pet, swd_ct);

    fused = iswt2(swa_fused, swh_fused, swv_fused, swd_fused, 'sym4');
end

function out = maxAbs(a, b)
    out = a;
    mask = abs(b) > abs(a);
    out(mask) = b(mask);
end
```

## Feature Extraction for Classification

### Wavelet Energy Features

Energy captures texture information at each scale:
```matlab
function features = waveletEnergy(img, wname, levels)
    [C, S] = wavedec2(double(img), levels, wname);

    features = [];
    for lev = 1:levels
        cH = detcoef2('h', C, S, lev);
        cV = detcoef2('v', C, S, lev);
        cD = detcoef2('d', C, S, lev);

        % Energy (normalized by number of coefficients)
        features = [features, ...
            sum(cH(:).^2)/numel(cH), ...
            sum(cV(:).^2)/numel(cV), ...
            sum(cD(:).^2)/numel(cD)];
    end

    % Approximation energy
    cA = appcoef2(C, S, wname);
    features = [features, sum(cA(:).^2)/numel(cA)];
end
```

### Wavelet Entropy Features

Shannon entropy quantifies coefficient distribution:
```matlab
function H = waveletEntropy(coeffs)
    % Normalized energy distribution
    E = coeffs(:).^2;
    p = E / sum(E);
    p = p(p > 0);  % Remove zeros

    H = -sum(p .* log2(p));
end
```

### Complete Feature Vector for Tumor Detection

```matlab
function features = tumorFeatures(roi, wname, levels)
    [C, S] = wavedec2(double(roi), levels, wname);

    features = [];
    for lev = 1:levels
        cH = detcoef2('h', C, S, lev);
        cV = detcoef2('v', C, S, lev);
        cD = detcoef2('d', C, S, lev);

        for subband = {cH, cV, cD}
            c = subband{1};
            % Statistical moments
            features = [features, ...
                mean(abs(c(:))), ...           % Mean absolute
                std(c(:)), ...                  % Standard deviation
                skewness(c(:)), ...            % Asymmetry
                kurtosis(c(:)), ...            % Peakedness
                sum(c(:).^2)/numel(c), ...    % Energy
                waveletEntropy(c)];            % Entropy
        end
    end

    % Approximation features
    cA = appcoef2(C, S, wname);
    features = [features, mean(cA(:)), std(cA(:)), ...
        skewness(cA(:)), kurtosis(cA(:))];
end
```

## Quality Metrics

```matlab
function metrics = evaluateDenoising(original, denoised, noisy)
    % Peak Signal-to-Noise Ratio
    metrics.psnr_before = psnr(noisy, original);
    metrics.psnr_after = psnr(denoised, original);
    metrics.psnr_gain = metrics.psnr_after - metrics.psnr_before;

    % Structural Similarity Index
    metrics.ssim_before = ssim(noisy, original);
    metrics.ssim_after = ssim(denoised, original);

    % Mean Squared Error
    metrics.mse_before = immse(noisy, original);
    metrics.mse_after = immse(denoised, original);

    % Edge preservation (gradient correlation)
    [gx_orig, gy_orig] = gradient(original);
    [gx_den, gy_den] = gradient(denoised);
    grad_orig = sqrt(gx_orig.^2 + gy_orig.^2);
    grad_den = sqrt(gx_den.^2 + gy_den.^2);
    metrics.edge_correlation = corr(grad_orig(:), grad_den(:));

    fprintf('PSNR: %.2f -> %.2f dB (+%.2f dB)\n', ...
        metrics.psnr_before, metrics.psnr_after, metrics.psnr_gain);
    fprintf('SSIM: %.4f -> %.4f\n', metrics.ssim_before, metrics.ssim_after);
    fprintf('Edge correlation: %.4f\n', metrics.edge_correlation);
end
```

## GPU Acceleration for Large Datasets

```matlab
% Process batch of medical images on GPU
function results = processImageBatchGPU(images, wname, level)
    results = cell(size(images));

    for i = 1:numel(images)
        % Transfer to GPU
        img_gpu = gpuArray(double(images{i}));

        % Decompose on GPU
        [C, S] = wavedec2(img_gpu, level, wname);

        % Process (example: denoising)
        sigma = gather(median(abs(C(end-prod(S(end,:))+1:end))) / 0.6745);
        thr = sigma * sqrt(2 * log(numel(img_gpu)));
        C = wthresh(C, 's', gpuArray(thr));

        % Reconstruct and gather
        results{i} = gather(waverec2(C, S, wname));
    end
end
```
