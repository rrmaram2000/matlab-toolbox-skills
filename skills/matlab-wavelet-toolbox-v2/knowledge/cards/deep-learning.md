# Wavelet + Deep Learning - Integration Patterns

## When to Combine Wavelets with Deep Learning

| Pattern | When to Use | Approach |
|---------|-------------|----------|
| Wavelet preprocessing | Multi-scale features for CNN input | Stack wavelet subbands as channels |
| Learnable subband weighting | Adaptive denoising/enhancement | `dldwt` + learnable scale per subband |
| Signal-to-image conversion | 1D signal classification | `cwtLayer` converts signal to scalogram |
| Data augmentation | Training data enhancement | Wavelet denoising on training images |
| Feature fusion | Combine structural + learned features | Concatenate wavelet energy features with CNN features |

## Key Integration Approaches

### Wavelet Preprocessing for CNNs
Decompose image into subbands, resize each to original size, stack as channels. For `levels` levels, this creates `3*levels + 1` channels (3 detail orientations per level + 1 approximation). Gives the CNN explicit multi-scale information.

### Differentiable Wavelet Processing (R2025a+)
Use `dldwt`/`dlidwt` inside a training loop. Gradients flow through automatically. Common pattern: learn per-subband weights that multiply detail coefficients before inverse transform.

### CWT Layer for Signals (R2022b+)
`cwtLayer` converts 1D signals to 2D scalograms as a network layer. Use analytic Morlet (`'amor'`) for most signal classification tasks. Feed scalogram into standard 2D CNN layers.

## Best Practices

- **GPU**: `wavedec2` and `dldwt` work transparently with `gpuArray` inputs. Keep data on GPU for the entire pipeline.
- **Batch processing**: Process full batches, not individual images. For custom layers, loop over batch and channel dimensions.
- **Filter constraints**: When learning wavelet filters, enforce `sum(lo) = sqrt(2)` for orthonormality and construct highpass via QMF relation.
