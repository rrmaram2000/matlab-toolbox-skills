# 2D Wavelet Transforms Quick Reference

## Transform Selection

| Transform | Function | Use Case | Properties |
|-----------|----------|----------|------------|
| Single-level DWT | `dwt2`/`idwt2` | Basic decomposition | Critically sampled |
| Multi-level DWT | `wavedec2`/`waverec2` | Standard analysis | Most common choice |
| Stationary WT | `swt2`/`iswt2` | Shift-invariant | Redundant, same size |
| Lifting DWT | `lwt2`/`ilwt2` | Custom wavelets | In-place computation |
| MODWT | `modwt`/`imodwt` | Variance analysis | **1D only** (no 2D version) |
| Dual-tree | `dualtree2`/`idualtree2` | Directional | 6 orientations |

## Standard Multi-Level Decomposition

```matlab
% Check maximum level FIRST
wname = 'db4';
maxLev = wmaxlev(size(img), wname);
level = min(4, maxLev);  % Typically 3-5

% Decompose
[C, S] = wavedec2(img, level, wname);

% Extract coefficients
cA = appcoef2(C, S, wname);           % Final approximation
cH = detcoef2('h', C, S, level);      % Horizontal detail
cV = detcoef2('v', C, S, level);      % Vertical detail
cD = detcoef2('d', C, S, level);      % Diagonal detail

% Reconstruct
imgRec = waverec2(C, S, wname);
```

## Single-Level Decomposition

```matlab
[cA, cH, cV, cD] = dwt2(img, 'db4');
% cA: Low-Low (approximation) - smooth content
% cH: Low-High (horizontal) - horizontal edges
% cV: High-Low (vertical) - vertical edges
% cD: High-High (diagonal) - diagonal edges

imgRec = idwt2(cA, cH, cV, cD, 'db4');
```

## Shift-Invariant Analysis

```matlab
% SWT - coefficients same size as input (redundant)
[swa, swh, swv, swd] = swt2(img, level, 'db4');
% Each is a 3D array: [rows, cols, levels]

imgRec = iswt2(swa, swh, swv, swd, 'db4');
```

## Coefficient Bookkeeping

The `wavedec2` output format:
```
C = [A(N) | H(N) | V(N) | D(N) | ... | H(1) | V(1) | D(1)]
S = bookkeeping matrix with sizes at each level
```

Extract specific components:
```matlab
% Approximation at any level
A3 = wrcoef2('a', C, S, wname, 3);

% Detail components
H2 = wrcoef2('h', C, S, wname, 2);  % Horizontal, level 2
V1 = wrcoef2('v', C, S, wname, 1);  % Vertical, level 1
```

## Boundary Handling

```matlab
% Default: 'symmetric' (best for most images)
[cA, cH, cV, cD] = dwt2(img, 'db4', 'mode', 'symmetric');

% Other modes: 'periodic', 'zpd' (zero-pad), 'sp0', 'sp1'
% For medical images: ALWAYS use 'symmetric'
```

## Common Pitfalls

| Problem | Cause | Solution |
|---------|-------|----------|
| "Level too high" | Image too small | Check `wmaxlev()` first |
| Dimension mismatch | Wrong inverse | Match pairs exactly |
| Border artifacts | Wrong extension | Use 'symmetric' mode |
| Different sizes | SWT vs DWT confusion | SWT keeps original size |
