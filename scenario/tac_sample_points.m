function points = tac_sample_points(N, side, min_separation)
%TAC_SAMPLE_POINTS Rejection sampling with a minimum separation.

    points = zeros(2,N);
    placed = 0;
    attempts = 0;
    while placed < N
        attempts = attempts + 1;
        if attempts > 5e5
            error('tac_sample_points:failed', ...
                'Could not place %d points with separation %.4f.', ...
                N, min_separation);
        end
        candidate = side*(rand(2,1)-0.5);
        if placed == 0
            ok = true;
        else
            gaps = hypot(points(1,1:placed)-candidate(1), ...
                         points(2,1:placed)-candidate(2));
            ok = min(gaps) >= min_separation;
        end
        if ok
            placed = placed + 1;
            points(:,placed) = candidate;
        end
    end
end
