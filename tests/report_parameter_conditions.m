function T = report_parameter_conditions()
%REPORT_PARAMETER_CONDITIONS Print the common parameter and condition table.

    this_dir = fileparts(mfilename('fullpath'));
    root = this_dir;
    if exist(fullfile(root,'config'),'dir') ~= 7
        root = fileparts(this_dir);
    end
    addpath(genpath(root),'-begin');
    scales = [20 32 64 96 128];
    T = table();
    for N = scales
        cfg = tac_parameter_set(N);
        audit = tac_validate_conditions(cfg,[], ...
            struct('run_mode','diagnostic'));
        row = table(N,audit.Nc,cfg.D0,cfg.D,cfg.R,cfg.v_bar, ...
            cfg.v_check,cfg.alpha,cfg.e_design,cfg.M,cfg.dt, ...
            audit.condition_margin(1),audit.condition_margin(2), ...
            audit.condition_margin(3),audit.condition_margin(4), ...
            'VariableNames',{'N','Nc','D0','D','R','v_bar','v_check','alpha', ...
            'e_design','M','dt','margin_Nc','margin_D', ...
            'margin_R','margin_v'});
        T = [T; row]; %#ok<AGROW>
    end
    disp(T);
end
