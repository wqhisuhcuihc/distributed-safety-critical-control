function opts = tac_default_options()
%TAC_DEFAULT_OPTIONS Default options for the unified formal runner.

    root = fileparts(mfilename('fullpath'));
    opts = struct();
    opts.run_mode = "formal";
    opts.Time = [];
    opts.show_plots = false;
    opts.compute_reference = false;
    opts.save_error_time_series = true;
    opts.save_raw = true;
    opts.render_video = false;
    opts.output_root = fullfile(root, 'results');
    opts.video_root = fullfile(root, 'videos');
    opts.tag = "";
    opts.seed = [];
    opts.filter_type = "sparse";
    opts.M_override = [];
    opts.verification_mode = "10ms";
    opts.sample_interval = 0.010;
    opts.record_stride = 10;
    opts.convergence_tolerance = 0.05;
    opts.convergence_hold_steps = 300;
    opts.anim_opts = {};
end
