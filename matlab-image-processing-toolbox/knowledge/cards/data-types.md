# Data Types and Conversions

Understanding image data types is **critical** - type mismatches are the #1 source of errors in image processing code.

## Image Data Types

| Type | Range | Size | Typical Use |
|------|-------|------|-------------|
| `uint8` | [0, 255] | 1 byte | Display, storage, web images |
| `uint16` | [0, 65535] | 2 bytes | Medical (DICOM), microscopy |
| `int16` | [-32768, 32767] | 2 bytes | DICOM signed data |
| `single` | [-Inf, Inf] or [0, 1] | 4 bytes | GPU processing, DL |
| `double` | [-Inf, Inf] or [0, 1] | 8 bytes | Arithmetic, filtering |
| `logical` | 0 or 1 | 1 bit | Binary masks, segmentation |

## Critical Conversion Rules

### uint8 ↔ double

```matlab
% uint8 [0,255] → double [0,1]
img_double = im2double(img_uint8);
% Internal operation: double(img) / 255

% double [0,1] → uint8 [0,255]
img_uint8 = im2uint8(img_double);
% Internal operation: uint8(img * 255)

% WRONG: Direct cast doesn't scale!
bad = double(img_uint8);  % Still [0,255], not [0,1]!
bad = uint8(img_double);  % Truncates to 0 or 1!
```

### uint16 ↔ double

```matlab
% uint16 [0,65535] → double [0,1]
img_double = im2double(img_uint16);
% Internal operation: double(img) / 65535

% double [0,1] → uint16 [0,65535]
img_uint16 = im2uint16(img_double);
```

### Any → Normalized [0,1]

```matlab
% mat2gray handles any range
img_normalized = mat2gray(img);  % Scales to [0,1]
img_normalized = mat2gray(img, [min_val, max_val]);  % Custom range
```

## Common Errors and Fixes

### Error 1: Black Image After Filtering

```matlab
% PROBLEM: Filtering uint8, then converting to double
img = imread('image.png');  % uint8
filtered = imfilter(img, fspecial('gaussian', 5, 1));  % uint8 output
result = im2double(filtered);  % [0,1]
% So far OK...

% But if you did arithmetic first:
img = imread('image.png');  % uint8
img_scaled = img / 255;     % WRONG! Integer division → mostly 0
```

**Fix:**
```matlab
img = im2double(imread('image.png'));  % Convert FIRST
% Now safe to do arithmetic
```

### Error 2: Saturated (White) Image

```matlab
% PROBLEM: Converting [0,1] to uint8 with direct multiply
img = im2double(imread('image.png'));  % [0,1]
processed = img * 2;  % Now [0,2]
result = im2uint8(processed);  % Everything > 1 becomes 255!

% FIX: Clip or normalize first
result = im2uint8(min(processed, 1));  % Clip
result = im2uint8(mat2gray(processed));  % Normalize
```

### Error 3: Wrong Threshold Range

```matlab
% PROBLEM: graythresh returns [0,1], comparing to uint8
img = imread('coins.png');  % uint8, [0,255]
level = graythresh(img);    % Returns 0.45 (normalized!)
bw = img > level;           % Compares [0-255] to 0.45 → all white!

% FIX: Use imbinarize (handles automatically)
bw = imbinarize(img);
% OR scale threshold
bw = img > level * 255;
```

### Error 4: Mixed Type Arithmetic

```matlab
% PROBLEM: Operating on different types
mask = imread('mask.png');       % uint8
weights = [0.5, 0.3, 0.2];       % double
result = mask .* weights(1);     % uint8 arithmetic!

% FIX: Convert to same type first
mask_double = im2double(mask);
result = mask_double * weights(1);
```

## Type Checking Functions

```matlab
% Check current type
class(img)          % Returns 'uint8', 'double', etc.
isa(img, 'uint8')   % Returns true/false

% Check if floating point
isfloat(img)        % true for single, double

% Check if integer
isinteger(img)      % true for uint8, uint16, int16, etc.

% Check if logical
islogical(img)      % true for binary masks
```

## Safe Conversion Function

```matlab
function img_out = safe_convert(img_in, target_class)
    % Safely convert image to target class
    %
    % Handles: uint8, uint16, int16, single, double, logical

    switch target_class
        case 'double'
            if islogical(img_in)
                img_out = double(img_in);
            else
                img_out = im2double(img_in);
            end

        case 'single'
            if islogical(img_in)
                img_out = single(img_in);
            else
                img_out = im2single(img_in);
            end

        case 'uint8'
            if islogical(img_in)
                img_out = uint8(img_in) * 255;
            elseif isfloat(img_in)
                img_out = im2uint8(mat2gray(img_in));
            else
                img_out = im2uint8(img_in);
            end

        case 'uint16'
            if islogical(img_in)
                img_out = uint16(img_in) * 65535;
            elseif isfloat(img_in)
                img_out = im2uint16(mat2gray(img_in));
            else
                img_out = im2uint16(img_in);
            end

        case 'logical'
            if isfloat(img_in)
                img_out = img_in > 0.5;
            else
                img_out = img_in > intmax(class(img_in))/2;
            end

        otherwise
            error('Unsupported target class: %s', target_class);
    end
end
```

## Medical Image Formats

### DICOM

```matlab
% Read DICOM (often int16 or uint16)
info = dicominfo('scan.dcm');
img = dicomread('scan.dcm');

% Check actual data type
fprintf('Data type: %s\n', class(img));
fprintf('Range: [%d, %d]\n', min(img(:)), max(img(:)));

% Convert to Hounsfield Units (CT)
if isfield(info, 'RescaleSlope')
    hu = double(img) * info.RescaleSlope + info.RescaleIntercept;
end

% Convert to double [0,1] for processing
img_norm = mat2gray(double(img));
```

### NIfTI

```matlab
% Read NIfTI (MRI volumes)
info = niftiinfo('brain.nii');
V = niftiread('brain.nii');

% Often single or double precision
fprintf('Data type: %s\n', class(V));

% Normalize for processing
V_norm = mat2gray(double(V));
```

## Display Considerations

```matlab
% imshow expects:
% - uint8: [0, 255]
% - double: [0, 1]

% PROBLEM: double not in [0,1]
img = rand(100) * 10;  % [0, 10]
imshow(img);           % Appears saturated!

% FIX: Specify display range or normalize
imshow(img, []);       % Auto-scale
imshow(img, [0 10]);   % Specify range
imshow(mat2gray(img)); % Normalize first
```

## Processing Pipeline Template

```matlab
function result = process_image(img)
    % Store original class for output
    original_class = class(img);

    % Convert to double for processing
    if ~isfloat(img)
        img = im2double(img);
    end

    % All processing in double
    filtered = imgaussfilt(img, 2);
    enhanced = adapthisteq(filtered);
    % ... more processing ...

    % Convert back to original class
    switch original_class
        case 'uint8'
            result = im2uint8(enhanced);
        case 'uint16'
            result = im2uint16(enhanced);
        case 'double'
            result = enhanced;
        otherwise
            result = enhanced;
    end
end
```

## Quick Reference

| From | To | Function |
|------|-----|----------|
| Any | double [0,1] | `im2double(img)` |
| Any | single [0,1] | `im2single(img)` |
| Any | uint8 [0,255] | `im2uint8(img)` |
| Any | uint16 [0,65535] | `im2uint16(img)` |
| Any | [0,1] normalized | `mat2gray(img)` |
| double | logical | `imbinarize(img)` or `img > thresh` |
| uint8 | logical | `imbinarize(img)` |

## Summary Rules

1. **Always convert to double before arithmetic operations**
2. **Use `im2double`/`im2uint8`, not `double()`/`uint8()`**
3. **Check data type with `class()` when debugging**
4. **`graythresh` returns [0,1]; use `imbinarize` instead of manual comparison**
5. **Use `mat2gray` to normalize arbitrary ranges to [0,1]**
6. **Store original class and convert back at the end of processing**

---
*Source: MathWorks IPT Reference (R2024b), pages 759 (im2double), 1442 (im2uint8)*
