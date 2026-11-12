function tac_concat_video_parts(part_folder,nparts,out_file,prefix)
%TAC_CONCAT_VIDEO_PARTS Concatenate independently rendered MP4 slices.

    writer = VideoWriter(out_file,'MPEG-4');
    writer.FrameRate = 25;
    writer.Quality = 75;
    open(writer);
    cleanup = onCleanup(@() close_writer(writer));
    total = 0;
    for part = 1:nparts
        f = fullfile(part_folder,sprintf('%s_part%02d.mp4',prefix,part));
        if exist(f,'file') ~= 2
            error('tac_concat_video_parts:missing','Missing %s.',f);
        end
        v = VideoReader(f);
        while hasFrame(v)
            writeVideo(writer,readFrame(v));
            total = total + 1;
        end
    end
    close(writer);
    fprintf('concatenated %d frames -> %s\n',total,out_file);
end

function close_writer(writer)
    if isvalid(writer)
        try, close(writer); catch, end
    end
end
