# Data Types: Gotchas and Medical Imaging Formats

Type mismatches are the #1 source of silent errors. This card covers the non-obvious pitfalls.

## Critical Gotchas

### Gotcha 1: `double()` vs `im2double()` — They Are NOT the Same

```matlab
% WRONG: Direct cast doesn't scale!
bad = double(img_uint8);  % Still [0,255], not [0,1]!
bad = uint8(img_double);  % Truncates to 0 or 1!

% CORRECT: Use im2double / im2uint8
img = im2double(img_uint8);  % [0,255] → [0,1]
```

### Gotcha 2: Integer Division Produces Black Images

```matlab
img = imread('image.png');  % uint8
img_scaled = img / 255;     % WRONG! Integer division → mostly 0

% FIX: Convert FIRST, then do arithmetic
img = im2double(imread('image.png'));
```

### Gotcha 3: `graythresh` Returns [0,1] — Not Pixel Values

```matlab
img = imread('coins.png');  % uint8, [0,255]
level = graythresh(img);    % Returns 0.45 (normalized!)
bw = img > level;           % Compares [0-255] to 0.45 → all white!

% FIX: Use imbinarize (handles automatically)
bw = imbinarize(img);
```

### Gotcha 4: Saturation After Arithmetic

```matlab
processed = im2double(img) * 2;  % Now [0,2]
result = im2uint8(processed);    % Everything > 1 becomes 255!

% FIX: Clip or normalize first
result = im2uint8(mat2gray(processed));  % Normalize
```

### Gotcha 5: imshow with Out-of-Range Doubles

```matlab
img = rand(100) * 10;  % double [0, 10]
imshow(img);           % Appears saturated!

% FIX: Specify display range
imshow(img, []);       % Auto-scale
```

## Medical Image Format Handling

### DICOM — Hounsfield Unit Conversion

```matlab
info = dicominfo('scan.dcm');
img = dicomread('scan.dcm');  % Often int16 or uint16

% Convert to Hounsfield Units (CT) — must use RescaleSlope/Intercept
if isfield(info, 'RescaleSlope')
    hu = double(img) * info.RescaleSlope + info.RescaleIntercept;
end

% For general processing: normalize with mat2gray, NOT im2double
% (im2double assumes standard uint16 range; DICOM data may differ)
img_norm = mat2gray(double(img));
```

### NIfTI — Variable Precision

```matlab
V = niftiread('brain.nii');
% Often single or double; may contain negative values
% Always use mat2gray for normalization
V_norm = mat2gray(double(V));
```

## Safe Processing Pipeline Pattern

```matlab
function result = process_image(img)
    original_class = class(img);
    if ~isfloat(img), img = im2double(img); end

    % All processing in double [0,1]
    % ... processing ...

    % Convert back to original class
    switch original_class
        case 'uint8',  result = im2uint8(enhanced);
        case 'uint16', result = im2uint16(enhanced);
        otherwise,     result = enhanced;
    end
end
```

---
*Source: MathWorks IPT Reference (R2025a)*
