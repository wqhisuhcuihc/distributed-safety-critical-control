function root = add_tac_paths()
%ADD_TAC_PATHS Add this repository to the MATLAB path.

    root = fileparts(mfilename('fullpath'));
    addpath(genpath(root),'-begin');
    fprintf('TAC simulation repository added: %s\n',root);
end
