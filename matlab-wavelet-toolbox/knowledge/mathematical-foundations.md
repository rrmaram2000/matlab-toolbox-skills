# Mathematical Foundations of Wavelet Analysis

## Multiresolution Analysis (MRA)

A multiresolution analysis of L²(ℝ) is a sequence of closed subspaces {Vⱼ}ⱼ∈ℤ satisfying:

1. **Nested**: ... ⊂ V₁ ⊂ V₀ ⊂ V₋₁ ⊂ ...
2. **Density**: ⋃ⱼVⱼ is dense in L²(ℝ)
3. **Separation**: ⋂ⱼVⱼ = {0}
4. **Scaling**: f(x) ∈ Vⱼ ⟺ f(2x) ∈ Vⱼ₋₁
5. **Shift-invariance**: f(x) ∈ V₀ ⟺ f(x-k) ∈ V₀ for all k ∈ ℤ
6. **Riesz basis**: ∃ φ ∈ V₀ such that {φ(x-k)}ₖ∈ℤ is a Riesz basis for V₀

The **scaling function** φ satisfies the two-scale relation (dilation equation):
```
φ(x) = √2 Σₖ hₖ φ(2x - k)
```
where {hₖ} are the lowpass filter coefficients.

The **wavelet function** ψ spans the orthogonal complement Wⱼ = Vⱼ ⊖ Vⱼ₊₁:
```
ψ(x) = √2 Σₖ gₖ φ(2x - k)
```
where gₖ = (-1)ᵏ h₁₋ₖ (QMF relation for orthogonal wavelets).

## Daubechies Wavelet Construction

Daubechies wavelets are constructed to maximize **vanishing moments** for a given filter length.

### Vanishing Moments
A wavelet ψ has N vanishing moments if:
```
∫ xⁿ ψ(x) dx = 0,  for n = 0, 1, ..., N-1
```

This is equivalent to the highpass filter G(z) having N zeros at z = 1:
```
G(z) = (1 + z⁻¹)ᴺ Q(z)
```

### Spectral Factorization (Daubechies Method)

For orthonormal wavelets with N vanishing moments:

1. Start with the polynomial:
```
P(y) = Σₖ₌₀ᴺ⁻¹ C(N-1+k, k) yᵏ
```
where C(n,k) is binomial coefficient.

2. Factor |H(ω)|² = P(sin²(ω/2)) using spectral factorization to get H(z).

3. The lowpass filter is:
```
H(z) = [(1 + z⁻¹)/2]ᴺ × R(z)
```
where R(z) comes from spectral factorization of P(y).

### db2 Example (N=2 vanishing moments, 4 coefficients)

> **Note:** Daubechies dbN wavelets have 2N coefficients. db2 has 4 coefficients; db4 has 8.

```matlab
% Daubechies db2 coefficients (normalized)
% db2 = 4 coefficients, db4 = 8 coefficients
h0 = (1 + sqrt(3)) / (4*sqrt(2));
h1 = (3 + sqrt(3)) / (4*sqrt(2));
h2 = (3 - sqrt(3)) / (4*sqrt(2));
h3 = (1 - sqrt(3)) / (4*sqrt(2));
Lo_D = [h0, h1, h2, h3];

% Verify: sum = sqrt(2), sum of squares = 1
fprintf('Sum: %.6f (should be sqrt(2) = %.6f)\n', sum(Lo_D), sqrt(2));
fprintf('Energy: %.6f (should be 1)\n', sum(Lo_D.^2));

% Verify vanishing moments via highpass
Hi_D = Lo_D .* [1, -1, 1, -1];  % QMF
fprintf('Sum of Hi: %.6f (should be 0 - 1st vanishing moment)\n', sum(Hi_D));
```

## Perfect Reconstruction Conditions

For a two-channel filter bank with analysis filters (H₀, H₁) and synthesis filters (G₀, G₁):

### Alias Cancellation
```
H₀(z)G₀(-z) + H₁(z)G₁(-z) = 0
```

### No Distortion
```
H₀(z)G₀(z) + H₁(z)G₁(z) = 2z⁻ᵈ
```
where d is the system delay.

### Orthogonal Case
For orthogonal wavelets: G₀(z) = H₀(z⁻¹), G₁(z) = H₁(z⁻¹)

This simplifies to:
```
|H₀(ω)|² + |H₀(ω + π)|² = 2
```

Verify in MATLAB:
```matlab
[Lo_D, Hi_D, Lo_R, Hi_R] = wfilters('db4');

% Check perfect reconstruction
N = 1024;
omega = linspace(0, 2*pi, N);
H0 = fft(Lo_D, N);
H0_shift = fft(Lo_D .* (-1).^(0:length(Lo_D)-1), N);

% Should equal 2 everywhere
PR_check = abs(H0).^2 + abs(H0_shift).^2;
fprintf('PR condition: max deviation = %.2e\n', max(abs(PR_check - 2)));
```

## Regularity and Smoothness

The **regularity** of a wavelet determines the smoothness of the scaling/wavelet functions.

### Sobolev Regularity
The Sobolev exponent s measures how many derivatives exist in L²:
```
φ ∈ Hˢ(ℝ) ⟺ ∫ |φ̂(ω)|² (1 + |ω|²)ˢ dω < ∞
```

For Daubechies dbN: regularity ≈ 0.2N (asymptotically)

### Hölder Regularity
The Hölder exponent α: f is Cᵅ if |f(x) - f(y)| ≤ C|x-y|ᵅ

Computed via cascade algorithm convergence rate.

```matlab
% Estimate regularity via cascade algorithm
wname = 'db8';
[phi, psi, xval] = wavefun(wname, 12);  % High iteration count

% Hölder exponent estimation (simplified)
diffs = abs(diff(psi));
dx = xval(2) - xval(1);
log_ratio = log(max(diffs)) / log(dx);
fprintf('Estimated Hölder exponent: %.2f\n', -log_ratio);
```

## Biorthogonal Wavelets

For biorthogonal systems, we have dual pairs (φ, φ̃) and (ψ, ψ̃) satisfying:
```
⟨φ(x-k), φ̃(x-l)⟩ = δₖₗ
⟨ψⱼ,ₖ, ψ̃ⱼ',ₗ⟩ = δⱼⱼ' δₖₗ
```

The analysis uses (φ̃, ψ̃), reconstruction uses (φ, ψ).

### Advantages for Image Processing
- **Symmetric filters**: Linear phase (no edge distortion)
- **Different analysis/synthesis**: Optimize each separately
- **JPEG2000**: Uses CDF 9/7 biorthogonal wavelet

```matlab
% CDF 9/7 (JPEG2000 wavelet)
[Lo_D, Hi_D, Lo_R, Hi_R] = wfilters('bior4.4');

% Note different lengths for analysis vs synthesis
fprintf('Decomposition lowpass length: %d\n', length(Lo_D));
fprintf('Reconstruction lowpass length: %d\n', length(Lo_R));
```

## Admissibility Condition

For a function ψ to be a valid wavelet, it must satisfy:
```
Cψ = ∫₀^∞ |ψ̂(ω)|²/ω dω < ∞
```

This requires:
1. ψ̂(0) = 0 (zero mean: ∫ψ(x)dx = 0)
2. Sufficient decay of ψ̂(ω) at high frequencies

For CWT reconstruction:
```
f(x) = (1/Cψ) ∫∫ Wf(a,b) ψₐ,ᵦ(x) da db / a²
```

## 2D Extension: Separable vs Non-Separable

### Separable 2D DWT
Apply 1D transforms to rows then columns:
```
cA = Lo_col * (Lo_row * X')'
cH = Lo_col * (Hi_row * X')'   [Horizontal edges]
cV = Hi_col * (Lo_row * X')'   [Vertical edges]
cD = Hi_col * (Hi_row * X')'   [Diagonal edges]
```

Limitations: Only 3 orientations (0°, 90°, 45°)

### Non-Separable: Dual-Tree Complex Wavelets
Two parallel trees with filters forming Hilbert pairs:
```
ψ_complex(x,y) = ψ_h(x)ψ_h(y) + j·ψ_g(x)ψ_g(y)
```

Provides 6 orientations: ±15°, ±45°, ±75°

### Shearlets (Anisotropic Scaling)
Shearlet transform uses anisotropic dilation and shearing:
```
ψₐ,ₛ,ₜ(x) = a^(-3/4) ψ(Sₛ Aₐ (x - t))
```
where Aₐ is parabolic scaling, Sₛ is shearing matrix.

Optimal for curvilinear singularities: ||f - fₙ||² = O(n⁻²(log n)³)
(vs O(n⁻¹) for wavelets on curves)

## Uncertainty Principle and Time-Frequency Localization

The Heisenberg uncertainty principle for wavelets:
```
Δt · Δω ≥ 1/2
```

Wavelet atoms have:
- **Time localization**: Δt ∝ a (scale)
- **Frequency localization**: Δω ∝ 1/a

This gives constant **Q-factor**: Q = ω₀/Δω = constant

Compare to STFT: constant Δt and Δω (poor multi-scale resolution).

```matlab
% Visualize time-frequency tiling
wname = 'morl';  % Morlet for illustration
scales = 2.^(1:0.5:7);
fb = cwtfilterbank('SignalLength', 1024, 'Wavelet', wname, ...
    'SamplingFrequency', 1000, 'FrequencyLimits', [1 500]);
freqz(fb);  % Shows frequency response at each scale
```
