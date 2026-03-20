# Wavelet Toolbox Skill - Test Results

**Test Date:** 2026-02-04
**Skill:** matlab-wavelet-toolbox
**Platform:** Claude Desktop with skill toggle

***

## Test 1: Shearlet Transforms for Directional Texture Analysis

**Question:**

```
How do I use shearlets for directional texture analysis in MATLAB?
```

### Without Skill

Claude suggests downloading a **third-party toolbox** (ShearLab 3D):

```matlab
% Install: download from www.shearlab.org
% Add to path
addpath(genpath('ShearLab3Dv11'));

% Load image
img = double(imread('your_medical_image.png'));

% Generate shearlet system
shearletSystem = SLgetShearletSystem2D(0, size(img,1), size(img,2), 4);

% Compute shearlet coefficients
coeffs = SLsheardec2D(img, shearletSystem);

% Reconstruct
imgRec = SLshearrec2D(coeffs, shearletSystem);
```

**Problems:**

* Requires downloading external toolbox from shearlab.org

* Uses non-standard function names (`SLgetShearletSystem2D`, `SLsheardec2D`)

* Adds external dependency to projects

* MATLAB's Wavelet Toolbox has native support that Claude doesn't know about

### With Skill

Claude uses MATLAB's **native shearlet functions**:

```matlab
img = double(imread('your_image.png'));
sh = shearletSystem('ImageSize', size(img), ...
    'NumScales', 4, ...
    'DirectionalFilter', 'meyer', ...
    'TransformType', 'real');

coeffs = sheart2(sh, img);
```

Feature extraction:

```matlab
for scale = 1:sh.NumScales
    numDirs = size(coeffs{scale}, 3);
    for dir = 1:numDirs
        subband = coeffs{scale}(:,:,dir);
        energy(scale, dir) = mean(abs(subband(:)).^2);
    end
end
```

Reconstruction:

```matlab
imgRec = isheart2(sh, coeffs);
```

Also explicitly notes:

> "sheart2/isheart2 are the correct forward/inverse function names (not shearletTransform)"

### Comparison Summary

| Aspect                | Without Skill                     | With Skill                        |
| --------------------- | --------------------------------- | --------------------------------- |
| Approach              | Third-party toolbox (ShearLab 3D) | **Native MATLAB Wavelet Toolbox** |
| Setup required        | Download from shearlab.org        | **None — built-in**               |
| System creation       | `SLgetShearletSystem2D`           | `shearletSystem`                  |
| Forward transform     | `SLsheardec2D`                    | `sheart2`                         |
| Inverse transform     | `SLshearrec2D`                    | `isheart2`                        |
| External dependencies | Yes                               | **No**                            |

### Verdict

**Clear practical improvement.** The skill directs users to MATLAB's built-in shearlet functions instead of requiring a third-party download. This:

* Eliminates external dependencies

* Uses officially supported MATLAB functions

* Simplifies project setup and distribution

* Ensures compatibility with MATLAB's documentation and support

***

## Overall Assessment

The Wavelet Toolbox skill demonstrates **clear practical value** by:

* Directing users to native MATLAB functions instead of third-party alternatives

* Clarifying correct function names (`sheart2`/`isheart2`, not `shearletTransform`)

* Providing accurate syntax for MATLAB's built-in Wavelet Toolbox features

This is particularly important for researchers who want reproducible workflows without external dependencies.