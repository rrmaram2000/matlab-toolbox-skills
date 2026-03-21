# Wavelet Filter Selection Guide

## Choosing Wavelets for Medical Imaging

| Clinical Task | Wavelet | Why |
|---------------|---------|-----|
| MRI denoising (smooth structures) | sym4-sym8 | Near-linear phase, good frequency localization |
| CT denoising (edge preservation) | db4-db8 | Good edge preservation, moderate support |
| Bone/calcification (sharp edges) | db2-db3 | Short filters, minimal ringing |
| Compression / JPEG2000 | bior4.4 | Symmetric filters (linear phase) |
| Smooth gradients (soft tissue) | sym6-sym8, coif3 | Higher vanishing moments |
| Speed-critical processing | db2, haar | Shortest filters |

## Key Filter Properties to Know

- **dbN wavelets**: 2N filter coefficients, N vanishing moments, NOT symmetric. Regularity ~ 0.2N.
- **symN wavelets**: Same length/moments as dbN, but near-symmetric (reduced phase distortion).
- **biorN.M wavelets**: Truly symmetric (linear phase), different analysis/synthesis filter lengths.
- **Daubechies are NOT symmetric**: If you need linear phase, use symlets or biorthogonal wavelets.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Mixing filter pairs across wavelets | Use same wavelet name for decomp and recon |
| Assuming Daubechies have linear phase | Switch to sym or bior families |
| Over-long filters for small images | Check `wmaxlev` -- longer filters reduce max decomposition level |
