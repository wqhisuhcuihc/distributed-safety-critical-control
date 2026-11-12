function result = tac_make_result(cfg,scenario,opts,audit,records,performance)
%TAC_MAKE_RESULT Build the single common serializable result structure.

    publicScenario = scenario;
    if isfield(publicScenario,'path') && isstruct(publicScenario.path)
        p = publicScenario.path;
        publicScenario.path = struct('length',p.length,'phase0',p.phase0, ...
            'speed',p.speed,'gain',p.gain,'loops',p.loops, ...
            'samples',p.samples,'tracks',p.tracks);
    end

    result = struct();
    result.metadata = struct('version',cfg.version, ...
        'created_at',datestr(now,31), ...
        'run_mode',string(opts.run_mode), ...
        'paper_valid',audit.paper_valid, ...
        'filter_type',string(performance.filter_type), ...
        'compute_reference',logical(opts.compute_reference), ...
        'verification_mode',string(opts.verification_mode), ...
        'sample_interval',opts.sample_interval, ...
        'record_stride',opts.record_stride, ...
        'internal_dt',cfg.dt);
    result.tag = sprintf('TAC_N%d_%s',cfg.N,scenario.name);
    result.N = cfg.N;
    result.n = cfg.n;
    result.D0 = cfg.D0;
    result.D = cfg.D;
    result.R = cfg.R;
    result.v_bar = cfg.v_bar;
    result.v_check = cfg.v_check;
    result.alpha = cfg.alpha;
    result.dt = cfg.dt;
    result.M = cfg.M;
    result.e_design = cfg.e_design;
    result.scenario_name = scenario.name;
    result.description = scenario.description;
    result.parameter = cfg;
    result.scenario = publicScenario;
    result.audit = audit;
    result.condition_margin = audit.condition_margin;
    result.initial_minimum = audit.initial_minimum;
    result.initial_position = scenario.initial_position;
    result.target = scenario.target;
    result.required_initial = audit.required_initial;
    result.minimum_distance = performance.minimum_distance;
    result.safe = performance.minimum_distance >= cfg.D0;
    result.n_max = performance.n_max;
    result.n_max_time = performance.n_max_time;
    result.neighbor_peak = performance.neighbor_peak;
    result.links_min = performance.links_min;
    result.links_max = performance.links_max;
    result.component_count_min = performance.component_count_min;
    result.component_count_max = performance.component_count_max;
    result.peak_fraction = performance.peak_fraction;
    result.elapsed = performance.elapsed;
    result.Time = performance.Time;
    result.arrival_time = performance.arrival_time;
    result.converged = performance.converged;
    result.final_residual = performance.final_residual;
    result.residual_max = performance.residual_max;
    result.e_returned = performance.e_returned;
    result.tracking = scenario.mode == "tracking";
    result.path_following = scenario.mode == "path";
    result.time_record = records.time;
    result.trajectory_record = records.trajectory;
    result.nearest_record = records.nearest;
    result.control_record = records.control;
    result.component_record = records.component;
    result.neighbor_max_record = records.neighbor_max;
    result.link_record = records.links;
    result.component_count_record = records.component_count;
    result.e_record = records.error;
    result.e_record_time = records.time;
end
