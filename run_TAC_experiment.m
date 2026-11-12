function result = run_TAC_experiment(N, scenario_name, options)
%RUN_TAC_EXPERIMENT Public entry point for all unified TAC experiments.
%
% result = run_TAC_experiment(N, scenarioName)
% result = run_TAC_experiment(N, scenarioName, options)
%
% options fields are documented by tac_default_options.  Formal runs always
% execute the same parameter gate.  Rendering is disabled by default; use
% tac_render_result after the raw result has been saved.

    if nargin < 3 || isempty(options), options = struct(); end
    root = fileparts(mfilename('fullpath'));
    addpath(fullfile(root,'config'),'-begin');
    addpath(fullfile(root,'scenario'),'-begin');
    addpath(fullfile(root,'core'),'-begin');
    addpath(fullfile(root,'filters'),'-begin');
    addpath(fullfile(root,'io'),'-begin');

    opts = merge_options(tac_default_options(),options);
    [opts, verification] = tac_apply_verification_mode(opts);
    if verification.mode == "1ms"
        warning('TAC:strict1ms', ...
            ['Strict 1 ms persistence is enabled. Runtime and output ' ...
             'size may increase by ten times or more.']);
    end
    cfg = tac_parameter_set(N);
    scenario = tac_build_scenario(N,scenario_name,cfg,opts);
    result = tac_run_closed_loop(cfg,scenario,opts);

    if opts.save_raw
        if strlength(string(opts.tag)) > 0
            tag = char(opts.tag);
        else
            tag = result.tag;
        end
        expected_file = fullfile(opts.output_root,[tag '_result.mat']);
        result.output_file = string(expected_file);
        result.output_file = string(tac_save_result(result,opts.output_root,tag));
    else
        result.output_file = "";
    end

    if opts.render_video
        if strlength(string(result.output_file)) == 0
            error('run_TAC_experiment:renderWithoutSavedResult', ...
                'render_video requires save_raw=true.');
        end
        video_file = fullfile(opts.video_root,[tag '_trajectory.mp4']);
        result.video_file = tac_render_result(result,video_file,opts.anim_opts);
        tac_save_result(result,opts.output_root,tag);
    else
        result.video_file = "";
    end
end

function out = merge_options(defaults,provided)
    out = defaults;
    names = fieldnames(provided);
    for i = 1:numel(names)
        out.(names{i}) = provided.(names{i});
    end
end
