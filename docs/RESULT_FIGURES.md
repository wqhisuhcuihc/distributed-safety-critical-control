# Paper-Style Result Figures

The optional result-figure exporter reads one raw data result and its matching
audit result. It does not modify either source file.

Four 1024-by-768 PNG figures are exported for each scenario:

| File | Quantity |
|---|---|
| `curve1_minimum_distance` | Minimum inter-agent distance over time |
| `curve2_maximum_speed` | Maximum absolute control component over time |
| `curve3_iteration_error` | Exact-QP iteration error over time |
| `curve4_maximum_component` | Largest connected communication component over time |

The default `"aggregate"` mode uses the safety-relevant global extremum at
every sample. This remains readable at every supported fleet size from 20 to
128 agents. The optional `"per_agent"` mode reproduces the original
small-team presentation with one curve per agent.

The visual style follows the paper figures: white background, no grid, no
title, 1024-by-768 pixels, 18-point tick labels, full box, inward ticks, and
parula colors. Only the minimum-distance and maximum-speed figures include
red dashed reference bounds (`D0` and `v_bar`). The iteration-error and
maximum-component figures do not include reference lines.

The plot margins and Y-axis formatting follow the original paper plotting
code.

```matlab
summary = generate_paper_figures( ...
    [20 32],["cross","rings4"], ...
    "path/to/final25_data","paper_results/figures");
```

Use per-agent curves for a small team:

```matlab
opts = struct('curve_mode',"per_agent","show_legend",true);
generate_paper_figures(20,"cross",data_root,output_root,opts);
```

## Reproducing the 25 result folders

The released figures are stored as:

```text
paper_results/figures/N20_cross/
paper_results/figures/N20_rings4/
...
paper_results/figures/N128_ellipses/
```

Run the complete set with:

```matlab
summary = generate_paper_figures( ...
    [20 32 64 96 128], ...
    ["cross","rings4","random","star","ellipses"], ...
    "path/to/final25_data", ...
    "paper_results/figures");
```
