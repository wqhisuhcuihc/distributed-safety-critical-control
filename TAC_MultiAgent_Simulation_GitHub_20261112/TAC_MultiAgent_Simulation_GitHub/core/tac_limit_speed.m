function u = tac_limit_speed(u, vmax)
%TAC_LIMIT_SPEED Componentwise common speed ceiling.

    u = u.*min(1,vmax./max(vecnorm(u,2,1),eps));
end
