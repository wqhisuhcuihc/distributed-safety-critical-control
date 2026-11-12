# TAC Multi-Agent Simulation

MATLAB code for simulation and verification of multi-agent trajectory
tracking with distributed safety-filter updates, control-barrier constraints,
and centralized exact-QP error auditing.

This repository contains the MATLAB source, tests, documentation, and the
processed results used for the paper. Raw `.mat` files, logs, historical
experiments, and local absolute paths are intentionally excluded.

## Processed results

The processed-result directory has two top-level folders:

```text
paper_results/
  videos/                 25 MP4 animations, one per formal scenario
  figures/                25 scenario folders
    N20_cross/            four PNG result figures
    N20_rings4/
    ...
```

Each figure folder contains:

- `curve1_minimum_distance.png`;
- `curve2_maximum_speed.png`;
- `curve3_iteration_error.png`;
- `curve4_maximum_component.png`.

The four figures use the original paper plotting conventions. The iteration
error and maximum-component figures do not draw red reference lines. The
minimum-distance and maximum-speed figures retain the `D0` and `v_bar`
red-dashed bounds.

## Requirements

- MATLAB R2021b or newer
- Optimization Toolbox is required for exact-QP error auditing (`quadprog`)
- No Simulink, ROS, compiler, or GPU is required for the MATLAB simulation

## Supported scenarios

Fleet sizes:

```text
N = 20, 32, 64, 96, 128
```

Scenarios:

| Name | Description |
|---|---|
| `cross` | Four-arm crossing |
| `rings4` | Four-centre circular tracking |
| `random` | Fixed-seed random starts and goals |
| `star` | Multi-arm mirrored-layer exchange |
| `ellipses` | Congruent rotating concentric ellipses |

The 25 formal combinations are selected by:

```matlab
result = run_TAC_experiment(N,scenario_name,options);
```

All scenarios use the same controller, safety-filter, parameter-gate, and
closed-loop implementations. Geometry and reference laws are isolated in
scenario adapters in `scenario/`.

## Quick start

Run `add_tac_paths` from the repository root, or add the repository to
MATLAB's path:

```matlab
add_tac_paths;
```

Generate one scenario and audit its saved states in the recommended 10 ms
mode:

```matlab
[result,audit] = run_TAC_workflow( ...
    64,"cross","10ms",fullfile(pwd,'results'));

fprintf('pass=%d e_max=%.12g\n',audit.pass,audit.e_max);
```

## Verification modes

The same code supports one unified option:

```matlab
opts = tac_default_options();
opts.verification_mode = "10ms"; % default and recommended
% opts.verification_mode = "1ms"; % strict, slow, and large
```

### `"10ms"`

```text
internal integration/control step: 0.001 s
saved and audited interval:         0.010 s
record stride:                      10
```

This is the recommended mode for normal simulation and paper comparisons.

### `"1ms"`

```text
internal integration/control step: 0.001 s
saved and audited interval:         0.001 s
record stride:                      1
```

This mode checks every internal simulation state. It is the correct choice
when the claim requires every 1 ms state to be audited.

**Warning:** 1 ms mode is substantially slower and produces much larger
files. Depending on the scenario, runtime and storage can increase by more
than ten times. Ten-millisecond results must not be described as strict 1 ms
verification.

## Separate data generation and auditing

Data generation does not modify or depend on previous audit files:

```matlab
opts = tac_default_options();
opts.verification_mode = "10ms";
opts.compute_reference = false;
opts.save_error_time_series = false;
result = run_TAC_experiment(96,"star",opts);
```

Audit the saved states separately:

```matlab
audit = audit_TAC_saved_states( ...
    char(result.output_file),'',"10ms");
```

The generic auditor reads the saved positions and recomputes both the safety
filter output and the no-warm-start exact-QP reference. It writes a new
`*_e10ms_audit_result.mat` or `*_e1ms_audit_result.mat` file.

## Run all 25 combinations

```matlab
summary = run_all_25("10ms",fullfile(pwd,'results'));
```

Strict mode is supported by the same interface but is intentionally not the
default:

```matlab
summary = run_all_25("1ms",fullfile(pwd,'results_strict_1ms'));
```

## Data format

Raw result files contain:

- parameter and condition metadata;
- initial positions and scenario reference data;
- `time_record`;
- `trajectory_record`;
- `control_record`;
- `nearest_record`;
- connectivity and component records;
- minimum distance, maximum local component, speed and residual statistics.

Audit files contain:

- `e_record`;
- `e_record_time`;
- maximum and per-agent error statistics;
- violation counts and first violation;
- maximum-error state diagnostics;
- pass/fail status.

See `docs/DATA_FORMAT.md` for field-level details.

## Rendering

Rendering is independent of simulation:

```matlab
video = render_saved_result( ...
    char(result.output_file), ...
    fullfile(pwd,'videos','example.mp4'));
```

The 25 final MP4 animations are included in `paper_results/videos`.

## Paper-style result figures

The optional figure exporter reads a raw result and its matching audit result:

```matlab
summary = generate_paper_figures( ...
    [20 32],["cross","rings4"], ...
    "path/to/final25_data","paper_results/figures");
```

It exports four figures per scenario: minimum inter-agent distance, maximum
control component, iteration error, and largest connected component. See
`docs/RESULT_FIGURES.md` for plotting conventions and the optional
per-agent mode.

## Tests

```matlab
run_all_tests
```

The public test suite checks:

- all 25 scenario constructions;
- parameter-gate validity;
- deterministic random generation;
- sparse/dense filter consistency;
- 10 ms and strict 1 ms recording modes;
- generic audit output structure.

## Additional documentation

- `docs/ARCHITECTURE.md`
- `docs/SCENARIOS_AND_PARAMETERS.md`
- `docs/VERIFICATION_MODES.md`
- `docs/DATA_FORMAT.md`
- `docs/REPRODUCIBILITY.md`
- `docs/RESULT_FIGURES.md`

## Known scope and limitations

- The default MATLAB simulation uses fixed-step explicit integration.
- The exact reference is defined by a centralized QP over active geometric
  neighbours; the implemented controller itself remains distributed.
- `control_record` stores the maximum control component, not the full 2-D
  control vector.
- Full `u_safe`, `u_aim`, and `u_ideal` histories are not stored by default.
- Ten-millisecond auditing is a sampled verification, not a continuous-time
  proof.
- No public license has been selected for this repository. Add an explicit
  license before public redistribution if desired.
