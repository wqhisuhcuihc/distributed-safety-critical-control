function scenario = tac_build_rings4(N, cfg, opts)
%TAC_BUILD_RINGS4 Four-centre circles. Every ring rotates clockwise.

    D0 = cfg.D0;
    if nargin < 3 || isempty(opts), opts = struct(); end
    radial_scale = 1.0;
    if N == 64
        radial_scale = 1.2;
    end
    if N == 96
        radial_scale = 1.5;
    end
    if N == 128
        radial_scale = 1.5;
    end
    if isfield(opts,'ring_radial_scale') && ~isempty(opts.ring_radial_scale)
        radial_scale = opts.ring_radial_scale;
    end
    tangential = 0.85*cfg.v_check;
    switch N
        case 20
            per_ring = 5;
            centres_count = 4;
            radii = 9.3333*D0;
            half_side = 0.54*radii;
            centres = [-half_side half_side -half_side half_side; ...
                       -half_side -half_side half_side half_side];
            phases = [0 216.293924 253.705418 109.673538];
            revolutions = 1.0;
        case 32
            per_ring = N/4;
            centres_count = 4;
            radii = 9.3333*D0;
            half_side = 0.54*radii;
            centres = [-half_side half_side -half_side half_side; ...
                       -half_side -half_side half_side half_side];
            phases = [0 243.582736 114.983156 225.367116];
            revolutions = 1.0;
        case 64
            centres_count = 4;
            radii = 0.85*[13.06 14.94]*D0;
            d = 0.54*radii(1);
            centres = [-1 1 -1 1; 1 1 -1 -1]*d ...
                + 0.10*d*[-0.55 0.80 -1.00 0.35; ...
                           0.90 0.20 -0.40 -0.75];
            phases = [15.0 17.3 41.4 9.3, 21.3 24.6 31.6 4.9];
            per_ring = N/8;
            revolutions = 1.0;
        case 96
            centres_count = 4;
            radii = 1.275*[11 12.6 14.2]*D0;
            d = 0.75*radii(1);
            centres = [-1 1 -1 1; 1 1 -1 -1]*d ...
                + 0.05*d*[-0.55 0.80 -1.00 0.35; ...
                           0.90 0.20 -0.40 -0.75];
            phase_frac = [0.53 0.52 0.27 0.07, ...
                          0.74 0.26 0.49 0.57, ...
                          0.80 0.60 0.76 0.45];
            phases = phase_frac*360/(N/12);
            per_ring = N/12;
            revolutions = 1.0;
        case 128
            centres_count = 4;
            radii = 1.275*[11 12.6 14.2 15.8]*D0;
            d = 0.54*radii(1);
            centres = [-1 1 -1 1; 1 1 -1 -1]*d ...
                + 0.05*d*[-0.55 0.80 -1.00 0.35; ...
                           0.90 0.20 -0.40 -0.75];
            phase_frac = [0.41 0.32 0.60 0.11, ...
                          0.38 0.17 0.06 0.96, ...
                          0.72 0.43 0.44 0.45, ...
                          0.57 0.47 0.82 0.79];
            phase_frac = phase_frac + 0.01*[0 0 0 0, 1 1 1 1, ...
                                           -1 -1 -1 -1, 0 0 0 0];
            phases = phase_frac*360/(N/16);
            per_ring = N/16;
            revolutions = 0.5;
        otherwise
            error('tac_build_rings4:unsupportedN', ...
                'No four-circle geometry for N=%d.', N);
    end

    position = zeros(2,N);
    centre_of = zeros(2,N);
    radius_of = zeros(1,N);
    omega = zeros(1,N);
    column = 0;

    if N == 20 || N == 32
        for ring = 1:centres_count
            angles = phases(ring) + 360/per_ring*(0:per_ring-1);
            cols = column+(1:per_ring); column = column+per_ring;
            position(:,cols) = centres(:,ring) + ...
                radii*[cosd(angles); sind(angles)];
            centre_of(:,cols) = repmat(centres(:,ring),1,per_ring);
            radius_of(cols) = radii;
            omega(cols) = tangential/radii;
        end
    else
        layers = numel(radii);
        for layer = 1:layers
            for ring = 1:centres_count
                slot = (layer-1)*centres_count+ring;
                angles = phases(slot) + 360/per_ring*(0:per_ring-1);
                cols = column+(1:per_ring); column = column+per_ring;
                position(:,cols) = centres(:,ring) + ...
                    radii(layer)*[cosd(angles); sind(angles)];
                centre_of(:,cols) = repmat(centres(:,ring),1,per_ring);
                radius_of(cols) = radii(layer);
                omega(cols) = tangential/radii(layer);
            end
        end
    end

    if radial_scale ~= 1
        position = radial_scale*position;
        centre_of = radial_scale*centre_of;
        radius_of = radial_scale*radius_of;
        radii = radial_scale*radii;
        centres = radial_scale*centres;
        omega = tangential./radius_of;
    end
    theta0 = atan2(position(2,:)-centre_of(2,:), ...
                   position(1,:)-centre_of(1,:));
    reference_mode = "time_parameterized";
    along_track_gain = 0.2;
    if isfield(opts,'tracking_reference_mode') && ...
            ~isempty(opts.tracking_reference_mode)
        reference_mode = string(opts.tracking_reference_mode);
    end
    if isfield(opts,'tracking_along_gain') && ...
            ~isempty(opts.tracking_along_gain)
        along_track_gain = opts.tracking_along_gain;
    end

    scenario = struct();
    scenario.mode = "tracking";
    scenario.initial_position = position;
    scenario.target = centre_of;
    scenario.seed = NaN;
    scenario.track = struct('centre',centre_of,'radius',radius_of, ...
        'omega',omega,'gain',1.2,'theta0',theta0);
    scenario.revolutions = revolutions;
    scenario.controller = struct('kind',"tracking",'gain',1.2, ...
        'tangential_speed',tangential,'clockwise',true, ...
        'reference_mode',reference_mode, ...
        'along_track_gain',along_track_gain);
    scenario.geometry = struct('centres',centres,'radii',radii, ...
        'cars_per_ring',per_ring,'radial_scale',radial_scale, ...
        'spatial_scale',radial_scale);
    scenario.description = sprintf(['4 centres, %d circles, %d cars per ring, ' ...
        'all clockwise, radial scale %.2f, reference %s, along gain %.2f, ' ...
        'revolutions %.2f'], numel(unique(radius_of)), per_ring, ...
        radial_scale, reference_mode, along_track_gain, revolutions);
end
