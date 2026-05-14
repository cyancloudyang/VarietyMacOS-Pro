
## Task 8: AmbilightColorExtractor Rewrite

### Problem
`CIAreaAverage` CIFilter computes mean color of a region → all edges produce nearly identical muddy gray/brown. This is mathematically expected: averaging diverse pixels always converges to gray.

### Solution: Top-K Dominant Color Extraction
1. **Downsample to 64×64** using `CILanczosScaleTransform` (GPU-accelerated, high quality) — ensures <100ms
2. **Extract raw pixels** from NSBitmapImageRep, skip near-black (<0.05 luminance) and near-white (>0.95)
3. **For edge colors**: Quantize hues into 36 bins (10° each), skip achromatic pixels (saturation < 0.15), pick the bin with >5% of pixels that has the highest average saturation, boost by 1.15x for vividness
4. **For dominant color**: Quantize into 18 broader bins (20°), include achromatic pixels, pick the most populous bin
5. **Fallback chain**: saturated-frequent → most-common-hue → simple average

### Key Design Decisions
- 36 hue bins for edges (fine-grained to distinguish similar colors) vs 18 bins for dominant (broader grouping for overall mood)
- Saturation threshold 0.15 filters achromatic pixels for edge extraction (we want vivid colors)
- 5% minimum frequency prevents outlier/noise colors from dominating
- 1.15x RGB boost on saturated edge colors makes Ambilight effect more vivid
- `Swift.max`/`Swift.min` needed to avoid ambiguity with `Float.max`/`Float.min`

### Performance
- 64×64 = 4096 pixels max → O(n) scan + O(k) bin sort where k ≤ 36
- CILanczosScaleTransform uses GPU via CIContext
- Should comfortably meet <100ms target
