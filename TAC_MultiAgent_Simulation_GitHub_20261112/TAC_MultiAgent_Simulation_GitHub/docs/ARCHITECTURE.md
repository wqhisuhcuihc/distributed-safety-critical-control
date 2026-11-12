# Architecture

The implementation separates the common algorithm from scenario-specific
geometry.

```text
run_TAC_experiment
  -> tac_parameter_set
  -> tac_build_scenario
  -> tac_run_closed_loop
       -> tac_nominal_control
       -> tac_filter_adapter
       -> tac_pair_stats
  -> tac_make_result
  -> tac_save_result
```

The scenario adapters construct only:

- initial positions;
- targets or time-parameterized references;
- path/track geometry;
- scenario-specific scale and phase.

The safety filter, parameter gate, integration core, result schema, and error
auditor are shared by all 25 combinations.

The no-active-edge filter shortcut is mathematically equivalent to running
obsolete iterations when no geometric constraint is active and no static
obstacle is present. When at least one edge is active, the original
fixed-iteration distributed update is used.
