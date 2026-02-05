# Shearlet Transform

## When to Use Shearlets

Shearlets are **optimal for curvilinear features**:
- Blood vessels
- Nerve fibers
- Tissue boundaries
- Any smooth curves in images

They provide better sparse representation of edges with curvature than wavelets or dual-tree.

## Basic Usage

```matlab
% Create shearlet system
sh = shearletSystem('ImageSize', size(img));

% Forward transform: sheart2 (not shearletTransform)
coeffs = sheart2(sh, img);
% coeffs is organized by scale and direction

% Inverse transform: isheart2 (not inverseShearletTransform)
imgRec = isheart2(sh, coeffs);
```

## Configuration Options

```matlab
% Full configuration
sh = shearletSystem(...
    'ImageSize', [256, 256], ...
    'NumScales', 4, ...               % Number of scales
    'DirectionalFilter', 'meyer', ... % 'meyer' or 'vow'
    'TransformType', 'real');         % 'real' or 'complex'

% Quick defaults
sh = shearletSystem('ImageSize', size(img));
```

## Accessing Coefficients

```matlab
sh = shearletSystem('ImageSize', size(img));
coeffs = sheart2(sh, img);

% Number of scales
numScales = sh.NumScales;

% Each scale has multiple shearing directions
for scale = 1:numScales
    numDirs = size(coeffs{scale}, 3);
    fprintf('Scale %d: %d directions\n', scale, numDirs);
end

% Lowpass (coarsest approximation)
lowpass = coeffs{end};
```

## Edge Detection

```matlab
sh = shearletSystem('ImageSize', size(img));
coeffs = sheart2(sh, img);

% Edge strength: sum of absolute coefficients
edgeStrength = zeros(size(img));
for scale = 1:sh.NumScales
    for dir = 1:size(coeffs{scale}, 3)
        edgeStrength = edgeStrength + abs(coeffs{scale}(:,:,dir));
    end
end

% Normalize
edgeStrength = edgeStrength / max(edgeStrength(:));
```

## Denoising with Shearlets

```matlab
sh = shearletSystem('ImageSize', size(noisyImg));
coeffs = sheart2(sh, noisyImg);

% Threshold all shearlet coefficients
for scale = 1:sh.NumScales
    for dir = 1:size(coeffs{scale}, 3)
        c = coeffs{scale}(:,:,dir);
        sigma = median(abs(c(:))) / 0.6745;
        thr = sigma * 3;  % Adjust as needed
        coeffs{scale}(:,:,dir) = wthresh(c, 's', thr);
    end
end

denoised = isheart2(sh, coeffs);
```

## Comparison: Shearlets vs Dual-Tree vs DWT

| Property | DWT | Dual-Tree | Shearlets |
|----------|-----|-----------|-----------|
| Directions | 3 | 6/scale | Many/scale |
| Curvature handling | Poor | Medium | Optimal |
| Sparsity for edges | Good | Better | Best |
| Speed | Fastest | Medium | Slower |
| Complexity | Simple | Medium | Higher |

## When to Choose Each

| Feature Type | Best Transform |
|--------------|----------------|
| General purpose | `wavedec2` |
| Oriented textures | `dualtree2` |
| Curvilinear edges | `shearletSystem` |
| Blood vessels | `shearletSystem` |
| Regular edges | `dualtree2` |
| Compression | `wavedec2` |

## Medical Imaging Applications

```matlab
% Vessel enhancement in angiography
sh = shearletSystem('ImageSize', size(angio));
coeffs = sheart2(sh, angio);

% Enhance fine-scale directional coefficients
for scale = 1:2  % Fine scales only
    coeffs{scale} = coeffs{scale} * 1.8;
end

enhanced = isheart2(sh, coeffs);
```
