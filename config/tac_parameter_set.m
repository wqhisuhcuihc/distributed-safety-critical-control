function cfg = tac_parameter_set(N)
%TAC_PARAMETER_SET One formal safety-parameter set per fleet size.
%
% The values below intentionally make all five scenarios at a given N share
% exactly the same safety parameters.  Scenario-specific control parameters
% live in the scenario adapters, not here.

    switch N
        case 20
            D0 = 3.00; D = 3.50; alpha = 0.0690000;
            e_design = 0.010; M = 400;
        case 32
            D0 = 9.00; D = 10.50; alpha = 0.0210050;
            % M=500 reduces the finite-iteration error below e_design
            % without changing the star geometry or the safety margins.
            e_design = 0.010; M = 500;
        case 64
            D0 = 8.00; D = 9.3336; alpha = 0.025;
            e_design = 0.010; M = 1000;
        case 96
            D0 = 16.00; D = 16.39; alpha = 0.068;
            e_design = 0.010; M = 1500;
        case 128
            % Keep alpha*D0 and the right-hand side of the D-selection
            % condition at the N=32/64 scale.  This is the N=96 lesson:
            % compact safety distances plus enough barrier gain, rather
            % than a large, weakly weighted safety buffer.
            D0 = 17.50; D = 19.65; alpha = 0.012;
            e_design = 0.010; M = 2000;
        otherwise
            error('tac_parameter_set:unsupportedN', ...
                'Supported fleet sizes are 20, 32, 64, 96 and 128 (got %d).', N);
    end

    cfg = struct();
    cfg.version = "1.0.0";
    cfg.N = N;
    cfg.n = 2;
    cfg.dt = 0.001;
    cfg.kp = 0.80;
    cfg.D0 = D0;
    cfg.D = D;
    cfg.R = 1.2*D0;
    if N == 96 || N == 128
        cfg.R = cfg.D+0.20;
    end
    if N == 20
        cfg.v_bar = 1.00;
    else
        cfg.v_bar = 1.50;
    end
    cfg.v_check = 0.90*cfg.v_bar;
    if N == 128
        cfg.v_bar = 1.80;
        cfg.v_check = 1.65;
    end
    cfg.alpha = alpha;
    cfg.e_design = e_design;
    cfg.M = M;
    cfg.agent_radius = D0/2;
    cfg.safe_distance = D - D0;
    cfg.wifi_distance = cfg.R - D0;
    cfg.static_obstacle = zeros(2,0);
    cfg.obstacle_radius = 0.4*ones(1,0);
    cfg.filter_type = "sparse";

    % N=20's original obstacle buffer is retained as a common value.  These
    % scenes have no static obstacles, so it does not affect the dynamics.
    cfg.obstacle_radius = [0.4 0.4 0.4 0.4];
end
