function [u_safe,error_vector] = tac_filter_sparse(pos_all,u_aim, ...
    radius_agent,safe_distance,wifi_distance,static_obstacle, ...
    obstacle_radius,alpha,M,v_max)
%TAC_FILTER_SPARSE Formal edge-list implementation of the same filter.

    N = size(pos_all,2);
    O_num = size(static_obstacle,2);
    NUM_iter = max(200,M);
    dxm = pos_all(1,:).'-pos_all(1,:);
    dym = pos_all(2,:).'-pos_all(2,:);
    dm = hypot(dxm,dym);
    hh = dm; hh(1:N+1:end) = 10;
    nx = dxm./hh; ny = dym./hh;
    sx = sum(nx.^2,1); sy = sum(ny.^2,1); sxy = sum(nx.*ny,1);
    G = sqrt(0.5*(sx+sy+4) + sqrt((0.5*(sx-sy)).^2+sxy.^2));
    act = dm < (2*radius_agent+wifi_distance);
    act(1:N+1:end) = false;
    [rw,cl] = find(act);
    E = numel(rw);
    if E > 1500
        [u_safe,error_vector] = tac_filter_fast(pos_all,u_aim, ...
            radius_agent,safe_distance,wifi_distance,static_obstacle, ...
            obstacle_radius,alpha,M,v_max);
        return;
    end
    if E == 0 && O_num == 0
        % With no active pair constraints or obstacles, the fixed-iteration
        % filter returns the box-projected nominal control.  tac_limit_speed
        % already supplies that feasible control, so the M empty iterations
        % have an exact closed-form result.
        u_safe = min(max(reshape(u_aim,2,N),-v_max),v_max);
        u_safe = u_safe(:);
        error_vector = zeros(2*N,1);
        return;
    end
    lin = sub2ind([N N],rw,cl);
    A = [nx(lin),ny(lin)];
    hA = alpha*(dm(lin)-2*radius_agent-safe_distance);
    den = G(cl).'.^2+G(rw).'.^2;
    lambda = zeros(E,1); lambda_self = zeros(4,N);
    two_over_G = 2./G.^2;
    u = reshape(u_aim,2,N);
    S = sparse(cl,1:E,1,N,E);
    local_obstacle = []; local_b = [];
    if O_num ~= 0
        local_obstacle = zeros(2,O_num,N); local_b = zeros(O_num,N);
        for i = 1:N
            local_obstacle(:,:,i) = static_obstacle-pos_all(:,i);
            local_b(:,i) = vecnorm(local_obstacle(:,:,i),2,1);
        end
    end
    u_safe = u_aim;
    for iter = 1:NUM_iter
        if E > 0
            half = 0.5*A.*lambda;
            x = u-(S*half).';
        else
            x = u;
        end
        x(1,:) = x(1,:)-lambda_self(1,:)+lambda_self(2,:);
        x(2,:) = x(2,:)-lambda_self(3,:)+lambda_self(4,:);
        x_vec = x(:);
        ux = x_vec(1:2:end).'; uy = x_vec(2:2:end).';
        lambda_self(1,:) = max(0,lambda_self(1,:)+two_over_G.*(ux-v_max));
        lambda_self(2,:) = max(0,lambda_self(2,:)+two_over_G.*(-ux-v_max));
        lambda_self(3,:) = max(0,lambda_self(3,:)+two_over_G.*(uy-v_max));
        lambda_self(4,:) = max(0,lambda_self(4,:)+two_over_G.*(-uy-v_max));
        if E > 0
            w = x(:,rw)-x(:,cl);
            g = -(A(:,1).'.*w(1,:)+A(:,2).'.*w(2,:)).' - hA;
            lambda = max(0,lambda+2*g./den);
        end
        if O_num ~= 0
            x_temp = reshape(x,2,N);
            for i = 1:N
                for j = 1:O_num
                    real_A = local_obstacle(:,j,i)/local_b(j,i);
                    real_b = local_b(j,i)-obstacle_radius(j);
                    touying = 0.2*dot(real_A,x_temp(:,i));
                    if ~(real_b >= 0 && real_b >= touying)
                        x_temp(:,i) = x_temp(:,i)-5*(touying-real_b)*real_A;
                    end
                end
            end
            x = reshape(x_temp,[],1);
            x_vec = x;
        end
        if iter == M, u_safe = x_vec; end
    end
    error_vector = x_vec-u_safe;
end
