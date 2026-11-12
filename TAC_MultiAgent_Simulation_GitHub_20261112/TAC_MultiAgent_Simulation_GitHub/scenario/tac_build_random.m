function scenario = tac_build_random(N, cfg, opts)
%TAC_BUILD_RANDOM Uniform random starts and goals with one fixed seed.

    if nargin < 3 || isempty(opts), opts = struct(); end
    seed = 20261049;
    if isfield(opts, 'seed') && ~isempty(opts.seed)
        seed = opts.seed;
    end

    min_separation = 1.2667*cfg.D0;
    spatial_scale = 1.0;
    if N == 128
        spatial_scale = tac_n128_scene_scale("random");
    elseif N == 32 || N == 64 || N == 96
        spatial_scale = 1.5;
    end
    if isfield(opts,'random_spatial_scale') && ~isempty(opts.random_spatial_scale)
        spatial_scale = opts.random_spatial_scale;
    end
    base_side = sqrt(5*N)*cfg.D0;
    side = spatial_scale*base_side;
    rng(seed, 'twister');
    if N == 32 || N == 64 || N == 96 || N == 128
        % Preserve the canonical random layout and scale every start/goal
        % by the same factor.  This keeps the scenario comparison meaningful.
        position = spatial_scale*tac_sample_points( ...
            N,base_side,min_separation);
        goals = spatial_scale*tac_sample_points( ...
            N,base_side,min_separation);
    else
        position = tac_sample_points(N, side, min_separation);
        goals = tac_sample_points(N, side, min_separation);
    end
    target = goals(:,randperm(N));

    scenario = struct();
    scenario.mode = "goal";
    scenario.initial_position = position;
    scenario.target = target;
    scenario.seed = seed;
    scenario.controller = struct('kind', "goal", 'kp', cfg.kp);
    actual_min_separation = min_separation;
    if N == 32 || N == 64 || N == 96 || N == 128
        actual_min_separation = spatial_scale*min_separation;
    end
    scenario.geometry = struct('side', side, ...
        'min_separation', actual_min_separation, ...
        'spatial_scale', spatial_scale);
    scenario.description = sprintf(['%d uniform random starts/goals, random ' ...
        'permutation, seed %d, side %.2f m, minimum separation %.2f m, ' ...
        'spatial scale %.2f'], ...
        N, seed, side, actual_min_separation, spatial_scale);
end
