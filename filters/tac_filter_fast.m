function [u_safe,error_vector] = tac_filter_fast(pos_all,u_aim, ...
    radius_agent,safe_distance,wifi_distance,static_obstacle, ...
    obstacle_radius,alpha,M,v_max)
%TAC_FILTER_FAST Dense fixed-iteration safety filter reference.

    N = size(pos_all,2);
    O_num = size(static_obstacle,2);
    NUM_iter = max(200,M);
    Fst = zeros(N,N); Sec = zeros(N,N); B = zeros(N,N); norm_G = zeros(1,N);
    for i = 1:N
        dx = pos_all(1,:).' - pos_all(1,i);
        dy = pos_all(2,:).' - pos_all(2,i);
        h = hypot(dx,dy);
        h(i) = 10;
        nx = dx./h; ny = dy./h;
        Fst(:,i) = nx; Sec(:,i) = ny;
        B(:,i) = alpha*(h-radius_agent*2-safe_distance);
        sx = sum(nx.^2); sy = sum(ny.^2); sxy = sum(nx.*ny);
        norm_G(i) = sqrt(0.5*(sx+sy+4) + ...
            sqrt((0.5*(sx-sy)).^2+sxy.^2));
    end
    if O_num ~= 0
        local_obstacle = zeros(2,O_num,N);
        local_b = zeros(O_num,N);
        for i = 1:N
            local_obstacle(:,:,i) = static_obstacle-pos_all(:,i);
            local_b(:,i) = vecnorm(local_obstacle(:,:,i),2,1);
        end
    end
    Fst = Fst.'; Sec = Sec.';
    denominator = norm_G(:).^2 + norm_G(:).'.^2;
    active = (B+alpha*safe_distance < alpha*wifi_distance);
    active(1:N+1:end) = false;
    Fst_arg = Fst.'; Sec_arg = Sec.';
    x = zeros(2*N,1); lambda = zeros(N,N); lambda_self = zeros(4,N);
    u_safe = x;
    for iter = 1:NUM_iter
        [x,lambda,lambda_self] = tac_dg_update(u_aim,lambda, ...
            Fst_arg,Sec_arg,B,N,norm_G,v_max, ...
            lambda_self,denominator,active);
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
        end
        if iter == M, u_safe = x; end
    end
    error_vector = x-u_safe;
end
