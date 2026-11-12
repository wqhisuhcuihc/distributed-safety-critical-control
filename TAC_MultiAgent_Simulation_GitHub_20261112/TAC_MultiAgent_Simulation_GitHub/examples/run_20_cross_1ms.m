% Example: strict 1 ms generation and audit for one scenario.
% This deliberately follows the expensive, high-storage verification mode.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root),'-begin');

[result,audit] = run_TAC_workflow( ...
    20,"cross","1ms",fullfile(root,'results_strict_1ms'));
fprintf('pass=%d e_max=%.12g samples=%d\n', ...
    audit.pass,audit.e_max,audit.sample_count);
