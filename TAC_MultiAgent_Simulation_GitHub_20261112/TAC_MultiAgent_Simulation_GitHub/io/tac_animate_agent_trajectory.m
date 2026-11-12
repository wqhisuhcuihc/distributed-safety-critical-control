function video_file = tac_animate_agent_trajectory(trajectory,N, ...
    agent_radius,wifi_distance,targets,varargin)
%TAC_ANIMATE_AGENT_TRAJECTORY Shared independent renderer.

    p = inputParser;
    p.addParameter('video_file','');
    p.addParameter('frame_interval',0.01);
    p.addParameter('fps',25);
    p.addParameter('max_frames',1500);
    p.addParameter('plot_width',640);
    p.addParameter('quality',75);
    p.addParameter('visible','off');
    p.addParameter('axis_limits',[]);
    p.addParameter('trail_history',zeros(2,N,0));
    p.parse(varargin{:});
    o = p.Results;
    video_file = char(o.video_file);
    if ~isnumeric(o.trail_history) || size(o.trail_history,1) ~= 2 || ...
            size(o.trail_history,2) ~= N
        error('trail_history must be a 2-by-%d-by-H numeric array.',N);
    end

    F = size(trajectory,3);
    real_step = max(1,round(1/(o.fps*o.frame_interval)));
    budget_step = ceil(F/max(1,o.max_frames));
    frame_step = max(real_step,budget_step);
    frame_indices = 1:frame_step:F;
    sampled = trajectory(:,:,frame_indices);
    sampled_x = reshape(sampled(1,:,:),N,[]);
    sampled_y = reshape(sampled(2,:,:),N,[]);
    history_x = reshape(o.trail_history(1,:,:),N,[]);
    history_y = reshape(o.trail_history(2,:,:),N,[]);
    all_x = [sampled_x(:).',targets(1,:)];
    all_y = [sampled_y(:).',targets(2,:)];
    if isempty(o.axis_limits)
        span = max(max(all_x)-min(all_x),max(all_y)-min(all_y));
        pad = max(2*agent_radius,0.05*span);
        x_limits = [min(all_x)-pad,max(all_x)+pad];
        y_limits = [min(all_y)-pad,max(all_y)+pad];
    else
        x_limits = o.axis_limits(1,:);
        y_limits = o.axis_limits(2,:);
    end
    span = max(max(all_x)-min(all_x),max(all_y)-min(all_y));
    scene_aspect = diff(y_limits)/max(diff(x_limits),eps);
    margin = 25;
    plot_width = o.plot_width;
    plot_height = round(plot_width*scene_aspect);
    figure_width = plot_width+2*margin;
    figure_height = plot_height+2*margin;
    fig = figure('Visible',o.visible,'Color','w', ...
        'Position',[100 100 figure_width figure_height], ...
        'Resize','off','Name',sprintf('%d-agent trajectory animation',N));
    ax = axes('Parent',fig,'Position', ...
        [margin/figure_width,margin/figure_height, ...
         plot_width/figure_width,plot_height/figure_height]);
    hold(ax,'on');
    axis(ax,'equal');
    box(ax,'on');
    xlim(ax,x_limits);
    ylim(ax,y_limits);
    set(ax,'XTick',[],'YTick',[],'XTickLabel',[],'YTickLabel',[], ...
        'XGrid','off','YGrid','off','XColor',[0 0 0],'YColor',[0 0 0], ...
        'LineWidth',1.5,'FontSize',12);
    colors = parula(N);
    relative_radius = 2*agent_radius/max(span,eps);
    marker_size = min(26,max(8,relative_radius*150));
    hTrail = gobjects(1,N); hAgent = gobjects(1,N); hTarget = gobjects(1,N);
    for i = 1:N
        hTrail(i) = plot(ax,NaN,NaN,'--','Color',colors(i,:), ...
            'LineWidth',1.2);
        hAgent(i) = plot(ax,NaN,NaN,'o','Color',colors(i,:), ...
            'MarkerFaceColor',colors(i,:),'MarkerSize',marker_size);
        hTarget(i) = plot(ax,targets(1,i),targets(2,i),'x', ...
            'Color',colors(i,:),'MarkerSize',10,'LineWidth',1.8);
    end
    communication_distance = 2*agent_radius+wifi_distance;
    hLink = plot(ax,NaN,NaN,':','Color',[0 0 0],'LineWidth',1.5);

    writer = [];
    if ~isempty(video_file)
        folder = fileparts(video_file);
        if ~isempty(folder) && exist(folder,'dir') ~= 7, mkdir(folder); end
        writer = VideoWriter(video_file,'MPEG-4');
        writer.FrameRate = o.fps;
        writer.Quality = o.quality;
        open(writer);
    end
    cleanup = onCleanup(@() clean_writer(writer));

    for j = 1:size(sampled,3)
        current = sampled(:,:,j);
        for i = 1:N
            set(hTrail(i),'XData',[history_x(i,:),sampled_x(i,1:j)], ...
                'YData',[history_y(i,:),sampled_y(i,1:j)]);
            set(hAgent(i),'XData',current(1,i),'YData',current(2,i));
        end
        d = tac_pairwise_distance(current);
        d(1:N+1:end) = inf;
        [ii,jj] = find(triu(d <= communication_distance,1));
        if isempty(ii)
            lx = NaN; ly = NaN;
        else
            lx = zeros(1,3*numel(ii)); ly = zeros(1,3*numel(ii));
            lx(1:3:end) = current(1,ii);
            lx(2:3:end) = current(1,jj);
            lx(3:3:end) = NaN;
            ly(1:3:end) = current(2,ii);
            ly(2:3:end) = current(2,jj);
            ly(3:3:end) = NaN;
        end
        set(hLink,'XData',lx,'YData',ly);
        drawnow;
        if ~isempty(writer)
            frame = getframe(fig);
            frame.cdata = frame.cdata(1:2*floor(end/2),1:2*floor(end/2),:);
            writeVideo(writer,frame);
        end
    end
    if ~isempty(writer), close(writer); end
    if strcmp(o.visible,'off') && isgraphics(fig), close(fig); end
end

function clean_writer(writer)
    if ~isempty(writer) && isvalid(writer)
        try, close(writer); catch, end
    end
end
