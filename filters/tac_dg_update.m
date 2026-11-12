function [x,lambda,lambda_self] = tac_dg_update(u_aim,lambda,Fst,Sec,B, ...
    N,G,v_max,lambda_self,denominator,active)
%TAC_DG_UPDATE Fixed-step dual-gradient update used by the dense reference.

    x_aim = reshape(u_aim,2,N);
    x_matrix = x_aim - 0.5*[sum(Fst.*lambda,1); sum(Sec.*lambda,1)];
    x_matrix(1,:) = x_matrix(1,:) - lambda_self(1,:) + lambda_self(2,:);
    x_matrix(2,:) = x_matrix(2,:) - lambda_self(3,:) + lambda_self(4,:);
    x = x_matrix(:);
    two_over_G = 2./G.^2;
    ux = x(1:2:end).';
    uy = x(2:2:end).';
    lambda_self(1,:) = max(0,lambda_self(1,:)+two_over_G.*(ux-v_max));
    lambda_self(2,:) = max(0,lambda_self(2,:)+two_over_G.*(-ux-v_max));
    lambda_self(3,:) = max(0,lambda_self(3,:)+two_over_G.*(uy-v_max));
    lambda_self(4,:) = max(0,lambda_self(4,:)+two_over_G.*(-uy-v_max));
    dx = x_matrix(1,:).' - x_matrix(1,:);
    dy = x_matrix(2,:).' - x_matrix(2,:);
    g = -Fst.*dx - Sec.*dy - B;
    lambda = max(0,lambda+2*g./denominator).*active;
end
