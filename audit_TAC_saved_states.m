function audit = audit_TAC_saved_states(source_file,output_file,verification_mode)
%AUDIT_TAC_SAVED_STATES Exact-QP audit at 10 ms or strict 1 ms.

    root = fileparts(mfilename('fullpath'));
    addpath(genpath(root),'-begin');
    if nargin < 1 || isempty(source_file)
        error('audit_TAC_saved_states:source', ...
            'A source result file is required.');
    end

    r = tac_load_result(source_file);
    if nargin < 3 || isempty(verification_mode)
        if isfield(r,'metadata') && ...
                isfield(r.metadata,'verification_mode')
            verification_mode = r.metadata.verification_mode;
        else
            verification_mode = "10ms";
        end
    end
    opts = tac_default_options();
    opts.verification_mode = verification_mode;
    [~,verification] = tac_apply_verification_mode(opts);
    expected_interval = verification.sample_interval;

    if nargin < 2 || isempty(output_file)
        [folder,name] = fileparts(char(source_file));
        if verification.mode == "1ms"
            suffix = '_e1ms_audit_result.mat';
        else
            suffix = '_e10ms_audit_result.mat';
        end
        output_file = fullfile(folder,[name suffix]);
    end

    cfg = r.parameter;
    scenario = r.scenario;
    if string(scenario.mode) == "path" && ...
            (~isfield(scenario,'path') || ...
             ~isfield(scenario.path,'points'))
        rebuilt = tac_build_scenario(r.N,string(r.scenario_name),cfg,struct());
        assert(max(vecnorm(rebuilt.initial_position- ...
            r.initial_position,2,1)) < 1e-8, ...
            'Rebuilt path scenario does not match the saved data.');
        scenario = rebuilt;
    end

    time_record = double(r.time_record(:).');
    trajectory_record = double(r.trajectory_record);
    sample_count = numel(time_record);
    assert(sample_count == size(trajectory_record,3), ...
        'Time and trajectory record lengths differ.');
    if sample_count >= 2
        max_interval_error = max(abs(diff(time_record)-expected_interval));
        assert(max_interval_error < 1e-9, ...
            'Saved states do not match the requested %s interval.', ...
            verification.mode);
    else
        max_interval_error = 0;
    end

    qopt = optimoptions('quadprog','Display','off', ...
        'Algorithm','active-set');
    e_record = zeros(cfg.N,sample_count);
    e_agent_max = zeros(1,cfg.N);
    e_max = -inf;
    e_max_time = NaN;
    e_max_agent = NaN;
    degree_at_max = NaN;
    nearest_at_max = NaN;
    violation_count = 0;
    first_violation_time = NaN;
    first_violation_agent = NaN;
    timer = tic;

    for kk = 1:sample_count
        p = trajectory_record(:,:,kk);
        t = time_record(kk);
        [u_aim,~] = tac_nominal_control(scenario,p,t,cfg);
        u_aim = tac_limit_speed(u_aim,cfg.v_check);
        [u_safe,~] = tac_filter_adapter(p,u_aim,cfg,cfg.filter_type);
        u_ideal = tac_exact_reference_qp(p,u_aim,cfg,qopt,[]);
        e = vecnorm(reshape(u_safe-u_ideal,2,cfg.N),2,1);
        e_record(:,kk) = e(:);
        e_agent_max = max(e_agent_max,e);

        bad = e > cfg.e_design;
        if any(bad)
            violation_count = violation_count + 1;
            if isnan(first_violation_time)
                first_violation_time = t;
                first_violation_agent = find(bad,1,'first');
            end
        end

        [current_max,current_agent] = max(e);
        if current_max > e_max
            e_max = current_max;
            e_max_time = t;
            e_max_agent = current_agent;
            d = vecnorm(p-p(:,current_agent),2,1);
            d(current_agent) = inf;
            degree_at_max = sum(d <= cfg.R);
            nearest_at_max = min(d);
        end

        if mod(kk,5000) == 0 || kk == sample_count
            fprintf('%d/%d t=%.3f e_max=%.12g violations=%d\n', ...
                kk,sample_count,t,e_max,violation_count);
        end
    end

    audit = struct();
    audit.description = sprintf( ...
        ['Every saved %s state was audited with the common sparse ' ...
         'filter and a no-warm-start centralized exact QP.'], ...
        verification.mode);
    audit.source_file = source_file;
    audit.audit_file = output_file;
    audit.completed_at = datestr(now,31);
    audit.sample_interval = expected_interval;
    audit.N = cfg.N;
    audit.scenario = string(r.scenario_name);
    audit.sample_count = sample_count;
    audit.max_sampling_interval_error = max_interval_error;
    audit.e_bound = cfg.e_design;
    audit.e_max = e_max;
    audit.e_max_time = e_max_time;
    audit.e_max_agent = e_max_agent;
    audit.e_max_agent_degree = degree_at_max;
    audit.e_max_agent_nearest = nearest_at_max;
    audit.violation_sample_count = violation_count;
    audit.first_violation_time = first_violation_time;
    audit.first_violation_agent = first_violation_agent;
    audit.pass = violation_count == 0 && e_max <= cfg.e_design;
    audit.elapsed_seconds = toc(timer);
    audit.e_record = e_record;
    audit.e_record_time = time_record;
    audit.e_agent_max = e_agent_max;
    save(output_file,'audit','-v7.3');

    fprintf(['AUDIT_DONE mode=%s N=%d scenario=%s pass=%d samples=%d ' ...
        'e_max=%.12g bound=%.12g violations=%d\n'], ...
        verification.mode,audit.N,char(audit.scenario),audit.pass, ...
        sample_count,e_max,cfg.e_design,violation_count);
end
