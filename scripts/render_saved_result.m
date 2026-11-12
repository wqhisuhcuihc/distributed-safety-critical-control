function video_file = render_saved_result(result_file,video_file,anim_opts)
%RENDER_SAVED_RESULT Render a saved result without rerunning the controller.

    if nargin < 2 || isempty(video_file)
        [folder,name] = fileparts(char(result_file));
        video_file = fullfile(folder,[name '.mp4']);
    end
    if nargin < 3 || isempty(anim_opts), anim_opts = {}; end
    video_file = tac_render_result(result_file,video_file,anim_opts);
end
