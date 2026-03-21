# Macenko Stain Normalization — With Skill

## Prompt
"Implement Macenko stain normalization for H&E histology. Convert to OD space, mask background, estimate stain vectors via SVD with angle-based extraction, normalize concentrations, reconstruct."

## Skill Consultation
The agent consulted:
- `matlab-image-processing-toolbox-v2/SKILL.md` — Critical Rules (im2double vs double)
- `matlab-image-processing-toolbox-v2/scripts/template_histology_stain_normalization.m` — Reference template

## Key Decisions (Guided by Skill)
1. **OD-space conversion**: `-log10(I/255 + eps)` — physically correct Beer-Lambert law
2. **Background masking**: OD threshold to exclude white background from PCA
3. **PCA + angle extraction**: Project onto first two PCs, use percentile angles for robustness
4. **Separate stain channels**: Full color deconvolution into Hematoxylin and Eosin
5. **Percentile-based normalization**: Match concentration distributions, not just mean/std
6. **Proper reconstruction**: Use reference stain matrix with normalized source concentrations

## Domain Depth
- Explains why background masking matters (skews PCA without it)
- Shows individual stain channel images (H and E separately)
- Computes color distance improvement metric
- 8-panel visualization with distributions

## Output
- 200-line Macenko implementation with full deconvolution
- Stain separation visualization (Hematoxylin-only and Eosin-only images)
- Quantitative color distance improvement metric
