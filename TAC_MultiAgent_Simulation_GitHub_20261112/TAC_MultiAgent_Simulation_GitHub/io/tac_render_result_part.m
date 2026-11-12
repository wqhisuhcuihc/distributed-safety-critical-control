function part_file = tac_render_result_part(result_file,part,nparts, ...
    max_frames,out_folder,prefix,plot_width)
%TAC_RENDER_RESULT_PART Render one isolated slice of a saved result.

    if nargin < 7 || isempty(plot_width), plot_width = 480; end
    result = tac_load_result(char(result_file));
    F = size(result.trajectory_record,3);
    edges = round(linspace(1,F+1,nparts+1));
    idx = edges(part):edges(part+1)-1;
    if isempty(idx), error('tac_render_result_part:empty','Empty slice.'); end
    if exist(out_folder,'dir') ~= 7, mkdir(out_folder); end
    part_file = fullfile(out_folder,sprintf('%s_part%02d.mp4',prefix,part));
    all_x = [reshape(result.trajectory_record(1,:,:),1,[]),result.target(1,:)];
    all_y = [reshape(result.trajectory_record(2,:,:),1,[]),result.target(2,:)];
    span = max(max(all_x)-min(all_x),max(all_y)-min(all_y));
    pad = max(result.D0,0.05*span);
    limits = [min(all_x)-pad,max(all_x)+pad; ...
              min(all_y)-pad,max(all_y)+pad];
    frame_interval = median(diff(result.time_record));
    history = result.trajectory_record(:,:,1:idx(1)-1);
    tac_animate_agent_trajectory(result.trajectory_record(:,:,idx), ...
        result.N,result.D0/2,result.R-result.D0,result.target, ...
        'video_file',part_file,'frame_interval',frame_interval, ...
        'max_frames',max_frames,'plot_width',plot_width, ...
        'visible','off','axis_limits',limits,'trail_history',history);
end
