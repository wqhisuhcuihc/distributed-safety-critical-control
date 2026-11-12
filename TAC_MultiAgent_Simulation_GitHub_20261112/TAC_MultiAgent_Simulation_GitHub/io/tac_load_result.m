function result = tac_load_result(result_file)
%TAC_LOAD_RESULT Load a result file produced by tac_save_result.

    S = load(result_file);
    if isfield(S,'result')
        result = S.result;
    elseif isfield(S,'r')
        result = S.r;
    else
        error('tac_load_result:format','No result variable in %s.',result_file);
    end
end
