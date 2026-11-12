function output_files = tac_plot_paper_figures( ...
    data_file,audit_file,output_dir,options)
%TAC_PLOT_PAPER_FIGURES Export four paper-style result figures.
%
% output_files = tac_plot_paper_figures(data_file,audit_file,output_dir)
% output_files = tac_plot_paper_figures(...,options)
%
% The four figures are:
%   1. minimum inter-agent distance;
%   2. maximum control component (speed infinity norm);
%   3. iteration error;
%   4. largest connected communication component.
%
% The default "aggregate" mode takes the safety-relevant global extremum at
% every time.  Set options.curve_mode="per_agent" to reproduce the original
% six-agent paper figures with one curve per agent.

    if nargin < 2 || isempty(audit_file)
        error('tac_plot_paper_figures:audit', ...
            'The matching audit result file is required.');
    end
    if nargin < 3 || isempty(output_dir)
        [folder,name] = fileparts(char(data_file));
        output_dir = fullfile(folder,[name '_figures']);
    end
    if nargin < 4 || isempty(options), options = struct(); end

    curve_mode = get_option(options,'curve_mode',"aggregate");
    show_legend = get_option(options,'show_legend',[]);
    export_formats = get_option(options,'formats',"png");
    export_formats = lower(string(export_formats));

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(root),'-begin');
    raw = tac_load_result(char(data_file));
    A = load(char(audit_file),'audit');
    if ~isfield(A,'audit')
        error('tac_plot_paper_figures:auditFormat', ...
            'No audit variable found in %s.',audit_file);
    end
    audit_result = A.audit;

    assert(raw.N == audit_result.N, ...
        'Raw and audit files have different agent counts.');
    sample_count = numel(raw.time_record);
    assert(isequal(size(raw.trajectory_record),[2,raw.N,sample_count]), ...
        'Unexpected trajectory_record dimensions.');
    assert(isequal(size(audit_result.e_record),[raw.N,sample_count]), ...
        'Audit e_record does not match the saved time grid.');

    if ~exist(output_dir,'dir'), mkdir(output_dir); end
    time = double(raw.time_record(:).');
    final_time = time(end);

    distance = double(raw.nearest_record);
    speed_component = double(raw.control_record);
    error_curve = double(audit_result.e_record);
    max_component = double(raw.component_record(:).');

    if curve_mode == "aggregate"
        distance = min(distance,[],1);
        speed_component = max(speed_component,[],1);
        error_curve = max(error_curve,[],1);
    elseif curve_mode ~= "per_agent"
        error('tac_plot_paper_figures:mode', ...
            'curve_mode must be "aggregate" or "per_agent".');
    end

    if isempty(show_legend)
        show_legend = curve_mode == "per_agent" && size(distance,1) <= 8;
    end
    curves = struct( ...
        'data',{distance,speed_component,error_curve,max_component}, ...
        'bound',{raw.D0,raw.v_bar,NaN,NaN}, ...
        'kind',{"bound_low","bound","free","free"}, ...
        'name',{"curve1_minimum_distance", ...
                "curve2_maximum_speed", ...
                "curve3_iteration_error", ...
                "curve4_maximum_component"});

    prefix = sprintf('N%d_%s',raw.N,raw.scenario_name);
    output_files = strings(1,numel(curves)*numel(export_formats));
    file_index = 0;
    for k = 1:numel(curves)
        fig = make_reference_figure(curves(k).data,time,final_time, ...
            curves(k).kind,curves(k).bound,show_legend);
        try
            for format = export_formats
                file_index = file_index+1;
                output_files(file_index) = string(fullfile(output_dir, ...
                    sprintf('%s_%s.%s',prefix,curves(k).name,format)));
                save_paper_figure(fig,char(output_files(file_index)),1024,768);
            end
        catch exception
            close_if_valid(fig);
            rethrow(exception);
        end
        close_if_valid(fig);
    end
end

function fig = make_reference_figure( ...
    curve_data,time,final_time,kind,bound,show_legend)
%MAKE_REFERENCE_FIGURE Reproduce the plotting style used in the paper.

    width_px = 1024;
    height_px = 768;
    fig = figure('Color','w','Visible','off','Units','pixels', ...
        'Position',[50 50 width_px height_px], ...
        'Renderer','painters','InvertHardcopy','off');
    ax = axes('Parent',fig,'Units','normalized', ...
        'Position',[0.060 0.058 0.921 0.903]);
    hold(ax,'on');

    curve_count = size(curve_data,1);
    colors = parula(curve_count);
    if curve_count == 1
        colors = [0 0.4470 0.7410];
    end
    handles = gobjects(curve_count,1);
    for i = 1:curve_count
        handles(i) = plot(ax,time,curve_data(i,:), ...
            'Color',colors(i,:),'LineWidth',1.5);
    end

    if isfinite(bound)
        plot(ax,[0 final_time],[bound bound],'r--','LineWidth',2.0);
    end

    set(ax,'Box','on','LineWidth',2.0,'FontSize',18, ...
        'FontWeight','normal','TickDir','in','TickLength',[0.012 0.025], ...
        'Layer','top','XMinorTick','off','YMinorTick','off');
    grid(ax,'off');
    xlim(ax,[0 final_time]);
    set_time_ticks(ax,final_time);

    finite_values = curve_data(isfinite(curve_data));
    switch kind
        case 'bound'
            if isempty(finite_values)
                upper_limit = 1.1*max(bound,1);
            else
                upper_limit = 1.1*max([finite_values(:);bound]);
            end
            ylim(ax,[0 upper_limit]);
        case 'bound_low'
            if isempty(finite_values)
                upper_limit = 1.1*max(bound,1);
            else
                upper_limit = 1.1*max([finite_values(:);bound]);
            end
            ylim(ax,[0.95*bound upper_limit]);
        case 'free'
            if isempty(finite_values)
                upper_limit = 1;
            else
                upper_limit = max(1.05*max(finite_values),eps);
            end
            ylim(ax,[0 upper_limit]);
    end

    if show_legend
        labels = arrayfun(@(k) sprintf('Agent%d',k), ...
            1:curve_count,'UniformOutput',false);
        legend(ax,handles,labels,'Location','northeast', ...
            'FontSize',10,'Box','on','Interpreter','none');
    else
        legend(ax,'off');
    end
    hold(ax,'off');
end

function set_time_ticks(ax,final_time)
    if final_time <= 40
        tick_step = 5;
    elseif final_time <= 80
        tick_step = 10;
    elseif final_time <= 160
        tick_step = 20;
    else
        tick_step = 50;
    end
    xticks(ax,0:tick_step:final_time);
end

function save_paper_figure(fig,filename,width_px,height_px)
    dpi = 96;
    set(fig,'PaperUnits','inches','PaperPositionMode','manual', ...
        'PaperPosition',[0 0 width_px/dpi,height_px/dpi], ...
        'PaperSize',[width_px/dpi,height_px/dpi]);
    if exist(filename,'file') == 2, delete(filename); end
    print(fig,filename,'-dpng',sprintf('-r%d',dpi));
end

function close_if_valid(fig)
    if ~isempty(fig) && isgraphics(fig)
        close(fig);
    end
end

function value = get_option(options,name,default_value)
    if isfield(options,name) && ~isempty(options.(name))
        value = options.(name);
    else
        value = default_value;
    end
end
