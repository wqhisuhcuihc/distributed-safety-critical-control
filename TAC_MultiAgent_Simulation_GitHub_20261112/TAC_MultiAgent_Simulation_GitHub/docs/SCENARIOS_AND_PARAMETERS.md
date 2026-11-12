# Scenarios and Parameters

## Parameter sets

| N | D0 | D | R | v_bar | v_check | alpha | M | e_design |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 3 | 3.5 | 3.6 | 1.0 | 0.9 | 0.069 | 400 | 0.01 |
| 32 | 9 | 10.5 | 10.8 | 1.5 | 1.35 | 0.021005 | 500 | 0.01 |
| 64 | 8 | 9.3336 | 9.6 | 1.5 | 1.35 | 0.025 | 1000 | 0.01 |
| 96 | 16 | 16.39 | 16.55 | 1.5 | 1.35 | 0.068 | 1500 | 0.01 |
| 128 | 17.5 | 19.65 | 19.85 | 1.8 | 1.65 | 0.012 | 2000 | 0.01 |

## Scenario definitions

- `cross`: four approaches with interleaved lane spacing.
- `rings4`: four circle centres with multiple concentric rings.
- `random`: fixed seed `20261049`, uniform starts and goals.
- `star`: eight arms with mirrored layer targets.
- `ellipses`: eight congruent rotating ellipses through one centre.

## Geometry highlights

- N=20 and N=32 four-circle scenes use optimized nonuniform phases to produce
  encounters at more circle intersections.
- N=128 uses four circle layers with half-circle motion.
- N=64 and N=96 ellipses use an `18:5` major-to-minor axis ratio.
- N=128 ellipses use the same `18:5` shape, with optimized scale and phase,
  and run through half of the closed path.
