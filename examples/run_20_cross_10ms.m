% Example: generate and audit one N=20 cross-junction scenario.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root),'-begin');

[result,audit] = run_TAC_workflow( ...
    20,"cross","10ms",fullfile(root,'results'));
fprintf('pass=%d e_max=%.12g\n',audit.pass,audit.e_max);
