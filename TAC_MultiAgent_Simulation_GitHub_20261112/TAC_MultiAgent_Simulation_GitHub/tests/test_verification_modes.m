function test_verification_modes()
%TEST_VERIFICATION_MODES Verify 10 ms and strict 1 ms workflow behavior.

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(root),'-begin');
    temp_root = tempname;
    mkdir(temp_root);
    cleanup = onCleanup(@() rmdir(temp_root,'s'));

    modes = ["10ms","1ms"];
    expected = [0.01,0.001];
    for k = 1:numel(modes)
        opts = tac_default_options();
        opts.Time = 0.02;
        opts.verification_mode = modes(k);
        opts.compute_reference = false;
        opts.save_raw = false;
        result = run_TAC_experiment(20,'cross',opts);
        interval = median(diff(result.time_record));
        assert(abs(interval-expected(k)) < 1e-10, ...
            'Unexpected record interval for %s.',modes(k));
        assert(string(result.metadata.verification_mode) == modes(k));
    end

    [result,audit] = run_TAC_workflow( ...
        20,'cross',"1ms",temp_root,struct('Time',0.02));
    assert(audit.sample_interval == 0.001);
    assert(size(audit.e_record,1) == 20);
    assert(size(audit.e_record,2) == numel(result.time_record));
    assert(numel(fieldnames(audit)) == 23);
    fprintf('verification mode tests passed\n');
end
