function scenario = tac_build_cross(N, cfg, opts)
%TAC_BUILD_CROSS Four-arm crossing; N20 keeps its accepted five-car arms.

    D0 = cfg.D0;
    if nargin < 3 || isempty(opts), opts = struct(); end
    if N == 20
        cars = 5;
        spacing = 2.5*D0;
        entry = (12/4.5)*spacing;
        lane = (1.7/4.5)*spacing;
        tgt_offset = [0 1.8 -1.4 2.0 -1.6];
        lat_offset = [0 0.10 -0.08 0.12 -0.10];
        dir_shift = 0.5;
        position = zeros(2,4*cars);
        target = zeros(2,4*cars);
        for d = 1:4
            idx = (d-1)*cars + (1:cars);
            base = entry + spacing*(0:cars-1);
            lateral = lane + lat_offset;
            oppos = -fliplr(base) - tgt_offset - dir_shift*(d-1);
            switch d
                case 1
                    position(:,idx) = [base; -lateral];
                    target(:,idx) = [oppos; -lane*ones(1,cars)];
                case 2
                    position(:,idx) = [lateral; base];
                    target(:,idx) = [lane*ones(1,cars); oppos];
                case 3
                    position(:,idx) = [-base; lateral];
                    target(:,idx) = [-oppos; lane*ones(1,cars)];
                case 4
                    position(:,idx) = [-lateral; -base];
                    target(:,idx) = [-lane*ones(1,cars); -oppos];
            end
        end
        description = '4 approaches x 5 cars through one junction';
    else
        cars = 4;
        L = N/(4*cars);
        if L ~= floor(L) || L < 1
            error('tac_build_cross:badSplit', ...
                'N=%d is not 16 times an integer lane count.', N);
        end
        lane_pitch = 1.5*D0;
        car_pitch = 4.0*D0;
        positions = ((1:2*L) - (2*L+1)/2)*lane_pitch;
        entry = (max(positions)-min(positions))/2 + 1.5*D0;
        offset_group = 0.35*D0;
        along_horizontal = entry + offset_group + (0:cars-1)*car_pitch;
        along_vertical = entry - offset_group + (0:cars-1)*car_pitch;

        position = zeros(2,N);
        target = zeros(2,N);
        column = 0;
        for arm = [1 3]
            for lane = 1:L
                if arm == 1, slot = 2*lane; else, slot = 2*lane-1; end
                d = positions(slot);
                columns = column+(1:cars); column = column+cars;
                if arm == 1
                    along = along_horizontal; mirrored = fliplr(along);
                    position(:,columns) = [along; d*ones(1,cars)];
                    target(:,columns) = [-mirrored; d*ones(1,cars)];
                else
                    along = along_horizontal; mirrored = fliplr(along);
                    position(:,columns) = [-along; d*ones(1,cars)];
                    target(:,columns) = [mirrored; d*ones(1,cars)];
                end
            end
        end
        for arm = [2 4]
            for lane = 1:L
                if arm == 2, slot = 2*lane; else, slot = 2*lane-1; end
                d = positions(slot);
                columns = column+(1:cars); column = column+cars;
                if arm == 2
                    along = along_vertical; mirrored = fliplr(along);
                    position(:,columns) = [d*ones(1,cars); along];
                    target(:,columns) = [d*ones(1,cars); -mirrored];
                else
                    along = along_vertical; mirrored = fliplr(along);
                    position(:,columns) = [d*ones(1,cars); -along];
                    target(:,columns) = [d*ones(1,cars); mirrored];
                end
            end
        end
        description = sprintf(['4 approaches x %d interleaved lanes x %d cars, ' ...
            'lane pitch %.2f m, car pitch %.2f m'], L, cars, lane_pitch, car_pitch);
    end

    spatial_scale = 1.0;
    if N == 64 || N == 96 || N == 128
        spatial_scale = 1.5;
    end
    if isfield(opts,'cross_spatial_scale') && ...
            ~isempty(opts.cross_spatial_scale)
        spatial_scale = opts.cross_spatial_scale;
    end
    if spatial_scale ~= 1
        position = spatial_scale*position;
        target = spatial_scale*target;
        description = sprintf('%s, uniform spatial scale %.2f', ...
            description,spatial_scale);
    end

    scenario = struct();
    scenario.mode = "goal";
    scenario.initial_position = position;
    scenario.target = target;
    scenario.seed = NaN;
    scenario.controller = struct('kind', "goal", 'kp', cfg.kp);
    scenario.geometry = struct('arms',4,'cars_per_arm',cars, ...
        'spatial_scale',spatial_scale);
    scenario.description = description;
end
