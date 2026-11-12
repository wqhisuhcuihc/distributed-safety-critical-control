function summary = run_all_TAC_experiments(options)
%RUN_ALL_TAC_EXPERIMENTS Run the canonical 5-by-5 experiment matrix.
%
% By default this performs long formal data-generation runs and does not
% render videos.  Rendering should be launched separately after the raw data
% have been checked.

    if nargin < 1 || isempty(options), options = struct(); end
    root = fileparts(mfilename('fullpath'));
    addpath(genpath(root),'-begin');
    opts = tac_default_options();
    scales = [20 32 64 96 128];
    scenarios = tac_scenario_registry();
    if isfield(options,'scales') && ~isempty(options.scales)
        scales = options.scales;
    end
    if isfield(options,'scenarios') && ~isempty(options.scenarios)
        scenarios = string(options.scenarios);
    end
    names = setdiff(fieldnames(options),{'scales','scenarios'});
    for i = 1:numel(names), opts.(names{i}) = options.(names{i}); end
    opts.save_raw = true;
    opts.render_video = false;

    summary = struct('N',{},'scenario',{},'minimum_distance',{}, ...
        'safe',{},'n_max',{},'final_residual',{},'output_file',{});
    row = 0;
    for N = scales
        for name = scenarios
            row = row+1;
            local = opts;
            local.tag = sprintf('TAC_N%d_%s',N,name);
            fprintf('\n=== N=%d, scenario=%s ===\n',N,name);
            r = run_TAC_experiment(N,name,local);
            summary(row).N = N;
            summary(row).scenario = name;
            summary(row).minimum_distance = r.minimum_distance;
            summary(row).safe = r.safe;
            summary(row).n_max = r.n_max;
            summary(row).final_residual = r.final_residual;
            summary(row).output_file = r.output_file;
        end
    end
    report_file = fullfile(opts.output_root,'run_all_summary.mat');
    save(report_file,'summary');
    fprintf('\nsummary: %s\n',report_file);
end
