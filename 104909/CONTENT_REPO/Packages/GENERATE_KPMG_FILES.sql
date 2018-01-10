CREATE OR REPLACE PACKAGE content_repo."GENERATE_KPMG_FILES"
is
    PROCEDURE generate_all_files (regenrate_flag NUMBER, dir_i varchar2);
    procedure perform_datachecks;
    procedure load_data(extract_date_i date);
    procedure load_generate_all_files(extract_date_i date, dir_i varchar2, regenarate number);
    --PROCEDURE generate_zip_pt;
    procedure generate_temp_tables;
end;
/