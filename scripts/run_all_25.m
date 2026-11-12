function summary = run_all_25(verification_mode,output_root,options)
%RUN_ALL_25 Run and audit the canonical 5-by-5 scenario matrix.

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(root),'-begin');
    if nargin < 1 || isempty(verification_mode)
        verification_mode = "10ms";
    end
    if nargin < 2 || isempty(output_root)
        output_root = fullfile(root,'results');
    end
    if nargin < 3 || isempty(options), options = struct(); end

    scales = [20 32 64 96 128];
    scenarios = tac_scenario_registry();
    summary = table();
    for N = scales
        for name = scenarios
            fprintf('\n=== N=%d, scenario=%s, mode=%s ===\n', ...
                N,name,verification_mode);
            [result,audit] = run_TAC_workflow( ...
                N,name,verification_mode,output_root,options);
            row = table(N,name,result.minimum_distance,result.safe, ...
                result.n_max,audit.e_max,audit.pass, ...
                'VariableNames',{'N','Scenario','MinimumDistance','Safe', ...
                'NMax','EMax','EPass'});
            summary = [summary; row]; %#ok<AGROW>
        end
    end
    writetable(summary,fullfile(output_root,'run_all_25_summary.csv'));
end
