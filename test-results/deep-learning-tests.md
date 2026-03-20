# Deep Learning Toolbox Skill - Test Results

**Test Date:** 2026-02-04
**Skill:** matlab-deep-learning
**Platform:** Claude Desktop with skill toggle

---

## Test 1: U-Net Architecture Creation

**Question:**
```
How do I create a U-Net architecture for image segmentation in MATLAB?
```

### Without Skill

Claude uses the legacy API only:

```matlab
% Create U-Net
lgraph = unetLayers(inputSize, numClasses, ...
    'EncoderDepth', 4, ...
    'NumFirstEncoderFilters', 32);

% Training
opts = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 8);

net = trainNetwork(ds, lgraph, opts);
```

**Key points:**
- Uses `unetLayers` (legacy API)
- Uses `trainNetwork` (deprecated in R2024b+)
- Basic training setup
- No mention of modern alternatives

### With Skill

Claude is aware of both legacy and modern APIs:

```matlab
% Legacy API (pre-R2024b):
lgraph = unetLayers(imageSize, numClasses, ...
    'EncoderDepth', 4, ...
    'NumFirstEncoderFilters', 64, ...
    'FilterSize', 3, ...
    'ConvolutionPadding', 'same');

% Modern API (R2024b+):
% net = unet(imageSize, numClasses, 'EncoderDepth', 4);
```

Also provides:
- Complete manual U-Net construction code (100+ lines)
- Class imbalance handling with inverse-frequency weighting
- Proper augmentation function (nearest-neighbor for masks)
- Batch normalization best practices
- Input size constraints (must be divisible by 2^EncoderDepth)

### Comparison Summary

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Architecture function | `unetLayers` only | **Both `unetLayers` AND `unet` (R2024b+)** |
| Training function | `trainNetwork` | `trainNetwork` (not fully updated) |
| Detail level | Basic | **Comprehensive** |
| Manual construction | Not shown | **Full encoder-decoder code** |
| Class imbalance | Mentioned briefly | **Detailed weighting approach** |
| Augmentation | Basic mention | **Complete function with mask handling** |
| Modern API awareness | No | **Yes — notes R2024b+ `unet` function** |

### Verdict

**Moderate improvement.** The skill makes Claude aware of the modern `unet` API and provides significantly more comprehensive guidance. However, the training step still uses `trainNetwork` rather than the modern `trainnet`.

The detailed manual construction code and best practices (class weighting, mask augmentation with nearest-neighbor interpolation) add substantial value for practitioners.

---

## Overall Assessment

The Deep Learning skill shows **moderate improvement**:
- Awareness of R2024b+ API changes (unetLayers → unet)
- Significantly more detailed architectural guidance
- Better coverage of practical concerns (class imbalance, augmentation)

The skill would benefit from stronger emphasis on the `trainnet` workflow in future updates.
