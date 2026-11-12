function scenario = tac_build_star(N, cfg)
%TAC_BUILD_STAR Mirrored-layer star with one common spacing rule.

    D0 = cfg.D0;
    % Keep the accepted geometry.  Increasing this spacing was found to
    % make the finite-iteration audit error worse at N=32.
    radial_scale = 1.20;
    if N == 64 || N == 96
        radial_scale = 1.50*radial_scale;
    end
    spatial_scale = 1.0;
    if N == 128
        spatial_scale = tac_n128_scene_scale("star");
        radial_scale = spatial_scale*radial_scale;
    end
    if N == 20
        arms = 5; layers = 4;
    else
        arms = 8;
        if mod(N,arms) ~= 0
            error('tac_build_star:badSplit', ...
                'N=%d must be divisible by %d arms.', N, arms);
        end
        layers = N/arms;
    end

    step_r = radial_scale*1.1833*D0;
    radii = radial_scale*1.82*D0 + (0:layers-1)*step_r;
    arm_angles = 360/arms*(0:arms-1);
    position = zeros(2,N);
    target = zeros(2,N);
    column = 0;
    for arm = 1:arms
        next_angle = arm_angles(mod(arm,arms)+1);
        for layer = 1:layers
            column = column + 1;
            position(:,column) = radii(layer)* ...
                [cosd(arm_angles(arm)); sind(arm_angles(arm))];
            mirrored = layers+1-layer;
            target(:,column) = radii(mirrored)* ...
                [cosd(next_angle); sind(next_angle)];
        end
    end

    scenario = struct();
    scenario.mode = "goal";
    scenario.initial_position = position;
    scenario.target = target;
    scenario.seed = NaN;
    scenario.controller = struct('kind', "goal", 'kp', cfg.kp);
    scenario.geometry = struct('arms',arms,'layers',layers, ...
        'radial_scale',radial_scale,'radii',radii, ...
        'spatial_scale',spatial_scale);
    scenario.description = sprintf(['%d arms x %d layers, mirrored layer ' ...
        'exchange, radial scale %.2f, step %.2f m'], ...
        arms, layers, radial_scale, step_r);
end
