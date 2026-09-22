# Model Card — RonaAir pH Strip Estimator

**Version:** ronair-ph-1.0.0
**Generated:** 2026-09-21T02:59:45+00:00
**Random seed:** 42

## Model purpose
Estimate the pH of a water sample from a smartphone photograph of a pH test strip, as the
colorimetric analysis component of the RonaAir water-quality system.

## Input
A smartphone photograph containing a pH indicator pad. The pad region is located either from a
supplied ROI annotation or by saturation-based segmentation. Colour statistics of that region
(RGB, normalised RGB, HSV, CIELAB — means and standard deviations) form the 24-dimensional
feature vector; see `feature_schema.json` for the exact order.

## Output
A single continuous pH estimate, plus an image-quality status (`GOOD` / `WARN` / `REJECT`) and any
range warnings. **No probabilistic confidence is reported**, because this is a point-estimate
regressor with no calibrated uncertainty.

## Model
- Architecture: **PolynomialRidge2** on feature set `COMBINED_ALL`
- Selection metric: group-aware 5-fold cross-validated MAE on the training split
- Selection CV MAE: 0.3598 pH
- Candidates evaluated: 37 (feature set x model) combinations

## Training data
- Datasets used: A_pH_test_dataset
- Subsets: benchmark_test, benchmark_train, blue, iphone6p_test, iphone6p_train, red, samsung_j5_test, samsung_j5_train, samsung_s7_test, samsung_s7_train, training
- Images: 329 across 92 derived sample groups
- Split: train 214 / validation 74 / test 41, group-disjoint
- Ground truth: continuous pH values supplied with the source datasets' annotations. No labels
  were created by the training pipeline.
- Held out as an out-of-domain probe: milk, wine_testing, wine_training

## Validated pH range
- Training: 5.016 – 8.552
- Validation: 5.005 – 8.565
- Test: 5.000 – 8.506

The model is **only** validated inside this range. It is not validated over pH 0–14, and it warns
when an estimate falls outside the range rather than reporting it silently.

## Metrics (held-out test set, n = 41, evaluated once)
| metric | value |
|---|---|
| MAE | 0.2905 pH |
| RMSE | 0.3621 pH |
| R² | 0.8809 |
| within ±0.25 pH | 48.8% |
| within ±0.50 pH | 85.4% |
| within ±1.00 pH | 100.0% |

Tolerance figures are the share of regression predictions landing inside a pH band. They are not
classification accuracy.

## Out-of-domain behaviour
Coloured-matrix samples (wine, milk): MAE 2.0218 pH versus 0.2905 pH in domain. The degradation is real and expected: a coloured sample tints the indicator pad itself.

## Limitations
- **Lighting.** The source images were captured inside a controlled light box. Free-hand photos
  under ambient light are a different distribution and are not represented here.
- **Camera variation.** Only the devices encoded in the folder names are represented. No lighting
  metadata exists in these datasets at all.
- **Strip brand.** One strip type. A different manufacturer's colour chart needs re-training.
- **Domain shift.** Demonstrated above on coloured sample matrices.
- **Sample grouping is inferred.** No explicit sample ID exists; groups were derived from the
  ground-truth pH value. This is conservative but approximate.
- **Small corpus.** A few hundred images and roughly a hundred distinct samples. Metrics carry
  real sampling uncertainty.
- **Colour reference not universal.** Only part of the corpus carries an in-image reference patch.
  A reference card reduces illumination and camera variation; it does not remove domain shift.
- **Unsupported pH range.** Outside the range above, predictions are extrapolation.

## Intended use
An indicative water-quality estimation aid inside the RonaAir application, alongside — not in place
of — a calibrated instrument where accuracy matters.

## Not intended for
Medical diagnosis, clinical decisions, regulatory compliance testing, or any safety-critical
determination of water potability. This model makes no medical claim of any kind.

## Deployment
- Android path: native Kotlin from `model_coefficients.json`
- Artifacts: `feature_schema.json`, `preprocessing_config.json`, `model_metadata.json`,
  `PhPredictor.kt`, `test_inference.py`
- The training and inference preprocessing paths are the same code, and the exported model was
  re-verified against its source implementation after export.
