function scenario = tac_build_scenario(N, name, cfg, opts)
%TAC_BUILD_SCENARIO Build one canonical scenario using a declarative adapter.

    if nargin < 4, opts = struct(); end
    name = lower(string(name));
    allowed = tac_scenario_registry();
    if ~any(name == allowed)
        error('tac_build_scenario:unknownScenario', ...
            'Unknown scenario "%s". Allowed: %s.', name, strjoin(allowed, ', '));
    end

    switch name
        case "cross"
            scenario = tac_build_cross(N, cfg, opts);
        case "rings4"
            scenario = tac_build_rings4(N, cfg, opts);
        case "random"
            scenario = tac_build_random(N, cfg, opts);
        case "star"
            scenario = tac_build_star(N, cfg);
        case "ellipses"
            scenario = tac_build_ellipses(N, cfg, opts);
    end

    scenario.N = N;
    scenario.name = name;
    scenario.seed = double(scenario.seed);
    if ~isfield(scenario, 'description') || isempty(scenario.description)
        scenario.description = sprintf('%s with %d agents', name, N);
    end
end
