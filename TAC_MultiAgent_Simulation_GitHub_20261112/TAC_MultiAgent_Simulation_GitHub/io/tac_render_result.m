function video_file = tac_render_result(result_or_file,video_file,anim_opts)
%TAC_RENDER_RESULT Render a saved result without rerunning the controller.

    if nargin < 2 || isempty(video_file)
        error('tac_render_result:output','A video path is required.');
    end
    if nargin < 3 || isempty(anim_opts), anim_opts = {}; end
    if ischar(result_or_file) || isstring(result_or_file)
        result = tac_load_result(char(result_or_file));
    else
        result = result_or_file;
    end
    frame_interval = 0.01;
    if numel(result.time_record) >= 2
        frame_interval = median(diff(result.time_record));
    end
    video_file = tac_animate_agent_trajectory(result.trajectory_record, ...
        result.N,result.D0/2,result.R-result.D0,result.target, ...
        'video_file',video_file,'frame_interval',frame_interval, ...
        'visible','off',anim_opts{:});
end
