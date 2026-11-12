function u_ideal = tac_exact_reference_qp(position,u_aim,cfg,options,x0)
%TAC_EXACT_REFERENCE_QP Optional central reference QP for error auditing.

    N = size(position,2);
    u_aim = u_aim(:);
    if nargin < 5 || isempty(x0)
        x0 = min(max(u_aim,-cfg.v_check),cfg.v_check);
    end
    x0 = reshape(x0,2*N,1);
    H = 2*eye(2*N);
    f = -2*u_aim;
    A = zeros(0,2*N); b = zeros(0,1);
    for i = 1:N
        for j = i+1:N
            delta = position(:,j)-position(:,i);
            distance = norm(delta);
            if distance > cfg.R
                continue;
            end
            normal = delta/max(distance,eps);
            row = zeros(1,2*N);
            row(2*i-1:2*i) = normal.';
            row(2*j-1:2*j) = -normal.';
            A(end+1,:) = row; %#ok<AGROW>
            b(end+1,1) = cfg.alpha*(distance-cfg.D); %#ok<AGROW>
        end
    end
    if isempty(A)
        u_ideal = x0;
    elseif exist('quadprog','file') ~= 2
        error('tac_exact_reference_qp:noQuadprog', ...
            'compute_reference requires the Optimization Toolbox quadprog.');
    else
        [u_ideal,~,exitflag] = quadprog(H,f,A,b,[],[], ...
            -cfg.v_check*ones(2*N,1),cfg.v_check*ones(2*N,1), ...
            x0,options);
        if exitflag <= 0
            fallback = optimoptions('quadprog','Display','off', ...
                'Algorithm','interior-point-convex','MaxIterations',2000);
            [u_ideal,~,exitflag] = quadprog(H,f,A,b,[],[], ...
                -cfg.v_check*ones(2*N,1),cfg.v_check*ones(2*N,1), ...
                x0,fallback);
        end
        if exitflag <= 0 || any(~isfinite(u_ideal))
            error('tac_exact_reference_qp:failed', ...
                'Reference QP failed with exitflag=%d.',exitflag);
        end
    end
    u_ideal = reshape(u_ideal,2*N,1);
    if numel(u_ideal) ~= 2*N
        error('tac_exact_reference_qp:dimension', ...
            'Reference QP returned %d values, expected %d.', ...
            numel(u_ideal),2*N);
    end
end
