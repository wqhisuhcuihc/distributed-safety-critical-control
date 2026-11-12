function setup_ok = verify_N128_setup()
%VERIFY_N128_SETUP Fast preflight before the expensive N=128 runs.

    this_dir = fileparts(mfilename('fullpath'));
    root = this_dir;
    if exist(fullfile(root,'config'),'dir') ~= 7
        root = fileparts(this_dir);
    end
    addpath(genpath(root),'-begin');
    cfg = tac_parameter_set(128);
    gate = tac_validate_conditions(cfg,[],struct('run_mode','diagnostic'));
    if exist('quadprog','file') ~= 2
        error('verify_N128_setup:noQuadprog', ...
            'Optimization Toolbox quadprog is required.');
    end

    scenarios = tac_scenario_registry();
    minimum_distance = zeros(1,numel(scenarios));
    spatial_scale = zeros(1,numel(scenarios));
    expected_scale = zeros(1,numel(scenarios));
    required_initial = gate.required_initial*ones(1,numel(scenarios));
    for k = 1:numel(scenarios)
        sc = tac_build_scenario(128,scenarios(k),cfg,struct());
        minimum_distance(k) = pairwise_minimum(sc.initial_position);
        spatial_scale(k) = sc.geometry.spatial_scale;
        expected_scale(k) = tac_n128_scene_scale(scenarios(k));
    end

    rings = tac_build_scenario(128,"rings4",cfg,struct());
    ellipses = tac_build_scenario(128,"ellipses",cfg,struct());
    ring_time = rings.revolutions*2*pi/max(abs(rings.track.omega));
    ellipse_time = ellipses.path.loops*max(ellipses.path.length)/ ...
        ellipses.path.speed;
    ring_omega_spread = max(rings.track.omega)-min(rings.track.omega);
    ellipse_length_spread = max(ellipses.path.length)- ...
        min(ellipses.path.length);

    setup_ok = gate.conditions_ok && ...
        all(minimum_distance >= required_initial) && ...
        all(abs(spatial_scale-expected_scale) <= 1e-12) && ...
        abs(rings.revolutions-0.5) <= eps && ...
        abs(ellipses.path.loops-0.5) <= eps && ...
        ellipse_length_spread <= 1e-8;

    fprintf('MATLAB: %s\n',version);
    fprintf('quadprog: %s\n',which('quadprog'));
    fprintf('conditions_ok=%d margins=[%.12g %.12g %.12g %.12g]\n', ...
        gate.conditions_ok,gate.condition_margin);
    for k = 1:numel(scenarios)
        fprintf('%-8s initial_min=%.9g required=%.9g scale=%.6g\n', ...
            scenarios(k),minimum_distance(k),required_initial(k), ...
            spatial_scale(k));
    end
    fprintf('rings4 half-cycle: T=%.9g s, omega spread=%.3g\n', ...
        ring_time,ring_omega_spread);
    fprintf('ellipses half-cycle: T=%.9g s, length spread=%.3g m\n', ...
        ellipse_time,ellipse_length_spread);
    fprintf('SETUP_OK=%d\n',setup_ok);
    if ~setup_ok
        error('verify_N128_setup:failed','N=128 preflight failed.');
    end
end

function minimum = pairwise_minimum(position)
    N = size(position,2);
    minimum = inf;
    for i = 1:N
        for j = i+1:N
            minimum = min(minimum,norm(position(:,i)-position(:,j)));
        end
    end
end
