# Reproducibility

- Random starts and goals use the fixed seed `20261049`.
- All scenarios at a given fleet size share the same safety parameters.
- Parameter conditions are checked before formal execution.
- The exact audit uses MATLAB `quadprog` with `active-set` and no warm start.
- The filter and controller use no unseeded randomness.
- Raw data generation and error auditing are separate steps.
- Raw data files are never modified by the auditor.
- The default save/audit interval is 10 ms.
- The internal simulation step is 1 ms.

For code-level reproduction, keep the MATLAB version, parameter file, scenario
adapter, and verification mode fixed.
