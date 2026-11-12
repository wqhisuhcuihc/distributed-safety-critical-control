function output_file = tac_save_result(result,output_root,tag)
%TAC_SAVE_RESULT Save one canonical raw result before any rendering work.

    if exist(output_root,'dir') ~= 7
        mkdir(output_root);
    end
    output_file = fullfile(output_root,[char(tag) '_result.mat']);
    save(output_file,'result','-v7.3');
end
