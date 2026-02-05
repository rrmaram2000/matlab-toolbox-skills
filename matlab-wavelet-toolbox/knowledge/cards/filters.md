# Wavelet Filters Quick Reference

## Get Filter Coefficients

```matlab
% Get all four filters
[Lo_D, Hi_D, Lo_R, Hi_R] = wfilters('db4');
% Lo_D: Lowpass decomposition (scaling function)
% Hi_D: Highpass decomposition (wavelet function)
% Lo_R: Lowpass reconstruction
% Hi_R: Highpass reconstruction

% Just decomposition or reconstruction
[Lo_D, Hi_D] = wfilters('db4', 'd');  % Decomposition only
[Lo_R, Hi_R] = wfilters('db4', 'r');  % Reconstruction only
```

## Filter Properties

| Wavelet | Filter Length | Vanishing Moments | Support |
|---------|---------------|-------------------|---------|
| db1 (Haar) | 2 | 1 | 1 |
| db2 | 4 | 2 | 3 |
| db4 | 8 | 4 | 7 |
| db8 | 16 | 8 | 15 |
| sym4 | 8 | 4 | 7 |
| sym8 | 16 | 8 | 15 |
| bior4.4 | 9/7 | 4/4 | - |

## Orthogonal Filter Construction

```matlab
% From lowpass, construct orthogonal highpass (QMF)
Hi_D = orthfilt(Lo_D);

% Verify orthogonality
sum(Lo_D .* Hi_D)  % Should be ~0
sum(Lo_D.^2)       % Should be 1
sum(Hi_D.^2)       % Should be 1
```

## Biorthogonal Filters

```matlab
% Biorthogonal have separate analysis/synthesis pairs
[Rf, Df] = biorfilt(Lo_D, Hi_D, Lo_R, Hi_R);
% Rf: Reconstruction filter bank
% Df: Decomposition filter bank
```

## Filter Bank Object (Modern API)

```matlab
% Create DWT filter bank
fb = dwtfilterbank('Wavelet', 'db4', ...
    'SignalLength', 1024, ...
    'Level', 4);

% Get filter info
[Lo, Hi] = filters(fb);

% Analyze signal
[cA, cD] = fb.dwt(signal);
```

## Perfect Reconstruction Conditions

For perfect reconstruction, filters must satisfy:
```
Lo_D * Lo_R + Hi_D * Hi_R = 2 (at z = 1)
Lo_D * Lo_R(-z) + Hi_D * Hi_R(-z) = 0 (alias cancellation)
```

Verify in MATLAB:
```matlab
[Lo_D, Hi_D, Lo_R, Hi_R] = wfilters('db4');

% Check normalization
fprintf('Lo sum: %.4f (should be sqrt(2))\n', sum(Lo_D));

% Perfect reconstruction test
x = randn(256, 256);
[C, S] = wavedec2(x, 4, 'db4');
xRec = waverec2(C, S, 'db4');
fprintf('Max error: %.2e\n', max(abs(x(:) - xRec(:))));
```

## Visualize Wavelet and Scaling Functions

```matlab
% Compute wavelet and scaling function values
[phi, psi, xval] = wavefun('db4', 10);  % 10 iterations

figure;
subplot(2,1,1); plot(xval, phi); title('Scaling Function φ(x)');
subplot(2,1,2); plot(xval, psi); title('Wavelet Function ψ(x)');
```

## Filter Selection Guidelines

| Need | Choose |
|------|--------|
| Short filters (speed) | db2, haar |
| Good frequency localization | db8, sym8 |
| Near-linear phase | sym4-sym8 |
| Symmetric filters | bior3.3, bior4.4 |
| Smooth reconstruction | coif3, coif4 |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Mixing filter pairs | Use same wavelet for decomp/recon |
| Wrong filter order | Decomp filters for forward, recon for inverse |
| Assuming symmetry | Daubechies are NOT symmetric (use symlets) |
