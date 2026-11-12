function run_all_tests()
%RUN_ALL_TESTS Run the fast public test suite.

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(root),'-begin');
    verify_N128_setup();
    test_verification_modes();
    test_unified_smoke();
    report_parameter_conditions();
    fprintf('\nAll public tests completed successfully.\n');
end
