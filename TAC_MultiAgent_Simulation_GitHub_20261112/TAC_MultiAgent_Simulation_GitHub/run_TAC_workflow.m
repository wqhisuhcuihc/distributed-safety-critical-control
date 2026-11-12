function [result,audit] = run_TAC_workflow( ...
    N,scenario_name,verification_mode,output_root,options)
%RUN_TAC_WORKFLOW Generate raw data and run the matching saved-state audit.
%
% [result,audit] = run_TAC_workflow(64,"cross","10ms")
% [result,audit] = run_TAC_workflow(64,"cross","1ms")

    root = fileparts(mfilename('fullpath'));
    addpath(genpath(root),'-begin');
    if nargin < 3 || isempty(verification_mode)
        verification_mode = "10ms";
    end
    if nargin < 4 || isempty(output_root)
        output_root = fullfile(root,'results');
    end
    if nargin < 5 || isempty(options), options = struct(); end
    if exist(output_root,'dir') ~= 7, mkdir(output_root); end

    opts = tac_default_options();
    names = fieldnames(options);
    for i = 1:numel(names)
        opts.(names{i}) = options.(names{i});
    end
    opts.verification_mode = verification_mode;
    opts.compute_reference = false;
    opts.save_error_time_series = false;
    opts.save_raw = true;
    opts.render_video = false;
    opts.output_root = output_root;
    mode_token = char(regexprep(lower(string(verification_mode)), ...
        '[^a-zA-Z0-9]+',''));
    opts.tag = sprintf('TAC_N%d_%s_%s',N,scenario_name,mode_token);

    result = run_TAC_experiment(N,scenario_name,opts);
    audit = audit_TAC_saved_states( ...
        char(result.output_file),'',verification_mode);
end
