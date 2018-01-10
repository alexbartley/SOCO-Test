CREATE OR REPLACE PROCEDURE content_repo.osr_extract_tmp
(
    stcode_i   VARCHAR2,
    start_dt_i DATE,
    tag_grp_i  NUMBER
)
IS

    user_i     NUMBER := -204;
    l_stcode   VARCHAR2(2 CHAR) := CASE WHEN stcode_i IS NULL THEN 'AS' ELSE stcode_i END;
    l_pid      NUMBER := gis_etl_process_log_sq.nextval;

    CURSOR states IS
        SELECT state_code, NAME state_name
        FROM   geo_states
        WHERE  state_code NOT IN ('AA', 'AE', 'AP', 'AS', 'FM', 'MH', 'MP', 'PW', 'VI') -- exclude territories
            AND (state_code = stcode_i
                 OR stcode_i IS NULL
                )
        ORDER BY state_code;

BEGIN
    gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>'generate_osr_rate_file', paction=>0, puser=>user_i);

    -- Determine the location of the STJs --
    osr_rate_extract.build_osr_spd_basic(l_stcode, l_pid, user_i);

    -- Determine the jurisdictions by tag group --
    osr_rate_extract.get_tag_data(l_stcode, l_pid, user_i, tag_grp_i);   -- 01/13/17

    -- Extract the Peferred Mailing City --
    osr_rate_extract.extract_preferred_city(l_stcode, l_pid, user_i);


    -- Loop through specific state --
    FOR s IN states LOOP
        -- Determine the zip data for the given state --
        osr_rate_extract.determine_zip_data(s.state_code, l_pid, user_i, tag_grp_i);

        -- Determine the zip4 data for the given state --
        osr_rate_extract.determine_zip4_data(s.state_code, l_pid, user_i);

        -- Populate the Rate staging table --
        osr_rate_extract.populate_osr_rates(s.state_code, l_pid, user_i, start_dt_i);

        -- Check for duplicate Zip records -- crapp-3153
        osr_rate_extract.datacheck_zip_dupes(s.state_code, l_pid, user_i);

        -- Export the rate files --
        osr_rate_extract.extract_rate_files(s.state_code, l_pid, user_i);
    END LOOP;


    -- Export the ALL State rate files --
    IF stcode_i IS NULL THEN
        -- Single All State File --
        osr_rate_extract.extract_rate_files('AS', l_pid, user_i);
    END IF;

    gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>'generate_osr_rate_file', paction=>1, puser=>user_i);
END osr_extract_tmp;
/