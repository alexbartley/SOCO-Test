CREATE OR REPLACE PACKAGE content_repo."OSR_RATE_EXTRACT"
IS
    PROCEDURE datacheck_zip_dupes(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);

    PROCEDURE datacheck_file_counts(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);   -- crapp-3329

    PROCEDURE datacheck_rate_amounts(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);  -- crapp-3456

    PROCEDURE datacheck_state_rates(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);   -- crapp-4167

    PROCEDURE build_osr_spd_basic(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);

    PROCEDURE get_tag_data(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);   -- 01/13/17

    PROCEDURE extract_preferred_city(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);  -- 12/08/16

    PROCEDURE determine_zip_data(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);

    PROCEDURE determine_zip4_data(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER); -- 01/13/17

    PROCEDURE get_rates(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER, start_dt_i IN DATE);

    PROCEDURE populate_osr_rates(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER, start_dt_i IN DATE);    -- crapp-4170, added start_dt_i

    PROCEDURE extract_rate_files(stcode_i IN VARCHAR2, pID_i IN NUMBER, user_i IN NUMBER);

    PROCEDURE generate_osr_rate_file(stcode_i IN VARCHAR2, user_i IN NUMBER, start_dt_i IN DATE, tag_grp_i  IN NUMBER);
END OSR_RATE_EXTRACT;
/