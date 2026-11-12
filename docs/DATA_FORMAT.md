# Data Format

## Raw result

The current result has 53 top-level fields.

Important arrays:

| Field | Shape | Description |
|---|---|---|
| `time_record` | `1 x T` | Saved times |
| `trajectory_record` | `2 x N x T` | Agent positions |
| `control_record` | `N x T` | Maximum absolute applied-control component |
| `nearest_record` | `N x T` | Distance to the nearest agent |
| `component_record` | `1 x T` | Largest connected-component size |
| `neighbor_max_record` | `1 x T` | Maximum direct-neighbor count |
| `link_record` | `1 x T` | Undirected communication-link count |
| `component_count_record` | `1 x T` | Number of connected components |
| `e_record` | `N x T` | Full error sequence when computed inline; empty for data-only runs |
| `e_record_time` | `1 x T` | Time axis for `e_record` |

`control_record` is not the full `u_safe` vector. Full 2-D control vectors are
not stored by default.

Metadata records the verification mode, sample interval, record stride, and
internal step size.

## Audit result

Audit files are written separately and are never merged into the source file.
The 23-field audit contains:

- `description`, `source_file`, `audit_file`, `completed_at`;
- `N`, `scenario`;
- `sample_interval`, `sample_count`, `max_sampling_interval_error`;
- `e_bound`, `e_max`, `e_max_time`, `e_max_agent`;
- maximum-error neighbourhood diagnostics;
- violation counts and first violation;
- `pass`, `elapsed_seconds`;
- `e_record`, `e_record_time`, `e_agent_max`.

`e_record` has dimensions `N x sample_count`.
