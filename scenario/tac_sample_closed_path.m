function [P,T,L] = tac_sample_closed_path(fun, M, Ndense)
%TAC_SAMPLE_CLOSED_PATH Arc-length sample and tangents for a closed path.

    u = linspace(0,1,Ndense+1);
    P = fun(u);
    P(:,end) = P(:,1);
    ds = vecnorm(diff(P,1,2),2,1);
    s = [0 cumsum(ds)];
    L = s(end);
    sq = linspace(0,L,M+1);
    P = interp1(s,P.',sq.','linear').';
    P(:,end) = P(:,1);
    T = zeros(2,M+1);
    T(:,2:M) = (P(:,3:M+1)-P(:,1:M-1))/2;
    T(:,1) = P(:,2)-P(:,M);
    T(:,M+1) = T(:,1);
    T = T./max(vecnorm(T,2,1),eps);
end
