function [opts, verification] = tac_apply_verification_mode(opts)
%TAC_APPLY_VERIFICATION_MODE Select 10 ms or strict 1 ms persistence.

    mode = lower(string(opts.verification_mode));
    switch mode
        case "10ms"
            sample_interval = 0.010;
            record_stride = 10;
        case "1ms"
            sample_interval = 0.001;
            record_stride = 1;
        otherwise
            error('tac_apply_verification_mode:mode', ...
                ['verification_mode must be "10ms" or "1ms" ' ...
                 '(got "%s").'],mode);
    end

    opts.verification_mode = mode;
    opts.sample_interval = sample_interval;
    opts.record_stride = record_stride;
    verification = struct( ...
        'mode',mode, ...
        'sample_interval',sample_interval, ...
        'record_stride',record_stride);
end
