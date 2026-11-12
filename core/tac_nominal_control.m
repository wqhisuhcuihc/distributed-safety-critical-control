function [u, reference] = tac_nominal_control(scenario, position, t, cfg)
%TAC_NOMINAL_CONTROL The only place where reference-control modes differ.

    switch scenario.mode
        case "goal"
            reference = scenario.target;
            u = cfg.kp*(reference-position);
        case "tracking"
            tr = scenario.track;
            offset = position-tr.centre;
            len = vecnorm(offset,2,1);
            if isfield(scenario,'controller') && ...
                    isfield(scenario.controller,'reference_mode') && ...
                    scenario.controller.reference_mode == "time_parameterized"
                theta = tr.theta0+tr.omega*t;
                direction = sign(tr.omega);
                radial_unit = [cos(theta);sin(theta)];
                tangent_unit = direction.*[-sin(theta);cos(theta)];
                reference = tr.centre+tr.radius.*radial_unit;
                tracking_error = reference-position;
                tangent_error = dot(tracking_error,tangent_unit,1);
                radial_error = dot(tracking_error,radial_unit,1);
                feedforward_speed = abs(tr.omega).*tr.radius;
                along_gain = scenario.controller.along_track_gain;
                u = feedforward_speed.*tangent_unit ...
                    + along_gain.*tangent_error.*tangent_unit ...
                    + tr.gain.*radial_error.*radial_unit;
            else
                tangential = tr.omega.*[-offset(2,:); offset(1,:)];
                radial = tr.gain*(tr.radius-len).*offset./max(len,eps);
                u = tangential+radial;
                reference = tr.centre;
            end
        case "path"
            p = scenario.path;
            uu = mod((p.phase0+p.speed*t)./p.length,1);
            idx = floor(uu*p.samples)+1;
            frac = uu*p.samples-(idx-1);
            lin_base = reshape(1:2*scenario.N,2,scenario.N);
            stride = 2*scenario.N;
            lin1 = lin_base+(idx-1)*stride;
            lin2 = lin1+stride;
            p1 = reshape(p.points(lin1),2,scenario.N);
            p2 = reshape(p.points(lin2),2,scenario.N);
            reference = p1+frac.*(p2-p1);
            q1 = reshape(p.tangent(lin1),2,scenario.N);
            q2 = reshape(p.tangent(lin2),2,scenario.N);
            tangent = q1+frac.*(q2-q1);
            tangent = tangent./max(vecnorm(tangent,2,1),eps);
            u = p.speed*tangent+p.gain*(reference-position);
        otherwise
            error('tac_nominal_control:mode', ...
                'Unknown reference mode "%s".', scenario.mode);
    end
end
