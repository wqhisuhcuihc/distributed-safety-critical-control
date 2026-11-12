function P = tac_ellipse_track(u, theta, a, b)
%TAC_ELLIPSE_TRACK Point on a rotated ellipse at normalised path coordinate.

    t = 2*pi*u;
    x = a*cos(t);
    y = b*sin(t);
    c = cos(theta);
    s = sin(theta);
    P = [c*x - s*y; s*x + c*y];
end
