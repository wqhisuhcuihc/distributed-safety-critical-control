function result = tac_run_closed_loop(cfg,scenario,opts)
%TAC_RUN_CLOSED_LOOP The single closed-loop implementation for all 25 cases.

    position = scenario.initial_position;
    target = scenario.target;
    if isfield(opts,'M_override') && ~isempty(opts.M_override)
        cfg.M = opts.M_override;
    end
    N = cfg.N;
    dt = cfg.dt;

    initial_minimum = tac_minimum_pair_distance(position);
    audit = tac_validate_conditions(cfg,initial_minimum,opts);

    if isfield(opts,'filter_type') && strlength(string(opts.filter_type)) > 0
        cfg.filter_type = lower(string(opts.filter_type));
    end

    travel = vecnorm(target-position,2,1);
    if isempty(opts.Time)
        switch scenario.mode
            case "path"
                Time = scenario.path.loops*max(scenario.path.length)/scenario.path.speed;
            case "tracking"
                revolutions = 1.0;
                if isfield(scenario,'revolutions'), revolutions = scenario.revolutions; end
                Time = revolutions*2*pi/max(abs(scenario.track.omega));
            otherwise
                Time = 4.0*max(travel)/cfg.v_check;
        end
    else
        Time = opts.Time;
    end

    steps = round(Time/dt);
    stride = max(1,round(opts.record_stride));
    record_capacity = ceil(steps/stride);
    time_record = zeros(1,record_capacity);
    trajectory_record = zeros(2,N,record_capacity);
    nearest_record = zeros(N,record_capacity);
    control_record = zeros(N,record_capacity);
    component_record = zeros(1,record_capacity);
    neighbor_max_record = zeros(1,record_capacity);
    link_record = zeros(1,record_capacity);
    component_count_record = zeros(1,record_capacity);
    error_record = [];
    if opts.compute_reference && opts.save_error_time_series
        error_record = zeros(N,record_capacity);
    end
    record_index = 0;

    minimum_distance = inf;
    n_max = 1; n_max_time = 0; neighbor_peak = 0;
    residual_max = 0; e_returned = 0;
    exact_norm = zeros(N,1);
    u_safe_next = zeros(2*N,1);
    convergence_count = 0; converged = false; stopped_at = steps;
    qp_options = [];
    if opts.compute_reference
        if exist('optimoptions','file') ~= 2
            error('tac_run_closed_loop:noOptimizationToolbox', ...
                'compute_reference requires optimoptions.');
        end
        qp_options = optimoptions('quadprog','Display','off', ...
            'Algorithm','active-set');
    end

    timer = tic;
    progress_stride = max(1,round(steps/10));
    used_filter = lower(string(cfg.filter_type));
    for k = 1:steps
        t = k*dt;
        [u_aim,~] = tac_nominal_control(scenario,position,t,cfg);
        u_aim = tac_limit_speed(u_aim,cfg.v_check);
        if k == 1
            u_applied = u_aim;
        else
            u_applied = u_safe_next;
        end

        [u_safe_next,residual_vector,used_filter] = tac_filter_adapter( ...
            position,u_aim,cfg,cfg.filter_type);
        residual_norm = vecnorm(reshape(residual_vector,2,N),2,1).';
        residual_max = max(residual_max,max(residual_norm));

        if opts.compute_reference
            % Do not warm-start this audit QP.  At an active-set transition,
            % a previous feasible solution can make active-set return a
            % spurious solution even though the current QP is feasible.
            u_ideal = tac_exact_reference_qp( ...
                position,u_aim,cfg,qp_options,[]);
            exact_norm = vecnorm(reshape(u_safe_next-u_ideal,2,N),2,1).';
            e_returned = max(e_returned,max(exact_norm));
        end

        position = position+reshape(u_applied,2,N)*dt;
        stats = tac_pair_stats(position,cfg.R);
        minimum_distance = min(minimum_distance,stats.minimum);
        neighbor_peak = max(neighbor_peak,stats.neighbor_max);
        if stats.largest_component > n_max
            n_max = stats.largest_component;
            n_max_time = t;
        end

        if mod(k-1,stride) == 0
            record_index = record_index+1;
            time_record(record_index) = t;
            trajectory_record(:,:,record_index) = position;
            nearest_record(:,record_index) = stats.nearest;
            control_record(:,record_index) = ...
                max(abs(reshape(u_applied,2,N)),[],1).';
            component_record(record_index) = stats.largest_component;
            neighbor_max_record(record_index) = stats.neighbor_max;
            link_record(record_index) = stats.link_count;
            component_count_record(record_index) = stats.component_count;
            if ~isempty(error_record)
                % exact_norm is the same no-warm-start error already used
                % for e_returned at this control-update time.  Reuse it so
                % strict 1 ms runs do not solve a second QP per step.
                error_record(:,record_index) = exact_norm;
            end
        end

        if mod(k,progress_stride) == 0 || k == steps
            fprintf('  %3.0f%%  t=%.1f s  min=%.3f  n_max=%d\n', ...
                100*k/steps,t,minimum_distance,n_max);
        end

        if scenario.mode == "goal" && ...
                max(vecnorm(target-position,2,1)) <= opts.convergence_tolerance
            convergence_count = convergence_count+1;
            if convergence_count >= opts.convergence_hold_steps
                converged = true;
                stopped_at = k;
                break;
            end
        else
            convergence_count = 0;
        end

        if any(~isfinite(position),'all') || any(~isfinite(u_safe_next))
            error('tac_run_closed_loop:diverged', ...
                'Non-finite state at step %d.',k);
        end
    end
    elapsed = toc(timer);

    records = struct();
    records.time = time_record(1:record_index);
    records.trajectory = trajectory_record(:,:,1:record_index);
    records.nearest = nearest_record(:,1:record_index);
    records.control = control_record(:,1:record_index);
    records.component = component_record(1:record_index);
    records.neighbor_max = neighbor_max_record(1:record_index);
    records.links = link_record(1:record_index);
    records.component_count = component_count_record(1:record_index);
    if isempty(error_record)
        records.error = [];
    else
        records.error = error_record(:,1:record_index);
    end

    final_position = records.trajectory(:,:,end);
    switch scenario.mode
        case "goal"
            final_residual = max(vecnorm(target-final_position,2,1));
        case "tracking"
            if isfield(scenario,'controller') && ...
                    isfield(scenario.controller,'reference_mode') && ...
                    scenario.controller.reference_mode == "time_parameterized"
                [~,reference] = tac_nominal_control( ...
                    scenario,final_position,stopped_at*dt,cfg);
                final_residual = max(vecnorm(reference-final_position,2,1));
            else
                radius_error = abs(vecnorm(final_position-scenario.track.centre,2,1) ...
                    -scenario.track.radius);
                final_residual = max(radius_error);
            end
        case "path"
            [~,reference] = tac_nominal_control(scenario,final_position, ...
                stopped_at*dt,cfg);
            final_residual = max(vecnorm(reference-final_position,2,1));
    end

    performance = struct();
    performance.minimum_distance = minimum_distance;
    performance.n_max = n_max;
    performance.n_max_time = n_max_time;
    performance.neighbor_peak = neighbor_peak;
    performance.links_min = min(records.links);
    performance.links_max = max(records.links);
    performance.component_count_min = min(records.component_count);
    performance.component_count_max = max(records.component_count);
    performance.peak_fraction = mean(records.component >= n_max);
    performance.elapsed = elapsed;
    performance.Time = Time;
    performance.arrival_time = stopped_at*dt;
    performance.converged = converged;
    performance.final_residual = final_residual;
    performance.residual_max = residual_max;
    performance.e_returned = e_returned;
    performance.filter_type = used_filter;

    result = tac_make_result(cfg,scenario,opts,audit,records,performance);
    fprintf(['done in %.1f s: min=%.4f safe=%d n_max=%d ' ...
        'links=%d..%d residual=%.4f\n'], ...
        elapsed,result.minimum_distance,result.safe,result.n_max, ...
        result.links_min,result.links_max,result.final_residual);
end

function minimum = tac_minimum_pair_distance(position)
    d = tac_pairwise_distance(position);
    d(1:size(d,1)+1:end) = inf;
    minimum = min(d(:));
end
