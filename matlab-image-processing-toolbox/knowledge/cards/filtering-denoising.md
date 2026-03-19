# Filtering: Medical Imaging Gotchas and Modality-Specific Denoising

The model knows standard filtering functions well. This card focuses on medical-specific denoising patterns and the critical gotchas.

## Key Gotchas

### `imfilter` vs `imgaussfilt` Padding Defaults

```matlab
% imgaussfilt defaults to 'replicate' padding — safe for medical images
filtered = imgaussfilt(I, 2);  % Already uses 'replicate'

% imfilter defaults to ZERO-padding — creates dark borders!
h = fspecial('gaussian', [5 5], 2);
bad = imfilter(I, h);            % Dark border artifacts!
good = imfilter(I, h, 'replicate');  % Fix: explicit padding
```

### Anscombe Transform is NOT Built-In

For Poisson noise (low-light microscopy, nuclear medicine), implement manually:
```matlab
y = 2*sqrt(x + 3/8);           % Forward (variance-stabilizing)
x = (y/2).^2 - 3/8;            % Inverse
```

## Modality-Specific Denoising

```matlab
function denoised = denoise_medical(img, modality)
    img = im2double(img);

    switch lower(modality)
        case 'mri'
            % MRI has Rician noise (NOT Gaussian) in magnitude images
            % Non-local means preserves structure best
            denoised = imnlmfilt(img, 'DegreeOfSmoothing', 0.05);

        case 'ct'
            % CT: Poisson + electronic noise
            denoised = wiener2(img, [5 5]);

        case 'ultrasound'
            % Speckle is MULTIPLICATIVE — must log-transform first
            img_log = log1p(img);
            denoised_log = wiener2(img_log, [7 7]);
            denoised = expm1(denoised_log);
            denoised = mat2gray(denoised);

        case 'xray'
            % Quantum noise — Gaussian or bilateral
            denoised = imgaussfilt(img, 1.5, 'Padding', 'replicate');
    end
end
```

### Why Each Modality Needs Different Treatment

| Modality | Noise Type | Why Standard Gaussian Fails |
|----------|-----------|---------------------------|
| MRI | Rician (magnitude) | Not symmetric; biases low-signal regions |
| Ultrasound | Multiplicative speckle | Gaussian assumes additive noise |
| CT | Poisson-dominated | Signal-dependent variance |
| Fluorescence microscopy | Poisson (photon-limited) | Need variance stabilization first |

---
*Source: MathWorks IPT Reference (R2025a). imgaussfilt defaults to 'replicate'; imfilter defaults to 0.*
