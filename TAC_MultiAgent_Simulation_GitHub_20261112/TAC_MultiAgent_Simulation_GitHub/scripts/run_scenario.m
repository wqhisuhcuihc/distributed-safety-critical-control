function [result,audit] = run_scenario(N,scenario_name,verification_mode,output_root,options)
%RUN_SCENARIO Generate one scenario and audit its saved states.

    if nargin < 3 || isempty(verification_mode)
        verification_mode = "10ms";
    end
    if nargin < 4, output_root = []; end
    if nargin < 5 || isempty(options), options = struct(); end
    [result,audit] = run_TAC_workflow( ...
        N,scenario_name,verification_mode,output_root,options);
end
