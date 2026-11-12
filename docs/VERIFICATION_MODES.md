# Verification Modes

The simulation always uses `dt=0.001 s`. Verification mode controls how often
states are persisted and audited.

## 10 ms mode

```matlab
opts.verification_mode = "10ms";
```

```text
record_stride = 10
sample_interval = 0.010 s
```

The exact QP is solved at every saved state. This is the default because it
keeps runtime and output size manageable.

## Strict 1 ms mode

```matlab
opts.verification_mode = "1ms";
```

```text
record_stride = 1
sample_interval = 0.001 s
```

Every internal state is saved and audited. This is required for strict
discrete-time verification of all simulated states.

## Important distinction

Ten-millisecond auditing does not inspect states between saved samples. It
can miss short error peaks. If every 1 ms control step must be included,
rerun the scenario in `"1ms"` mode and save all states.

## Audit method

For each saved state:

1. Reconstruct the nominal control from the saved state and time.
2. Apply the same sparse distributed safety filter.
3. Solve the centralized no-warm-start exact QP using `active-set`.
4. Compute each agent's two-dimensional velocity error norm.
5. Save the complete `N x T` error time series.
