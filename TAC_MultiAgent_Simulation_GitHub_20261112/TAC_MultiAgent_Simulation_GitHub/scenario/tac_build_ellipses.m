function scenario = tac_build_ellipses(N, cfg, opts)
%TAC_BUILD_ELLIPSES Congruent thin ellipses through one centre.

    D0 = cfg.D0;
    if nargin < 3 || isempty(opts), opts = struct(); end
    spatial_scale = 1.0;
    if N == 20
        K = 5; cars = 4;
        a = 15*D0; b = 2*D0;
        speed = 0.72; base_phase = 0.16; phase_step = 0.01;
    else
        K = 8;
        if mod(N,K) ~= 0
            error('tac_build_ellipses:badSplit', ...
                'N=%d must be a multiple of 8.', N);
        end
        cars = N/K;
        a = 18*D0;
        switch N
            case 32
                b = 2.5*D0; base_phase = 0.026; phase_step = 0.015;
            case 64
                b = 5*D0; base_phase = 0.82; phase_step = -0.02;
            case 96
                b = 5*D0; base_phase = 0.077; phase_step = 0.030;
                spatial_scale = 1.5;
            case 128
                b = 5*D0;
                base_phase = 0.970534559550;
                phase_step = -0.056337851576;
                spatial_scale = 1.65;
        end
        speed = 1.10;
    end
    if isfield(opts,'ellipse_minor_scale') && ~isempty(opts.ellipse_minor_scale)
        b = opts.ellipse_minor_scale*D0;
    end
    if isfield(opts,'ellipse_base_phase') && ~isempty(opts.ellipse_base_phase)
        base_phase = opts.ellipse_base_phase;
    end
    if isfield(opts,'ellipse_phase_step') && ~isempty(opts.ellipse_phase_step)
        phase_step = opts.ellipse_phase_step;
    end
    if isfield(opts,'ellipse_speed') && ~isempty(opts.ellipse_speed)
        speed = opts.ellipse_speed;
    end
    if spatial_scale ~= 1
        a = spatial_scale*a;
        b = spatial_scale*b;
    end

    M = 1200;
    Ndense = 20000;
    points = zeros(2,N,M+1);
    tangent = zeros(2,N,M+1);
    lengths = zeros(1,N);
    phase0 = zeros(1,N);
    position = zeros(2,N);
    u = linspace(0,1,Ndense+1);
    t = 2*pi*u;
    ds = hypot(-a*sin(t),b*cos(t));
    du = u(2)-u(1);
    s = [0 cumsum(0.5*(ds(1:end-1)+ds(2:end))*du)];
    arc = s/s(end);

    column = 0;
    for k = 1:K
        theta = (k-1)*2*pi/K;
        fun = @(uu) tac_ellipse_track(uu,theta,a,b);
        [P,T,L] = tac_sample_closed_path(fun,M,Ndense);
        param_phase = mod(base_phase + phase_step*(k-1) + (0:cars-1)/cars,1);
        phases = interp1(u,arc,param_phase,'linear');
        for j = 1:cars
            column = column+1;
            points(:,column,:) = P;
            tangent(:,column,:) = T;
            lengths(column) = L;
            phase0(column) = phases(j)*L;
            idx = mod(round(phases(j)*M),M)+1;
            position(:,column) = P(:,idx);
        end
    end

    loops = 1;
    if N == 128
        loops = 0.5;
    end

    scenario = struct();
    scenario.mode = "path";
    scenario.initial_position = position;
    scenario.target = position;
    scenario.seed = NaN;
    scenario.path = struct('points',points,'tangent',tangent, ...
        'length',lengths,'phase0',phase0,'speed',speed,'gain',1.20, ...
        'loops',loops,'samples',M,'tracks',K);
    scenario.controller = struct('kind',"path",'speed',speed,'gain',1.20);
    scenario.geometry = struct('ellipses',K,'cars_per_ellipse',cars, ...
        'major_axis',a,'minor_axis',b, ...
        'spatial_scale',spatial_scale);
    scenario.description = sprintf(['%d congruent thin ellipses, %d cars each, ' ...
        'major/minor %.2f/%.2f m, path speed %.2f m/s, loops %.2f'], ...
        K, cars, a, b, speed, loops);
end
