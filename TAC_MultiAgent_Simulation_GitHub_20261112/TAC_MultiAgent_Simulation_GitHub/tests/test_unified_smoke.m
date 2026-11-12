function test_unified_smoke()
%TEST_UNIFIED_SMOKE Fast structural and numerical smoke test for unified_TAC.

    this_dir = fileparts(mfilename('fullpath'));
    root = this_dir;
    if exist(fullfile(root,'config'),'dir') ~= 7
        root = fileparts(this_dir);
    end
    addpath(fullfile(root,'config'),'-begin');
    addpath(fullfile(root,'scenario'),'-begin');
    addpath(fullfile(root,'core'),'-begin');
    addpath(fullfile(root,'filters'),'-begin');
    addpath(fullfile(root,'io'),'-begin');
    addpath(root,'-begin');

    scales = [20 32 64 96 128];
    scenarios = tac_scenario_registry();
    for N = scales
        cfg = tac_parameter_set(N);
        for name = scenarios
            sc = tac_build_scenario(N,name,cfg,struct());
            assert(size(sc.initial_position,1) == 2);
            assert(size(sc.initial_position,2) == N);
            assert(all(isfinite(sc.initial_position),'all'));
            d = tac_pairwise_distance(sc.initial_position);
            d(1:N+1:end) = inf;
            tac_validate_conditions(cfg,min(d(:)),struct('run_mode',"formal"));
            fprintf('ok  N=%3d %-8s mode=%s\n',N,name,sc.mode);
        end
    end

    cfg = tac_parameter_set(20);
    a = tac_build_scenario(20,"random",cfg,struct());
    b = tac_build_scenario(20,"random",cfg,struct());
    assert(isequal(a.initial_position,b.initial_position));
    assert(isequal(a.target,b.target));
    fprintf('ok  random scene is deterministic\n');

    q = a.initial_position;
    u = zeros(2*size(q,2),1);
    [us,~] = tac_filter_sparse(q,u,cfg.agent_radius,cfg.safe_distance, ...
        cfg.wifi_distance,cfg.static_obstacle,cfg.obstacle_radius, ...
        cfg.alpha,cfg.M,cfg.v_check);
    [ud,~] = tac_filter_fast(q,u,cfg.agent_radius,cfg.safe_distance, ...
        cfg.wifi_distance,cfg.static_obstacle,cfg.obstacle_radius, ...
        cfg.alpha,cfg.M,cfg.v_check);
    assert(norm(us-ud) < 1e-10);
    fprintf('ok  dense/sparse filters agree\n');

    quick = tac_default_options();
    quick.Time = 0.02;
    quick.save_raw = false;
    quick.show_plots = false;
    for name = ["cross","rings4","ellipses"]
        r = run_TAC_experiment(20,name,quick);
        assert(r.N == 20 && r.scenario_name == name);
        assert(r.minimum_distance > 0);
        fprintf('ok  quick closed loop N=20 %s\n',name);
    end
end
