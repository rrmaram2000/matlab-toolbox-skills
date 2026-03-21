# Custom Wavelet Design via Lifting Scheme

## When to Design a Custom Wavelet

Before customizing, check if a standard wavelet suffices:
- **db4-db8**: General medical imaging, good edge preservation
- **sym4-sym8**: Near-linear phase, smooth structures
- **bior4.4**: Symmetric filters, compression (JPEG2000)

**Customize when**: Standard wavelets underperform for your specific signal/image characteristics, or you need data-driven adaptation.

## Lifting Scheme Theory (Sweldens, 1996)

The lifting scheme factors any wavelet into predict/update steps operating on polyphase components:

**Predict (P)**: `d[n] = x_odd[n] - P(x_even)[n]` -- detail coefficients measure prediction error.
**Update (U)**: `s[n] = x_even[n] + U(d)[n]` -- approximation coefficients preserve signal properties.

Key property: Each additional lifting step increases vanishing moments or regularity. The **Lifting Factorization Theorem** guarantees any wavelet filter bank can be decomposed this way.

## Design Guidance

- **More vanishing moments** = better polynomial suppression, but longer filters (more boundary effects)
- **Higher regularity** = smoother wavelet/scaling functions (regularity ~ 0.2N for dbN)
- **CDF 9/7** (JPEG2000): 4 lifting steps, coefficients [-1.586, -0.053, 0.883, 0.444] -- use `liftingScheme` + `addlift` to construct

## Learning Wavelets from Data

### Optimization Framework

Optimize lifting coefficients to minimize: `min_{P,U} L(x, x_hat) + lambda * R(P,U)`
- L: reconstruction loss, sparsity loss, or task-specific loss
- R: regularization (smoothness, vanishing moments)

### Constraints for Valid Learned Wavelets

Three constraints must be enforced when learning filters:

1. **Perfect Reconstruction**: For biorthogonal filters, `H_tilde(z)H(z) + H_tilde(-z)H(-z) = 2`. Enforce via parameterization or projection after each gradient step.
2. **Vanishing Moments**: Parameterize lowpass as `(1+z^-1)^N * Q(z)` and only optimize Q(z), ensuring N zeros at z=-1 automatically.
3. **Regularity**: Estimate via cascade algorithm convergence rate. Higher regularity = smoother wavelet.

### Approaches in MATLAB

- **Differentiable lifting**: Wrap predict/update coefficients in `dlarray`, split signal into even/odd polyphase, apply predict and update via convolution, compute loss + `dlgradient`.
- **Built-in dldwt** (R2025a+): Use `dldwt`/`dlidwt` with learnable coefficient weighting for simpler integration (fixed wavelet, learned subband processing).
- **Custom layer**: Implement `nnet.layer.Layer` with `PredictCoeffs` and `UpdateCoeffs` as learnable properties.

## Verification Checklist for Custom Wavelets

After designing any custom wavelet via lifting, verify:
1. Perfect reconstruction error < 1e-10 (round-trip lwt/ilwt test)
2. Highpass filter sums to 0 (vanishing moment check)
3. Filter energy = 1 (energy preservation)
4. Orthogonality: `Lo_D * Hi_D' ~ 0` (for orthogonal wavelets)

Use `ls2filt(ls)` to extract filter coefficients from a liftingScheme object for verification.
