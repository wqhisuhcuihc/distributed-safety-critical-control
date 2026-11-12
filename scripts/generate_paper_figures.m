function summary = generate_paper_figures( ...
    fleet_sizes,scenario_names,data_root,output_root,options)
%GENERATE_PAPER_FIGURES Export four paper-style figures per scenario.
%
% summary = generate_paper_figures([20 32],["cross","rings4"], ...
%     "path/to/final25_data","paper_results");
%
% Each scenario directory must contain one raw "*_data_result.mat" file and
% one matching "*_audit_result.mat" file.

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(root),'-begin');
    if nargin < 1 || isempty(fleet_sizes), fleet_sizes = [20 32]; end
    if nargin < 2 || isempty(scenario_names)
        scenario_names = ["cross","rings4"];
    end
    if nargin < 3 || isempty(data_root)
        error('generate_paper_figures:dataRoot', ...
            'A data root containing Nxx_scenario directories is required.');
    end
    if nargin < 4 || isempty(output_root)
        output_root = fullfile(root,'paper_results','figures');
    end
    if nargin < 5 || isempty(options), options = struct(); end

    scenario_names = string(scenario_names);
    summary = struct('N',{},'scenario',{},'output_dir',{},'files',{});
    for N = fleet_sizes
        for scenario_name = scenario_names
            source_dir = fullfile(data_root, ...
                sprintf('N%d_%s',N,scenario_name));
            data_item = dir(fullfile(source_dir,'*data_result.mat'));
            audit_item = dir(fullfile(source_dir,'*audit_result.mat'));
            if numel(data_item) ~= 1
                error('generate_paper_figures:rawCount', ...
                    'Expected one data result in %s, found %d.', ...
                    source_dir,numel(data_item));
            end
            if numel(audit_item) ~= 1
                error('generate_paper_figures:auditCount', ...
                    'Expected one audit result in %s, found %d.', ...
                    source_dir,numel(audit_item));
            end

            case_name = sprintf('N%d_%s',N,scenario_name);
            output_dir = fullfile(output_root,case_name);
            fprintf('\n=== paper figures: %s ===\n',case_name);
            files = tac_plot_paper_figures( ...
                fullfile(source_dir,data_item(1).name), ...
                fullfile(source_dir,audit_item(1).name), ...
                output_dir,options);

            row = numel(summary)+1;
            summary(row).N = N;
            summary(row).scenario = scenario_name;
            summary(row).output_dir = string(output_dir);
            summary(row).files = files;
        end
    end
end
