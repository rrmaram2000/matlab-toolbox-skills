# Custom Wavelet Design via Lifting Scheme

## Mathematical Foundation

The lifting scheme (Sweldens, 1996) provides a framework for:
1. Constructing wavelets with desired properties
2. In-place computation (memory efficient)
3. **Learning wavelets from data** (differentiable operations)

### Polyphase Representation

Any signal x[n] can be split into even and odd polyphase components:
```
xₑ[n] = x[2n]      (even samples)
xₒ[n] = x[2n+1]    (odd samples)
```

The lifting scheme operates on these polyphase components.

### Lifting Factorization Theorem

**Any wavelet filter bank can be factored into lifting steps:**
```
[Lo_D(z)]     [1    0  ] [1  s(z)] ... [1    0  ] [K    0  ] [1  1]
[Hi_D(z)]  =  [t(z) 1  ] [0  1   ]     [uₙ(z) 1] [0  1/K  ] [1 -1]
```

where:
- Predict steps: P(z) = s(z), applied to odd samples
- Update steps: U(z) = t(z), u(z), applied to even samples
- K: normalization constant

### Lifting Step Operators

**Predict (P)**: Predicts odd samples from even neighbors
```
d[n] = xₒ[n] - P(xₑ)[n]
```
The wavelet (detail) coefficients measure "prediction error."

**Update (U)**: Updates even samples using detail
```
s[n] = xₑ[n] + U(d)[n]
```
The scaling (approximation) coefficients preserve signal properties.

## Constructing Custom Wavelets in MATLAB

### Starting from Lazy Wavelet (Identity)

```matlab
% Lazy wavelet: no processing, just split into polyphase
% xₑ = x[2n], xₒ = x[2n+1]

% Build Haar from lazy wavelet
ls = liftingScheme;  % Start with lazy (identity)

% Add predict: d = odd - even (difference)
pStep = liftingStep('Type', 'predict', ...
    'Coefficients', -1, ...  % d[n] = xₒ[n] - 1*xₑ[n]
    'MaxOrder', 0);          % Zero-delay filter
ls = addlift(ls, pStep);

% Add update: s = even + 0.5*d (average)
uStep = liftingStep('Type', 'update', ...
    'Coefficients', 0.5, ... % s[n] = xₑ[n] + 0.5*d[n]
    'MaxOrder', 0);
ls = addlift(ls, uStep);

% This creates Haar wavelet!
[LL, LH, HL, HH] = lwt2(img, liftingScheme=ls);
```

### Building Higher-Order Wavelets

Each additional lifting step increases vanishing moments or regularity.

```matlab
% Start from Haar
ls = liftingScheme('Wavelet', 'haar');

% Add predict step for 2 more vanishing moments
% Uses linear interpolation of neighbors
pStep = liftingStep('Type', 'predict', ...
    'Coefficients', [-0.5, 0.5], ...  % Linear interpolation
    'MaxOrder', 1);                    % Access neighbor at n+1
ls = addlift(ls, pStep);

% Add update step for smoother scaling function
uStep = liftingStep('Type', 'update', ...
    'Coefficients', [0.25, 0.25], ...  % Average of neighbors
    'MaxOrder', 0);
ls = addlift(ls, uStep);

% Verify properties
[phi, psi, xval] = liftwave(ls, 'plot');
```

### CDF 9/7 Wavelet (JPEG2000)

```matlab
% CDF 9/7: the wavelet used in JPEG2000 lossy compression
% Constructed via 4 lifting steps

ls = liftingScheme;

% Step 1: Predict
p1 = liftingStep('Type', 'predict', ...
    'Coefficients', [-1.586134342, -1.586134342], 'MaxOrder', 1);
ls = addlift(ls, p1);

% Step 2: Update
u1 = liftingStep('Type', 'update', ...
    'Coefficients', [-0.052980118, -0.052980118], 'MaxOrder', 0);
ls = addlift(ls, u1);

% Step 3: Predict
p2 = liftingStep('Type', 'predict', ...
    'Coefficients', [0.882911076, 0.882911076], 'MaxOrder', 1);
ls = addlift(ls, p2);

% Step 4: Update
u2 = liftingStep('Type', 'update', ...
    'Coefficients', [0.443506852, 0.443506852], 'MaxOrder', 0);
ls = addlift(ls, u2);

% Normalization: K = 1.149604398
```

## Learning Wavelets from Image Data

### Optimization Framework

For data-driven wavelets, optimize lifting coefficients to minimize a loss:

```
min_{P,U} L(x, x̂) + λR(P,U)
```

where:
- L: reconstruction loss, sparsity loss, or task-specific loss
- R: regularization (smoothness, vanishing moments constraint)

### Differentiable Lifting in MATLAB

```matlab
% Wrap lifting coefficients in dlarray for gradient descent
pCoeffs = dlarray([0.5, -0.5], 'CB');  % Predict filter
uCoeffs = dlarray([0.25, 0.25], 'CB'); % Update filter

% Define learnable lifting transform
function [s, d] = learnableLift1D(x, pCoeffs, uCoeffs)
    % Split into even/odd
    xEven = x(1:2:end);
    xOdd = x(2:2:end);

    % Predict step: d = odd - P(even)
    pEven = conv(xEven, pCoeffs, 'same');
    d = xOdd - pEven;

    % Update step: s = even + U(d)
    uD = conv(d, uCoeffs, 'same');
    s = xEven + uD;
end

% Training loop (simplified)
for epoch = 1:numEpochs
    for batch = 1:numBatches
        x = getMiniBatch(data, batch);

        % Forward pass
        [s, d] = learnableLift1D(x, pCoeffs, uCoeffs);

        % Loss: sparsity of details + reconstruction
        loss = mean(abs(d)) + lambda * reconstructionLoss(x, s, d);

        % Backward pass
        grads = dlgradient(loss, {pCoeffs, uCoeffs});

        % Update coefficients
        pCoeffs = pCoeffs - lr * grads{1};
        uCoeffs = uCoeffs - lr * grads{2};
    end
end
```

### Constraints for Valid Wavelets

When learning filters, enforce constraints:

**1. Perfect Reconstruction:**
```matlab
% For biorthogonal: H̃(z)H(z) + H̃(-z)H(-z) = 2
% Enforce via parameterization or projection

function coeffs = projectToPR(coeffs)
    % Project to nearest perfect reconstruction filters
    % using alternating projections or parameterization
end
```

**2. Vanishing Moments:**
```matlab
% Wavelet has N vanishing moments if:
% sum(h .* (0:length(h)-1).^k) = 0 for k = 0,...,N-1

function [lo, hi] = enforceVanishingMoments(lo, N)
    % Parameterize as (1+z^-1)^N * Q(z)
    % Only optimize Q(z), ensuring N zeros at z=-1

    % Construct high-pass via QMF
    hi = lo .* ((-1).^(0:length(lo)-1));
end
```

**3. Regularity (Smoothness):**
```matlab
% Regularity ≈ log2(|eigenvalue|) of subdivision matrix
% Higher regularity = smoother wavelet

function reg = estimateRegularity(lo)
    % Cascade algorithm: iterate dilation equation
    phi = lo;
    for iter = 1:10
        phi_up = upsample(phi, 2);
        phi = conv(phi_up, lo, 'same') * sqrt(2);
    end
    % Estimate smoothness from convergence rate
    reg = estimateSobolevExponent(phi);
end
```

## Integration with Deep Learning (R2025a+)

### Learnable Wavelet Layer

```matlab
classdef learnableWaveletLayer < nnet.layer.Layer & ...
        nnet.layer.Formattable

    properties (Learnable)
        PredictCoeffs  % Learnable predict filter
        UpdateCoeffs   % Learnable update filter
    end

    properties
        FilterLength = 4
        NumLevels = 3
    end

    methods
        function layer = learnableWaveletLayer(name, filterLen, levels)
            layer.Name = name;
            layer.FilterLength = filterLen;
            layer.NumLevels = levels;

            % Initialize with Haar-like coefficients
            layer.PredictCoeffs = dlarray(randn(1, filterLen)*0.1);
            layer.UpdateCoeffs = dlarray(randn(1, filterLen)*0.1);
        end

        function [Z, memory] = forward(layer, X)
            % X: input image [H, W, C, B]
            [H, W, C, B] = size(X);

            % Apply lifting DWT with learnable filters
            % Implementation depends on your specific needs
            Z = liftingDWT2D(X, layer.PredictCoeffs, layer.UpdateCoeffs, layer.NumLevels);
        end
    end
end
```

### Using dldwt for Differentiable Wavelets

```matlab
% R2025a+: Built-in differentiable DWT
x = dlarray(img, 'SSCB');

% Forward with gradient tracking - returns 2 outputs only
[A, D] = dldwt(x, Wavelet='db4');
% A = approximation coefficients
% D = detail coefficients (H,V,D concatenated in 3rd dimension)
% For 2D: D(:,:,1,:)=H, D(:,:,2,:)=V, D(:,:,3,:)=D

% Modify coefficients (example: learned weighting on detail)
D_weighted = D .* learnableWeight;

% Inverse - takes 2 coefficient inputs
xRec = dlidwt(A, D_weighted, Wavelet='db4');

% Loss and gradients
loss = mse(xRec, target);
grads = dlgradient(loss, learnableWeight);
```

## Verifying Wavelet Properties

```matlab
function validateCustomWavelet(ls)
    % Extract filters (ls2filt for liftingScheme objects)
    [Lo_D, Hi_D, Lo_R, Hi_R] = ls2filt(ls);

    fprintf('=== Wavelet Validation ===\n');

    % 1. Perfect reconstruction
    x = randn(256, 1);
    [lo, hi] = lwt(x, liftingScheme=ls);
    xRec = ilwt(lo, hi, liftingScheme=ls);
    prError = max(abs(x - xRec));
    fprintf('Perfect reconstruction error: %.2e\n', prError);

    % 2. Vanishing moments (highpass sum = 0)
    fprintf('Highpass sum (VM check): %.6f\n', sum(Hi_D));

    % 3. Energy preservation
    fprintf('Lowpass energy: %.6f (should be 1)\n', sum(Lo_D.^2));
    fprintf('Highpass energy: %.6f (should be 1)\n', sum(Hi_D.^2));

    % 4. Orthogonality (for orthogonal wavelets)
    ortho = abs(Lo_D * Hi_D');
    fprintf('Orthogonality: %.6f (should be 0)\n', ortho);

    % 5. Regularity estimate
    [phi, psi, xval] = wavefun(ls, 10);
    fprintf('Wavelet support: [%.2f, %.2f]\n', min(xval), max(xval));
end
```

## Application: Edge-Adaptive Wavelet for Medical Images

```matlab
% Design wavelet optimized for edge preservation in MRI

% Start from sym4 (good baseline for medical)
ls = liftingScheme('Wavelet', 'sym4');

% Add predict step tuned for edge sharpening
% Negative coefficients enhance edges
edgePredict = liftingStep('Type', 'predict', ...
    'Coefficients', [0.1, -0.2, 0.1], ...  % Edge-enhancing
    'MaxOrder', 1);
ls = addlift(ls, edgePredict);

% Apply to MRI
[LL, LH, HL, HH] = lwt2(mri, liftingScheme=ls, Level=4);

% Edge-based processing in wavelet domain
LH_enhanced = LH .* (1 + 0.5 * abs(LH) ./ (abs(LH) + eps));
HL_enhanced = HL .* (1 + 0.5 * abs(HL) ./ (abs(HL) + eps));

% Reconstruct
mri_enhanced = ilwt2(LL, LH_enhanced, HL_enhanced, HH, liftingScheme=ls);
```
