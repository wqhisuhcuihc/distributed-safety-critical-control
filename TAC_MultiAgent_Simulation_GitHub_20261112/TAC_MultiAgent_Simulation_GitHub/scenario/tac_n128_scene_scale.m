function scale = tac_n128_scene_scale(scenario)
%TAC_N128_SCENE_SCALE Current spatial scale for each N=128 scenario.

    switch lower(string(scenario))
        case {'random','star'}
            scale = 2.25;
        case {'cross','rings4'}
            scale = 1.50;
        case 'ellipses'
            scale = 1.65;
        otherwise
            error('tac_n128_scene_scale:scenario', ...
                'Unknown N=128 scenario "%s".',string(scenario));
    end
end
