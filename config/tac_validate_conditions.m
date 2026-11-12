function audit = tac_validate_conditions(cfg, initial_minimum, opts)
%TAC_VALIDATE_CONDITIONS Evaluate all common paper conditions identically.

    if nargin < 2, initial_minimum = []; end
    if nargin < 3 || isempty(opts), opts = struct(); end
    if ~isfield(opts, 'run_mode') || isempty(opts.run_mode)
        opts.run_mode = "formal";
    end

    n = cfg.n;
    Nc = cfg.N; % Conservative maximum-scale interpretation of N_c.
    nc_term = cfg.alpha*(cfg.D-cfg.D0)*(Nc-1)/2;
    m1_lo = nc_term;
    m1_mid = cfg.v_check-nc_term;
    m1_outer = cfg.v_bar-cfg.v_check;
    mNc = min([m1_lo,m1_mid,m1_outer]);
    m119 = cfg.alpha*cfg.D ...
        - (cfg.alpha*cfg.D0 ...
        + 4*cfg.alpha*sqrt(n)*cfg.v_bar*cfg.dt ...
        + 16*n*cfg.v_check*cfg.v_bar*cfg.dt/cfg.D0 ...
        + 2*cfg.e_design);
    m120 = cfg.R - (cfg.D0 + 4*sqrt(n)*cfg.v_bar*cfg.dt);
    m121 = (cfg.v_bar - cfg.e_design) - cfg.v_check;
    required_initial = cfg.D0 + 2*sqrt(n)*cfg.v_bar*cfg.dt;

    audit = struct();
    audit.Nc = Nc;
    audit.condition_detail = struct('Nc_term',nc_term, ...
        'v_check_minus_Nc_term',m1_mid,'v_bar_minus_v_check',m1_outer);
    audit.condition_margin = [mNc m119 m120 m121];
    audit.required_initial = required_initial;
    audit.initial_minimum = initial_minimum;
    audit.conditions_ok = all(audit.condition_margin > 0);
    if isempty(initial_minimum)
        audit.initial_ok = true;
    else
        audit.initial_ok = initial_minimum >= required_initial;
    end
    audit.all_ok = audit.conditions_ok && audit.initial_ok;
    audit.run_mode = string(opts.run_mode);
    audit.paper_valid = audit.all_ok && audit.run_mode == "formal";

    if ~audit.all_ok && audit.run_mode == "formal"
        error('tac_validate_conditions:infeasible', ...
            ['Formal configuration failed: updated margins=[%.9g %.9g %.9g %.9g], ' ...
             'initial=%.6g, required=%.6g.'], ...
            audit.condition_margin(1),audit.condition_margin(2), ...
            audit.condition_margin(3),audit.condition_margin(4), ...
            audit.initial_minimum,audit.required_initial);
    end
end
