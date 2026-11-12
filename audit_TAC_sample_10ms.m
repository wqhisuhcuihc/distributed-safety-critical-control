function audit = audit_TAC_sample_10ms(source_file,output_file)
%AUDIT_TAC_SAMPLE_10MS Compatibility wrapper for the 10 ms mode.

    if nargin < 2, output_file = ''; end
    audit = audit_TAC_saved_states(source_file,output_file,"10ms");
end
