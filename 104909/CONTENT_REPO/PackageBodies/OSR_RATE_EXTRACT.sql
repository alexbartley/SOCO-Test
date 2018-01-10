CREATE OR REPLACE PACKAGE BODY content_repo."OSR_RATE_EXTRACT"
IS

    -- ************************************************************************ --
    -- Datacheck to look for duplicate Zip records before generating Rate Files --
    -- ************************************************************************ --
    PROCEDURE datacheck_zip_dupes   -- crapp-3153
    (
        stcode_i IN VARCHAR2,
        pID_i    IN NUMBER,
        user_i   IN NUMBER
    )
    IS
        l_cnt       NUMBER;
        zipdupe_exp EXCEPTION;
    BEGIN
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_zip_dupes', paction=>0, puser=>user_i);

        SELECT COUNT(1)
        INTO  l_cnt
        FROM (
              SELECT state_code, zip_code, county_name, city_name, default_flag, COUNT(DISTINCT zip_code) cnt   -- 03/31/17 added distinct
              FROM   osr_as_complete_plus_tmp
              WHERE  state_code = stcode_i
              GROUP BY state_code, zip_code, county_name, city_name, default_flag
              HAVING COUNT(DISTINCT zip_code) > 1
             );

        IF l_cnt > 0 THEN
            dbms_output.put_line('There are duplicate Zip records in OSR_AS_COMPLETE_PLUS_TMP for '||stcode_i);
            RAISE zipdupe_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_zip_dupes', paction=>1, puser=>user_i);

        EXCEPTION WHEN zipdupe_exp THEN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - There are duplicate Zip records in OSR_AS_COMPLETE_PLUS_TMP for '||stcode_i, paction=>3, puser=>user_i);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_zip_dupes', paction=>1, puser=>user_i);
            errlogger.report_and_stop(2004,'ONESOURCE Rate Extract generted duplicate Zip records for '||stcode_i||'- osr_as_complete_plus_tmp');
    END datacheck_zip_dupes;



    -- ***************************************************************** --
    -- Datacheck to determine record count before generating Rate Files  --
    -- ***************************************************************** --
    -- File record counts between below sets of files should be the same --
    --      Basic / Expanded / Basic+ / Expanded+                        --
    --      BasicII / Complete                                           --
    --      BasicII+ / Complete+                                         --
    -- ***************************************************************** --
    PROCEDURE datacheck_file_counts   -- 07/19/17 logic change
    (
        stcode_i IN VARCHAR2,
        pID_i    IN NUMBER,
        user_i   IN NUMBER
    )
    IS
        l_cnt1    NUMBER;
        l_cnt2    NUMBER;
        l_cnt3    NUMBER;
        l_msg     VARCHAR2(50 CHAR);
        filecount_exp EXCEPTION;
    BEGIN
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_file_counts', paction=>0, puser=>user_i);

        -- Basic / Expanded / Basic+ / Expanded+ --
        WITH basic AS
            (
             SELECT DISTINCT
                    zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , county_sales_tax
                    , county_use_tax
                    , city_sales_tax
                    , city_use_tax
                    , total_sales_tax
                    , total_use_tax
                    , tax_shipping_alone
                    , tax_shipping_and_handling
             FROM   (
                     SELECT DISTINCT
                            b.zip_code
                            , b.state_code
                            , b.county_name
                            , b.city_name    --NVL(s.city_name, b.city_name) -- crapp-3416, changed
                            , b.acceptable_city                              -- crapp-3416, added
                            , RANK( ) OVER(PARTITION BY b.state_code, b.zip_code, b.county_name ORDER BY b.acceptable_city DESC) acpt_rnk   -- crapp-3416, added
                            , b.state_sales_tax
                            , b.state_use_tax
                            , CASE WHEN TO_NUMBER(b.city_sales_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.county_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                                   ELSE b.county_sales_tax
                              END county_sales_tax
                            , CASE WHEN TO_NUMBER(b.city_use_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.county_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                                   ELSE b.county_use_tax
                              END county_use_tax
                            , CASE WHEN TO_NUMBER(b.city_sales_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.city_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                                   ELSE b.city_sales_tax
                              END city_sales_tax
                            , CASE WHEN TO_NUMBER(b.city_use_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.city_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                                   ELSE b.city_use_tax
                              END city_use_tax
                            , b.total_sales_tax
                            , b.total_use_tax
                            , b.tax_shipping_alone
                            , b.tax_shipping_and_handling
                     FROM   osr_as_complete_plus_tmp b
                            LEFT JOIN (
                                 SELECT DISTINCT
                                        uaid
                                        , zip_code
                                        , state_code
                                        , county_name
                                        , city_name
                                        , TO_NUMBER(mta_sales_tax)
                                            + TO_NUMBER(spd_sales_tax)
                                            + TO_NUMBER(other1_sales_tax)+TO_NUMBER(other2_sales_tax)+TO_NUMBER(other3_sales_tax)+TO_NUMBER(other4_sales_tax) stj_salestax
                                        , TO_NUMBER(mta_use_tax)
                                            + TO_NUMBER(spd_use_tax)
                                            + TO_NUMBER(other1_use_tax)+TO_NUMBER(other2_use_tax)+TO_NUMBER(other3_use_tax)+TO_NUMBER(other4_use_tax) stj_usetax
                                        , acceptable_city -- 07/20/17
                                 FROM   osr_as_complete_plus_tmp
                                 WHERE  state_code = stcode_i
                                        AND default_flag = 'Y'
                                        AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3416, added to exclude cities with (1..n) in the name
                                        --AND city_name = 'UNINCORPORATED' -- 12/08/16, changed to = from <>  -- crapp-3416, removed
                                        --AND acceptable_city = 'N'   -- crapp-3244   -- crapp-3416, removed
                                 ) s ON ( b.state_code = s.state_code
                                          AND b.uaid   = s.uaid
                                          AND b.county_name = s.county_name -- crapp-3416
                                          AND b.city_name   = s.city_name   -- 07/20/17
                                          AND b.zip_code    = s.zip_code
                                        )
                     WHERE  b.state_code = stcode_i
                            AND b.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities - 12/08/16, removed - crapp-3416, added back in
                            AND b.default_flag = 'Y'
                            AND (NOT REGEXP_LIKE(b.city_name, '[0-9]') AND b.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
                            --AND b.acceptable_city = 'N'   -- crapp-3244  -- crapp-3416, removed
                     ORDER BY b.state_code, b.zip_code, b.county_name, b.city_name
                    )
             WHERE acpt_rnk = 1
            ),
            expanded AS
            (
             SELECT DISTINCT
                    zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , county_sales_tax
                    , county_use_tax
                    , city_sales_tax
                    , city_use_tax
                    , mta_sales_tax
                    , mta_use_tax
                    , spd_sales_tax
                    , spd_use_tax
                    , other1_sales_tax
                    , other1_use_tax
                    , other2_sales_tax
                    , other2_use_tax
                    , other3_sales_tax
                    , other3_use_tax
                    , other4_sales_tax
                    , other4_use_tax
                    , total_sales_tax
                    , total_use_tax
                    , county_number
                    , city_number
                    , mta_name
                    , mta_number
                    , spd_name
                    , spd_number
                    , other1_name
                    , other1_number
                    , other2_name
                    , other2_number
                    , other3_name
                    , other3_number
                    , other4_name
                    , other4_number
                    , tax_shipping_alone
                    , tax_shipping_and_handling
             FROM   (
                     SELECT DISTINCT
                            o.zip_code
                            , o.state_code
                            , o.county_name
                            , o.city_name  --NVL(p.city_name, o.city_name)  -- crapp-3416, changed
                            , o.acceptable_city                             -- crapp-3416, added
                            , RANK( ) OVER(PARTITION BY o.state_code, o.zip_code, o.county_name ORDER BY o.acceptable_city DESC) acpt_rnk   -- crapp-3416, added
                            , o.state_sales_tax
                            , o.state_use_tax
                            , o.county_sales_tax
                            , o.county_use_tax
                            , o.city_sales_tax
                            , o.city_use_tax
                            , o.mta_sales_tax
                            , o.mta_use_tax
                            , o.spd_sales_tax
                            , o.spd_use_tax
                            , o.other1_sales_tax
                            , o.other1_use_tax
                            , o.other2_sales_tax
                            , o.other2_use_tax
                            , o.other3_sales_tax
                            , o.other3_use_tax
                            , o.other4_sales_tax
                            , o.other4_use_tax
                            , o.total_sales_tax
                            , o.total_use_tax
                            , o.county_number
                            , o.city_number
                            , o.mta_name
                            , o.mta_number
                            , o.spd_name
                            , o.spd_number
                            , o.other1_name
                            , o.other1_number
                            , o.other2_name
                            , o.other2_number
                            , o.other3_name
                            , o.other3_number
                            , o.other4_name
                            , o.other4_number
                            , o.tax_shipping_alone
                            , o.tax_shipping_and_handling
                     FROM   osr_as_complete_plus_tmp o
                     WHERE  o.state_code = stcode_i
                            AND o.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities - 12/08/16, removed - crapp-3416, added back in
                            AND o.default_flag = 'Y'
                            AND (NOT REGEXP_LIKE(o.city_name, '[0-9]') AND o.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
                            --AND o.acceptable_city = 'N'   -- crapp-3244   -- crapp-3416, removed
                     ORDER BY o.state_code, o.zip_code, o.county_name, o.city_name
             )
             WHERE acpt_rnk = 1
            ),
            basic_plus AS
            (
             SELECT DISTINCT
                    zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , county_sales_tax
                    , county_use_tax
                    , city_sales_tax
                    , city_use_tax
                    , total_sales_tax
                    , total_use_tax
                    , tax_shipping_alone
                    , tax_shipping_and_handling
                    , fips_state
                    , fips_county
                    , fips_city
                    , geocode
                    , MAX(state_effective_date)  state_effective_date   -- 07/19/17
                    , MAX(county_effective_date) county_effective_date  -- 07/19/17
                    , MAX(city_effective_date)   city_effective_date    -- 07/19/17
             FROM   (
                     SELECT DISTINCT
                            bp.zip_code
                            , bp.state_code
                            , bp.county_name
                            , bp.city_name  --NVL(s.city_name, bp.city_name)  -- crapp-3416, changed
                            , bp.acceptable_city                              -- crapp-3416, added
                            , RANK( ) OVER(PARTITION BY bp.state_code, bp.zip_code, bp.county_name ORDER BY bp.acceptable_city DESC) acpt_rnk   -- crapp-3416, added
                            , bp.state_sales_tax
                            , bp.state_use_tax
                            , CASE WHEN TO_NUMBER(bp.city_sales_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.county_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                                   ELSE bp.county_sales_tax
                              END county_sales_tax
                            , CASE WHEN TO_NUMBER(bp.city_use_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.county_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                                   ELSE bp.county_use_tax
                              END county_use_tax
                            , CASE WHEN TO_NUMBER(bp.city_sales_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.city_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                                   ELSE bp.city_sales_tax
                              END city_sales_tax
                            , CASE WHEN TO_NUMBER(bp.city_use_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.city_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                                   ELSE bp.city_use_tax
                              END city_use_tax
                            , bp.total_sales_tax
                            , bp.total_use_tax
                            , bp.tax_shipping_alone
                            , bp.tax_shipping_and_handling
                            , bp.fips_state
                            , bp.fips_county
                            , bp.fips_city
                            , bp.geocode
                            , bp.state_effective_date
                            , bp.county_effective_date
                            , bp.city_effective_date
                     FROM   osr_as_complete_plus_tmp bp
                            LEFT JOIN
                                (
                                 SELECT DISTINCT
                                        uaid
                                        , zip_code
                                        , state_code
                                        , county_name
                                        , city_name
                                        , TO_NUMBER(mta_sales_tax)
                                            + TO_NUMBER(spd_sales_tax)
                                            + TO_NUMBER(other1_sales_tax)+TO_NUMBER(other2_sales_tax)+TO_NUMBER(other3_sales_tax)+TO_NUMBER(other4_sales_tax) stj_salestax
                                        , TO_NUMBER(mta_use_tax)
                                            + TO_NUMBER(spd_use_tax)
                                            + TO_NUMBER(other1_use_tax)+TO_NUMBER(other2_use_tax)+TO_NUMBER(other3_use_tax)+TO_NUMBER(other4_use_tax) stj_usetax
                                        , acceptable_city -- 07/20/17
                                 FROM   osr_as_complete_plus_tmp
                                 WHERE  state_code = stcode_i
                                        AND default_flag = 'Y'
                                        AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3416, added to exclude cities with (1..n) in the name
                                        --AND city_name = 'UNINCORPORATED' -- 12/08/16, changed to = from <>   -- crapp-3416, removed
                                        --AND acceptable_city = 'N'   -- crapp-3244   -- crapp-3416, removed
                                ) s ON ( bp.state_code = s.state_code
                                         AND bp.uaid   = s.uaid
                                         AND bp.county_name = s.county_name -- crapp-3416
                                         AND bp.city_name   = s.city_name   -- 07/20/17
                                         AND bp.zip_code    = s.zip_code
                                       )
                     WHERE  bp.state_code = stcode_i
                            AND bp.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities - 12/08/16, removed - crapp-3416, added back in
                            AND bp.default_flag = 'Y'
                            AND (NOT REGEXP_LIKE(bp.city_name, '[0-9]') AND bp.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
                            --AND bp.acceptable_city = 'N'   -- crapp-3244   -- crapp-3416, removed
                     ORDER BY bp.state_code, bp.zip_code, bp.county_name, bp.city_name
             )
             WHERE acpt_rnk = 1
             GROUP BY -- 07/19/17
                      zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , county_sales_tax
                    , county_use_tax
                    , city_sales_tax
                    , city_use_tax
                    , total_sales_tax
                    , total_use_tax
                    , tax_shipping_alone
                    , tax_shipping_and_handling
                    , fips_state
                    , fips_county
                    , fips_city
                    , geocode
            ),
            expanded_plus AS
            (
             SELECT DISTINCT
                    zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , county_sales_tax
                    , county_use_tax
                    , city_sales_tax
                    , city_use_tax
                    , mta_sales_tax
                    , mta_use_tax
                    , spd_sales_tax
                    , spd_use_tax
                    , other1_sales_tax
                    , other1_use_tax
                    , other2_sales_tax
                    , other2_use_tax
                    , other3_sales_tax
                    , other3_use_tax
                    , other4_sales_tax
                    , other4_use_tax
                    , total_sales_tax
                    , total_use_tax
                    , county_number
                    , city_number
                    , mta_name
                    , mta_number
                    , spd_name
                    , spd_number
                    , other1_name
                    , other1_number
                    , other2_name
                    , other2_number
                    , other3_name
                    , other3_number
                    , other4_name
                    , other4_number
                    , tax_shipping_alone
                    , tax_shipping_and_handling
                    , fips_state
                    , fips_county
                    , fips_city
                    , geocode
                    , mta_geocode
                    , spd_geocode
                    , other1_geocode
                    , other2_geocode
                    , other3_geocode
                    , other4_geocode
                    , geocode_long
                    , MAX(state_effective_date)     state_effective_date    -- 07/19/17
                    , MAX(county_effective_date)    county_effective_date
                    , MAX(city_effective_date)      city_effective_date
                    , MAX(mta_effective_date)       mta_effective_date
                    , MAX(spd_effective_date)       spd_effective_date
                    , MAX(other1_effective_date)    other1_effective_date
                    , MAX(other2_effective_date)    other2_effective_date
                    , MAX(other3_effective_date)    other3_effective_date
                    , MAX(other4_effective_date)    other4_effective_date
                    , county_tax_collected_by
                    , city_tax_collected_by
                    , state_taxable_max
                    , state_tax_over_max
                    , county_taxable_max
                    , county_tax_over_max
                    , city_taxable_max
                    , city_tax_over_max
                    , sales_tax_holiday
                    , sales_tax_holiday_dates
                    , sales_tax_holiday_items
             FROM   (
                     SELECT DISTINCT
                            o.zip_code
                            , o.state_code
                            , o.county_name
                            , o.city_name  --NVL(p.city_name, o.city_name)  -- crapp-3416, changed
                            , o.acceptable_city                             -- crapp-3416, added
                            , RANK( ) OVER(PARTITION BY o.state_code, o.zip_code, o.county_name ORDER BY o.acceptable_city DESC) acpt_rnk   -- crapp-3416, added
                            , o.state_sales_tax
                            , o.state_use_tax
                            , o.county_sales_tax
                            , o.county_use_tax
                            , o.city_sales_tax
                            , o.city_use_tax
                            , o.mta_sales_tax
                            , o.mta_use_tax
                            , o.spd_sales_tax
                            , o.spd_use_tax
                            , o.other1_sales_tax
                            , o.other1_use_tax
                            , o.other2_sales_tax
                            , o.other2_use_tax
                            , o.other3_sales_tax
                            , o.other3_use_tax
                            , o.other4_sales_tax
                            , o.other4_use_tax
                            , o.total_sales_tax
                            , o.total_use_tax
                            , o.county_number
                            , o.city_number
                            , o.mta_name
                            , o.mta_number
                            , o.spd_name
                            , o.spd_number
                            , o.other1_name
                            , o.other1_number
                            , o.other2_name
                            , o.other2_number
                            , o.other3_name
                            , o.other3_number
                            , o.other4_name
                            , o.other4_number
                            , o.tax_shipping_alone
                            , o.tax_shipping_and_handling
                            , o.fips_state
                            , o.fips_county
                            , o.fips_city
                            , o.geocode
                            , o.mta_geocode
                            , o.spd_geocode
                            , o.other1_geocode
                            , o.other2_geocode
                            , o.other3_geocode
                            , o.other4_geocode
                            , o.geocode_long
                            , o.state_effective_date
                            , o.county_effective_date
                            , o.city_effective_date
                            , o.mta_effective_date
                            , o.spd_effective_date
                            , o.other1_effective_date
                            , o.other2_effective_date
                            , o.other3_effective_date
                            , o.other4_effective_date
                            , o.county_tax_collected_by
                            , o.city_tax_collected_by
                            , o.state_taxable_max
                            , o.state_tax_over_max
                            , o.county_taxable_max
                            , o.county_tax_over_max
                            , o.city_taxable_max
                            , o.city_tax_over_max
                            , o.sales_tax_holiday
                            , o.sales_tax_holiday_dates
                            , o.sales_tax_holiday_items
                     FROM   osr_as_complete_plus_tmp o
                     WHERE  o.state_code = stcode_i
                            AND o.default_flag = 'Y'
                            AND o.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities - 12/08/16, removed - crapp-3416, added back in
                            AND (NOT REGEXP_LIKE(o.city_name, '[0-9]') AND o.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
                            --AND o.acceptable_city = 'N'   -- crapp-3244   -- crapp-3416, removed
                     ORDER BY o.state_code, o.zip_code, o.county_name, o.city_name
                   )
             WHERE acpt_rnk = 1
             GROUP BY -- 07/19/17
                    zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , county_sales_tax
                    , county_use_tax
                    , city_sales_tax
                    , city_use_tax
                    , mta_sales_tax
                    , mta_use_tax
                    , spd_sales_tax
                    , spd_use_tax
                    , other1_sales_tax
                    , other1_use_tax
                    , other2_sales_tax
                    , other2_use_tax
                    , other3_sales_tax
                    , other3_use_tax
                    , other4_sales_tax
                    , other4_use_tax
                    , total_sales_tax
                    , total_use_tax
                    , county_number
                    , city_number
                    , mta_name
                    , mta_number
                    , spd_name
                    , spd_number
                    , other1_name
                    , other1_number
                    , other2_name
                    , other2_number
                    , other3_name
                    , other3_number
                    , other4_name
                    , other4_number
                    , tax_shipping_alone
                    , tax_shipping_and_handling
                    , fips_state
                    , fips_county
                    , fips_city
                    , geocode
                    , mta_geocode
                    , spd_geocode
                    , other1_geocode
                    , other2_geocode
                    , other3_geocode
                    , other4_geocode
                    , geocode_long
                    , county_tax_collected_by
                    , city_tax_collected_by
                    , state_taxable_max
                    , state_tax_over_max
                    , county_taxable_max
                    , county_tax_over_max
                    , city_taxable_max
                    , city_tax_over_max
                    , sales_tax_holiday
                    , sales_tax_holiday_dates
                    , sales_tax_holiday_items
            ),
            match AS
            (
            SELECT DISTINCT
                   a.state_code
                   , b.cnt   BASIC
                   , e.cnt   EXPANDED
                   , bp.cnt "BASIC+"
                   , ep.cnt "EXPANDED+"
                   , CASE WHEN b.cnt = e.cnt AND b.cnt = bp.cnt AND b.cnt = ep.cnt THEN 'Match'
                          ELSE 'NoMatch'
                     END file_counts
            FROM osr_as_complete_plus_tmp a
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   basic
                       GROUP BY state_code
                     ) b ON ( a.state_code = b.state_code)
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   expanded
                       GROUP BY state_code
                     ) e ON ( a.state_code = e.state_code)
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   basic_plus
                       GROUP BY state_code
                     ) bp ON ( a.state_code = bp.state_code)
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   expanded_plus
                       GROUP BY state_code
                     ) ep ON ( a.state_code = ep.state_code)
            )
            SELECT COUNT(1) cnt
            INTO   l_cnt1
            FROM   match
            WHERE  file_counts = 'NoMatch';


        -- BasicII / Complete --
        WITH basic_2 AS
            (
            SELECT DISTINCT
                   b.zip_code
                   , b.state_code
                   , b.county_name
                   , b.city_name
                   , b.state_sales_tax
                   , b.state_use_tax
                   , CASE WHEN TO_NUMBER(b.city_sales_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.county_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                          ELSE b.county_sales_tax
                     END county_sales_tax
                   , CASE WHEN TO_NUMBER(b.city_use_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.county_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                          ELSE b.county_use_tax
                     END county_use_tax
                   , CASE WHEN TO_NUMBER(b.city_sales_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.city_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                          ELSE b.city_sales_tax
                    END city_sales_tax
                   , CASE WHEN TO_NUMBER(b.city_use_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(b.city_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                          ELSE b.city_use_tax
                     END city_use_tax
                   , b.total_sales_tax
                   , b.total_use_tax
                   , b.tax_shipping_alone
                   , b.tax_shipping_and_handling
            FROM   osr_as_complete_plus_tmp b
                   JOIN (
                        SELECT DISTINCT
                               uaid
                               ,zip_code
                               ,state_code
                               ,county_name
                               ,city_name
                               ,SUM(TO_NUMBER(mta_sales_tax)
                                   + TO_NUMBER(spd_sales_tax)
                                   + TO_NUMBER(other1_sales_tax)+TO_NUMBER(other2_sales_tax)+TO_NUMBER(other3_sales_tax)+TO_NUMBER(other4_sales_tax)) stj_salestax
                               ,SUM(TO_NUMBER(mta_use_tax)
                                   + TO_NUMBER(spd_use_tax)
                                   + TO_NUMBER(other1_use_tax)+TO_NUMBER(other2_use_tax)+TO_NUMBER(other3_use_tax)+TO_NUMBER(other4_use_tax)) stj_usetax
                        FROM   osr_as_complete_plus_tmp
                        WHERE  state_code = stcode_i
                               AND city_name <> 'UNINCORPORATED'
                               AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3416, added to exclude cities with (1..n) in the name
                        GROUP BY uaid -- crapp-3416, added group by due to SUM
                               ,zip_code
                               ,state_code
                               ,county_name
                               ,city_name
                        ) s ON (     b.state_code  = s.state_code
                                 AND b.county_name = s.county_name  -- crapp-3416, added
                                 AND b.city_name   = s.city_name    -- crapp-3416, added
                                 AND b.zip_code    = s.zip_code
                                 --AND b.uaid     = s.uaid          -- crapp-3416, removed
                               )
            WHERE  b.state_code = stcode_i
                   AND b.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities
                   AND (NOT REGEXP_LIKE(b.city_name, '[0-9]') AND b.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
            ),
            complete AS
            (
            SELECT DISTINCT
                   zip_code
                   ,state_code
                   ,county_name
                   ,city_name
                   ,state_sales_tax
                   ,state_use_tax
                   ,county_sales_tax
                   ,county_use_tax
                   ,city_sales_tax
                   ,city_use_tax
                   ,mta_sales_tax
                   ,mta_use_tax
                   ,spd_sales_tax
                   ,spd_use_tax
                   ,other1_sales_tax
                   ,other1_use_tax
                   ,other2_sales_tax
                   ,other2_use_tax
                   ,other3_sales_tax
                   ,other3_use_tax
                   ,other4_sales_tax
                   ,other4_use_tax
                   ,total_sales_tax
                   ,total_use_tax
                   ,county_number
                   ,city_number
                   ,mta_name
                   ,mta_number
                   ,spd_name
                   ,spd_number
                   ,other1_name
                   ,other1_number
                   ,other2_name
                   ,other2_number
                   ,other3_name
                   ,other3_number
                   ,other4_name
                   ,other4_number
                   ,tax_shipping_alone
                   ,tax_shipping_and_handling
            FROM   osr_as_complete_plus_tmp
            WHERE  state_code = stcode_i
                   AND city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities
                   AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
            ),
            match AS
            (
            SELECT DISTINCT
                   a.state_code
                   , b2.cnt BASICII
                   , c.cnt  COMPLETE
                   , CASE WHEN b2.cnt = c.cnt THEN 'Match'
                          ELSE 'NoMatch'
                     END file_counts
            FROM osr_as_complete_plus_tmp a
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   basic_2
                       GROUP BY state_code
                     ) b2 ON ( a.state_code = b2.state_code)
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   complete
                       GROUP BY state_code
                     ) c ON ( a.state_code = c.state_code)
            )
            SELECT COUNT(1) cnt
            INTO   l_cnt2
            FROM   match
            WHERE  file_counts = 'NoMatch';


        -- BasicII+ / Complete+ --
        WITH basic_2_plus AS
            (
             SELECT DISTINCT
                    zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , TRIM(TO_CHAR(county_sales_tax, '90.999999')) county_sales_tax
                    , TRIM(TO_CHAR(county_use_tax, '90.999999'))   county_use_tax
                    , TRIM(TO_CHAR(city_sales_tax, '90.999999'))   city_sales_tax
                    , TRIM(TO_CHAR(city_use_tax, '90.999999'))     city_use_tax
                    , TRIM(TO_CHAR( TO_NUMBER(state_sales_tax) + county_sales_tax + city_sales_tax, '90.999999')) total_sales_tax
                    , TRIM(TO_CHAR( TO_NUMBER(state_use_tax) + county_use_tax + city_use_tax, '90.999999')) total_use_tax
                    , tax_shipping_alone
                    , tax_shipping_and_handling
                    , fips_state
                    , fips_county
                    , fips_city
                    , geocode
                    , MAX(state_effective_date)     state_effective_date    -- 07/19/17
                    , MAX(county_effective_date)    county_effective_date
                    , MAX(city_effective_date)      city_effective_date
             FROM   (
                    SELECT DISTINCT
                           bp.zip_code
                           , bp.state_code
                           , bp.county_name
                           , bp.city_name
                           , bp.state_sales_tax
                           , bp.state_use_tax
                           , CASE WHEN TO_NUMBER(bp.city_sales_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.county_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                                  ELSE bp.county_sales_tax
                             END county_sales_tax
                           , CASE WHEN TO_NUMBER(bp.city_use_tax) = 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.county_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                                  ELSE bp.county_use_tax
                             END county_use_tax
                           , CASE WHEN TO_NUMBER(bp.city_sales_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.city_sales_tax) + NVL(s.stj_salestax,0), '90.999999'))
                                  ELSE bp.city_sales_tax
                             END city_sales_tax
                           , CASE WHEN TO_NUMBER(bp.city_use_tax) > 0 THEN TRIM(TO_CHAR(TO_NUMBER(bp.city_use_tax) + NVL(s.stj_usetax,0), '90.999999'))
                                  ELSE bp.city_use_tax
                             END city_use_tax
                           , bp.total_sales_tax
                           , bp.total_use_tax
                           , bp.tax_shipping_alone
                           , bp.tax_shipping_and_handling
                           , bp.fips_state
                           , bp.fips_county
                           , bp.fips_city
                           , bp.geocode
                           , bp.state_effective_date
                           , bp.county_effective_date
                           , bp.city_effective_date
                    FROM   osr_as_complete_plus_tmp bp
                           JOIN (
                                SELECT DISTINCT
                                       uaid
                                       ,zip_code
                                       ,state_code
                                       ,county_name
                                       ,city_name
                                       ,SUM(TO_NUMBER(mta_sales_tax)
                                           + TO_NUMBER(spd_sales_tax)
                                           + TO_NUMBER(other1_sales_tax)+TO_NUMBER(other2_sales_tax)+TO_NUMBER(other3_sales_tax)+TO_NUMBER(other4_sales_tax)) stj_salestax
                                       ,SUM(TO_NUMBER(mta_use_tax)
                                           + TO_NUMBER(spd_use_tax)
                                           + TO_NUMBER(other1_use_tax)+TO_NUMBER(other2_use_tax)+TO_NUMBER(other3_use_tax)+TO_NUMBER(other4_use_tax)) stj_usetax
                                FROM   osr_as_complete_plus_tmp
                                WHERE  state_code = stcode_i
                                GROUP BY uaid -- crapp-3416, added group by due to SUM
                                       ,zip_code
                                       ,state_code
                                       ,county_name
                                       ,city_name
                                ) s ON (    bp.state_code  = s.state_code
                                        AND bp.county_name = s.county_name  -- crapp-3416, added
                                        AND bp.city_name   = s.city_name    -- crapp-3416, added
                                        AND bp.zip_code    = s.zip_code
                                        --AND bp.uaid     = s.uaid          -- crapp-3416, removed
                                       )
                    WHERE  bp.state_code = stcode_i
                    )
             GROUP BY -- 07/19/17
                    zip_code
                    , state_code
                    , county_name
                    , city_name
                    , state_sales_tax
                    , state_use_tax
                    , TRIM(TO_CHAR(county_sales_tax, '90.999999'))
                    , TRIM(TO_CHAR(county_use_tax, '90.999999'))
                    , TRIM(TO_CHAR(city_sales_tax, '90.999999'))
                    , TRIM(TO_CHAR(city_use_tax, '90.999999'))
                    , TRIM(TO_CHAR( TO_NUMBER(state_sales_tax) + county_sales_tax + city_sales_tax, '90.999999'))
                    , TRIM(TO_CHAR( TO_NUMBER(state_use_tax) + county_use_tax + city_use_tax, '90.999999'))
                    , tax_shipping_alone
                    , tax_shipping_and_handling
                    , fips_state
                    , fips_county
                    , fips_city
                    , geocode
            ),
            complete_plus AS
            (
            SELECT DISTINCT
                   zip_code
                   ,state_code
                   ,county_name
                   ,city_name
                   ,state_sales_tax
                   ,state_use_tax
                   ,county_sales_tax
                   ,county_use_tax
                   ,city_sales_tax
                   ,city_use_tax
                   ,mta_sales_tax
                   ,mta_use_tax
                   ,spd_sales_tax
                   ,spd_use_tax
                   ,other1_sales_tax
                   ,other1_use_tax
                   ,other2_sales_tax
                   ,other2_use_tax
                   ,other3_sales_tax
                   ,other3_use_tax
                   ,other4_sales_tax
                   ,other4_use_tax
                   ,total_sales_tax
                   ,total_use_tax
                   ,county_number
                   ,city_number
                   ,mta_name
                   ,mta_number
                   ,spd_name
                   ,spd_number
                   ,other1_name
                   ,other1_number
                   ,other2_name
                   ,other2_number
                   ,other3_name
                   ,other3_number
                   ,other4_name
                   ,other4_number
                   ,tax_shipping_alone
                   ,tax_shipping_and_handling
                   ,fips_state
                   ,fips_county
                   ,fips_city
                   ,geocode
                   ,mta_geocode
                   ,spd_geocode
                   ,other1_geocode
                   ,other2_geocode
                   ,other3_geocode
                   ,other4_geocode
                   ,geocode_long
                   ,MAX(state_effective_date)     state_effective_date    -- 07/19/17
                   ,MAX(county_effective_date)    county_effective_date
                   ,MAX(city_effective_date)      city_effective_date
                   ,MAX(mta_effective_date)       mta_effective_date
                   ,MAX(spd_effective_date)       spd_effective_date
                   ,MAX(other1_effective_date)    other1_effective_date
                   ,MAX(other2_effective_date)    other2_effective_date
                   ,MAX(other3_effective_date)    other3_effective_date
                   ,MAX(other4_effective_date)    other4_effective_date
                   ,MAX(county_tax_collected_by)  county_tax_collected_by
                   ,MAX(city_tax_collected_by)    city_tax_collected_by
                   ,state_taxable_max
                   ,state_tax_over_max
                   ,county_taxable_max
                   ,county_tax_over_max
                   ,city_taxable_max
                   ,city_tax_over_max
                   ,sales_tax_holiday
                   ,sales_tax_holiday_dates
                   ,sales_tax_holiday_items
            FROM   osr_as_complete_plus_tmp
            WHERE  state_code = stcode_i
            GROUP BY -- 07/19/17
                   zip_code
                   ,state_code
                   ,county_name
                   ,city_name
                   ,state_sales_tax
                   ,state_use_tax
                   ,county_sales_tax
                   ,county_use_tax
                   ,city_sales_tax
                   ,city_use_tax
                   ,mta_sales_tax
                   ,mta_use_tax
                   ,spd_sales_tax
                   ,spd_use_tax
                   ,other1_sales_tax
                   ,other1_use_tax
                   ,other2_sales_tax
                   ,other2_use_tax
                   ,other3_sales_tax
                   ,other3_use_tax
                   ,other4_sales_tax
                   ,other4_use_tax
                   ,total_sales_tax
                   ,total_use_tax
                   ,county_number
                   ,city_number
                   ,mta_name
                   ,mta_number
                   ,spd_name
                   ,spd_number
                   ,other1_name
                   ,other1_number
                   ,other2_name
                   ,other2_number
                   ,other3_name
                   ,other3_number
                   ,other4_name
                   ,other4_number
                   ,tax_shipping_alone
                   ,tax_shipping_and_handling
                   ,fips_state
                   ,fips_county
                   ,fips_city
                   ,geocode
                   ,mta_geocode
                   ,spd_geocode
                   ,other1_geocode
                   ,other2_geocode
                   ,other3_geocode
                   ,other4_geocode
                   ,geocode_long
                   ,state_taxable_max
                   ,state_tax_over_max
                   ,county_taxable_max
                   ,county_tax_over_max
                   ,city_taxable_max
                   ,city_tax_over_max
                   ,sales_tax_holiday
                   ,sales_tax_holiday_dates
                   ,sales_tax_holiday_items
            ),
            match AS
            (
            SELECT DISTINCT
                   a.state_code
                   , b2p.cnt  "BASICII+"
                   , cp.cnt   "COMPLETE+"
                   , CASE WHEN b2p.cnt = cp.cnt THEN 'Match'
                          ELSE 'NoMatch'
                     END file_counts
            FROM osr_as_complete_plus_tmp a
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   basic_2_plus
                       GROUP BY state_code
                     ) b2p ON ( a.state_code = b2p.state_code)
                JOIN (
                       SELECT state_code, COUNT(1) cnt
                       FROM   complete_plus
                       GROUP BY state_code
                     ) cp ON ( a.state_code = cp.state_code)
            )
            SELECT COUNT(1) cnt
            INTO   l_cnt3
            FROM   match
            WHERE  file_counts = 'NoMatch';


        -- Check for Exception --
        IF l_cnt1 > 0 THEN
            l_msg := 'Basic / Expanded / Basic+ / Expanded+';
            dbms_output.put_line('There are invalid file counts for '||stcode_i||' in extract set: '||l_msg);
            RAISE filecount_exp;

        ELSIF l_cnt2 > 0 THEN
            l_msg := 'BasicII / Complete';
            dbms_output.put_line('There are invalid file counts for '||stcode_i||' in extract set: '||l_msg);
            RAISE filecount_exp;

        ELSIF l_cnt3 > 0 THEN
            l_msg := 'BasicII+ / Complete+';
            dbms_output.put_line('There are invalid file counts for '||stcode_i||' in extract set: '||l_msg);
            RAISE filecount_exp;

        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_file_counts', paction=>1, puser=>user_i);

        EXCEPTION WHEN filecount_exp THEN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - There are invalid file counts for '||stcode_i||' in extract set: '||l_msg, paction=>3, puser=>user_i);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_file_counts', paction=>1, puser=>user_i);
            errlogger.report_and_stop(2004,'ONESOURCE Rate Extract has invalid file counts for '||stcode_i||' in extract set: '||l_msg);
    END datacheck_file_counts;



    PROCEDURE datacheck_rate_amounts    -- crapp-3456
    (
        stcode_i IN VARCHAR2,
        pID_i    IN NUMBER,
        user_i   IN NUMBER
    ) IS
        l_maxrate NUMBER := 0.1250;  -- 12.5% (No rate should be over 12.5% per US standard Sales/Use tax)
        l_sales   NUMBER := 0;
        l_use     NUMBER := 0;
        l_level   VARCHAR2(10 CHAR);
        rate_exp  EXCEPTION;
    BEGIN
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_rate_amounts', paction=>0, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate State Rates', paction=>0, puser=>user_i);
        SELECT MAX(state_sales_tax), MAX(state_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'State';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate State Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate County Rates', paction=>0, puser=>user_i);
        SELECT MAX(county_sales_tax), MAX(county_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'County';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate County Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate City Rates', paction=>0, puser=>user_i);
        SELECT MAX(city_sales_tax), MAX(city_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'City';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate City Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate MTA Rates', paction=>0, puser=>user_i);
        SELECT MAX(mta_sales_tax), MAX(mta_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'MTA';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate MTA Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate SPD Rates', paction=>0, puser=>user_i);
        SELECT MAX(spd_sales_tax), MAX(spd_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'SPD';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate SPD Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other1 Rates', paction=>0, puser=>user_i);
        SELECT MAX(other1_sales_tax), MAX(other1_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'Other1';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other1 Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other2 Rates', paction=>0, puser=>user_i);
        SELECT MAX(other2_sales_tax), MAX(other2_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'Other2';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other2 Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other3 Rates', paction=>0, puser=>user_i);
        SELECT MAX(other3_sales_tax), MAX(other3_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'Other3';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other3 Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other4 Rates', paction=>0, puser=>user_i);
        SELECT MAX(other4_sales_tax), MAX(other4_use_tax)
        INTO  l_sales, l_use
        FROM  osr_as_complete_plus_tmp
        WHERE state_code = stcode_i;

        IF l_sales > l_maxrate THEN
            l_level := 'Other4';
            RAISE rate_exp;
        END IF;
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - Validate Other4 Rates', paction=>1, puser=>user_i);

        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_rate_amounts', paction=>1, puser=>user_i);

    EXCEPTION WHEN rate_exp THEN
        dbms_output.put_line('There are '||l_level||' rates for '||stcode_i||' that are greater than the max allowed of '||l_maxrate);
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'  - There are '||l_level||' rates for '||stcode_i||' that are greater than the max allowed of '||l_maxrate, paction=>3, puser=>user_i);
        gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' datacheck_rate_amounts', paction=>1, puser=>user_i);
        errlogger.report_and_stop(2005,'ONESOURCE Rate Extract has '||l_level||' rates for '||stcode_i||' that are greater than the max allowed of '||l_maxrate);
    END datacheck_rate_amounts;



    -- crapp-4167 --
    -- ************************************* --
    -- Compare TDS vs. TDR State Rate values --
    -- ************************************* --
    PROCEDURE datacheck_state_rates
    (
        stcode_i IN VARCHAR2,
        pID_i    IN NUMBER,
        user_i   IN NUMBER
    )
    IS
        l_cnt    NUMBER := 0;
        rate_exp EXCEPTION;
    BEGIN
        gis_etl_p(pID_i, stcode_i, ' datacheck_rate_amounts', 0, user_i);

        -- Check TDS vs TDR --
        SELECT COUNT(1) cnt
        INTO l_cnt
        FROM (
                SELECT DISTINCT state_code, state_sales_tax, state_use_tax
                FROM   osr_expected_state_rates
                WHERE  state_code = stcode_i
                MINUS
                SELECT DISTINCT state_code, state_sales_tax, state_use_tax
                FROM   osr_as_complete_plus_tmp
                WHERE  state_code = stcode_i
             );

        IF l_cnt > 0 THEN
            RAISE rate_exp;
        END IF;

        -- Check TDR vs TDS --
        SELECT COUNT(1) cnt
        INTO l_cnt
        FROM (
                SELECT DISTINCT state_code, state_sales_tax, state_use_tax
                FROM   osr_as_complete_plus_tmp
                WHERE  state_code = stcode_i
                MINUS
                SELECT DISTINCT state_code, state_sales_tax, state_use_tax
                FROM   osr_expected_state_rates
                WHERE  state_code = stcode_i
             );

        IF l_cnt > 0 THEN
            RAISE rate_exp;
        END IF;
        gis_etl_p(pID_i, stcode_i, ' datacheck_rate_amounts', 1, user_i);

    EXCEPTION WHEN rate_exp THEN
        dbms_output.put_line('There are state rates for '||stcode_i||' that do not match TDS');
        gis_etl_p(pID_i, stcode_i, '  - There are state rates for '||stcode_i||' that do not match TDS', 3, user_i);
        gis_etl_p(pID_i, stcode_i, ' datacheck_state_rates', 1, user_i);
        errlogger.report_and_stop(2005,'ONESOURCE Rate Extract has invalid state rates for: '||stcode_i);
    END datacheck_state_rates;



    PROCEDURE build_osr_spd_basic
    (
        stcode_i IN VARCHAR2,
        pID_i    IN NUMBER,
        user_i   IN NUMBER
    )
    IS
        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' build_osr_spd_basic', paction=>0, puser=>user_i);

            -- update osr_transit_authorities_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get transit authorities - osr_transit_authorities_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_transit_authorities_tmp DROP STORAGE';
            INSERT INTO osr_transit_authorities_tmp
                SELECT *
                FROM (SELECT SUBSTR(geo_area_key, 4, INSTR(geo_area_key, '-', 4)-4) AUTHORITY_ID
                             , TRIM(SUBSTR(geo_area_key, INSTR(geo_area_key, '-', 4)+1, 100)) AUTHORITY_NAME
                      FROM  geo_polygons
                      WHERE hierarchy_level_id = '7'
                            AND end_date IS NULL
                            AND next_rid IS NULL
                     )
                WHERE authority_name LIKE '%TRANSIT%' OR authority_name LIKE '%TRANSPORT%';
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get transit authorities - osr_transit_authorities_tmp', paction=>1, puser=>user_i);


            -- update osr_auth_positions_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get authority positions - osr_auth_positions_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_auth_positions_tmp DROP STORAGE';

            INSERT INTO osr_auth_positions_tmp
                SELECT q1.*, q3.uaid_num_auths
                FROM
                    (SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, '1' auth_position, area_id uaid
                     FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=17 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id,  '1' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=22 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id,  '2' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=22 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id,  '1' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id,  '2' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id,  '3' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id,  '1' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id,  '2' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id,  '3' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, '4' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, '1' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, '2' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, '3' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, '4' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, '5' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, '1' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, '2' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, '3' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, '4' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, '5' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, '6' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, '1' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, '2' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, '3' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, '4' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, '5' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, '6' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,44,4) authority_id, '7' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, '1' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, '2' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, '3' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, '4' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, '5' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, '6' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,44,4) authority_id, '7' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                        UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,49,4) authority_id, '8' auth_position, area_id uaid FROM
                        (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                    ) q1
                    LEFT JOIN (SELECT authority_id, COUNT(uaid) auth_num_unique_areas
                               FROM (SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                     FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=17 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=22 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=22 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,44,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,44,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,49,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                    )
                               GROUP BY authority_id
                              ) q2 ON q1.authority_id = q2.authority_id
                    LEFT JOIN (SELECT uaid, COUNT(authority_id) uaid_num_auths
                               FROM (SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                     FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=17 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=22 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=22 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=27 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=32 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=37 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=42 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,44,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=47 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,14,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,19,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,24,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,29,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,34,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,39,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,44,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                           UNION SELECT SUBSTR(area_id,1,2)||SUBSTR(area_id,49,4) authority_id, area_id uaid
                                                 FROM (SELECT DISTINCT area_id FROM  geo_unique_areas WHERE LENGTH(area_id)=52 AND end_date IS NULL AND next_rid IS NULL)
                                    )
                               GROUP BY uaid
                        ) q3 ON q1.uaid = q3.uaid
                ORDER BY q3.uaid_num_auths desc, q1.authority_id;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get authority positions - osr_auth_positions_tmp', paction=>1, puser=>user_i);


            -- update osr_auth_new_positions_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get new authority positions - osr_auth_new_positions_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_auth_new_positions_tmp DROP STORAGE';

            INSERT INTO osr_auth_new_positions_tmp
                SELECT q1.uaid
                       , z.authority_id
                       , TO_NUMBER(z.auth_position)-1 new_auth_position
                FROM (
                     SELECT x.*, y.authority_name
                     FROM osr_auth_positions_tmp x
                          LEFT JOIN osr_transit_authorities_tmp y ON (x.authority_id = y.authority_id)
                     WHERE y.authority_name IS NOT NULL
                           AND x.auth_position != x.uaid_num_auths
                    ) q1
                    LEFT JOIN osr_auth_positions_tmp z ON (q1.uaid = z.uaid
                                                           AND q1.auth_position < z.auth_position
                                                          );
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get new authority positions - osr_auth_new_positions_tmp', paction=>1, puser=>user_i);


            -- update osr_auth_pos_reassigned_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine authority position reassignment - osr_auth_pos_reassigned_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_auth_pos_reassigned_tmp DROP STORAGE';

            INSERT INTO osr_auth_pos_reassigned_tmp
                SELECT uaid
                       , authority_id
                       , DECODE(gta_auth_id, NULL, auth_position,'9') auth_position
                FROM (
                     SELECT q1.*, gta.authority_id gta_auth_id
                     FROM (
                          SELECT uaid
                                 , authority_id
                                 , DECODE(new_auth_position, NULL, auth_position, new_auth_position) auth_position
                          FROM (
                                SELECT x.*, y.new_auth_position
                                FROM osr_auth_positions_tmp x
                                     LEFT JOIN osr_auth_new_positions_tmp y ON x.uaid = y.uaid AND x.authority_id = y.authority_id
                               )
                          ) q1
                          LEFT JOIN osr_transit_authorities_tmp gta ON q1.authority_id = gta.authority_id
                     );
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine authority position reassignment - osr_auth_pos_reassigned_tmp', paction=>1, puser=>user_i);


            -- update osr_auth_final_positions_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine final authority positions - osr_auth_final_positions_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_auth_final_positions_tmp DROP STORAGE';

            INSERT INTO osr_auth_final_positions_tmp
                --all uaids AND auths ready to go with no double transits
                SELECT q2.uaid, q2.authority_id, q2.auth_position
                FROM (
                      SELECT q1.*, gapr.authority_id
                      FROM (
                            SELECT uaid, auth_position
                            FROM (
                                 SELECT uaid, auth_position, COUNT(authority_id) cai
                                 FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                 GROUP BY uaid, auth_position
                                 )
                            WHERE cai = 1
                           ) q1
                           LEFT JOIN osr_auth_pos_reassigned_tmp gapr ON q1.uaid = gapr.uaid
                                                                      AND q1.auth_position = gapr.auth_position
                     ) q2
                     LEFT JOIN (
                                SELECT uaid, auth_position
                                FROM (
                                      SELECT uaid, auth_position, COUNT(authority_id) cai
                                      FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                      GROUP BY uaid, auth_position
                                     )
                                WHERE cai > 1
                               ) q3 ON q2.uaid = q3.uaid
                WHERE q3.uaid IS NULL
                UNION
                --lowest transit auth assinged to mta for any with more than one
                SELECT uaid, min(authority_id) authority_id, '9' auth_position
                FROM (
                      SELECT q2.*, q3.poses
                      FROM (
                            SELECT q1.*, gap.authority_id, gap.uaid_num_auths
                            FROM (
                                  SELECT uaid, auth_position
                                  FROM (
                                        SELECT uaid, auth_position, COUNT(authority_id) cai
                                        FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                        GROUP BY uaid, auth_position
                                       )
                                  WHERE cai > 1
                                 ) q1
                                 LEFT JOIN osr_auth_positions_tmp gap ON q1.uaid = gap.uaid
                           ) q2
                           LEFT JOIN (
                                      SELECT uaid, listagg(auth_position,',') WITHIN GROUP (ORDER BY auth_position) poses
                                      FROM (
                                            SELECT q1.*, gap.authority_id, gap.uaid_num_auths
                                            FROM (
                                                  SELECT uaid, auth_position
                                                  FROM (
                                                        SELECT uaid, auth_position, COUNT(authority_id) cai
                                                        FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                                        GROUP BY uaid, auth_position
                                                       )
                                                  WHERE cai > 1
                                                 ) q1
                                                 LEFT JOIN osr_auth_positions_tmp gap ON q1.uaid = gap.uaid) GROUP BY uaid
                                     ) q3 ON q2.uaid = q3.uaid
                      ORDER BY authority_id
                     )
                WHERE auth_position = '9'
                GROUP BY uaid
                UNION
                --additional transit auth and all other authorities for any uaid with multiple transit auths
                SELECT uaid
                       , authority_id
                       , DECODE(auth_position,'9',
                                DECODE(INSTR(poses,'2',1,1),0,
                                       '2', DECODE(INSTR(poses,'3',1,1),0,
                                                   '3', DECODE(INSTR(poses,'4',1,1),0,
                                                               '4', DECODE(INSTR(poses,'5',1,1),0,
                                                                           '5', DECODE(INSTR(poses,'6',1,1),0,
                                                                                       '6', DECODE(INSTR(poses,'7',1,1),0,
                                                                                                   '7', DECODE(INSTR(poses,'8',1,1),0,'8','NA')
                                                                                                  )
                                                                                      )
                                                                          )
                                                              )
                                                  )
                                      ), auth_position
                               ) auth_position
                FROM (
                      SELECT q4.*
                      FROM (
                            SELECT q2.*, q3.poses
                            FROM (
                                  SELECT q1.*, gap.authority_id, gap.uaid_num_auths
                                  FROM (
                                        SELECT uaid, auth_position
                                        FROM (
                                              SELECT uaid, auth_position, COUNT(authority_id) cai
                                              FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                              GROUP BY uaid, auth_position
                                             )
                                        WHERE cai > 1
                                       ) q1
                                       LEFT JOIN osr_auth_positions_tmp gap ON q1.uaid = gap.uaid
                                 ) q2
                                LEFT JOIN (
                                           SELECT uaid, listagg(auth_position,',') WITHIN GROUP (ORDER BY auth_position) poses
                                           FROM (
                                                 SELECT q1.*, gap.authority_id, gap.uaid_num_auths
                                                 FROM (
                                                       SELECT uaid, auth_position
                                                       FROM (
                                                             SELECT uaid, auth_position, COUNT(authority_id) cai
                                                             FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                                             GROUP BY uaid, auth_position
                                                            )
                                                       WHERE cai > 1
                                                      ) q1
                                                      LEFT JOIN osr_auth_positions_tmp gap ON (q1.uaid = gap.uaid)
                                                )
                                           GROUP BY uaid
                                          ) q3 ON (q2.uaid = q3.uaid)
                            ORDER BY authority_id
                           ) q4
                           LEFT JOIN (
                                      SELECT uaid, MIN(authority_id) authority_id, '9' auth_position
                                      FROM (
                                            SELECT q2.*, q3.poses
                                            FROM (
                                                  SELECT q1.*, gap.authority_id, gap.uaid_num_auths
                                                  FROM (
                                                        SELECT uaid, auth_position
                                                        FROM (
                                                              SELECT uaid, auth_position, COUNT(authority_id) cai
                                                              FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                                              GROUP BY uaid, auth_position
                                                             )
                                                        WHERE cai > 1
                                                       ) q1
                                                       LEFT JOIN osr_auth_positions_tmp gap ON (q1.uaid = gap.uaid)
                                                 ) q2
                                                 LEFT JOIN (
                                                            SELECT uaid, listagg(auth_position,',') WITHIN GROUP (ORDER BY auth_position) poses
                                                            FROM (
                                                                  SELECT q1.*, gap.authority_id, gap.uaid_num_auths
                                                                  FROM (
                                                                        SELECT uaid, auth_position
                                                                        FROM (
                                                                              SELECT uaid, auth_position, COUNT(authority_id) cai
                                                                              FROM (SELECT * FROM osr_auth_pos_reassigned_tmp)
                                                                              GROUP BY uaid, auth_position
                                                                             )WHERE cai > 1
                                                                       ) q1
                                                                       LEFT JOIN osr_auth_positions_tmp gap ON (q1.uaid = gap.uaid)
                                                                 )
                                                            GROUP BY uaid
                                                           ) q3 ON (q2.uaid = q3.uaid)
                                            ORDER BY authority_id
                                           )
                                      WHERE auth_position = '9'
                                      GROUP BY uaid
                                     ) q5 ON (q4.uaid = q4.uaid
                                              AND q4.authority_id = q5.authority_id)
                      WHERE q5.authority_id IS NULL
                     );
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine final authority positions - osr_auth_final_positions_tmp', paction=>1, puser=>user_i);


            -- update osr_stj_lookup_tmp -- crapp-3456, moved up a step
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine stj names - osr_stj_lookup_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_stj_lookup_tmp DROP STORAGE';

            INSERT INTO osr_stj_lookup_tmp
                SELECT SUBSTR(geo_area_key,4,6) ID, TRIM(SUBSTR(geo_area_key,11,200)) NAME
                FROM  geo_polygons
                WHERE hierarchy_level_id = '7'
                      AND geo_area_key NOT LIKE (SELECT official_name FROM osr_rate_exclusions WHERE nkid IS NULL); -- crapp-3456, added exclusions
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine stj names - osr_stj_lookup_tmp', paction=>1, puser=>user_i);


            -- update osr_auth_id_table_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine final authority positions - osr_auth_id_table_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_auth_id_table_tmp DROP STORAGE';

            INSERT INTO osr_auth_id_table_tmp
                SELECT DISTINCT
                       area_id uaid
                       , NULL mta_id
                       , NULL spd_id
                       , NULL other1_id
                       , NULL other2_id
                       , NULL other3_id
                       , NULL other4_id
                       , NULL other5_id
                       , NULL other6_id
                       , NULL other7_id
                FROM geo_unique_areas
                WHERE LENGTH(area_id) = 12
                      AND end_date IS NULL
                      AND next_rid IS NULL
                UNION
                SELECT uaid
                       , MAX(mta_id) mta_id
                       , MAX(spd_id) spd_id
                       , MAX(other1_id) other1_id
                       , MAX(other2_id) other2_id
                       , MAX(other3_id) other3_id
                       , MAX(other4_id) other4_id
                       , MAX(other5_id) other5_id
                       , MAX(other6_id) other6_id
                       , MAX(other7_id) other7_id
                FROM (
                      SELECT uaid
                             , DECODE(auth_position,'9',authority_id,NULL) mta_id
                             , DECODE(auth_position,'1',authority_id,NULL) spd_id
                             , DECODE(auth_position,'2',authority_id,NULL) other1_id
                             , DECODE(auth_position,'3',authority_id,NULL) other2_id
                             , DECODE(auth_position,'4',authority_id,NULL) other3_id
                             , DECODE(auth_position,'5',authority_id,NULL) other4_id
                             , DECODE(auth_position,'6',authority_id,NULL) other5_id
                             , DECODE(auth_position,'7',authority_id,NULL) other6_id
                             , DECODE(auth_position,'8',authority_id,NULL) other7_id
                      FROM osr_auth_final_positions_tmp
                      WHERE authority_id IN (SELECT DISTINCT id FROM osr_stj_lookup_tmp)    -- crapp-3456, added to restrict records
                     )
                GROUP BY uaid;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine final authority positions - osr_auth_id_table_tmp', paction=>1, puser=>user_i);


            -- update osr_final_spd_placement_lt_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine final placement of stjs - osr_final_spd_placement_lt_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_final_spd_placement_lt_tmp DROP STORAGE';
            --EXECUTE IMMEDIATE 'ALTER INDEX osr_final_spd_placement_n1 UNUSABLE';

            INSERT INTO osr_final_spd_placement_lt_tmp
                SELECT x.uaid
                       , x.mta_id
                       , t.name mta_name
                       , x.spd_id
                       , y.name spd_name
                       , x.other1_id
                       , z.name other1_name
                       , x.other2_id
                       , q.name other2_name
                       , x.other3_id
                       , r.name other3_name
                       , x.other4_id
                       , s.name other4_name
                       , x.other5_id
                       , x1.name other5_name
                       , x.other6_id
                       , u.name other6_name
                       , x.other7_id
                       , v.name other7_name
                FROM osr_auth_id_table_tmp x
                     LEFT JOIN osr_stj_lookup_tmp t  ON (x.mta_id = t.id)
                     LEFT JOIN osr_stj_lookup_tmp y  ON (x.spd_id = y.id)
                     LEFT JOIN osr_stj_lookup_tmp z  ON (x.other1_id = z.id)
                     LEFT JOIN osr_stj_lookup_tmp q  ON (x.other2_id = q.id)
                     LEFT JOIN osr_stj_lookup_tmp r  ON (x.other3_id = r.id)
                     LEFT JOIN osr_stj_lookup_tmp s  ON (x.other4_id = s.id)
                     LEFT JOIN osr_stj_lookup_tmp x1 ON (x.other5_id = x1.id)
                     LEFT JOIN osr_stj_lookup_tmp u  ON (x.other6_id = u.id)
                     LEFT JOIN osr_stj_lookup_tmp v  ON (x.other7_id = v.id)
                WHERE x.mta_id IS NOT NULL
                      OR x.spd_id IS NOT NULL
                      OR x.other1_id IS NOT NULL
                      OR x.other2_id IS NOT NULL
                      OR x.other3_id IS NOT NULL
                      OR x.other4_id IS NOT NULL
                      OR x.other5_id IS NOT NULL
                      OR x.other6_id IS NOT NULL
                      OR x.other7_id IS NOT NULL;
            COMMIT;
            --EXECUTE IMMEDIATE 'ALTER INDEX osr_final_spd_placement_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_final_spd_placement_lt_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine final placement of stjs - osr_final_spd_placement_lt_tmp', paction=>1, puser=>user_i);


            -- update osr_missing_uaids_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine any missing areas - osr_missing_uaids_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_missing_uaids_tmp DROP STORAGE';

            INSERT INTO osr_missing_uaids_tmp
                SELECT q1.*
                FROM (
                      SELECT a.*
                      FROM (
                            SELECT DISTINCT area_id uaid
                            FROM  geo_unique_areas
                            WHERE end_date IS NULL
                                  AND next_rid IS NULL
                           ) a
                           LEFT JOIN osr_auth_id_table_tmp b ON (a.uaid = b.uaid)
                      WHERE b.uaid IS NULL
                     ) q1;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine any missing areas - osr_missing_uaids_tmp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>'ALL', ppart=>' build_osr_spd_basic', paction=>1, puser=>user_i);
        END build_osr_spd_basic;



    PROCEDURE get_tag_data -- 11/03/17
    (
        stcode_i  IN VARCHAR2,
        pID_i     IN NUMBER,
        user_i    IN NUMBER
    )
    IS

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' get_tag_data', paction=>0, puser=>user_i);

            -- Get Tag Data --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdictions by Tag List - osr_zone_auth_tags_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_auth_tags_tmp DROP STORAGE';
            INSERT INTO osr_zone_auth_tags_tmp
                (ref_nkid, tagcnt)
                SELECT  ref_nkid,
                        COUNT(*) tagcnt
                FROM    tag_group_tags tv
                        JOIN  (
                                SELECT jt.ref_nkid
                                       , listagg(tag.name,',') WITHIN GROUP (ORDER BY tag.name) tag_list
                                       , j.official_name
                                FROM   ( SELECT DISTINCT
                                                ref_nkid
                                                ,tag_id
                                         FROM   jurisdiction_tags
                                         WHERE  tag_id NOT IN (SELECT id FROM tags WHERE NAME IN ('KPMG','Deprecated','International')) -- Exclude KPMG and Deprected jurisdictions
                                       ) jt
                                       JOIN tags tag ON (tag.id = jt.tag_id)
                                       JOIN jurisdictions j ON (jt.ref_nkid = j.nkid)
                                WHERE  j.next_rid IS NULL
                                       AND tag.tag_type_id NOT IN (SELECT ID FROM tag_types WHERE NAME LIKE '%USER%') -- crapp-3576, exclude USER tags = 5
                                       --AND j.status = 2 -- published only
                                GROUP BY jt.ref_nkid, j.official_name
                              ) e on (e.tag_list = tv.tag_list)
                WHERE   e.tag_list LIKE 'Determination%United States'
                GROUP BY ref_nkid
                -- crapp-4167 - including US - NO TAX STATES jurisdiction - This will be removed once crapp-3570 has been completed
                UNION
                SELECT DISTINCT nkid, 0 tagcnt
                FROM   jurisdictions
                WHERE  official_name LIKE '%US - NO TAX STATES%';
            COMMIT;

            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_auth_tags_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdictions by Tag List - osr_zone_auth_tags_tmp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' get_tag_data', paction=>1, puser=>user_i);
        END get_tag_data;



    PROCEDURE extract_preferred_city    -- crapp-3416
    (
        stcode_i IN VARCHAR2,
        pID_i    IN NUMBER,
        user_i   IN NUMBER
    ) IS
            l_stcode VARCHAR2(2 CHAR) := CASE WHEN stcode_i = 'XX' THEN NULL ELSE stcode_i END;
            l_sql    VARCHAR2(2000 CHAR);

            CURSOR states IS
                SELECT state_code, NAME
                FROM   geo_states
                WHERE  (state_code = l_stcode
                        OR l_stcode IS NULL
                       )
                       AND state_code != 'XX'
                ORDER BY state_code;

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'extract_preferred_city', paction=>0, puser=>user_i);

            -- Remove previous extracted records --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_usps_preferred_city DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_usps_preferred_city_n1 UNUSABLE';

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get current preferred mailing city records', paction=>0, puser=>user_i);

            -- crapp-3329 - Excluding invalid city names provided by Tom -- Using GEO_USPS_MAILING_CITY which is updated when GIS performs an import
            FOR s IN states LOOP
                l_sql := 'INSERT INTO osr_usps_preferred_city '||
                             '(state_code, zip, county_name, city_name, area_id) '||
                             'SELECT DISTINCT '||
                                    'z.state '||
                                    ', z.zipcode '||
                                    ', REPLACE(UPPER(z.countyname),CHR(39),'''') county_name '||
                                    ', REPLACE(UPPER(z.city),CHR(39),'''')       city_name '||
                                    ', z.uaid '||
                             'FROM  gis.'||s.state_code||'_ua_zip9@gis.corp.ositax.com z '||
                             'WHERE NOT EXISTS (SELECT 1 '||
                                               'FROM   osr_city_exclude_list e '||
                                               'WHERE      z.state   = e.state_code '||
                                                      'AND z.zipcode = e.zip '||
                                                      'AND REPLACE(UPPER(z.countyname),CHR(39),'''') = e.county_name '||
                                                      'AND REPLACE(UPPER(z.city),CHR(39),'''')       = e.city_name) '||
                                   'AND z.city IS NOT NULL '||
                             'ORDER BY z.zipcode, REPLACE(UPPER(z.countyname),CHR(39),''''), REPLACE(UPPER(z.city),CHR(39),'''')';

                EXECUTE IMMEDIATE l_sql;
                COMMIT;
            END LOOP;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get current preferred mailing city records', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild index and refresh stats - geo_usps_preferred_city', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX osr_usps_preferred_city_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_usps_preferred_city', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild index and refresh stats - geo_usps_preferred_city', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'extract_preferred_city', paction=>1, puser=>user_i);
        END extract_preferred_city;




    PROCEDURE determine_zip_data -- 11/10/17 -- performance changes
    (
        stcode_i  IN VARCHAR2,
        pID_i     IN NUMBER,
        user_i    IN NUMBER
    )
    IS
            l_rec   NUMBER := 0;
            l_fips  VARCHAR2(4 CHAR);
            l_sql   VARCHAR2(1000 CHAR);
            l_state VARCHAR2(50 CHAR);
            l_hlvl  NUMBER;

            TYPE t_counties IS VARRAY(5) OF VARCHAR(3);
            v_county_start t_counties;
            v_county_end   t_counties;

            TYPE t_stj IS TABLE OF osr_zone_stj_areas_tmp%ROWTYPE;              -- 07/11/17, added per meeting
            v_stj  t_stj;

            TYPE r_arealist IS RECORD
            (
                unique_area         osr_zone_area_list_tmp.unique_area%TYPE
                , stj_flag          osr_zone_area_list_tmp.stj_flag%TYPE
                , state_name        osr_zone_area_list_tmp.state_name%TYPE
                , county_name       osr_zone_area_list_tmp.county_name%TYPE
                , city_name         osr_zone_area_list_tmp.city_name%TYPE
                , zip               osr_zone_area_list_tmp.zip%TYPE
                , zip4              osr_zone_area_list_tmp.zip4%TYPE
                , default_flag      osr_zone_area_list_tmp.default_flag%TYPE
                , code_fips         osr_zone_area_list_tmp.code_fips%TYPE
                , state_code        osr_zone_area_list_tmp.state_code%TYPE
                , jurisdiction_id   osr_zone_area_list_tmp.jurisdiction_id%TYPE
                , official_name     osr_zone_area_list_tmp.official_name%TYPE
                , rid               osr_zone_area_list_tmp.rid%TYPE
                , nkid              osr_zone_area_list_tmp.nkid%TYPE
                , geo_area          osr_zone_area_list_tmp.geo_area%TYPE
                , geoarea_updated   osr_zone_area_list_tmp.geoarea_updated%TYPE
                --, tax_area_id       osr_zone_area_list_tmp.tax_area_id%TYPE     -- crapp-3971 - removed
                , area_id           osr_zone_area_list_tmp.area_id%TYPE
                , acceptable_city   osr_zone_area_list_tmp.acceptable_city%TYPE
            );
            TYPE t_arealist IS TABLE OF r_arealist;
            v_arealist  t_arealist;


            -- crapp-3416 - Added 03/08/17 --
            TYPE r_geoarea IS RECORD
            (
                state_code        osr_zone_area_list_tmp.state_code%TYPE
              , official_name     osr_zone_area_list_tmp.official_name%TYPE
              , geo_polygon_rid   osr_zone_area_list_tmp.rid%TYPE
              , geo_area          osr_zone_area_list_tmp.geo_area%TYPE
            );
            TYPE t_geoarea IS TABLE OF r_geoarea;
            v_geoarea t_geoarea;


            -- crapp-3416 - Added 03/10/17 --
            TYPE r_geoarea_step2 IS RECORD
            (
                state_code        osr_zone_area_list_tmp.state_code%TYPE
              , zip               osr_zone_area_list_tmp.zip%TYPE
              , area_id           osr_zone_area_list_tmp.area_id%TYPE
              , geo_area          osr_zone_area_list_tmp.geo_area%TYPE
              , official_name     osr_zone_area_list_tmp.official_name%TYPE
              , jurisdiction_id   osr_zone_area_list_tmp.jurisdiction_id%TYPE
            );
            TYPE t_geoarea_step2 IS TABLE OF r_geoarea_step2;
            v_geoarea_step2 t_geoarea_step2;


            -- 04/18/17 - added for performance --
            TYPE r_detail IS RECORD
            (
                  state_code        osr_zone_detail_usps_tmp.state_code%TYPE
                , state_name        osr_zone_detail_usps_tmp.state_name%TYPE
                , county_name       osr_zone_detail_usps_tmp.county_name%TYPE
                , city_name         osr_zone_detail_usps_tmp.city_name%TYPE
                , zip               osr_zone_detail_usps_tmp.zip%TYPE
                , zip4              osr_zone_detail_usps_tmp.zip4%TYPE
                , zip9              osr_zone_detail_usps_tmp.zip9%TYPE
                , default_flag      osr_zone_detail_usps_tmp.default_flag%TYPE
                , area_id           osr_zone_detail_usps_tmp.area_id%TYPE
                , geo_polygon_id    osr_zone_detail_usps_tmp.geo_polygon_id%TYPE
            );
            TYPE t_detail IS TABLE OF r_detail;
            v_detail  t_detail;

            -- 05/12/17 - added for performance --
            TYPE r_zonedetail IS RECORD
            (
               state_code       osr_zone_detail_tmp.state_code%TYPE
             , state_name       osr_zone_detail_tmp.state_name%TYPE
             , county_name      osr_zone_detail_tmp.county_name%TYPE
             , city_name        osr_zone_detail_tmp.city_name%TYPE
             , zip              osr_zone_detail_tmp.zip%TYPE
             , zip9             osr_zone_detail_tmp.zip9%TYPE
             , zip4             osr_zone_detail_tmp.zip4%TYPE
             , default_flag     osr_zone_detail_tmp.default_flag%TYPE
             , code_fips        osr_zone_detail_tmp.code_fips%TYPE
             , geo_area         osr_zone_detail_tmp.geo_area%TYPE
             , unique_area      osr_zone_detail_tmp.unique_area%TYPE
             , rid              osr_zone_detail_tmp.rid%TYPE
             --, tax_area_id      osr_zone_detail_tmp.tax_area_id%TYPE  -- crapp-3971 - removed
             , area_id          osr_zone_detail_tmp.area_id%TYPE
             , acceptable_city  osr_zone_detail_tmp.acceptable_city%TYPE
            );
            TYPE t_zonedetail IS TABLE OF r_zonedetail;
            v_zonedetail t_zonedetail;

            -- 11/10/17 - Added for performance --
            TYPE t_dtl IS TABLE OF osr_zone_detail_tmp%ROWTYPE;
            v_dtl  t_dtl;

            -- 11/10/17 - Added for performance --
            CURSOR detail(stcd VARCHAR2) IS
                WITH usps AS
                    (
                    SELECT DISTINCT
                           state_code
                           , SUBSTR(UPPER(state_name), 1, 50)  state_name
                           , SUBSTR(UPPER(county_name), 1, 65) county_name
                           , SUBSTR(UPPER(city_name), 1, 65)   city_name
                           , zip
                           , zip9
                           , SUBSTR(zip9, 6, 4) zip4
                           , CASE WHEN override_rank = 1 THEN 'Y' ELSE NULL END default_flag
                           , area_id
                           , geo_polygon_id
                           , city_fips
                    FROM   geo_usps_lookup u
                    WHERE  state_code = stcd
                    ),
                    poly AS
                    (
                    SELECT /*+index(p geo_polygons_un)*/
                           DISTINCT
                           u.state_code
                           , u.state_name
                           , u.county_name
                           , u.city_name
                           , u.zip
                           , u.zip9
                           , u.zip4
                           , u.default_flag
                           , ac.NAME geo_area
                           , u.area_id
                           , p.rid
                           , u.city_fips
                    FROM   usps u
                           JOIN geo_polygons p ON (p.id = u.geo_polygon_id)
                           JOIN geo_poly_ref_revisions r ON (    r.nkid = p.nkid
                                                             AND rev_join (p.rid, r.id, COALESCE (p.next_rid, 999999999)) = 1)
                           JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
                           JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
                    WHERE  u.state_code = stcd
                           AND p.next_rid IS NULL
                    )
                    SELECT   u1.state_code
                           , u1.state_name
                           , u1.county_name
                           , u1.city_name
                           , u1.zip
                           , u1.zip9
                           , u1.zip4
                           , u1.default_flag
                           , u1.city_fips
                           , u1.geo_area
                           , gua.unique_area
                           , u1.rid
                           , u1.area_id
                           , TRIM('N') acceptable_city -- crapp-3244
                    FROM   poly u1
                           JOIN osr_zone_detail_areas_tmp gua ON (u1.area_id = gua.area_id);

            -- 09/29/17 - added for performance --
            CURSOR dtl_unincorp(st_i VARCHAR2) IS
                SELECT /*+parallel(u,4) index(p geo_polygons_un) index(u osr_zone_detail_usps_tmp_n1)*/
                       DISTINCT
                       u.state_code
                       , u.state_name
                       , u.county_name
                       , SUBSTR(UPPER(mc.city_name), 1, 65) city_name
                       , u.zip
                       , u.zip9
                       , u.zip4
                       , u.default_flag
                       , TRIM('00000') code_fips      -- crapp-3416
                       , p.geo_area --ac.NAME  geo_area
                       , gua.unique_area
                       , p.rid
                       --, NULL tax_area_id   -- crapp-3971 - removed
                       , u.area_id
                       , TRIM('Y') acceptable_city    -- crapp-3244
                 FROM osr_zone_detail_usps_tmp u      -- now using staging table instead of geo_usps_lookup - 02/13/17
                      JOIN vgeo_polygons p ON (p.id = u.geo_polygon_id) -- 02/14/17 changed to view

                      -- 09/29/17 - added staging table --
                      LEFT JOIN osr_zone_detail_areas_tmp gua ON (    u.state_code    = gua.state_code
                                                                  AND NVL(u.zip, -1)  = NVL(gua.zip, -1)
                                                                  AND NVL(u.zip9, -1) = NVL(gua.zip9, -1)
                                                                  --AND u.county_name   = gua.county_name    -- 07/12/17, added    -- 07/18/17 out??
                                                                  --AND u.city_name     = gua.city_name      -- 07/12/17, added    -- 07/18/17 out??
                                                                  AND u.area_id       = gua.area_id      -- 07/12/17, removed      -- 07/18/17 back in??
                                                                 )
                      -- crapp-3416, using Preferred City table directly --
                      JOIN osr_usps_preferred_city mc ON (    u.state_code  = mc.state_code
                                                          AND u.zip         = mc.zip
                                                          AND u.county_name = mc.county_name
                                                          AND u.city_name  != mc.city_name
                                                          AND u.area_id     = mc.area_id      -- 07/18/17, back in??
                                                         )
                      --LEFT JOIN osr_convert_names cn ON (1=1) -- crapp-3416 - 03/08/17 removed
                 WHERE u.state_code = st_i
                       --AND gua.zip IS NULL -- 07/12/17, added -- 07/18/17 out??
                       AND p.next_rid IS NULL;

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' determine_zip_data', paction=>0, puser=>user_i);

            -- Get STJ Count -- 07/11/17, added per meeting
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine STJ counts - osr_zone_stj_areas_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_stj_areas_tmp DROP STORAGE';

            SELECT  hl.id
            INTO    l_hlvl
            FROM    hierarchy_levels hl
                    JOIN geo_area_categories g ON (hl.geo_area_category_id = g.id)
                    JOIN hierarchy_definitions hd ON (hl.hierarchy_definition_id = hd.id)
            WHERE   hl.hierarchy_definition_id = 2  -- using: "US State to District Hierarchy"
                    AND g.NAME = 'District';

            WITH zips AS
                (
                 SELECT u.state_code
                        , u.zip9
                        , u.area_id
                 FROM   geo_usps_lookup u
                        JOIN geo_polygons p ON (u.geo_polygon_id = p.id)
                 WHERE  u.state_code = stcode_i
                        AND DECODE(NVL(SUBSTR(u.zip9,6,4), 'XXXX'), 'XXXX', 0, 1) = 1   -- zip4 is not null
                        AND p.hierarchy_level_id = l_hlvl --'District'
                        AND p.next_rid IS NULL
                ),
               areas AS
                (
                 SELECT state_code
                        , zip9
                        , unique_area
                        , area_id
                 FROM   vgeo_unique_areas2
                 WHERE  state_code = stcode_i
                        AND zip9 IS NOT NULL
                )
                SELECT  DISTINCT
                        z.state_code
                        , a.unique_area
                        , 1 stj_flag
                        , z.zip9
                BULK COLLECT INTO v_stj
                FROM    zips z
                        JOIN areas a ON (    z.state_code = a.state_code
                                         AND z.zip9       = a.zip9
                                         AND z.area_id    = a.area_id
                                        );

            FORALL i IN v_stj.first..v_stj.last
                INSERT INTO osr_zone_stj_areas_tmp
                VALUES v_stj(i);
            COMMIT;

            v_stj := t_stj();
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_stj_areas_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine STJ counts - osr_zone_stj_areas_tmp', paction=>1, puser=>user_i);


            -- Determine Authority Tree Mappings -- 07/11/17
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine authority tree mappings - osr_zone_authorities_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_authorities_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_authorities_tmp_n1 UNUSABLE';

            SELECT NAME
            INTO   l_state
            FROM   geo_states
            WHERE  state_code = stcode_i;

            INSERT INTO osr_zone_authorities_tmp
                SELECT DISTINCT TRIM(stcode_i) state_code, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name, za.range_min, za.range_max, authority_name
                FROM   sbxtax.ct_zone_authorities za
                WHERE  zone_3_name = l_state
                    AND authority_name IN (SELECT DISTINCT official_name FROM osr_rates_tmp)
                ORDER BY zone_6_name, zone_4_name, zone_5_name, authority_name;
            COMMIT;

            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_authorities_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_authorities_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine authority tree mappings - osr_zone_authorities_tmp', paction=>1, puser=>user_i);


            -- Determine Areas with Jurisdiction Overrides --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine area overrides - osr_zone_areas_tmp', paction=>0, puser=>user_i);

            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_areas_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_areas_tmp_n1 UNUSABLE';
            INSERT INTO osr_zone_areas_tmp
                (unique_area_id, unique_area_rid, unique_area_nkid, official_name, jurisdiction_id, jurisdiction_nkid, unique_area, state_code, effective_level)
                 SELECT DISTINCT
                        uaa.unique_area_id
                        , uaa.unique_area_rid
                        , uaa.unique_area_nkid
                        , uaa.VALUE  official_name
                        , j.id       jurisdiction_id
                        , j.nkid     jurisdiction_nkid
                        , guas.unique_area
                        , guas.state_code
                        , j.effective_level
                 FROM   osr_zone_area_ovrd_tmp uaa  -- 09/29/17 - new staging table     --overrides uaa
                        JOIN vgeo_unique_area_search guas ON (uaa.unique_area_id = guas.unique_area_id)
                        JOIN (SELECT j1.id
                                     , j1.nkid
                                     , j1.official_name
                                     , NVL(rlo.rate_level, gac.NAME) effective_level
                              FROM   jurisdictions j1
                                     JOIN geo_area_categories gac ON (j1.geo_area_category_id = gac.id)
                                     LEFT JOIN osr_rate_level_overrides rlo ON (j1.nkid = rlo.nkid  -- Rate Level Override -- crapp-3416
                                                                                AND NVL(rlo.unabated,'N') != 'Y')
                              WHERE  j1.next_rid IS NULL
                                     AND j1.nkid IN (SELECT jurisdiction_nkid FROM osr_rates_tmp) -- Limit Jursidictions to only those with ST/SU rates - crapp-3456
                                     AND j1.nkid NOT IN (SELECT nkid FROM osr_rate_exclusions WHERE nkid IS NOT NULL)
                                     AND j1.nkid NOT IN ( SELECT DISTINCT juris_nkid              -- Exclude SERVICE Jurisdicions - crapp-3416 --
                                                          FROM   vjurisdiction_attributes
                                                          WHERE  VALUE = 'SERVICES'
                                                                 AND next_rid IS NULL
                                                                 AND status = 2
                                                     )
                             ) j ON (uaa.value_id = j.nkid)
                 WHERE  guas.state_code = stcode_i;
            COMMIT;
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_areas_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_areas_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine area overrides - osr_zone_areas_tmp', paction=>1, puser=>user_i);


            -- Build mapped Jurisdiction staging table - osr_zone_mapped_auths_tmp --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build mapped Jurisdiction staging table - osr_zone_mapped_auths_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_mapped_auths_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_mapped_auths_tmp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_mapped_auths_tmp_n2 UNUSABLE';

            INSERT INTO osr_zone_mapped_auths_tmp
                (state_code, official_name, jurisdiction_id, jurisdiction_nkid, rid, nkid, geo_polygon_rid)
                SELECT  DISTINCT state_code, official_name, jurisdiction_id, jurisdiction_nkid, rid, nkid, geo_polygon_rid
                FROM    vjuris_geo_areas
                WHERE   state_code = stcode_i
                        AND jurisdiction_nkid NOT IN ( SELECT DISTINCT juris_nkid               -- Exclude SERVICE Jurisdicions - crapp-3416 --
                                                       FROM   vjurisdiction_attributes
                                                       WHERE  VALUE = 'SERVICES'
                                                              AND next_rid IS NULL
                                                              AND status = 2
                                                     )
                        AND jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_exclusions WHERE nkid IS NOT NULL) -- Exclude specific Jurisdictions based on Tax Research - crapp-3416
                        AND jurisdiction_nkid IN (SELECT jurisdiction_nkid FROM osr_rates_tmp); -- Limit Jursidictions to only those with ST/SU rates - crapp-3456
            COMMIT;

            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_mapped_auths_tmp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_mapped_auths_tmp_n2 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_mapped_auths_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build mapped Jurisdiction staging table - osr_zone_mapped_auths_tmp', paction=>1, puser=>user_i);


            -- 11/10/17 - added for performance changes --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - UA detail stage table - osr_zone_detail_areas_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_detail_areas_tmp DROP STORAGE';
            INSERT INTO osr_zone_detail_areas_tmp
                (state_code, unique_area, area_id)
                SELECT DISTINCT
                       state_code
                       , UPPER(unique_area) unique_area
                       , area_id
                FROM   vgeo_unique_areas2
                WHERE  state_code = stcode_i;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - UA detail stage table - osr_zone_detail_areas_tmp', paction=>1, puser=>user_i);

            -- Build temp table of GIS Zip data --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get zip data detail - osr_zone_detail_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_detail_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n3 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n4 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n5 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n6 UNUSABLE';    -- 07/22/17

            -- 11/10/17 - changed to limited fetch loop for performance --
            OPEN detail(stcode_i);
            LOOP
                FETCH detail BULK COLLECT INTO v_dtl LIMIT 25000;

                FORALL d IN 1..v_dtl.COUNT
                    INSERT INTO osr_zone_detail_tmp
                    VALUES v_dtl(d);
                COMMIT;

                EXIT WHEN detail%NOTFOUND;
            END LOOP;
            COMMIT;

            v_dtl := t_dtl();
            CLOSE detail;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get zip data detail - osr_zone_detail_tmp', paction=>1, puser=>user_i);


            -- crapp-3211 -- Determine records for Acceptable Mailing City - (UNINCORPORATED)
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get zip detail for Acceptable Mailing Cities (UNINCORPORATED) - osr_zone_detail_tmp', paction=>0, puser=>user_i);

            -- 02/13/17 - created staging table for performance improvements --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get USPS staging detail - osr_zone_detail_usps_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_detail_usps_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_usps_tmp_n1 UNUSABLE';
            INSERT INTO osr_zone_detail_usps_tmp
                SELECT DISTINCT
                       u.state_code
                       , UPPER(u.state_name) state_name
                       , SUBSTR(UPPER(u.county_name), 1, 65) county_name
                       --, SUBSTR(REPLACE(UPPER(u.county_name), cn.orig_name, cn.new_name), 1, 65) county_name
                       , UPPER(u.city_name)  city_name
                       , u.zip
                       , SUBSTR(u.zip9, 6, 4) zip4
                       , u.zip9
                       , TRIM(CASE WHEN u.override_rank = 1 THEN 'Y' ELSE NULL END) default_flag
                       , u.area_id
                       , u.geo_polygon_id
                FROM   geo_usps_lookup u
                       --LEFT JOIN osr_convert_names cn ON (1=1) -- crapp-3416 - 03/08/17 removed
                WHERE u.state_code = stcode_i
                      AND UPPER(u.city_name) = 'UNINCORPORATED';
            COMMIT;
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_usps_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_detail_usps_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get USPS staging detail - osr_zone_detail_usps_tmp', paction=>1, puser=>user_i);

            -- 09/29/17 - changed to a limited fetch loop for performance --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_detail_areas_tmp DROP STORAGE';
            INSERT INTO osr_zone_detail_areas_tmp
                (
                    state_code
                    , county_name
                    , city_name
                    , zip
                    , zip9
                    , unique_area
                    , area_id
                )
                SELECT DISTINCT
                       state_code
                       , county_name
                       , city_name
                       , zip
                       , zip9
                       , unique_area
                       , area_id
                FROM   vgeo_unique_areas2
                WHERE  state_code = stcode_i;
            COMMIT;

            -- 09/29/17 - changed to a limited fetch loop for performance --
            OPEN dtl_unincorp(stcode_i);
            LOOP
                FETCH dtl_unincorp BULK COLLECT INTO v_zonedetail LIMIT 50000;

                FORALL i IN 1..v_zonedetail.COUNT
                    INSERT INTO osr_zone_detail_tmp
                    VALUES v_zonedetail(i);
                COMMIT;

                EXIT WHEN dtl_unincorp%NOTFOUND;
            END LOOP;
            COMMIT;

            CLOSE dtl_unincorp;
            v_zonedetail := t_zonedetail();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get zip detail for Acceptable Mailing Cities (UNINCORPORATED) - osr_zone_detail_tmp', paction=>1, puser=>user_i);


            -- crapp-3211 -- Determine records for Acceptable Mailing City - (Other City Names)
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get zip detail for Acceptable Mailing Cities (Other City Names) - osr_zone_detail_tmp', paction=>0, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get USPS staging detail - osr_zone_detail_usps_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_detail_usps_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_usps_tmp_n1 UNUSABLE';

            -- 04/18/17 - converted to collection for performance --
            SELECT DISTINCT
                   u.state_code
                   , UPPER(u.state_name) state_name
                   , SUBSTR(UPPER(u.county_name), 1, 65) county_name
                   , SUBSTR(UPPER(u.city_name), 1, 65)   city_name
                   --, SUBSTR(REPLACE(UPPER(u.county_name), cn.orig_name, cn.new_name), 1, 65) county_name
                   --, SUBSTR(REPLACE(UPPER(u.city_name), cn.orig_name, cn.new_name), 1, 65)   city_name
                   , u.zip
                   , SUBSTR(u.zip9, 6, 4) zip4
                   , u.zip9
                   , TRIM(CASE WHEN u.override_rank = 1 THEN TRIM('Y') ELSE NULL END) default_flag
                   , u.area_id
                   , u.geo_polygon_id
            BULK COLLECT INTO v_detail
            FROM   geo_usps_lookup u
                   --LEFT JOIN osr_convert_names cn ON (1=1) -- crapp-3416 - 03/08/17 removed
            WHERE u.state_code = stcode_i;

            FORALL i IN v_detail.first..v_detail.last
                INSERT INTO osr_zone_detail_usps_tmp
                VALUES v_detail(i);
            COMMIT;
            v_detail := t_detail();
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_usps_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_detail_usps_tmp', cascade => TRUE);

            DELETE FROM osr_zone_detail_usps_tmp WHERE state_code = stcode_i AND city_name = 'UNINCORPORATED';
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>'   - Get USPS staging detail - osr_zone_detail_usps_tmp', paction=>1, puser=>user_i);

            -- 05/12/17 - converted to collection
            SELECT /*+parallel(u,4) index(u osr_zone_detail_usps_tmp_n1)*/
                   DISTINCT
                   u.state_code
                   , u.state_name
                   , u.county_name
                   , SUBSTR(UPPER(mc.city_name), 1, 65) city_name
                   --, SUBSTR(REPLACE(UPPER(mc.city_name), cn.orig_name, cn.new_name), 1, 65) city_name
                   , u.zip
                   , u.zip9
                   , u.zip4
                   , u.default_flag
                   , TRIM('00000') code_fips      -- crapp-3416
                   , p.geo_area --ac.NAME  geo_area
                   , gua.unique_area
                   , p.rid
                   --, NULL tax_area_id           -- crapp-3971 - removed
                   , u.area_id
                   , TRIM('Y') acceptable_city    -- crapp-3244
            BULK COLLECT INTO v_zonedetail
            FROM  osr_zone_detail_usps_tmp u      -- now using staging table instead of geo_usps_lookup - 01/12/17
                  JOIN --vgeo_polygons -- 05/10/17 replaced with only needed items from view
                       (
                         SELECT  /*+index(p geo_polygons_un)*/
                                 DISTINCT
                                 p.id
                                 , p.rid
                                 , p.nkid
                                 , p.next_rid
                                 , p.geo_area_key
                                 , ac.NAME  geo_area
                         FROM    geo_poly_ref_revisions r
                                 JOIN geo_polygons p ON (    r.nkid = p.nkid
                                                         AND rev_join (p.rid, r.id, COALESCE(p.next_rid, 999999999)) = 1)
                                 JOIN hierarchy_levels hl ON (p.hierarchy_level_id = hl.id)
                                 JOIN geo_area_categories ac ON (hl.geo_area_category_id = ac.id)
                         WHERE   SUBSTR(geo_area_key, 1, 2) = stcode_i
                                 AND p.next_rid IS NULL
                       ) p ON (p.id = u.geo_polygon_id)
                  LEFT JOIN vgeo_unique_areas2 gua ON (    u.state_code    = gua.state_code
                                                       AND NVL(u.zip, -1)  = NVL(gua.zip, -1)
                                                       AND NVL(u.zip9, -1) = NVL(gua.zip9, -1)
                                                       --AND u.county_name   = gua.county_name    -- 07/12/17, added    -- 07/18/17 out??
                                                       --AND u.city_name     = gua.city_name      -- 07/12/17, added    -- 07/18/17 out??
                                                       AND u.area_id       = gua.area_id      -- 07/12/17, removed      -- 07/18/17 back in??
                                                      )
                  -- crapp-3416, using Preferred City table directly --
                  JOIN osr_usps_preferred_city mc ON (    u.state_code  = mc.state_code
                                                      AND u.zip         = mc.zip
                                                      AND u.county_name = mc.county_name
                                                      AND u.city_name  != mc.city_name
                                                      AND u.area_id     = mc.area_id        -- 07/18/17, back in??
                                                     )
                  --LEFT JOIN osr_convert_names cn ON (1=1) -- crapp-3416 - 03/08/17 removed
            WHERE u.state_code = stcode_i;
                  --AND gua.zip IS NULL; -- 07/12/17, added -- 07/18/17 out??

            FORALL i IN v_zonedetail.first..v_zonedetail.last
                INSERT INTO osr_zone_detail_tmp
                VALUES v_zonedetail(i);
            COMMIT;
            v_zonedetail := t_zonedetail();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get zip detail for Acceptable Mailing Cities (Other City Names) - osr_zone_detail_tmp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - osr_zone_detail_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n3 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n4 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n5 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_detail_tmp_n6 REBUILD'; -- 07/22/17
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_detail_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - osr_zone_detail_tmp', paction=>1, puser=>user_i);


            -- Update Default Flag -- 07/18/17, added
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Flag - osr_zone_detail_tmp', paction=>0, puser=>user_i);
            SELECT DISTINCT
                   state_code
                   , NULL state_name
                   , county_name
                   , city_name
                   , zip
                   , NULL zip4
                   , NULL zip9
                   , default_flag
                   , area_id
                   , NULL geo_polygon_id
            BULK COLLECT INTO v_detail
            FROM   osr_zone_detail_tmp
            WHERE  default_flag = 'Y'
            ORDER BY area_id, zip;

            FORALL d IN v_detail.first..v_detail.last
                UPDATE osr_zone_detail_tmp z
                    SET default_flag = v_detail(d).default_flag
                WHERE     z.state_code  = v_detail(d).state_code
                      AND z.county_name = v_detail(d).county_name
                      AND z.city_name   = v_detail(d).city_name
                      AND z.zip         = v_detail(d).zip
                      AND z.area_id     = v_detail(d).area_id
                      AND z.default_flag IS NULL;
            COMMIT;
            v_detail := t_detail();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Default Flag - osr_zone_detail_tmp', paction=>1, puser=>user_i);


            -- Get Zipcode detail for Jurisdictions with no Overrides --
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_area_list_tmp DROP STORAGE';

            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n1 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n2 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n3 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n4 UNUSABLE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n5 UNUSABLE';

            -- Splitting into Multiple County ranges for inserts
            v_county_start := t_counties('', '', '', '', '');
            v_county_end   := t_counties('', '', '', '', '');
            v_county_start(1) := 'A';
            v_county_end(1)   := 'EZZ';
            v_county_start(2) := 'F';
            v_county_end(2)   := 'JZZ';
            v_county_start(3) := 'K';
            v_county_end(3)   := 'OZZ';
            v_county_start(4) := 'P';
            v_county_end(4)   := 'TZZ';
            v_county_start(5) := 'U';
            v_county_end(5)   := 'ZZZ';

            FOR i IN 1..5 LOOP
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip9 detail no overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>0, puser=>user_i);
                SELECT /*+parallel(g,4) index(g osr_zone_detail_tmp_n4)*/
                       DISTINCT
                       g.unique_area
                       , NVL(d.stj_flag, 0) stj_flag    -- 07/11/17, changed from NULL
                       , g.state_name
                       , g.county_name
                       , g.city_name
                       , g.zip
                       , g.zip4
                       , NULL default_flag   -- 07/19/17, changed from "g." - assigning later
                       , g.code_fips
                       , g.state_code
                       , jpa.jurisdiction_id
                       , jpa.official_name
                       , jpa.rid
                       , jpa.nkid
                       , NVL(rlo.rate_level, gac.NAME) geo_area  -- crapp-3338, changed from g.geo_area, crapp-3416 added NVL
                       --, CASE WHEN g.code_fips IN ('00000', '99999') THEN REPLACE(g.area_id, SUBSTR(area_id,7,6), '-00000') ELSE g.area_id END area_id -- crapp-3416
                       , NULL geoarea_updated
                       --, NULL tax_area_id     -- crapp-3971 - removed
                       , g.area_id
                       , g.acceptable_city      -- crapp-3244
                BULK COLLECT INTO v_arealist
                FROM   osr_zone_detail_tmp g
                       JOIN osr_zone_mapped_auths_tmp jpa ON (g.rid = jpa.geo_polygon_rid)
                       JOIN jurisdictions j ON (jpa.jurisdiction_nkid = j.nkid)
                       JOIN geo_area_categories gac ON (j.geo_area_category_id = gac.id)    -- crapp-3338
                       LEFT JOIN osr_rate_level_overrides rlo ON (j.nkid = rlo.nkid         -- Rate Level Override -- crapp-3416
                                                                  AND NVL(rlo.unabated,'N') != 'Y')
                       LEFT JOIN osr_zone_stj_areas_tmp d ON (g.unique_area = d.unique_area
                                                              AND g.zip9 = d.zip9)
                WHERE  g.state_code = stcode_i
                       AND g.county_name BETWEEN v_county_start(i) AND v_county_end(i)
                       AND g.zip4 IS NOT NULL
                       --AND g.geo_area <> 'State'  -- Removed, crapp-3211
                       --AND g.default_flag = 'Y'   -- Depending on OSR rate file, multi-points may be extracted
                       AND j.nkid IN (SELECT /*+index(tt osr_zone_auth_tags_tmp_n1)*/ ref_nkid FROM osr_zone_auth_tags_tmp tt)
                       AND j.next_rid IS NULL
                       AND NOT EXISTS ( SELECT 1
                                        FROM   osr_zone_areas_tmp o
                                        WHERE      g.unique_area = o.unique_area
                                               AND g.state_code  = o.state_code
                                      );

                FORALL i IN v_arealist.first..v_arealist.last
                    INSERT INTO osr_zone_area_list_tmp
                    VALUES v_arealist(i);
                COMMIT;
                v_arealist := t_arealist();
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip9 detail no overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>1, puser=>user_i);
            END LOOP;


            FOR i IN 1..5 LOOP
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip5 detail no overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>0, puser=>user_i);

                INSERT INTO osr_zone_area_list_tmp
                      (unique_area
                       , stj_flag
                       , state_name
                       , county_name
                       , city_name
                       , zip
                       , zip4
                       , default_flag
                       , code_fips      -- crapp-3416
                       , state_code
                       , jurisdiction_id
                       , official_name
                       , rid
                       , nkid
                       , geo_area
                       , area_id
                       , acceptable_city
                      )
                SELECT  /*+index(g osr_zone_detail_tmp_n4)*/
                       DISTINCT
                       g.unique_area
                       , NVL(sa.stj_flag, 0) stj_flag   -- 07/11/17, added per meeting
                       , g.state_name
                       , g.county_name
                       , g.city_name
                       , g.zip
                       , g.zip4
                       , NULL default_flag   -- 07/19/17, changed from "g." - assigning later
                       , g.code_fips
                       , g.state_code
                       , jpa.jurisdiction_id
                       , jpa.official_name
                       , jpa.rid
                       , jpa.nkid
                       , NVL(rlo.rate_level, gac.NAME) geo_area  -- crapp-3338, changed from g.geo_area, crapp-3416 added NVL
                       --, CASE WHEN g.code_fips IN ('00000', '99999') THEN REPLACE(g.area_id, SUBSTR(area_id,7,6), '-00000') ELSE g.area_id END area_id -- crapp-3416
                       , g.area_id
                       , g.acceptable_city  -- crapp-3244
                FROM   osr_zone_detail_tmp g
                       JOIN osr_zone_mapped_auths_tmp jpa ON (g.rid = jpa.geo_polygon_rid)
                       JOIN jurisdictions j ON (jpa.jurisdiction_nkid = j.nkid)
                       JOIN geo_area_categories gac ON (j.geo_area_category_id = gac.id)    -- crapp-3338
                       LEFT JOIN osr_rate_level_overrides rlo ON (j.nkid = rlo.nkid         -- Rate Level Override -- crapp-3416
                                                                  AND NVL(rlo.unabated,'N') != 'Y')
                       LEFT JOIN gis_zone_stj_areas_tmp sa ON ( g.unique_area = sa.unique_area
                                                                AND g.zip = SUBSTR(sa.zip9,1,5))
                WHERE  g.state_code = stcode_i
                       AND g.county_name BETWEEN v_county_start(i) AND v_county_end(i)
                       AND g.zip IS NOT NULL
                       AND g.zip4 IS NULL
                       --AND g.geo_area <> 'State'  -- Removed, crapp-3211
                       --AND g.default_flag = 'Y'   -- Depending on OSR rate file, multi-points may be extracted
                       AND j.nkid IN (SELECT /*+index(tt osr_zone_auth_tags_tmp_n1)*/ ref_nkid FROM osr_zone_auth_tags_tmp tt)
                       AND j.next_rid IS NULL
                       AND NOT EXISTS ( SELECT 1
                                        FROM   osr_zone_areas_tmp o
                                        WHERE      g.unique_area = o.unique_area
                                               AND g.state_code  = o.state_code
                                      );
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip5 detail no overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>1, puser=>user_i);
            END LOOP;


            -- Get Zipcode detail for Jurisdictions with Overrides --
            FOR i IN 1..5 LOOP
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip9 detail with overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>0, puser=>user_i);

                WITH detail AS
                    ( SELECT  /*+index(g osr_zone_detail_tmp_n4)*/
                              DISTINCT
                              g.unique_area
                            , g.geo_area
                            , g.state_name
                            , g.county_name
                            , g.city_name
                            , zip
                            , zip9
                            , zip4
                            , NULL default_flag   -- 07/19/17, changed from "g." - assigning later
                            , g.code_fips
                            , g.state_code
                            , g.rid
                            , p.nkid
                            --, CASE WHEN g.code_fips IN ('00000', '99999') THEN REPLACE(g.area_id, SUBSTR(area_id,7,6), '-00000') ELSE g.area_id END area_id -- crapp-3416
                            , g.area_id
                            , g.acceptable_city
                      FROM  osr_zone_detail_tmp g
                            JOIN geo_polygons p ON (g.rid = p.rid
                                                    AND p.next_rid IS NULL
                                                   )
                      WHERE   g.state_code = stcode_i
                              AND g.county_name BETWEEN v_county_start(i) AND v_county_end(i)
                              AND g.zip4 IS NOT NULL
                              --AND g.default_flag = 'Y'  -- Depending on OSR rate file, multi-points may be extracted
                    )
                    SELECT  /*+index(z osr_zone_detail_tmp_n1)*/
                            DISTINCT
                            d.unique_area
                            , NVL(sa.stj_flag, 0) stj_flag  -- 07/11/17, added per meeting
                            , d.state_name
                            , d.county_name
                            , d.city_name
                            , d.zip
                            , d.zip4
                            , d.default_flag
                            , d.code_fips
                            , d.state_code
                            , o.jurisdiction_id
                            , o.official_name
                            , d.rid
                            , d.nkid
                            , NULL geo_area  --d.geo_area -- crapp-3416, 03/10/17 - removed to use Override step instead (TEST)
                            , 1 geoarea_updated     -- 07/17/17, changed to "1" to indicate overrides
                            --, NULL tax_area_id    -- crapp-3971 - removed
                            , d.area_id
                            , d.acceptable_city     -- crapp-3244
                    BULK COLLECT INTO v_arealist
                    FROM    detail d
                            JOIN osr_zone_areas_tmp o ON ( d.unique_area = o.unique_area
                                                            AND d.state_code = o.state_code
                                                            --AND d.geo_area   = o.effective_level -- crapp-3416, removed 03/10/17
                                                          )
                            LEFT JOIN gis_zone_stj_areas_tmp sa ON ( d.unique_area = sa.unique_area
                                                                     AND d.zip9 = sa.zip9)
                    WHERE   o.jurisdiction_nkid IN (SELECT /*+index(tt osr_zone_auth_tags_tmp_n1)*/ ref_nkid FROM osr_zone_auth_tags_tmp tt);

                FORALL i IN v_arealist.first..v_arealist.last
                    INSERT INTO osr_zone_area_list_tmp
                    VALUES v_arealist(i);
                COMMIT;

                v_arealist := t_arealist();
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip9 detail with overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>1, puser=>user_i);
            END LOOP;


            FOR i IN 1..5 LOOP
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get Jurisdiction zip5 detail with overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>0, puser=>user_i);

                WITH detail AS
                    ( SELECT  /*+index(g osr_zone_detail_tmp_n4)*/
                              DISTINCT
                              g.unique_area
                            , g.geo_area
                            , g.state_name
                            , g.county_name
                            , g.city_name
                            , zip
                            , NULL zip9
                            , NULL zip4
                            , NULL default_flag   -- 07/19/17, changed from "g." - assigning later
                            , g.code_fips
                            , g.state_code
                            , g.rid
                            , p.nkid
                            --, CASE WHEN g.code_fips IN ('00000', '99999') THEN REPLACE(g.area_id, SUBSTR(area_id,7,6), '-00000') ELSE g.area_id END area_id -- crapp-3416
                            , g.area_id
                            , g.acceptable_city
                      FROM  osr_zone_detail_tmp g    --TABLE(post_publish.F_GetZoneDetailFeed(stcode_i)) g -- crapp-2911, using table directly
                            JOIN geo_polygons p ON (g.rid = p.rid
                                                    AND p.next_rid IS NULL
                                                   )
                      WHERE   g.state_code = stcode_i
                              AND g.county_name BETWEEN v_county_start(i) AND v_county_end(i)
                              AND g.zip IS NOT NULL
                              AND g.zip4 IS NULL
                              --AND g.default_flag = 'Y'  -- Depending on OSR rate file, multi-points may be extracted
                    )
                    SELECT  /*+index(z osr_zone_detail_tmp_n1)*/
                            DISTINCT
                            d.unique_area
                            , NVL(sa.stj_flag, 0) stj_flag -- 07/11/17, changed per meeting from "0"
                            , d.state_name
                            , d.county_name
                            , d.city_name
                            , d.zip
                            , d.zip4
                            , d.default_flag
                            , d.code_fips
                            , d.state_code
                            , o.jurisdiction_id
                            , o.official_name
                            , d.rid
                            , d.nkid
                            , NULL geo_area  --d.geo_area -- crapp-3416, 03/10/17 - removed to use Override step instead (TEST)
                            , 1 geoarea_updated     -- 07/17/17, changed to "1" to indicate overrides
                            --, NULL tax_area_id    -- crapp-3971 - removed
                            , d.area_id
                            , d.acceptable_city     -- crapp-3244
                    BULK COLLECT INTO v_arealist
                    FROM    detail d
                            JOIN osr_zone_areas_tmp o ON ( d.unique_area = o.unique_area
                                                            AND d.state_code = o.state_code
                                                            --AND d.geo_area   = o.effective_level -- crapp-3416, removed 03/10/17
                                                          )
                            LEFT JOIN gis_zone_stj_areas_tmp sa ON ( d.unique_area = sa.unique_area
                                                                     AND d.zip = SUBSTR(sa.zip9,1,5))
                    WHERE   o.jurisdiction_nkid IN (SELECT /*+index(tt osr_zone_auth_tags_tmp_n1)*/ ref_nkid FROM osr_zone_auth_tags_tmp tt);

                FORALL i IN v_arealist.first..v_arealist.last
                    INSERT INTO osr_zone_area_list_tmp
                    VALUES v_arealist(i);
                COMMIT;

                v_arealist := t_arealist();
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=> ' - Get Jurisdiction zip5 detail with overrides '||v_county_start(i)||' to '||v_county_end(i)||' - osr_zone_area_list_tmp', paction=>1, puser=>user_i);
            END LOOP;

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - osr_zone_area_list_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n1 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n4 REBUILD';
            --EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n2 REBUILD';    -- rebuilding after Step1 override update
            --EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n3 REBUILD';
            --EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n5 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_area_list_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - osr_zone_area_list_tmp', paction=>1, puser=>user_i);


            -- crapp-3458 - Added 03/08/17 to update GEO_AREA based on where the authority is attached --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 1) - osr_zone_area_list_tmp', paction=>0, puser=>user_i);
            SELECT  /*+index(p geo_polygons_n1)*/
                    DISTINCT
                    j.state_code
                    , j.official_name
                    , j.geo_polygon_rid
                    , g.NAME geo_area
            BULK COLLECT INTO v_geoarea
            FROM    osr_zone_mapped_auths_tmp j
                    JOIN geo_polygons p        ON (j.geo_polygon_rid = p.rid)
                    JOIN hierarchy_levels h    ON (p.hierarchy_level_id = h.id)
                    JOIN geo_area_categories g ON (h.geo_area_category_id = g.id)
            WHERE  state_code = stcode_i
                   AND NOT EXISTS ( SELECT 1    -- crapp-4167, 11/15/17
                                    FROM   osr_rate_level_overrides rlo
                                    WHERE  rlo.state_code = j.state_code
                                           AND rlo.official_name = j.official_name
                                           AND NVL(rlo.unabated,'N') != 'Y'
                                  );

            FORALL i IN 1..v_geoarea.COUNT
                UPDATE  osr_zone_area_list_tmp
                    SET geo_area = v_geoarea(i).geo_area
                WHERE      state_code    = v_geoarea(i).state_code
                       AND official_name = v_geoarea(i).official_name
                       AND rid           = v_geoarea(i).geo_polygon_rid;
            COMMIT;

            v_geoarea := t_geoarea();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 1) - osr_zone_area_list_tmp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 1) index rebuild - osr_zone_area_list_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n2 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n3 REBUILD';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_area_list_tmp_n5 REBUILD';
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 1) index rebuild - osr_zone_area_list_tmp', paction=>1, puser=>user_i);


            -- crapp-3458 - Added 03/10/17 to update GEO_AREA based on where the authority is attached for Overrides --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 2) - osr_zone_area_list_tmp', paction=>0, puser=>user_i);
            SELECT  DISTINCT
                    state_code
                    , zip
                    , area_id
                    , geo_area
                    , official_name
                    , jurisdiction_id
            BULK COLLECT INTO v_geoarea_step2
            FROM    osr_zone_area_list_tmp
            WHERE   state_code = stcode_i
                    AND geo_area IS NOT NULL;

            FORALL i IN 1..v_geoarea_step2.COUNT
                UPDATE  osr_zone_area_list_tmp
                    SET geo_area = v_geoarea_step2(i).geo_area
                WHERE      state_code      = v_geoarea_step2(i).state_code
                       AND zip             = v_geoarea_step2(i).zip
                       AND area_id         = v_geoarea_step2(i).area_id
                       AND jurisdiction_id = v_geoarea_step2(i).jurisdiction_id
                       AND geo_area IS NULL;
            COMMIT;

            v_geoarea_step2 := t_geoarea_step2();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 2) - osr_zone_area_list_tmp', paction=>1, puser=>user_i);


            -- crapp-3458 - Added 03/10/17 to update GEO_AREA based on Rate Effective Level - Overrides --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 3) - osr_zone_area_list_tmp', paction=>0, puser=>user_i);
            SELECT  DISTINCT
                    a.state_code
                    , a.zip
                    , a.area_id
                    , r.location_category  geo_area
                    , a.official_name
                    , r.jurisdiction_id
            BULK COLLECT INTO v_geoarea_step2
            FROM    osr_zone_area_list_tmp a
                    JOIN osr_rates_tmp r ON (a.jurisdiction_id = r.jurisdiction_id)
            WHERE   a.state_code = stcode_i
                    AND a.geo_area IS NULL;

            FORALL i IN 1..v_geoarea_step2.COUNT
                UPDATE  osr_zone_area_list_tmp
                    SET geo_area = v_geoarea_step2(i).geo_area
                WHERE      state_code      = v_geoarea_step2(i).state_code
                       AND zip             = v_geoarea_step2(i).zip
                       AND area_id         = v_geoarea_step2(i).area_id
                       AND jurisdiction_id = v_geoarea_step2(i).jurisdiction_id
                       AND geo_area IS NULL;
            COMMIT;

            v_geoarea_step2 := t_geoarea_step2();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Override effective_level (Step 3) - osr_zone_area_list_tmp', paction=>1, puser=>user_i);


            -- Update Default Flag -- 07/19/17, added to fix duplicate Zip issue in extracts
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Zip Default Flag - osr_zone_area_list_tmp', paction=>0, puser=>user_i);
            SELECT DISTINCT
                   d.state_code
                   , d.state_name
                   , d.county_name
                   , d.city_name
                   , d.zip
                   , NULL zip4
                   , NULL zip9
                   , CASE WHEN cb.zip9rank != 1 THEN NULL ELSE d.default_flag END default_flag   -- crapp-3971
                   , d.area_id
                   , NULL geo_polygon_id
            BULK COLLECT INTO v_detail
            FROM   (
                    SELECT DISTINCT
                           state_code
                           , state_name
                           , county_name
                           , city_name
                           , zip
                           , CASE WHEN override_rank = 1 THEN TRIM('Y') ELSE NULL END default_flag
                           , area_id
                    FROM   geo_usps_lookup
                    WHERE state_Code = stcode_i
                          AND zip IS NOT NULL
                          AND zip9 IS NULL
                   ) d
                   LEFT JOIN osr_crossborder_zips_tmp cb ON (d.state_code  = cb.state_code
                                                             AND d.zip     = cb.zip
                                                             AND d.county_name = cb.county_name -- added 08/18/17
                                                             AND d.city_name   = cb.city_name   -- added 08/18/17
                                                             --AND d.area_id = cb.area_id       -- removed 08/18/17
                                                            )
            ORDER BY d.zip, d.area_id;

            FORALL d IN v_detail.first..v_detail.last
                UPDATE osr_zone_area_list_tmp z
                    SET default_flag = v_detail(d).default_flag
                WHERE     z.state_code  = v_detail(d).state_code
                      --AND z.county_name = v_detail(d).county_name
                      --AND z.city_name   = v_detail(d).city_name
                      AND z.zip         = v_detail(d).zip
                      AND z.area_id     = v_detail(d).area_id;
            COMMIT;
            v_detail := t_detail();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Zip Default Flag - osr_zone_area_list_tmp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' determine_zip_data', paction=>1, puser=>user_i);
        END determine_zip_data;



    PROCEDURE determine_zip4_data -- 11/09/17 - crapp-4169
    (
        stcode_i  IN VARCHAR2,
        pID_i     IN NUMBER,
        user_i    IN NUMBER
    )
    IS
            l_firstpass  BOOLEAN := TRUE;
            l_areaid     VARCHAR2(60 CHAR);
            l_county     VARCHAR2(64 CHAR);
            l_city       VARCHAR2(64 CHAR);
            l_rec_type   CHAR(1);
            l_default    CHAR(1);
            l_zip        CHAR(5);
            l_zip4min    CHAR(4);
            l_nextzip4   CHAR(4);

            -- crapp-4169 --
            CURSOR zip4tree IS
                SELECT  DISTINCT        -- Zip Defaults --
                        state_code
                        , state_name
                        , zip
                        , TRIM('0000') zip4
                        , TRIM('Y')    default_flag
                        , county_name
                        , city_name
                        , area_id
                        , TRIM('Z') rec_type
                FROM    geo_usps_lookup
                WHERE   state_code = stcode_i
                        AND zip IS NOT NULL
                        AND zip9 IS NULL
                        AND override_rank = 1
                UNION
                SELECT  DISTINCT        -- Zip4 Defaults --
                        state_code
                        , state_name
                        , zip
                        , NVL(SUBSTR(zip9,6,4), '0000') zip4
                        , TRIM('Y') default_flag
                        , county_name
                        , city_name
                        , area_id
                        , TRIM('4') rec_type
                FROM    geo_usps_lookup
                WHERE   state_code = stcode_i
                        AND (SUBSTR(zip9,6,4) IS NOT NULL
                             OR ASCII(SUBSTR(zip9,6,4)) BETWEEN 48 AND 57   -- exclude FOUR Zip4s
                            )
                        AND NOT ASCII(SUBSTR(SUBSTR(zip9,6,4),3,2)) BETWEEN 65 AND 90
                        AND override_rank = 1
                ORDER BY zip, zip4, county_name, city_name, area_id;

        BEGIN

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' determine_zip4_data', paction=>0, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove previous ranges - osr_zone_zip4_ranges_tmp', paction=>0, puser=>user_i);
            DELETE FROM osr_zone_zip4_ranges_tmp WHERE state_code = stcode_i;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove previous ranges - osr_zone_zip4_ranges_tmp', paction=>1, puser=>user_i);

            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_zip4_ranges_tmp_n1 UNUSABLE';

            -- Determine zip code ranges --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build zip code ranges - osr_zone_zip4_ranges_tmp', paction=>0, puser=>user_i);
            FOR t IN zip4tree LOOP <<zip4tree_loop>>

                IF l_firstpass THEN -- first pass
                    l_firstpass := FALSE;
                    l_areaid    := t.area_id;
                    l_county    := t.county_name;
                    l_city      := t.city_name;
                    l_default   := t.default_flag;
                    l_rec_type  := t.rec_type;
                    l_zip       := t.zip;
                    l_zip4min   := t.zip4;
                ELSE
                    -- Determine the if the Zip Range needs to updated
                    IF     l_county   <> t.county_name
                        OR l_city     <> t.city_name
                        OR l_rec_type <> t.rec_type
                        OR l_zip      <> t.zip THEN

                        IF l_zip4min = '0000' THEN
                            l_nextzip4 := l_zip4min;
                        END IF;

                        INSERT INTO osr_zone_zip4_ranges_tmp
                            (state_code, zip, zip4_range, range_min, range_max, rec_type, area_id, default_flag, county_name, city_name)
                            VALUES ( stcode_i
                                     , l_zip
                                     , NVL2(l_zip4min, (l_zip4min ||'-'|| l_nextzip4), NULL)
                                     , l_zip4min
                                     , l_nextzip4
                                     , l_rec_type
                                     , l_areaid
                                     , l_default
                                     , l_county
                                     , l_city
                                   );

                        l_zip4min  := t.zip4;
                        l_nextzip4 := t.zip4;
                        l_county   := t.county_name;
                        l_city     := t.city_name;
                        l_areaid   := t.area_id;
                        l_zip      := t.zip;
                        l_rec_type := t.rec_type;
                        l_default  := t.default_flag;
                    ELSE

                        l_nextzip4 :=  t.zip4;

                    END IF;
                END IF;

            END LOOP zip4tree_loop;
            COMMIT;

            -- End of Loop, so output last range record
            INSERT INTO osr_zone_zip4_ranges_tmp
                (state_code, zip, zip4_range, range_min, range_max, rec_type, area_id, default_flag, county_name, city_name)
                VALUES ( stcode_i
                         , l_zip
                         , NVL2(l_zip4min, (l_zip4min ||'-'|| l_nextzip4), NULL)
                         , l_zip4min
                         , l_nextzip4
                         , l_rec_type
                         , l_areaid
                         , l_default
                         , l_county
                         , l_city
                       );
            COMMIT;
            EXECUTE IMMEDIATE 'ALTER INDEX osr_zone_zip4_ranges_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_zone_zip4_ranges_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Build zip code ranges - osr_zone_zip4_ranges_tmp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' determine_zip4_data', paction=>1, puser=>user_i);
        END determine_zip4_data;



    PROCEDURE get_rates    -- 11/01/17 - crapp-4167
    (
        stcode_i   IN VARCHAR2,
        pID_i      IN NUMBER,
        user_i     IN NUMBER,
        start_dt_i IN DATE
    )
    IS
            l_rec  NUMBER;

            TYPE r_ship IS RECORD
            (
              official_name             jurisdictions.official_name%TYPE,
              juris_nkid                jurisdictions.nkid%TYPE,                        -- crapp-3330
              NAME                      commodities.NAME%TYPE,
              commodity_code            commodities.commodity_code%TYPE,
              reference_code            juris_tax_applicabilities.reference_code%TYPE,
              applicability_type        juris_tax_applicabilities.exempt%TYPE,          -- crapp-3330
              exempt                    juris_tax_applicabilities.exempt%TYPE,
              no_tax                    juris_tax_applicabilities.no_tax%TYPE,
              ref_rule_order            juris_tax_applicabilities.ref_rule_order%TYPE
            );
            TYPE t_ship IS TABLE OF r_ship;
            v_ship t_ship;


            CURSOR rates IS
                SELECT s.state_code
                       , NVL(r.rates, 0) ratecnt
                FROM   geo_states s
                       LEFT JOIN (
                                    SELECT state_code, COUNT(1) rates
                                    FROM   osr_rates_tmp
                                    GROUP BY state_code
                                 ) r ON (s.state_code = r.state_code)
                WHERE r.state_code IS NULL
                      AND s.state_code != 'XX';

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' get_rates', paction=>0, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get all ST/SU rates (step 1) - osr_rates_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_rates_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_rates_tmp_n1 UNUSABLE';

            INSERT INTO osr_rates_tmp
                (
                  state_code
                  , id
                  , nkid
                  , rid
                  , next_rid
                  , juris_tax_entity_rid
                  , juris_tax_next_rid
                  , reference_code
                  , start_date
                  , end_date
                  , taxation_type_id
                  , taxation_type
                  , spec_applicability_type_id
                  , specific_applicability_type
                  , transaction_type_id
                  , transaction_type
                  , tax_structure_type_id
                  , tax_structure
                  , value_type
                  , min_threshold
                  , max_limit
                  , tax_value
                  , official_name
                  , jurisdiction_id
                  , jurisdiction_rid
                  , jurisdiction_nkid
                  , ref_juris_tax_rid
                  , status
                  , tax_description
                  , location_category
                  , admin_name
                  , reporting_code
                  , tax_shipping_alone
                  , tax_shipping_and_handling
                )
               -- Based on vTax_Search -- 03/10/17 - crapp-3456
               SELECT /*+parallel(jti,4) parallel(tou,4)*/
                      DISTINCT
                      SUBSTR(jti.official_name, 1, 2) state_code
                      , td2.id
                      , td2.nkid
                      , td2.rid
                      , td2.next_rid
                      , jti.rid  juris_tax_entity_rid
                      , jti.juris_tax_next_rid
                      , jti.reference_code
                      , TO_DATE(tou.start_date, 'mm/dd/yyyy') start_date
                      , TO_DATE(tou.end_date, 'mm/dd/yyyy')   end_date
                      , td.taxation_type_id
                      , td.taxation_type
                      , td.spec_applicability_type_id
                      , td.specific_applicability_type
                      , td.transaction_type_id
                      , td.transaction_type
                      , tcs.id tax_calc_structure_id
                      , tcs.tax_structure
                      , td2.value_type
                      , td2.min_threshold
                      , td2.max_limit
                      , CASE WHEN td2.value_type = 'Rate' THEN (COALESCE(jtr.reference_code, TO_CHAR (td2.VALUE))/100)
                             WHEN td2.value_type = 'Fee'  THEN td2.VALUE
                        END tax_value
                      , vj.official_name              -- crapp-3370, changed from jti
                      , vj.id    jurisdiction_id      -- crapp-3370, changed from jti.jurisdiction_id
                      , vj.rid   jurisdiction_rid     -- crapp-3370, changed from jti.jurisdiction_rid
                      , vj.nkid  jurisdiction_nkid    -- crapp-3370, changed from jti.jurisdiction_nkid
                      , jtr.rid  ref_juris_tax_rid
                      , jti.status
                      , jti.description tax_description
                      , NVL(rlo.rate_level, vj.location_category) location_category -- crapp-3416
                      , vj.default_admin_name    admin_name
                      , NVL(tat.VALUE, ja.VALUE) reporting_code
                      , TRIM('Y') tax_shipping_alone            -- crapp-3416, changed default value to Y
                      , TRIM('Y') tax_shipping_and_handling     -- crapp-3416, changed default value to Y
                FROM  vjuris_tax_impositions jti
                      JOIN vtax_outlines tou ON (tou.juris_tax_rid = jti.juris_tax_entity_rid)
                      JOIN vtax_calc_structures tcs ON (tou.calculation_structure_id = tcs.id)
                      JOIN vtax_descriptions td ON (td.id = jti.tax_description_id)
                      JOIN vtax_definitions2 td2 ON (    TD2.TAX_OUTLINE_nkid = tou.nkid
                                                     AND td2.juris_tax_rid = tou.juris_tax_rid)
                      LEFT JOIN vjuris_tax_impositions jtr ON (td2.ref_juris_tax_id = jtr.id
                                                               AND jtr.rid = jtr.juris_tax_entity_rid
                                                              )
                      -- Reporting Code --
                      LEFT JOIN vtax_attributes tat ON (jti.juris_tax_entity_rid = tat.juris_tax_rid
                                                        AND tat.attribute_id = 8
                                                        AND TO_DATE(tat.start_date, 'mm/dd/yyyy') <= start_dt_i     -- crapp-3416, added dates
                                                        AND (TO_DATE(tat.end_date, 'mm/dd/yyyy') >= start_dt_i OR tat.end_date IS NULL)
                                                        AND tat.status = 2
                                                       )
                      JOIN vjurisdictions vj ON (jti.jurisdiction_nkid = vj.nkid
                                                 AND rev_join(vj.rid, jti.id, COALESCE (vj.next_rid, 9999999999)) = 1
                                                )
                      -- Rate Level Override -- crapp-3416
                      LEFT JOIN osr_rate_level_overrides rlo ON (vj.nkid = rlo.nkid
                                                                 AND NVL(rlo.unabated,'N') != 'Y'
                                                                )
                      -- Default Reporting Code --
                      LEFT JOIN vjurisdiction_attributes ja ON (jti.jurisdiction_rid = ja.juris_rid
                                                                AND ja.juris_next_rid IS NULL
                                                                AND ja.attribute_name = 'Default Reporting Code'
                                                                AND TO_DATE(ja.start_date, 'mm/dd/yyyy') <= start_dt_i
                                                                AND (TO_DATE(ja.end_date, 'mm/dd/yyyy') >= start_dt_i OR ja.end_date IS NULL)
                                                                AND ja.status = 2
                                                               )
                WHERE jti.juris_tax_next_rid IS NULL
                      AND jti.reference_code IN ('ST','SU')
                      AND jti.jurisdiction_nkid IN (SELECT ref_nkid FROM osr_zone_auth_tags_tmp)    -- added 03/08/17
                      -- Return current active rates for reporting period --
                      AND TO_DATE(tou.start_date, 'mm/dd/yyyy') <= start_dt_i     -- crapp-3416, added dates
                      AND (TO_DATE(tou.end_date, 'mm/dd/yyyy') >= start_dt_i OR tou.end_date IS NULL)
                      -- Exclude SERVICES Jurisdicions - crapp-3416 --
                      AND jti.jurisdiction_nkid NOT IN ( SELECT DISTINCT juris_nkid
                                                         FROM   vjurisdiction_attributes
                                                         WHERE  VALUE = 'SERVICES'
                                                                AND next_rid IS NULL
                                                                AND status = 2
                                                       )
                      -- Exclude Jurisdictions based on Tax Research - crapp-3416 --
                      AND jti.jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_exclusions WHERE nkid IS NOT NULL)
                ORDER BY vj.official_name, jti.reference_code, TO_DATE(tou.start_date, 'mm/dd/yyyy'), TO_DATE(tou.end_date, 'mm/dd/yyyy');

            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get all ST/SU rates (step 1) - osr_rates_tmp', paction=>1, puser=>user_i);

            -- crapp-4167 - Added to include Crossborder overrides --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get all ST/SU rates (step 2) - osr_rates_tmp', paction=>0, puser=>user_i);
            INSERT INTO osr_rates_tmp
                (
                  state_code
                  , id
                  , nkid
                  , rid
                  , next_rid
                  , juris_tax_entity_rid
                  , juris_tax_next_rid
                  , reference_code
                  , start_date
                  , end_date
                  , taxation_type_id
                  , taxation_type
                  , spec_applicability_type_id
                  , specific_applicability_type
                  , transaction_type_id
                  , transaction_type
                  , tax_structure_type_id
                  , tax_structure
                  , value_type
                  , min_threshold
                  , max_limit
                  , tax_value
                  , official_name
                  , jurisdiction_id
                  , jurisdiction_rid
                  , jurisdiction_nkid
                  , ref_juris_tax_rid
                  , status
                  , tax_description
                  , location_category
                  , admin_name
                  , reporting_code
                  , tax_shipping_alone
                  , tax_shipping_and_handling
                )
               -- Based on vTax_Search -- 03/10/17 - crapp-3456
               SELECT /*+parallel(jti,4) parallel(tou,4)*/
                      DISTINCT
                      rlo.state_code
                      , td2.id
                      , td2.nkid
                      , td2.rid
                      , td2.next_rid
                      , jti.rid  juris_tax_entity_rid
                      , jti.juris_tax_next_rid
                      , jti.reference_code
                      , TO_DATE(tou.start_date, 'mm/dd/yyyy') start_date
                      , TO_DATE(tou.end_date, 'mm/dd/yyyy')   end_date
                      , td.taxation_type_id
                      , td.taxation_type
                      , td.spec_applicability_type_id
                      , td.specific_applicability_type
                      , td.transaction_type_id
                      , td.transaction_type
                      , tcs.id tax_calc_structure_id
                      , tcs.tax_structure
                      , td2.value_type
                      , td2.min_threshold
                      , td2.max_limit
                      , CASE WHEN td2.value_type = 'Rate' THEN (COALESCE(jtr.reference_code, TO_CHAR (td2.VALUE))/100)
                             WHEN td2.value_type = 'Fee'  THEN td2.VALUE
                        END tax_value
                      , vj.official_name              -- crapp-3370, changed from jti
                      , vj.id    jurisdiction_id      -- crapp-3370, changed from jti.jurisdiction_id
                      , vj.rid   jurisdiction_rid     -- crapp-3370, changed from jti.jurisdiction_rid
                      , vj.nkid  jurisdiction_nkid    -- crapp-3370, changed from jti.jurisdiction_nkid
                      , jtr.rid  ref_juris_tax_rid
                      , jti.status
                      , jti.description tax_description
                      , NVL(rlo.rate_level, vj.location_category) location_category -- crapp-3416
                      , vj.default_admin_name    admin_name
                      , NVL(tat.VALUE, ja.VALUE) reporting_code
                      , TRIM('Y') tax_shipping_alone            -- crapp-3416, changed default value to Y
                      , TRIM('Y') tax_shipping_and_handling     -- crapp-3416, changed default value to Y
                FROM  vjuris_tax_impositions jti
                      JOIN vtax_outlines tou ON (tou.juris_tax_rid = jti.juris_tax_entity_rid)
                      JOIN vtax_calc_structures tcs ON (tou.calculation_structure_id = tcs.id)
                      JOIN vtax_descriptions td ON (td.id = jti.tax_description_id)
                      JOIN vtax_definitions2 td2 ON (    TD2.TAX_OUTLINE_nkid = tou.nkid
                                                     AND td2.juris_tax_rid = tou.juris_tax_rid)
                      LEFT JOIN vjuris_tax_impositions jtr ON (td2.ref_juris_tax_id = jtr.id
                                                               AND jtr.rid = jtr.juris_tax_entity_rid
                                                              )
                      -- Reporting Code --
                      LEFT JOIN vtax_attributes tat ON (jti.juris_tax_entity_rid = tat.juris_tax_rid
                                                        AND tat.attribute_id = 8
                                                        AND TO_DATE(tat.start_date, 'mm/dd/yyyy') <= start_dt_i     -- crapp-3416, added dates
                                                        AND (TO_DATE(tat.end_date, 'mm/dd/yyyy') >= start_dt_i OR tat.end_date IS NULL)
                                                        AND tat.status = 2
                                                       )
                      JOIN vjurisdictions vj ON (jti.jurisdiction_nkid = vj.nkid
                                                 AND rev_join(vj.rid, jti.id, COALESCE (vj.next_rid, 9999999999)) = 1
                                                )
                      -- Rate Level Override -- crapp-3416
                      JOIN osr_rate_level_overrides rlo ON (vj.nkid = rlo.nkid
                                                            AND NVL(rlo.unabated,'N') != 'Y'
                                                            AND rlo.state_code != SUBSTR(rlo.official_name, 1, 2)   -- crapp-4167
                                                           )
                      -- Default Reporting Code --
                      LEFT JOIN vjurisdiction_attributes ja ON (jti.jurisdiction_rid = ja.juris_rid
                                                                AND ja.juris_next_rid IS NULL
                                                                AND ja.attribute_name = 'Default Reporting Code'
                                                                AND TO_DATE(ja.start_date, 'mm/dd/yyyy') <= start_dt_i
                                                                AND (TO_DATE(ja.end_date, 'mm/dd/yyyy') >= start_dt_i OR ja.end_date IS NULL)
                                                                AND ja.status = 2
                                                               )
                WHERE jti.juris_tax_next_rid IS NULL
                      AND jti.reference_code IN ('ST','SU')
                      AND jti.jurisdiction_nkid IN (SELECT ref_nkid FROM osr_zone_auth_tags_tmp)    -- added 03/08/17
                      -- Return current active rates for reporting period --
                      AND TO_DATE(tou.start_date, 'mm/dd/yyyy') <= start_dt_i     -- crapp-3416, added dates
                      AND (TO_DATE(tou.end_date, 'mm/dd/yyyy') >= start_dt_i OR tou.end_date IS NULL)
                      -- Exclude SERVICES Jurisdicions - crapp-3416 --
                      AND jti.jurisdiction_nkid NOT IN ( SELECT DISTINCT juris_nkid
                                                         FROM   vjurisdiction_attributes
                                                         WHERE  VALUE = 'SERVICES'
                                                                AND next_rid IS NULL
                                                                AND status = 2
                                                       )
                      -- Exclude Jurisdictions based on Tax Research - crapp-3416 --
                      AND jti.jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_exclusions WHERE nkid IS NOT NULL)
                ORDER BY vj.official_name, jti.reference_code, TO_DATE(tou.start_date, 'mm/dd/yyyy'), TO_DATE(tou.end_date, 'mm/dd/yyyy');

            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get all ST/SU rates (step 2) - osr_rates_tmp', paction=>1, puser=>user_i);


            -- crapp-4167 - US - NO TAX STATES --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get NO TAX STATES ST/SU rates (step 3) - osr_rates_tmp', paction=>0, puser=>user_i);
            INSERT INTO osr_rates_tmp
                (
                  state_code
                  , reference_code
                  , start_date
                  , end_date
                  , tax_structure
                  , value_type
                  , tax_value
                  , official_name
                  , jurisdiction_id
                  , jurisdiction_rid
                  , jurisdiction_nkid
                  , status
                  , tax_description
                  , location_category
                  , tax_shipping_alone
                  , tax_shipping_and_handling
                )
                SELECT DISTINCT
                       rlo.state_code
                       , TRIM('ST') reference_code
                       , TO_DATE(vj.start_date, 'mm/dd/yyyy') start_date
                       , TO_DATE(vj.end_date, 'mm/dd/yyyy')   end_date
                       , 'Basic' tax_structure
                       , 'Rate'  value_type
                       , 0 tax_value
                       , vj.official_name
                       , vj.id    jurisdiction_id
                       , vj.rid   jurisdiction_rid
                       , vj.nkid  jurisdiction_nkid
                       , vj.status
                       , 'Sales Tax Rate' tax_description
                       , rlo.rate_level location_category       -- crapp-3416
                       , TRIM('Y') tax_shipping_alone           -- crapp-3416, changed default value to Y
                       , TRIM('Y') tax_shipping_and_handling    -- crapp-3416, changed default value to Y
                FROM   vjurisdictions vj
                       JOIN osr_rate_level_overrides rlo ON (vj.nkid = rlo.nkid
                                                             AND NVL(rlo.unabated,'N') != 'Y'
                                                             AND rlo.state_code != SUBSTR(rlo.official_name, 1, 2)   -- crapp-4167
                                                            )
                WHERE  vj.nkid IN (SELECT ref_nkid FROM osr_zone_auth_tags_tmp)
                       AND vj.official_name LIKE '%US - NO TAX STATES%'
                UNION
                SELECT DISTINCT
                       rlo.state_code
                       , TRIM('SU') reference_code
                       , TO_DATE(vj.start_date, 'mm/dd/yyyy') start_date
                       , TO_DATE(vj.end_date, 'mm/dd/yyyy')   end_date
                       , 'Basic' tax_structure
                       , 'Rate'  value_type
                       , 0 tax_value
                       , vj.official_name
                       , vj.id    jurisdiction_id
                       , vj.rid   jurisdiction_rid
                       , vj.nkid  jurisdiction_nkid
                       , vj.status
                       , 'Seller'||CHR(39)||'s Use Tax Rate' tax_description
                       , rlo.rate_level location_category       -- crapp-3416
                       , TRIM('Y') tax_shipping_alone           -- crapp-3416, changed default value to Y
                       , TRIM('Y') tax_shipping_and_handling    -- crapp-3416, changed default value to Y
                FROM   vjurisdictions vj
                       JOIN osr_rate_level_overrides rlo ON (vj.nkid = rlo.nkid
                                                             AND NVL(rlo.unabated,'N') != 'Y'
                                                             AND rlo.state_code != SUBSTR(rlo.official_name, 1, 2)   -- crapp-4167
                                                            )
                WHERE  vj.nkid IN (SELECT ref_nkid FROM osr_zone_auth_tags_tmp)
                       AND vj.official_name LIKE '%US - NO TAX STATES%';
            COMMIT;
            EXECUTE IMMEDIATE 'ALTER INDEX osr_rates_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_rates_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get NO TAX STATES ST/SU rates (step 3) - osr_rates_tmp', paction=>1, puser=>user_i);


            -- Check to see if any rates were created. If not, then insert a NULL ST/SU record for each Official Name
            FOR r IN rates LOOP
                IF r.ratecnt = 0 THEN
                    INSERT INTO osr_rates_tmp
                      (
                        state_code, reference_code, tax_structure, tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                        , tax_shipping_alone, tax_shipping_and_handling, start_date, end_date
                      )
                      SELECT state_code
                            , 'ST' reference_code
                            , 'Basic' tax_structure
                            , 0 tax_value
                            , official_name
                            , jurisdiction_id
                            , jurisdiction_nkid
                            , 'N' tax_shipping_alone
                            , 'N' tax_shipping_and_handling
                            , NULL start_date
                            , NULL end_date
                      FROM (
                            SELECT DISTINCT
                                   r.state_code
                                   , j.official_name
                                   , j.id   jurisdiction_id
                                   , j.nkid jurisdiction_nkid
                            FROM jurisdictions j
                                 -- crapp-3456 --
                                 JOIN tax_search_v ts ON ( j.nkid = ts.jurisdiction_nkid
                                                           AND j.next_rid IS NULL
                                                           AND ts.reference_code = 'ST'
                                                         )
                            WHERE j.nkid IN (SELECT ref_nkid FROM osr_zone_auth_tags_tmp)
                                  AND SUBSTR(j.official_name,1,2) = r.state_code
                                  -- Exclude SERVICES Jurisdicions - crapp-3416 --
                                  AND j.nkid NOT IN ( SELECT DISTINCT juris_nkid
                                                      FROM   vjurisdiction_attributes
                                                      WHERE  VALUE = 'SERVICES'
                                                             AND next_rid IS NULL
                                                             AND status = 2
                                                    )
                                  -- Exclude Jurisdictions based on Tax Research - crapp-3416 --
                                  AND j.nkid NOT IN (SELECT nkid FROM osr_rate_exclusions WHERE nkid IS NOT NULL)
                           );

                    INSERT INTO osr_rates_tmp
                      (
                        state_code, reference_code, tax_structure, tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                        , tax_shipping_alone, tax_shipping_and_handling, start_date, end_date
                      )
                      SELECT state_code
                            , 'SU' reference_code
                            , 'Basic' tax_structure
                            , 0 tax_value
                            , official_name
                            , jurisdiction_id
                            , jurisdiction_nkid
                            , 'N' tax_shipping_alone
                            , 'N' tax_shipping_and_handling
                            , NULL start_date
                            , NULL end_date
                      FROM (
                            SELECT DISTINCT
                                   r.state_code
                                   , j.official_name
                                   , j.id   jurisdiction_id
                                   , j.nkid jurisdiction_nkid
                            FROM jurisdictions j
                                 -- crapp-3456 --
                                 JOIN tax_search_v ts ON ( j.nkid = ts.jurisdiction_nkid
                                                           AND j.next_rid IS NULL
                                                           AND ts.reference_code = 'SU'
                                                         )
                            WHERE j.nkid IN (SELECT ref_nkid FROM osr_zone_auth_tags_tmp)
                                  AND SUBSTR(j.official_name,1,2) = r.state_code
                                  -- Exclude SERVICES Jurisdicions - crapp-3416 --
                                  AND j.nkid NOT IN ( SELECT DISTINCT juris_nkid
                                                      FROM   vjurisdiction_attributes
                                                      WHERE  VALUE = 'SERVICES'
                                                             AND next_rid IS NULL
                                                             AND status = 2
                                                    )
                                  -- Exclude Jurisdictions based on Tax Research - crapp-3416 --
                                  AND j.nkid NOT IN (SELECT nkid FROM osr_rate_exclusions WHERE nkid IS NOT NULL)
                           );
                    COMMIT;
                END IF;
            END LOOP;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Get all ST/SU rates - osr_rates_tmp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Exempt Shipping and Handling - osr_rates_tmp', paction=>0, puser=>user_i);
            -- Determine - Shipping and Handling - Commodity --
            SELECT /*+parallel(jta, 4) index(jta jta_n4)*/
                   DISTINCT
                   j.official_name
                   , j.nkid juris_nkid  -- crapp-3330
                   , c.NAME
                   , c.commodity_code
                   --, ta.juris_tax_imposition_nkid
                   , ta.reference_code
                   , t.abbreviation applicability_type
                   , jta.exempt
                   , jta.no_tax
                   , jta.ref_rule_order
            BULK COLLECT INTO v_ship
            FROM juris_tax_applicabilities jta
                  JOIN commodities c ON (jta.commodity_nkid = c.nkid
                                         AND c.next_rid IS NULL)
                  JOIN jurisdictions j ON (jta.jurisdiction_nkid = j.nkid
                                           AND j.next_rid IS NULL)
                  JOIN vappl_tax_appl_inv ta ON (jta.rid = ta.juris_tax_applicability_rid)
                  JOIN applicability_types t ON (jta.applicability_type_id = t.id)
            WHERE jta.exempt = 'Y'
                  AND c.commodity_code = '78.100'
                  AND jta.ref_rule_order IS NOT NULL
                  -- Return current active rates for reporting period --
                  AND jta.start_date <= start_dt_i
                  AND (jta.end_date >= start_dt_i OR jta.end_date IS NULL);

            FORALL s IN 1..v_ship.COUNT
                UPDATE osr_rates_tmp
                       SET tax_shipping_and_handling = TRIM('N'),
                           tax_shipping_alone        = TRIM('N')
                WHERE  jurisdiction_nkid  = v_ship(s).juris_nkid;        -- crapp-3330, changed from juris_tax_imposition_nkid
                       --AND reference_code = v_ship(s).reference_code;  -- crapp-3330, added -- crapp-3416, removed
            COMMIT;

            v_ship := t_ship();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Exempt Shipping and Handling - osr_rates_tmp', paction=>1, puser=>user_i);


/*
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Shipping and Handling overrides based on attribute - osr_rates_tmp', paction=>0, puser=>user_i);
            -- Determine - Shipping and Handling Overrides based on Attribute -- crapp-3840
            SELECT COUNT(1)
            INTO   l_rec
            FROM   vjurisdiction_attributes ja
                   JOIN jurisdictions j ON (ja.juris_nkid = j.nkid
                                            AND j.next_rid IS NULL)
            WHERE  ja.attribute_name = 'ONESOURCE Rates Shipping and Handling'
                   AND ja.VALUE IN ('Y', 'N')
                   -- Return current active rates for reporting period --
                   AND ja.start_date <= start_dt_i
                   AND (ja.end_date >= start_dt_i OR ja.end_date IS NULL);

            IF l_rec > 0 THEN
                FOR s IN (
                          SELECT DISTINCT
                                 j.official_name
                                 , ja.juris_nkid
                                 , ja.value
                                 , ja.start_date
                                 , ja.end_date
                          FROM vjurisdiction_attributes ja
                                JOIN jurisdictions j ON (ja.juris_nkid = j.nkid
                                                         AND j.next_rid IS NULL)
                          WHERE ja.attribute_name = 'ONESOURCE Rates Shipping and Handling'
                                AND ja.VALUE IN ('Y', 'N')
                                -- Return current active rates for reporting period --
                                AND ja.start_date <= start_dt_i
                                AND (ja.end_date >= start_dt_i OR ja.end_date IS NULL)
                         )
                LOOP
                    UPDATE osr_rates_tmp
                           SET tax_shipping_and_handling = s.value
                    WHERE jurisdiction_nkid = s.juris_nkid;
                END LOOP;
                COMMIT;
            END IF;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Shipping and Handling overrides based on attribute - osr_rates_tmp', paction=>1, puser=>user_i);
*/

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Exempt Shipping (78.130) - osr_rates_tmp', paction=>0, puser=>user_i);
            -- Determine - Shipping - Commodity --
            SELECT /*+parallel(jta, 4) index(jta jta_n4)*/
                   DISTINCT
                   j.official_name
                   , j.nkid juris_nkid  -- crapp-3330
                   , c.NAME
                   , c.commodity_code
                   --, ta.juris_tax_imposition_nkid
                   , ta.reference_code
                   , t.abbreviation applicability_type
                   , jta.exempt
                   , jta.no_tax
                   , jta.ref_rule_order
            BULK COLLECT INTO v_ship
            FROM juris_tax_applicabilities jta
                  JOIN commodities c ON (jta.commodity_nkid = c.nkid
                                         AND c.next_rid IS NULL)
                  JOIN jurisdictions j ON (jta.jurisdiction_nkid = j.nkid
                                           AND j.next_rid IS NULL)
                  JOIN vappl_tax_appl_inv ta ON (jta.rid = ta.juris_tax_applicability_rid)
                  JOIN applicability_types t ON (jta.applicability_type_id = t.id)
            WHERE jta.exempt = 'Y'
                  AND c.commodity_code = '78.130'
                  AND jta.ref_rule_order IS NOT NULL
                  -- Return current active rates for reporting period --
                  AND jta.start_date <= start_dt_i
                  AND (jta.end_date >= start_dt_i OR jta.end_date IS NULL);

            FORALL s IN 1..v_ship.COUNT
                UPDATE osr_rates_tmp
                       SET tax_shipping_alone = TRIM('N')
                WHERE  jurisdiction_nkid  = v_ship(s).juris_nkid;        -- crapp-3330, changed from juris_tax_imposition_nkid
                       --AND reference_code = v_ship(s).reference_code;  -- crapp-3330, added -- crapp-3416, removed
            COMMIT;

            v_ship := t_ship();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Exempt Shipping (78.130) - osr_rates_tmp', paction=>1, puser=>user_i);


/*
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Shipping overrides based on attribute - osr_rates_tmp', paction=>0, puser=>user_i);
            -- Determine - Shipping Overrides based on Attribute -- crapp-3840
            FOR s IN (
                      SELECT DISTINCT
                             j.official_name
                             , ja.juris_nkid
                             , ja.value
                             , ja.start_date
                             , ja.end_date
                      FROM vjurisdiction_attributes ja
                            JOIN jurisdictions j ON (ja.juris_nkid = j.nkid
                                                     AND j.next_rid IS NULL)
                      WHERE ja.attribute_name = 'ONESOURCE Rates Shipping Alone'
                            AND ja.VALUE IN ('Y', 'N')
                            -- Return current active rates for reporting period --
                            AND ja.start_date <= start_dt_i
                            AND (ja.end_date >= start_dt_i OR ja.end_date IS NULL)
                     )
            LOOP
                UPDATE osr_rates_tmp
                       SET tax_shipping_alone = s.value
                WHERE jurisdiction_nkid = s.juris_nkid;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Determine Shipping overrides based on attribute - osr_rates_tmp', paction=>1, puser=>user_i);
*/

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' get_rates', paction=>1, puser=>user_i);
        END get_rates;


    PROCEDURE populate_osr_rates    -- 11/02/17 - crapp-4170
    (
        stcode_i   IN VARCHAR2,
        pID_i      IN NUMBER,
        user_i     IN NUMBER,
        start_dt_i IN DATE          -- crapp-4170
    )
    IS
            l_sql   VARCHAR2(5000 CHAR);
            l_rates NUMBER := 0;

            TYPE r_districts IS RECORD
            (
                state_code          osr_zone_area_list_tmp.state_code%TYPE
                , zip               osr_zone_area_list_tmp.zip%TYPE
                , county_name       osr_zone_area_list_tmp.county_name%TYPE
                , city_name         osr_zone_area_list_tmp.city_name%TYPE
                , sales_tax         osr_as_complete_plus_tmp.other1_sales_tax%TYPE
                , use_tax           osr_as_complete_plus_tmp.other1_use_tax%TYPE
                , stj_name          osr_as_complete_plus_tmp.other1_name%TYPE
                , stj_number        osr_as_complete_plus_tmp.other1_number%TYPE
                , stj_geocode       osr_as_complete_plus_tmp.other1_geocode%TYPE
                , effective_date    osr_as_complete_plus_tmp.other1_effective_date%TYPE
                , area_id           osr_as_complete_plus_tmp.uaid%TYPE
                , acceptable_city   osr_as_complete_plus_tmp.acceptable_city%TYPE
            );
            TYPE t_districts IS TABLE OF r_districts;
            v_districts t_districts;


            TYPE r_cities IS RECORD
            (
                state_code          osr_as_complete_plus_tmp.state_code%TYPE
                , default_flag      osr_as_complete_plus_tmp.default_flag%TYPE
                , zip_code          osr_as_complete_plus_tmp.zip_code%TYPE
                , county_name       osr_as_complete_plus_tmp.county_name%TYPE
                , city_name         osr_as_complete_plus_tmp.city_name%TYPE
                , county_number     osr_as_complete_plus_tmp.county_number%TYPE
                , city_number       osr_as_complete_plus_tmp.city_number%TYPE
                , state_sales_tax   osr_as_complete_plus_tmp.state_sales_tax%TYPE
                , state_use_tax     osr_as_complete_plus_tmp.state_use_tax%TYPE
                , county_sales_tax  osr_as_complete_plus_tmp.county_sales_tax%TYPE
                , county_use_tax    osr_as_complete_plus_tmp.county_use_tax%TYPE
                , city_sales_tax    osr_as_complete_plus_tmp.city_sales_tax%TYPE
                , city_use_tax      osr_as_complete_plus_tmp.city_use_tax%TYPE
                , mta_sales_tax     osr_as_complete_plus_tmp.mta_sales_tax%TYPE
                , mta_use_tax       osr_as_complete_plus_tmp.mta_use_tax%TYPE
                , spd_sales_tax     osr_as_complete_plus_tmp.spd_sales_tax%TYPE
                , spd_use_tax       osr_as_complete_plus_tmp.spd_use_tax%TYPE
                , other1_sales_tax  osr_as_complete_plus_tmp.other1_sales_tax%TYPE
                , other1_use_tax    osr_as_complete_plus_tmp.other1_use_tax%TYPE
                , other2_sales_tax  osr_as_complete_plus_tmp.other2_sales_tax%TYPE
                , other2_use_tax    osr_as_complete_plus_tmp.other2_use_tax%TYPE
                , other3_sales_tax  osr_as_complete_plus_tmp.other3_sales_tax%TYPE
                , other3_use_tax    osr_as_complete_plus_tmp.other3_use_tax%TYPE
                , other4_sales_tax  osr_as_complete_plus_tmp.other4_sales_tax%TYPE
                , other4_use_tax    osr_as_complete_plus_tmp.other4_use_tax%TYPE
                , mta_name          osr_as_complete_plus_tmp.mta_name%TYPE
                , mta_number        osr_as_complete_plus_tmp.mta_number%TYPE
                , spd_name          osr_as_complete_plus_tmp.spd_name%TYPE
                , spd_number        osr_as_complete_plus_tmp.spd_number%TYPE
                , other1_name       osr_as_complete_plus_tmp.other1_name%TYPE
                , other1_number     osr_as_complete_plus_tmp.other1_number%TYPE
                , other2_name       osr_as_complete_plus_tmp.other2_name%TYPE
                , other2_number     osr_as_complete_plus_tmp.other2_number%TYPE
                , other3_name       osr_as_complete_plus_tmp.other3_name%TYPE
                , other3_number     osr_as_complete_plus_tmp.other3_number%TYPE
                , other4_name       osr_as_complete_plus_tmp.other4_name%TYPE
                , other4_number     osr_as_complete_plus_tmp.other4_number%TYPE
                , rnk               NUMBER
            );
            TYPE t_cities IS TABLE OF r_cities;
            v_cities t_cities;


            TYPE r_fips IS RECORD -- crapp-3416
            (
                state_code   osr_zone_detail_tmp.state_code%TYPE,
                city_name    osr_zone_detail_tmp.city_name%TYPE,
                code_fips    osr_zone_detail_tmp.code_fips%TYPE
            );
            TYPE t_fips IS TABLE OF r_fips;
            v_fips t_fips;


            TYPE r_detail IS RECORD -- 07/21/17, added to handle states with no Rates
            (
                  state_code        osr_zone_detail_usps_tmp.state_code%TYPE
                , state_name        osr_zone_detail_usps_tmp.state_name%TYPE
                , county_name       osr_zone_detail_usps_tmp.county_name%TYPE
                , city_name         osr_zone_detail_usps_tmp.city_name%TYPE
                , zip               osr_zone_detail_usps_tmp.zip%TYPE
                , zip4              osr_zone_detail_usps_tmp.zip4%TYPE
                , zip9              osr_zone_detail_usps_tmp.zip9%TYPE
                , default_flag      osr_zone_detail_usps_tmp.default_flag%TYPE
                , area_id           osr_zone_detail_usps_tmp.area_id%TYPE
                , geo_polygon_id    osr_zone_detail_usps_tmp.geo_polygon_id%TYPE
            );
            TYPE t_detail IS TABLE OF r_detail;
            v_detail  t_detail;


            CURSOR countyrates IS
                SELECT DISTINCT -- crapp-3338, now grouping by County/City and handling Tiered/Basic
                       state_code
                       , zip
                       , county_name
                       , city_name
                       , TRIM(TO_CHAR(NVL(SUM(county_sales_tax), 0), '90.999999')) county_sales_tax
                       , TRIM(TO_CHAR(NVL(SUM(county_use_tax), 0), '90.999999'))   county_use_tax
                       , NVL(MIN(county_number), 'n/a')           county_number
                       , NVL(MIN(county_effective_date), 'n/a')   county_effective_date
                       , NVL(MIN(county_tax_collected_by), 'n/a') county_tax_collected_by
                       , NVL(MAX(county_taxable_max), 'N')        county_taxable_max
                       , NVL(MAX(county_tax_over_max), 'n/a')     county_tax_over_max
                       , area_id
                FROM (
                     SELECT DISTINCT
                            a.state_code
                            , a.zip
                            , a.county_name
                            , a.city_name
                            , NVL(st.tax_value, 0)  county_sales_tax
                            , NVL(su.tax_value, 0)  county_use_tax
                            --, a.official_name
                            , a.jurisdiction_id
                            , COALESCE(st.reporting_code, su.reporting_code, NULL) county_number
                            , COALESCE(TO_CHAR(st.county_effective_date), TO_CHAR(su.county_effective_date), NULL) county_effective_date
                            , COALESCE(st.admin_name, su.admin_name, NULL) county_tax_collected_by
                            , COALESCE(st.county_taxable_max, su.county_taxable_max, NULL)   county_taxable_max
                            , COALESCE(st.county_tax_over_max, su.county_tax_over_max, NULL) county_tax_over_max
                            , a.area_id
                     FROM (
                            SELECT DISTINCT t.state_code, t.zip, t.city_name, t.acceptable_city, t.county_name, t.jurisdiction_id, t.geo_area, t.area_id -- 07/12/17 added area_id
                            FROM   osr_zone_area_list_tmp t
                            WHERE  t.state_code = stcode_i
                                   AND t.zip4 IS NULL -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                                   AND t.geo_area = 'County'
                          ) a -- crapp-3416, added to determine rate by area/jurisdiction
                          LEFT JOIN (
                                    -- crapp-3338, separating Basic and Tiered rates
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                           , tax_value, r.official_name, jurisdiction_id, jurisdiction_nkid
                                           , TO_CHAR(start_date, 'fmmm/dd/yyyy') county_effective_date, end_date
                                           , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END county_taxable_max
                                           , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END county_tax_over_max
                                           , reporting_code, admin_name
                                    FROM  osr_rates_tmp r
                                    WHERE reference_code = 'ST'
                                          AND state_code = stcode_i
                                          AND tax_structure = 'Basic'
                                          AND jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                    UNION
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           TRIM(r.state_code)       state_code
                                           , TRIM(r.reference_code) reference_code
                                           , TRIM(r.tax_structure)  tax_structure
                                           , r.value_type
                                           , NVL(MIN(mn.min_threshold), MIN(r.min_threshold))  min_threshold
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN NVL(MAX(mx.max_limit), MAX(mx.min_threshold))
                                                  ELSE MAX(r.min_threshold)
                                             END max_limit
                                           , NVL(MIN(mn.tax_value), MIN(mx.tax_value)) tax_value
                                           , TRIM(r.official_name) official_name
                                           , r.jurisdiction_id
                                           , r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy') county_effective_date
                                           , r.end_date
                                           , TRIM('Y') county_taxable_max
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN TO_CHAR(NVL(MAX(mx.max_limit), MAX(mx.min_threshold)))
                                                  ELSE TO_CHAR(MAX(r.min_threshold))
                                             END county_tax_over_max
                                           , r.reporting_code
                                           , r.admin_name
                                    FROM  osr_rates_tmp r
                                          LEFT JOIN ( SELECT r1.*
                                                      FROM  osr_rates_tmp r1
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY min_threshold) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'ST'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mnr1 ON (r1.id = mnr1.id)
                                                      WHERE mnr1.threshold_rank = 1
                                                    ) mn ON (r.id = mn.id
                                                             AND r.jurisdiction_id = mn.jurisdiction_id)
                                          LEFT JOIN ( SELECT r2.*
                                                      FROM  osr_rates_tmp r2
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY max_limit DESC) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'ST'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mxr2 ON (r2.id = mxr2.id)
                                                      WHERE mxr2.threshold_rank = 1
                                                    ) mx ON (r.id = mx.id
                                                             AND r.jurisdiction_id = mx.jurisdiction_id)
                                    WHERE r.reference_code = 'ST'
                                          AND r.state_code = stcode_i
                                          AND r.tax_structure <> 'Basic'
                                          AND r.jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND r.location_category = 'County' -- crapp-3458, removed 03/10/17
                                    GROUP BY r.state_code, r.reference_code, r.tax_structure, r.value_type
                                           , r.official_name, r.jurisdiction_id, r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy'), r.end_date
                                           , r.reporting_code, r.admin_name
                                    ) st ON (a.state_code = st.state_code
                                            AND a.jurisdiction_id = st.jurisdiction_id)
                          LEFT JOIN (
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                           , tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                                           , TO_CHAR(start_date, 'fmmm/dd/yyyy') county_effective_date, end_date
                                           , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END county_taxable_max
                                           , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END county_tax_over_max
                                           , reporting_code, admin_name
                                    FROM  osr_rates_tmp r
                                    WHERE reference_code = 'SU'
                                          AND state_code = stcode_i
                                          AND tax_structure = 'Basic'
                                          AND jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                    UNION
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           TRIM(r.state_code)       state_code
                                           , TRIM(r.reference_code) reference_code
                                           , TRIM(r.tax_structure)  tax_structure
                                           , r.value_type
                                           , NVL(MIN(mn.min_threshold), MIN(r.min_threshold))  min_threshold
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN NVL(MAX(mx.max_limit), MAX(mx.min_threshold))
                                                  ELSE MAX(r.min_threshold)
                                             END  max_limit
                                           , NVL(MIN(mn.tax_value), MIN(mx.tax_value)) tax_value
                                           , TRIM(r.official_name) official_name
                                           , r.jurisdiction_id
                                           , r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy') county_effective_date
                                           , r.end_date
                                           , TRIM('Y') county_taxable_max
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN TO_CHAR(NVL(MAX(mx.max_limit), MAX(mx.min_threshold)))
                                                  ELSE TO_CHAR(MAX(r.min_threshold))
                                             END  county_tax_over_max
                                           , r.reporting_code
                                           , r.admin_name
                                    FROM  osr_rates_tmp r
                                          LEFT JOIN ( SELECT r1.*
                                                      FROM  osr_rates_tmp r1
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY min_threshold) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'SU'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mnr1 ON (r1.id = mnr1.id)
                                                      WHERE mnr1.threshold_rank = 1
                                                    ) mn ON (r.id = mn.id
                                                             AND r.jurisdiction_id = mn.jurisdiction_id)
                                          LEFT JOIN ( SELECT r2.*
                                                      FROM  osr_rates_tmp r2
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY max_limit DESC) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'SU'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mxr2 ON (r2.id = mxr2.id)
                                                      WHERE mxr2.threshold_rank = 1
                                                    ) mx ON (r.id = mx.id
                                                             AND r.jurisdiction_id = mx.jurisdiction_id)
                                    WHERE r.reference_code = 'SU'
                                          AND r.state_code = stcode_i
                                          AND r.tax_structure <> 'Basic'
                                          AND r.jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND r.location_category = 'County' -- crapp-3458, removed 03/10/17
                                    GROUP BY r.state_code, r.reference_code, r.tax_structure, r.value_type
                                           , r.official_name, r.jurisdiction_id, r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy'), r.end_date
                                           , r.reporting_code, r.admin_name
                                   ) su ON (a.state_code = su.state_code
                                            AND a.jurisdiction_id = su.jurisdiction_id)
                    WHERE a.state_code = stcode_i
                          --AND a.zip4 IS NULL        -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                          AND a.geo_area = 'County' -- 12/08/16
                )
                GROUP BY state_code
                       , zip
                       , county_name
                       , city_name
                       , area_id
                ORDER BY zip, county_name, city_name;


            CURSOR countyrates_unbated IS
                SELECT DISTINCT -- crapp-3416 new cursor to determine Unabated County Rates
                       state_code
                       , zip
                       , county_name
                       , city_name
                       , TRIM(TO_CHAR(NVL(SUM(county_sales_tax), 0), '90.999999')) county_sales_tax
                       , TRIM(TO_CHAR(NVL(SUM(county_use_tax), 0), '90.999999'))   county_use_tax
                       , NVL(MIN(county_number), 'n/a')           county_number
                       , NVL(MIN(county_effective_date), 'n/a')   county_effective_date
                       , NVL(MIN(county_tax_collected_by), 'n/a') county_tax_collected_by
                       , NVL(MAX(county_taxable_max), 'N')        county_taxable_max
                       , NVL(MAX(county_tax_over_max), 'n/a')     county_tax_over_max
                       , area_id
                FROM (
                     SELECT DISTINCT
                            a.state_code
                            , a.zip
                            , a.county_name
                            , a.city_name
                            , NVL(st.tax_value, 0)  county_sales_tax
                            , NVL(su.tax_value, 0)  county_use_tax
                            --, a.official_name
                            , a.jurisdiction_id
                            , COALESCE(st.reporting_code, su.reporting_code, NULL) county_number
                            , COALESCE(TO_CHAR(st.county_effective_date), TO_CHAR(su.county_effective_date), NULL) county_effective_date
                            , COALESCE(st.admin_name, su.admin_name, NULL) county_tax_collected_by
                            , COALESCE(st.county_taxable_max, su.county_taxable_max, NULL)   county_taxable_max
                            , COALESCE(st.county_tax_over_max, su.county_tax_over_max, NULL) county_tax_over_max
                            , a.area_id
                     FROM (
                            SELECT DISTINCT t.state_code, t.zip, t.city_name, t.acceptable_city, t.county_name, t.jurisdiction_id, t.geo_area, t.area_id -- 07/12/17 added area_id
                            FROM   osr_zone_area_list_tmp t
                            WHERE  t.state_code = stcode_i
                                   AND t.zip4 IS NULL -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                                   AND t.geo_area = 'County'
                                   AND t.acceptable_city = 'N'
                          ) a -- crapp-3416, added to determine rate by area/jurisdiction
                          JOIN (
                                    -- crapp-3338, separating Basic and Tiered rates
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                           , tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                                           , TO_CHAR(start_date, 'fmmm/dd/yyyy') county_effective_date, end_date
                                           , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END county_taxable_max
                                           , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END county_tax_over_max
                                           , reporting_code, admin_name
                                    FROM  osr_rates_tmp
                                    WHERE reference_code = 'ST'
                                          AND state_code = stcode_i
                                          AND tax_structure = 'Basic'
                                          AND jurisdiction_nkid IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y')
                                          --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                    UNION
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           TRIM(r.state_code)       state_code
                                           , TRIM(r.reference_code) reference_code
                                           , TRIM(r.tax_structure)  tax_structure
                                           , r.value_type
                                           , NVL(MIN(mn.min_threshold), MIN(r.min_threshold))  min_threshold
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN NVL(MAX(mx.max_limit), MAX(mx.min_threshold))
                                                  ELSE MAX(r.min_threshold)
                                             END max_limit
                                           , NVL(MIN(mn.tax_value), MIN(mx.tax_value)) tax_value
                                           , TRIM(r.official_name) official_name
                                           , r.jurisdiction_id
                                           , r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy') county_effective_date
                                           , r.end_date
                                           , TRIM('Y') county_taxable_max
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN TO_CHAR(NVL(MAX(mx.max_limit), MAX(mx.min_threshold)))
                                                  ELSE TO_CHAR(MAX(r.min_threshold))
                                             END county_tax_over_max
                                           , r.reporting_code
                                           , r.admin_name
                                    FROM  osr_rates_tmp r
                                          LEFT JOIN ( SELECT r1.*
                                                      FROM  osr_rates_tmp r1
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY min_threshold) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'ST'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mnr1 ON (r1.id = mnr1.id)
                                                      WHERE mnr1.threshold_rank = 1
                                                    ) mn ON (r.id = mn.id
                                                             AND r.jurisdiction_id = mn.jurisdiction_id)
                                          LEFT JOIN ( SELECT r2.*
                                                      FROM  osr_rates_tmp r2
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY max_limit DESC) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'ST'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mxr2 ON (r2.id = mxr2.id)
                                                      WHERE mxr2.threshold_rank = 1
                                                    ) mx ON (r.id = mx.id
                                                             AND r.jurisdiction_id = mx.jurisdiction_id)
                                    WHERE r.reference_code = 'ST'
                                          AND r.state_code = stcode_i
                                          AND r.tax_structure <> 'Basic'
                                          AND r.jurisdiction_nkid IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y')
                                          --AND r.location_category = 'County' -- crapp-3458, removed 03/10/17
                                    GROUP BY r.state_code, r.reference_code, r.tax_structure, r.value_type
                                           , r.official_name, r.jurisdiction_id, r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy'), r.end_date
                                           , r.reporting_code, r.admin_name
                                    ) st ON (a.state_code = st.state_code
                                            AND a.jurisdiction_id = st.jurisdiction_id)
                          JOIN (
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                           , tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                                           , TO_CHAR(start_date, 'fmmm/dd/yyyy') county_effective_date, end_date
                                           , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END county_taxable_max
                                           , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END county_tax_over_max
                                           , reporting_code, admin_name
                                    FROM  osr_rates_tmp
                                    WHERE reference_code = 'SU'
                                          AND state_code = stcode_i
                                          AND tax_structure = 'Basic'
                                          AND jurisdiction_nkid IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y')
                                          --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                    UNION
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           TRIM(r.state_code)       state_code
                                           , TRIM(r.reference_code) reference_code
                                           , TRIM(r.tax_structure)  tax_structure
                                           , r.value_type
                                           , NVL(MIN(mn.min_threshold), MIN(r.min_threshold))  min_threshold
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN NVL(MAX(mx.max_limit), MAX(mx.min_threshold))
                                                  ELSE MAX(r.min_threshold)
                                             END  max_limit
                                           , NVL(MIN(mn.tax_value), MIN(mx.tax_value)) tax_value
                                           , TRIM(r.official_name) official_name
                                           , r.jurisdiction_id
                                           , r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy') county_effective_date
                                           , r.end_date
                                           , TRIM('Y') county_taxable_max
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN TO_CHAR(NVL(MAX(mx.max_limit), MAX(mx.min_threshold)))
                                                  ELSE TO_CHAR(MAX(r.min_threshold))
                                             END  county_tax_over_max
                                           , r.reporting_code
                                           , r.admin_name
                                    FROM  osr_rates_tmp r
                                          LEFT JOIN ( SELECT r1.*
                                                      FROM  osr_rates_tmp r1
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY min_threshold) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'SU'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mnr1 ON (r1.id = mnr1.id)
                                                      WHERE mnr1.threshold_rank = 1
                                                    ) mn ON (r.id = mn.id
                                                             AND r.jurisdiction_id = mn.jurisdiction_id)
                                          LEFT JOIN ( SELECT r2.*
                                                      FROM  osr_rates_tmp r2
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY max_limit DESC) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'SU'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'County' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mxr2 ON (r2.id = mxr2.id)
                                                      WHERE mxr2.threshold_rank = 1
                                                    ) mx ON (r.id = mx.id
                                                             AND r.jurisdiction_id = mx.jurisdiction_id)
                                    WHERE r.reference_code = 'SU'
                                          AND r.state_code = stcode_i
                                          AND r.tax_structure <> 'Basic'
                                          AND r.jurisdiction_nkid IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y')
                                          --AND r.location_category = 'County' -- crapp-3458, removed 03/10/17
                                    GROUP BY r.state_code, r.reference_code, r.tax_structure, r.value_type
                                           , r.official_name, r.jurisdiction_id, r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy'), r.end_date
                                           , r.reporting_code, r.admin_name
                                   ) su ON (a.state_code = su.state_code
                                            AND a.jurisdiction_id = su.jurisdiction_id)
                    WHERE a.state_code = stcode_i
                          --AND a.zip4 IS NULL        -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                          AND a.geo_area = 'County' -- 12/08/16
                )
                GROUP BY state_code
                       , zip
                       , county_name
                       , city_name
                       , area_id
                ORDER BY zip, county_name, city_name;


            -- 03/15/17 - based on CountyRates Cursor
            CURSOR cityrates IS
                SELECT DISTINCT -- crapp-3338, now grouping by County/City and handling Tiered/Basic
                       state_code
                       , zip
                       , county_name
                       , city_name
                       , TRIM(TO_CHAR(NVL(SUM(city_sales_tax), 0), '90.999999')) city_sales_tax
                       , TRIM(TO_CHAR(NVL(SUM(city_use_tax), 0), '90.999999'))   city_use_tax
                       , NVL(MIN(city_number), 'n/a')           city_number
                       , NVL(MIN(city_effective_date), 'n/a')   city_effective_date
                       , NVL(MIN(city_tax_collected_by), 'n/a') city_tax_collected_by
                       , NVL(MAX(city_taxable_max), 'N')        city_taxable_max
                       , NVL(MAX(city_tax_over_max), 'n/a')     city_tax_over_max
                       , area_id
                FROM (
                     SELECT DISTINCT
                            a.state_code
                            , a.zip
                            , a.county_name
                            , a.city_name
                            , NVL(st.tax_value, 0)  city_sales_tax
                            , NVL(su.tax_value, 0)  city_use_tax
                            , a.jurisdiction_id
                            , COALESCE(st.reporting_code, su.reporting_code, NULL) city_number
                            , COALESCE(TO_CHAR(st.city_effective_date), TO_CHAR(su.city_effective_date), NULL) city_effective_date
                            , COALESCE(st.admin_name, su.admin_name, NULL) city_tax_collected_by
                            , COALESCE(st.city_taxable_max, su.city_taxable_max, NULL)   city_taxable_max
                            , COALESCE(st.city_tax_over_max, su.city_tax_over_max, NULL) city_tax_over_max
                            , a.area_id
                     FROM (
                            SELECT DISTINCT t.state_code, t.zip, t.city_name, t.acceptable_city, t.county_name, t.jurisdiction_id, t.geo_area, t.area_id -- 07/12/17 added area_id
                            FROM   osr_zone_area_list_tmp t
                            WHERE  t.state_code = stcode_i
                                   AND t.zip4 IS NULL -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                                   AND t.geo_area = 'City'
                                   AND t.acceptable_city = 'N'
                          ) a -- crapp-3416, added to determine rate by area/jurisdiction
                          LEFT JOIN (
                                    -- crapp-3338, separating Basic and Tiered rates
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                           , tax_value, r.official_name, jurisdiction_id, jurisdiction_nkid
                                           , TO_CHAR(start_date, 'fmmm/dd/yyyy') city_effective_date, end_date
                                           , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END city_taxable_max
                                           , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END city_tax_over_max
                                           , reporting_code, admin_name
                                    FROM  osr_rates_tmp r
                                    WHERE reference_code = 'ST'
                                          AND state_code = stcode_i
                                          AND tax_structure = 'Basic'
                                          AND jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND location_category = 'City' -- crapp-3458, removed 03/10/17
                                    UNION
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           TRIM(r.state_code)       state_code
                                           , TRIM(r.reference_code) reference_code
                                           , TRIM(r.tax_structure)  tax_structure
                                           , r.value_type
                                           , NVL(MIN(mn.min_threshold), MIN(r.min_threshold))  min_threshold
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN NVL(MAX(mx.max_limit), MAX(mx.min_threshold))
                                                  ELSE MAX(r.min_threshold)
                                             END max_limit
                                           , NVL(MIN(mn.tax_value), MIN(mx.tax_value)) tax_value
                                           , TRIM(r.official_name) official_name
                                           , r.jurisdiction_id
                                           , r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy') city_effective_date
                                           , r.end_date
                                           , TRIM('Y') city_taxable_max
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN TO_CHAR(NVL(MAX(mx.max_limit), MAX(mx.min_threshold)))
                                                  ELSE TO_CHAR(MAX(r.min_threshold))
                                             END city_tax_over_max
                                           , r.reporting_code
                                           , r.admin_name
                                    FROM  osr_rates_tmp r
                                          LEFT JOIN ( SELECT r1.*
                                                      FROM  osr_rates_tmp r1
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY min_threshold) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'ST'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'City' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mnr1 ON (r1.id = mnr1.id)
                                                      WHERE mnr1.threshold_rank = 1
                                                    ) mn ON (r.id = mn.id
                                                             AND r.jurisdiction_id = mn.jurisdiction_id)
                                          LEFT JOIN ( SELECT r2.*
                                                      FROM  osr_rates_tmp r2
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY max_limit DESC) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'ST'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'City' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mxr2 ON (r2.id = mxr2.id)
                                                      WHERE mxr2.threshold_rank = 1
                                                    ) mx ON (r.id = mx.id
                                                             AND r.jurisdiction_id = mx.jurisdiction_id)
                                    WHERE r.reference_code = 'ST'
                                          AND r.state_code = stcode_i
                                          AND r.tax_structure <> 'Basic'
                                          AND r.jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND r.location_category = 'City' -- crapp-3458, removed 03/10/17
                                    GROUP BY r.state_code, r.reference_code, r.tax_structure, r.value_type
                                           , r.official_name, r.jurisdiction_id, r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy'), r.end_date
                                           , r.reporting_code, r.admin_name
                                    ) st ON (a.state_code = st.state_code
                                            AND a.jurisdiction_id = st.jurisdiction_id)
                          LEFT JOIN (
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                           , tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                                           , TO_CHAR(start_date, 'fmmm/dd/yyyy') city_effective_date, end_date
                                           , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END city_taxable_max
                                           , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END city_tax_over_max
                                           , reporting_code, admin_name
                                    FROM  osr_rates_tmp r
                                    WHERE reference_code = 'SU'
                                          AND state_code = stcode_i
                                          AND tax_structure = 'Basic'
                                          AND jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND location_category = 'City' -- crapp-3458, removed 03/10/17
                                    UNION
                                    SELECT /*+index(r osr_rates_tmp_n1)*/
                                           TRIM(r.state_code)       state_code
                                           , TRIM(r.reference_code) reference_code
                                           , TRIM(r.tax_structure)  tax_structure
                                           , r.value_type
                                           , NVL(MIN(mn.min_threshold), MIN(r.min_threshold))  min_threshold
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN NVL(MAX(mx.max_limit), MAX(mx.min_threshold))
                                                  ELSE MAX(r.min_threshold)
                                             END  max_limit
                                           , NVL(MIN(mn.tax_value), MIN(mx.tax_value)) tax_value
                                           , TRIM(r.official_name) official_name
                                           , r.jurisdiction_id
                                           , r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy') city_effective_date
                                           , r.end_date
                                           , TRIM('Y') city_taxable_max
                                           , CASE WHEN r.tax_structure = 'Tiered' THEN TO_CHAR(NVL(MAX(mx.max_limit), MAX(mx.min_threshold)))
                                                  ELSE TO_CHAR(MAX(r.min_threshold))
                                             END  city_tax_over_max
                                           , r.reporting_code
                                           , r.admin_name
                                    FROM  osr_rates_tmp r
                                          LEFT JOIN ( SELECT r1.*
                                                      FROM  osr_rates_tmp r1
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY min_threshold) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'SU'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'City' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mnr1 ON (r1.id = mnr1.id)
                                                      WHERE mnr1.threshold_rank = 1
                                                    ) mn ON (r.id = mn.id
                                                             AND r.jurisdiction_id = mn.jurisdiction_id)
                                          LEFT JOIN ( SELECT r2.*
                                                      FROM  osr_rates_tmp r2
                                                            JOIN (
                                                                  SELECT id, jurisdiction_id, min_threshold, max_limit, tax_value
                                                                         , RANK( ) OVER(PARTITION BY jurisdiction_id ORDER BY max_limit DESC) threshold_rank
                                                                  FROM osr_rates_tmp
                                                                  WHERE reference_code = 'SU'
                                                                        AND state_code = stcode_i
                                                                        AND tax_structure <> 'Basic'
                                                                        --AND location_category = 'City' -- crapp-3458, removed 03/10/17
                                                                  ORDER BY jurisdiction_id, min_threshold, max_limit
                                                                 ) mxr2 ON (r2.id = mxr2.id)
                                                      WHERE mxr2.threshold_rank = 1
                                                    ) mx ON (r.id = mx.id
                                                             AND r.jurisdiction_id = mx.jurisdiction_id)
                                    WHERE r.reference_code = 'SU'
                                          AND r.state_code = stcode_i
                                          AND r.tax_structure <> 'Basic'
                                          AND r.jurisdiction_nkid NOT IN (SELECT nkid FROM osr_rate_level_overrides WHERE unabated = 'Y') -- crapp-3416, exlcude Unabated
                                          --AND r.location_category = 'City' -- crapp-3458, removed 03/10/17
                                    GROUP BY r.state_code, r.reference_code, r.tax_structure, r.value_type
                                           , r.official_name, r.jurisdiction_id, r.jurisdiction_nkid
                                           , TO_CHAR(r.start_date, 'fmmm/dd/yyyy'), r.end_date
                                           , r.reporting_code, r.admin_name
                                   ) su ON (a.state_code = su.state_code
                                            AND a.jurisdiction_id = su.jurisdiction_id)
                    WHERE a.state_code = stcode_i
                          AND a.geo_area = 'City'   -- 12/08/16
                )
                GROUP BY state_code
                       , zip
                       , county_name
                       , city_name
                       , area_id
                ORDER BY zip, county_name, city_name;


            CURSOR mtarates IS    -- crapp-3456 --
                WITH st_rates AS
                    (
                     SELECT /*+index(r osr_rates_tmp_n1)*/
                            state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                            , tax_value, r.official_name, jurisdiction_id, jurisdiction_nkid
                            , TO_CHAR(start_date, 'fmmm/dd/yyyy') mta_effective_date, end_date
                            , reporting_code, admin_name
                     FROM osr_rates_tmp r
                          JOIN osr_transit_authorities_tmp ta ON (official_name LIKE '%'||authority_name||'%') -- crapp-3456
                     WHERE state_code = stcode_i
                           AND reference_code = 'ST'
                           AND location_category = 'District'
                    ),
                    su_rates AS
                    (
                     SELECT /*+index(r osr_rates_tmp_n1)*/
                            state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                            , tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                            , TO_CHAR(start_date, 'fmmm/dd/yyyy') mta_effective_date, end_date
                            , reporting_code, admin_name
                     FROM osr_rates_tmp r
                          JOIN osr_transit_authorities_tmp ta ON (official_name LIKE '%'||authority_name||'%') -- crapp-3456
                     WHERE state_code = stcode_i
                           AND reference_code = 'SU'
                           AND location_category = 'District'
                    ),
                    exclusions AS -- crapp-3416, created to exclude non-District overrides
                    (
                     SELECT DISTINCT area_id
                     FROM   osr_zone_area_list_tmp z
                            JOIN osr_rate_level_overrides rlo ON (z.official_name = rlo.official_name)
                     WHERE  rlo.rate_level != 'District'
                            AND NVL(rlo.unabated,'N') != 'Y'
                    )
                    -- No Overrides --
                    SELECT DISTINCT
                           mta.state_code
                           , mta.zip
                           , mta.county_name
                           , mta.city_name
                           , TRIM(TO_CHAR(NVL(SUM(mta.mta_sales_tax), 0), '90.999999')) mta_sales_tax
                           , TRIM(TO_CHAR(NVL(SUM(mta.mta_use_tax), 0), '90.999999'))   mta_use_tax
                           , mta.mta_name
                           , NVL(MIN(mta.mta_number), 'n/a')         mta_number
                           , MIN(mta.mta_geocode)                    mta_geocode
                           , NVL(MIN(mta.mta_effective_date), 'n/a') mta_effective_date
                           , mta.area_id                -- 07/12/17
                    FROM (
                          SELECT DISTINCT
                                 a.state_code
                                 , a.zip
                                 , a.county_name
                                 , a.city_name
                                 , NVL(st.tax_value, 0)  mta_sales_tax
                                 , NVL(su.tax_value, 0)  mta_use_tax
                                 , SUBSTR(m.mta_name, 1, 50) mta_name   -- 08/19/17
                                 , COALESCE(st.reporting_code, su.reporting_code, NULL) mta_number
                                 , RPAD(m.mta_id, 10, '0') mta_geocode
                                 , COALESCE(TO_CHAR(st.mta_effective_date), TO_CHAR(su.mta_effective_date), NULL) mta_effective_date
                                 , a.official_name
                                 , a.area_id            -- 07/12/17
                          FROM osr_zone_area_list_tmp a
                               JOIN (
                                      SELECT DISTINCT t.uaid, t.mta_id, t.mta_name, p.geo_area_key, p.rid, p.nkid
                                      FROM   osr_final_spd_placement_lt_tmp t
                                             JOIN geo_polygons p ON (t.mta_id = SUBSTR(p.geo_area_key,4, 6))
                                      WHERE  p.hierarchy_level_id = 7
                                             AND p.next_rid IS NULL
                                             AND t.mta_id IS NOT NULL
                                    ) m ON (    a.area_id = m.uaid
                                            AND a.rid = m.rid     -- crapp-3370, removed to account for Overrides
                                            --AND a.jurisdiction_id = m.jurisdiction_id  -- crapp-3456  -- 07/17/17, removed
                                           )
                               LEFT JOIN st_rates st ON (a.state_code = st.state_code
                                                         AND a.jurisdiction_id = st.jurisdiction_id)
                               LEFT JOIN su_rates su ON (a.state_code = su.state_code
                                                         AND a.jurisdiction_id = su.jurisdiction_id)
                          WHERE a.state_code = stcode_i
                                AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                                AND a.area_id NOT IN (SELECT area_id FROM exclusions) -- crapp-3416, exclude non-District overrides
                                AND a.geo_area = 'District'     -- crapp-3456, added
                                AND a.geoarea_updated IS NULL   -- 07/17/17 - indicate no overrides
                         ) mta
                    GROUP BY mta.state_code
                           , mta.zip
                           , mta.county_name
                           , mta.city_name
                           , mta.mta_name
                           , mta.area_id            -- 07/12/17

                    UNION

                    -- With Overrides --

                    SELECT DISTINCT
                           mta.state_code
                           , mta.zip
                           , mta.county_name
                           , mta.city_name
                           , TRIM(TO_CHAR(NVL(SUM(mta.mta_sales_tax), 0), '90.999999')) mta_sales_tax
                           , TRIM(TO_CHAR(NVL(SUM(mta.mta_use_tax), 0), '90.999999'))   mta_use_tax
                           , mta.mta_name
                           , NVL(MIN(mta.mta_number), 'n/a')         mta_number
                           , MIN(mta.mta_geocode)                    mta_geocode
                           , NVL(MIN(mta.mta_effective_date), 'n/a') mta_effective_date
                           , mta.area_id                -- 07/12/17
                    FROM (
                          SELECT DISTINCT
                                 a.state_code
                                 , a.zip
                                 , a.county_name
                                 , a.city_name
                                 , NVL(st.tax_value, 0)  mta_sales_tax
                                 , NVL(su.tax_value, 0)  mta_use_tax
                                 , SUBSTR(m.mta_name, 1, 50) mta_name   -- 08/19/17
                                 , COALESCE(st.reporting_code, su.reporting_code, NULL) mta_number
                                 , RPAD(m.mta_id, 10, '0') mta_geocode
                                 , COALESCE(TO_CHAR(st.mta_effective_date), TO_CHAR(su.mta_effective_date), NULL) mta_effective_date
                                 , a.official_name
                                 , a.area_id            -- 07/12/17
                          FROM osr_zone_area_list_tmp a
                               JOIN (
                                      SELECT DISTINCT t.uaid, t.mta_id, t.mta_name, p.geo_area_key, p.rid, p.nkid
                                      FROM   osr_final_spd_placement_lt_tmp t
                                             JOIN geo_polygons p ON (t.mta_id = SUBSTR(p.geo_area_key,4, 6))
                                      WHERE  p.hierarchy_level_id = 7
                                             AND p.next_rid IS NULL
                                             AND t.mta_id IS NOT NULL
                                    ) m ON (a.area_id = m.uaid)
                               -- 07/17/17 added --
                               JOIN osr_zone_authorities_tmp za ON (    a.state_name    = za.zone_3_name
                                                                    AND a.county_name   = za.zone_4_name
                                                                    AND a.city_name     = za.zone_5_name
                                                                    AND a.zip           = za.zone_6_name
                                                                    AND a.official_name = za.authority_name
                                                                    AND a.official_name LIKE '%'||TRIM(m.mta_name)||'%'
                                                                   )
                               LEFT JOIN st_rates st ON (a.state_code = st.state_code
                                                         AND a.jurisdiction_id = st.jurisdiction_id)
                               LEFT JOIN su_rates su ON (a.state_code = su.state_code
                                                         AND a.jurisdiction_id = su.jurisdiction_id)
                          WHERE a.state_code = stcode_i
                                AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                                AND a.area_id NOT IN (SELECT area_id FROM exclusions) -- crapp-3416, exclude non-District overrides
                                AND a.geo_area = 'District' -- crapp-3456, added
                                AND a.geoarea_updated = 1   -- 07/17/17 - indicats overrides
                         ) mta
                    GROUP BY mta.state_code
                           , mta.zip
                           , mta.county_name
                           , mta.city_name
                           , mta.mta_name
                           , mta.area_id      -- 07/12/17
                   ORDER BY zip, county_name, city_name;


            CURSOR spdrates IS  -- crapp-3456 --
                WITH st_rates AS
                    (
                      SELECT /*+index(r osr_rates_tmp_n1)*/
                             state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                             , tax_value, r.official_name, jurisdiction_id, jurisdiction_nkid
                             , TO_CHAR(start_date, 'fmmm/dd/yyyy') spd_effective_date, end_date
                             , reporting_code, admin_name
                      FROM osr_rates_tmp r
                      WHERE state_code = stcode_i
                            AND reference_code = 'ST'
                            AND location_category = 'District'
                    ),
                    su_rates AS
                    (
                      SELECT /*+index(r osr_rates_tmp_n1)*/
                             state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                             , tax_value, official_name, jurisdiction_id, jurisdiction_nkid
                             , TO_CHAR(start_date, 'fmmm/dd/yyyy') spd_effective_date, end_date
                             , reporting_code, admin_name
                      FROM osr_rates_tmp r
                      WHERE state_code = stcode_i
                            AND reference_code = 'SU'
                            AND location_category = 'District'
                    ),
                    exclusions AS -- crapp-3416, created to exclude non-District overrides
                    (
                     SELECT DISTINCT area_id
                     FROM   osr_zone_area_list_tmp z
                            JOIN osr_rate_level_overrides rlo ON (z.official_name = rlo.official_name)
                     WHERE  rlo.rate_level != 'District'
                            AND NVL(rlo.unabated,'N') != 'Y'
                    )
                    -- No Overrides --
                    SELECT DISTINCT
                           spd.state_code
                           , spd.zip
                           , spd.county_name
                           , spd.city_name
                           , TRIM(TO_CHAR(NVL(SUM(spd.spd_sales_tax), 0), '90.999999')) spd_sales_tax
                           , TRIM(TO_CHAR(NVL(SUM(spd.spd_use_tax), 0), '90.999999'))   spd_use_tax
                           , spd.spd_name
                           , NVL(MIN(spd.spd_number), 'n/a')         spd_number
                           , MIN(spd.spd_geocode)                    spd_geocode
                           , NVL(MIN(spd.spd_effective_date), 'n/a') spd_effective_date
                           , spd.area_id            -- 07/12/17
                    FROM (
                          SELECT DISTINCT
                                 a.state_code
                                 , a.zip
                                 , a.county_name
                                 , a.city_name
                                 , NVL(st.tax_value, 0)  spd_sales_tax
                                 , NVL(su.tax_value, 0)  spd_use_tax
                                 , s.spd_name
                                 , COALESCE(st.reporting_code, su.reporting_code, NULL) spd_number
                                 , RPAD(s.spd_id, 10, '0')  spd_geocode
                                 , COALESCE(TO_CHAR(st.spd_effective_date), TO_CHAR(su.spd_effective_date), NULL) spd_effective_date
                                 , a.area_id            -- 07/12/17
                          FROM osr_zone_area_list_tmp a
                               JOIN (
                                      SELECT DISTINCT t.uaid, t.spd_id, t.spd_name, p.geo_area_key, p.rid, p.nkid
                                      FROM   osr_final_spd_placement_lt_tmp t
                                             JOIN geo_polygons p ON (t.spd_id = SUBSTR(p.geo_area_key,4, 6))
                                      WHERE  p.hierarchy_level_id = 7
                                             AND p.next_rid IS NULL
                                             AND t.spd_id IS NOT NULL
                                    ) s ON (a.area_id = s.uaid
                                            AND a.rid = s.rid     -- crapp-3370, removed to account for Overrides -- 07/17/17, added back in
                                            --AND a.jurisdiction_id = s.jurisdiction_id  -- crapp-3456  -- 07/17/17, removed
                                           )
                               LEFT JOIN st_rates st ON (a.state_code = st.state_code
                                                         AND a.jurisdiction_id = st.jurisdiction_id)
                               LEFT JOIN su_rates su ON (a.state_code = su.state_code
                                                         AND a.jurisdiction_id = su.jurisdiction_id)
                          WHERE a.state_code = stcode_i
                                AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                                AND a.area_id NOT IN (SELECT area_id FROM exclusions) -- crapp-3416, exclude non-District overrides
                                AND a.geo_area = 'District' -- crapp-3456, added back in
                                AND a.geoarea_updated IS NULL   -- 07/17/17 - indicate no overrides
                         ) spd
                    GROUP BY spd.state_code
                           , spd.zip
                           , spd.county_name
                           , spd.city_name
                           , spd.area_id          -- 07/12/17
                           , spd.spd_name

                    UNION

                    -- With Overrides --

                    SELECT DISTINCT
                           spd.state_code
                           , spd.zip
                           , spd.county_name
                           , spd.city_name
                           , TRIM(TO_CHAR(NVL(SUM(spd.spd_sales_tax), 0), '90.999999')) spd_sales_tax
                           , TRIM(TO_CHAR(NVL(SUM(spd.spd_use_tax), 0), '90.999999'))   spd_use_tax
                           , spd.spd_name
                           , NVL(MIN(spd.spd_number), 'n/a')         spd_number
                           , MIN(spd.spd_geocode)                    spd_geocode
                           , NVL(MIN(spd.spd_effective_date), 'n/a') spd_effective_date
                           , spd.area_id            -- 07/12/17
                    FROM (
                          SELECT DISTINCT
                                 a.state_code
                                 , a.zip
                                 , a.county_name
                                 , a.city_name
                                 , NVL(st.tax_value, 0)  spd_sales_tax
                                 , NVL(su.tax_value, 0)  spd_use_tax
                                 , s.spd_name
                                 , COALESCE(st.reporting_code, su.reporting_code, NULL) spd_number
                                 , RPAD(s.spd_id, 10, '0')  spd_geocode
                                 , COALESCE(TO_CHAR(st.spd_effective_date), TO_CHAR(su.spd_effective_date), NULL) spd_effective_date
                                 , a.area_id            -- 07/12/17
                          FROM osr_zone_area_list_tmp a
                               JOIN (
                                      SELECT DISTINCT t.uaid, t.spd_id, t.spd_name, p.geo_area_key, p.rid, p.nkid
                                      FROM   osr_final_spd_placement_lt_tmp t
                                             JOIN geo_polygons p ON (t.spd_id = SUBSTR(p.geo_area_key,4, 6))
                                      WHERE  p.hierarchy_level_id = 7
                                             AND p.next_rid IS NULL
                                             AND t.spd_id IS NOT NULL
                                    ) s ON (a.area_id = s.uaid)
                               -- 07/17/17 added --
                               JOIN osr_zone_authorities_tmp za ON (    a.state_name    = za.zone_3_name
                                                                    AND a.county_name   = za.zone_4_name
                                                                    AND a.city_name     = za.zone_5_name
                                                                    AND a.zip           = za.zone_6_name
                                                                    AND a.official_name = za.authority_name
                                                                    AND a.official_name LIKE '%'||TRIM(s.spd_name)||'%'
                                                                   )
                               LEFT JOIN st_rates st ON (a.state_code = st.state_code
                                                         AND a.jurisdiction_id = st.jurisdiction_id)
                               LEFT JOIN su_rates su ON (a.state_code = su.state_code
                                                         AND a.jurisdiction_id = su.jurisdiction_id)
                          WHERE a.state_code = stcode_i
                                AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                                AND a.area_id NOT IN (SELECT area_id FROM exclusions) -- crapp-3416, exclude non-District overrides
                                AND a.geo_area = 'District' -- crapp-3456, added back in
                                AND a.geoarea_updated = 1   -- 07/17/17 - indicates overrides
                         ) spd
                    GROUP BY spd.state_code
                           , spd.zip
                           , spd.county_name
                           , spd.city_name
                           , spd.area_id          -- 07/12/17
                           , spd.spd_name
                    ORDER BY zip, county_name, city_name;


            CURSOR state_shipping IS
                SELECT DISTINCT
                       a.state_code
                       , a.zip
                       , a.county_name
                       , a.city_name
                       , sh.tax_shipping_alone
                       , sh.tax_shipping_and_handling
                       , a.area_id
                FROM osr_zone_area_list_tmp a
                    JOIN (
                         SELECT DISTINCT state_code, jurisdiction_id, jurisdiction_nkid, tax_shipping_alone, tax_shipping_and_handling
                         FROM   osr_rates_tmp
                         WHERE  reference_code IN ('ST', 'SU')
                                AND location_category = 'State'
                         ) sh ON (a.jurisdiction_id = sh.jurisdiction_id) -- 02/15/17, joining by Jurisdiction only to account for Crossborder areas
                WHERE a.state_code = stcode_i
                      AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                      AND (sh.tax_shipping_alone = 'N' OR sh.tax_shipping_and_handling = 'N')
                ORDER BY zip, county_name, city_name, area_id;


            CURSOR county_shipping IS
                SELECT DISTINCT
                       a.state_code
                       , a.zip
                       , a.county_name
                       , a.city_name
                       , sh.tax_shipping_alone
                       , sh.tax_shipping_and_handling
                       , a.area_id
                FROM osr_zone_area_list_tmp a
                    JOIN (
                         SELECT DISTINCT state_code, jurisdiction_id, jurisdiction_nkid, tax_shipping_alone, tax_shipping_and_handling
                         FROM   osr_rates_tmp
                         WHERE  reference_code IN ('ST', 'SU')
                                AND location_category = 'County'
                         ) sh ON (a.jurisdiction_id = sh.jurisdiction_id) -- 02/15/17, joining by Jurisdiction only to account for Crossborder areas
                WHERE a.state_code = stcode_i
                      AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                      AND (sh.tax_shipping_alone = 'N' OR sh.tax_shipping_and_handling = 'N')
                ORDER BY zip, county_name, city_name, area_id;


            CURSOR city_shipping IS
                SELECT DISTINCT
                       a.state_code
                       , a.zip
                       , a.county_name
                       , a.city_name
                       , sh.tax_shipping_alone
                       , sh.tax_shipping_and_handling
                       , a.area_id
                FROM osr_zone_area_list_tmp a
                    JOIN (
                         SELECT DISTINCT state_code, jurisdiction_id, jurisdiction_nkid, tax_shipping_alone, tax_shipping_and_handling
                         FROM   osr_rates_tmp
                         WHERE  reference_code IN ('ST', 'SU')
                                AND location_category = 'City'
                         ) sh ON (a.jurisdiction_id = sh.jurisdiction_id) -- 02/15/17, joining by Jurisdiction only to account for Crossborder areas
                WHERE a.state_code = stcode_i
                      AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                      AND (sh.tax_shipping_alone = 'N' OR sh.tax_shipping_and_handling = 'N')
                ORDER BY zip, county_name, city_name, area_id;


            -- crapp-4170 --
            CURSOR sth IS
                SELECT state_code, COUNT(1) cnt
                FROM (
                    SELECT DISTINCT
                           rt.state_code
                           , tou.id tou_id
                           , tou.nkid tou_nkid
                           , tou.rid tou_rid
                           , tou.next_rid
                           , tou.juris_tax_id
                           , tou.juris_tax_rid
                           , tou.juris_tax_nkid
                           , tou.juris_tax_next_rid
                           , tou.start_date
                           , tou.end_date
                           , tou.outline_status
                           , tou.entered_by
                           , tou.entered_date
                           , td.id
                           , td.rid
                           , td.nkid
                           , td.tax_outline_id
                           , td.tax_outline_nkid
                           , td.tax_outline_rid
                           , td.tax_outline_next_rid
                           , td.min_threshold
                           , td.max_limit
                           , td.value
                           , td.currency_id
                           , jti.official_name
                           , jti.jurisdiction_nkid
                    FROM vtax_outlines tou
                         JOIN vtax_definitions2 td ON (td.juris_tax_rid = tou.juris_tax_rid
                                                       AND td.tax_outline_nkid = tou.nkid
                                                      )
                         JOIN vjuris_tax_impositions jti ON (tou.juris_tax_rid = jti.juris_tax_entity_rid)
                         JOIN (
                                SELECT DISTINCT state_code, jurisdiction_nkid, official_name
                                FROM   osr_rates_tmp
                                WHERE  location_category = 'State'
                              ) rt ON (jti.jurisdiction_nkid = rt.jurisdiction_nkid)
                    WHERE (TO_DATE(tou.start_date, 'mm/dd/yyyy') >= ADD_MONTHS(start_dt_i,-18)
                           OR tou.end_date IS NULL
                          )
                          AND jti.reference_code LIKE '%TH%'
                    --ORDER BY TO_DATE(tou.end_date,'mm/dd/yyyy') DESC, TO_DATE(tou.start_date,'mm/dd/yyyy') DESC, td.min_threshold, td.max_limit
                )
                GROUP BY state_code;

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' populate_osr_rates', paction=>0, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove previous extract of rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER TABLE osr_as_complete_plus_tmp MODIFY PARTITION OS_CMPT_' ||stcode_i|| ' UNUSABLE LOCAL INDEXES';
            EXECUTE IMMEDIATE 'ALTER TABLE osr_as_complete_plus_tmp TRUNCATE PARTITION OS_CMPT_' ||stcode_i|| '';
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Remove previous extract of rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current State rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);

            -- Insert State Taxes --
            INSERT INTO osr_as_complete_plus_tmp
                (state_code, zip_code, county_name, city_name, state_sales_tax, state_use_tax, fips_state
                 , fips_county, fips_city, geocode, state_effective_date, state_taxable_max, state_tax_over_max, uaid, default_flag, acceptable_city
                 , county_sales_tax, county_use_tax, city_sales_tax, city_use_tax, mta_sales_tax, mta_use_tax, spd_sales_tax, spd_use_tax
                 , county_number, city_number, mta_number, mta_name, spd_number, spd_name, tax_shipping_alone, tax_shipping_and_handling
                 , county_effective_date, city_effective_date, mta_effective_date, spd_effective_date
                 , county_tax_collected_by, city_tax_collected_by, county_taxable_max, county_tax_over_max, city_taxable_max, city_tax_over_max
                 , mta_geocode, spd_geocode
                 , other1_sales_tax, other1_use_tax, other2_sales_tax, other2_use_tax, other3_sales_tax, other3_use_tax, other4_sales_tax, other4_use_tax
                 , other5_sales_tax, other5_use_tax, other6_sales_tax, other6_use_tax, other7_sales_tax, other7_use_tax
                 , other1_name, other1_number, other2_name, other2_number, other3_name, other3_number, other4_name, other4_number
                 , other5_name, other5_number, other6_name, other6_number, other7_name, other7_number
                 , other1_geocode, other2_geocode, other3_geocode, other4_geocode, other5_geocode, other6_geocode, other7_geocode
                 , other1_effective_date, other2_effective_date, other3_effective_date, other4_effective_date
                 , other5_effective_date, other6_effective_date, other7_effective_date
                 , sales_tax_holiday, sales_tax_holiday_dates, sales_tax_holiday_items
                )
                SELECT DISTINCT
                       state_code
                       , zip
                       , county_name
                       , city_name
                       , TRIM(TO_CHAR( SUM(state_sales_tax), '90.999999')) state_sales_tax
                       , TRIM(TO_CHAR( SUM(state_use_tax), '90.999999'))   state_use_tax
                       , fips_state
                       , fips_county
                       , fips_city
                       , geocode
                       , NVL(MAX(state_effective_date), 'n/a') state_effective_date
                       , NVL(MAX(state_taxable_max), 'N')      state_taxable_max
                       , NVL(MAX(state_tax_over_max), 'n/a')   state_tax_over_max
                       , area_id
                       , default_flag
                       , acceptable_city

                       -- Set default values --
                       , TRIM('0.000000')   county_sales_tax
                       , TRIM('0.000000')   county_use_tax
                       , TRIM('0.000000')   city_sales_tax
                       , TRIM('0.000000')   city_use_tax
                       , TRIM('0.000000')   mta_sales_tax
                       , TRIM('0.000000')   mta_use_tax
                       , TRIM('0.000000')   spd_sales_tax
                       , TRIM('0.000000')   spd_use_tax
                       , TRIM('n/a')        county_number
                       , TRIM('n/a')        city_number
                       , TRIM('n/a')        mta_number
                       , TRIM('n/a')        mta_name
                       , TRIM('n/a')        spd_number
                       , TRIM('n/a')        spd_name
                       , TRIM('Y')          tax_shipping_alone            -- crapp-3416, changed from 'N'
                       , TRIM('Y')          tax_shipping_and_handling     -- crapp-3416, changed from 'N'
                       , TRIM('n/a')        county_effective_date
                       , TRIM('n/a')        city_effective_date
                       , TRIM('n/a')        mta_effective_date
                       , TRIM('n/a')        spd_effective_date
                       , TRIM('n/a')        county_tax_collected_by
                       , TRIM('n/a')        city_tax_collected_by
                       , TRIM('N')          county_taxable_max
                       , TRIM('n/a')        county_tax_over_max
                       , TRIM('N')          city_taxable_max
                       , TRIM('n/a')        city_tax_over_max
                       , TRIM('0000000000') mta_geocode
                       , TRIM('0000000000') spd_geocode
                       , TRIM('0.000000')   other1_sales_tax
                       , TRIM('0.000000')   other1_use_tax
                       , TRIM('0.000000')   other2_sales_tax
                       , TRIM('0.000000')   other2_use_tax
                       , TRIM('0.000000')   other3_sales_tax
                       , TRIM('0.000000')   other3_use_tax
                       , TRIM('0.000000')   other4_sales_tax
                       , TRIM('0.000000')   other4_use_tax
                       , TRIM('0.000000')   other5_sales_tax
                       , TRIM('0.000000')   other5_use_tax
                       , TRIM('0.000000')   other6_sales_tax
                       , TRIM('0.000000')   other6_use_tax
                       , TRIM('0.000000')   other7_sales_tax
                       , TRIM('0.000000')   other7_use_tax
                       , TRIM('n/a')        other1_name
                       , TRIM('n/a')        other1_number
                       , TRIM('n/a')        other2_name
                       , TRIM('n/a')        other2_number
                       , TRIM('n/a')        other3_name
                       , TRIM('n/a')        other3_number
                       , TRIM('n/a')        other4_name
                       , TRIM('n/a')        other4_number
                       , TRIM('n/a')        other5_name
                       , TRIM('n/a')        other5_number
                       , TRIM('n/a')        other6_name
                       , TRIM('n/a')        other6_number
                       , TRIM('n/a')        other7_name
                       , TRIM('n/a')        other7_number
                       , TRIM('0000000000') other1_geocode
                       , TRIM('0000000000') other2_geocode
                       , TRIM('0000000000') other3_geocode
                       , TRIM('0000000000') other4_geocode
                       , TRIM('0000000000') other5_geocode
                       , TRIM('0000000000') other6_geocode
                       , TRIM('0000000000') other7_geocode
                       , TRIM('n/a')        other1_effective_date
                       , TRIM('n/a')        other2_effective_date
                       , TRIM('n/a')        other3_effective_date
                       , TRIM('n/a')        other4_effective_date
                       , TRIM('n/a')        other5_effective_date
                       , TRIM('n/a')        other6_effective_date
                       , TRIM('n/a')        other7_effective_date
                       , TRIM('N')          sales_tax_holiday
                       , TRIM('n/a')        sales_tax_holiday_dates
                       , TRIM('n/a')        sales_tax_holiday_items
                FROM (
                        SELECT DISTINCT
                               a.state_code
                               , a.zip
                               , a.county_name
                               , a.city_name
                               , NVL(st.tax_value, 0)   state_sales_tax
                               , NVL(su.tax_value, 0)   state_use_tax
                               , SUBSTR(a.area_id,1, 2) fips_state
                               , SUBSTR(a.area_id,4, 3) fips_county
                               , CASE WHEN SUBSTR(a.area_id, 8, 5) = '99999' THEN '00000' ELSE SUBSTR(a.area_id, 8, 5) END fips_city     -- crapp-3069, making 00000 instead of 99999
                               , CASE WHEN SUBSTR(a.area_id, 8, 5) = '99999' THEN SUBSTR(RPAD(REPLACE(SUBSTR(a.area_id, 1, 12),'-',''), 10, '0'), 1, 5)||'00000'
                                      ELSE RPAD(REPLACE(SUBSTR(a.area_id, 1, 12),'-',''), 10, '0')
                                 END geocode
                               , COALESCE(st.state_effective_date, su.state_effective_date, NULL) state_effective_date
                               , COALESCE(st.state_taxable_max, su.state_taxable_max, NULL)       state_taxable_max
                               , COALESCE(st.state_tax_over_max, su.state_tax_over_max, NULL)     state_tax_over_max
                               , a.area_id
                               , a.default_flag
                               , a.acceptable_city  -- crapp-3244
                        FROM osr_zone_area_list_tmp a
                            JOIN (
                                 SELECT DISTINCT state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                        , tax_value, official_name, jurisdiction_id, jurisdiction_nkid, location_category
                                        , TO_CHAR(start_date, 'fmmm/dd/yyyy') state_effective_date, end_date
                                        , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END state_taxable_max
                                        , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END state_tax_over_max
                                 FROM  osr_rates_tmp
                                 WHERE location_category = 'State'
                                       AND reference_code = 'ST'
                                       AND jurisdiction_id IN (SELECT DISTINCT jurisdiction_id FROM osr_zone_area_list_tmp WHERE geo_area = 'State')
                                 ) st ON (--a.state_code = st.state_code AND      -- 07/21/17, removed to handle crossborder jurisdictions
                                          a.jurisdiction_id = st.jurisdiction_id) -- 07/11/17, added per meeting
                            JOIN (
                                 SELECT DISTINCT state_code, reference_code, tax_structure, value_type, min_threshold, max_limit
                                        , tax_value, official_name, jurisdiction_id, jurisdiction_nkid, location_category
                                        , TO_CHAR(start_date, 'fmmm/dd/yyyy') state_effective_date, end_date
                                        , CASE WHEN tax_structure = 'Basic' THEN 'N' ELSE 'Y' END state_taxable_max
                                        , CASE WHEN tax_structure = 'Basic' THEN NULL ELSE TO_CHAR(max_limit) END state_tax_over_max
                                 FROM  osr_rates_tmp
                                 WHERE location_category = 'State'
                                       AND reference_code = 'SU'
                                       AND jurisdiction_id IN (SELECT DISTINCT jurisdiction_id FROM osr_zone_area_list_tmp WHERE geo_area = 'State')
                                 ) su ON (--a.state_code = su.state_code AND      -- 07/21/17, removed to handle crossborder jurisdictions
                                          a.jurisdiction_id = su.jurisdiction_id) -- 07/11/17, added per meeting
                        WHERE a.state_code = stcode_i
                              AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                      )
                GROUP BY
                       state_code
                       , zip
                       , county_name
                       , city_name
                       , fips_state
                       , fips_county
                       , fips_city
                       , geocode
                       , area_id
                       , default_flag
                       , acceptable_city
                ORDER BY zip, county_name, city_name;

            l_rates := (SQL%ROWCOUNT);
            COMMIT;

            -- If no State records, we need to insert "NULL" records for each Zip --
            IF l_rates = 0 THEN
                INSERT INTO osr_as_complete_plus_tmp
                    (state_code, zip_code, county_name, city_name, state_sales_tax, state_use_tax, fips_state
                     , fips_county, fips_city, geocode, state_effective_date, state_taxable_max, state_tax_over_max, uaid, default_flag, acceptable_city
                     , county_sales_tax, county_use_tax, city_sales_tax, city_use_tax, mta_sales_tax, mta_use_tax, spd_sales_tax, spd_use_tax
                     , county_number, city_number, mta_number, mta_name, spd_number, spd_name, tax_shipping_alone, tax_shipping_and_handling
                     , county_effective_date, city_effective_date, mta_effective_date, spd_effective_date
                     , county_tax_collected_by, city_tax_collected_by, county_taxable_max, county_tax_over_max, city_taxable_max, city_tax_over_max
                     , mta_geocode, spd_geocode
                     , other1_sales_tax, other1_use_tax, other2_sales_tax, other2_use_tax, other3_sales_tax, other3_use_tax, other4_sales_tax, other4_use_tax
                     , other5_sales_tax, other5_use_tax, other6_sales_tax, other6_use_tax, other7_sales_tax, other7_use_tax
                     , other1_name, other1_number, other2_name, other2_number, other3_name, other3_number, other4_name, other4_number
                     , other5_name, other5_number, other6_name, other6_number, other7_name, other7_number
                     , other1_geocode, other2_geocode, other3_geocode, other4_geocode, other5_geocode, other6_geocode, other7_geocode
                     , other1_effective_date, other2_effective_date, other3_effective_date, other4_effective_date
                     , other5_effective_date, other6_effective_date, other7_effective_date
                     , sales_tax_holiday, sales_tax_holiday_dates, sales_tax_holiday_items
                    )
                    SELECT DISTINCT
                           a.state_code
                           , a.zip
                           , a.county_name
                           , a.city_name
                           , TRIM('0.000000')   state_sales_tax
                           , TRIM('0.000000')   state_use_tax
                           , SUBSTR(a.area_id,1, 2)  fips_state
                           , SUBSTR(a.area_id,4, 3)  fips_county
                           , CASE WHEN SUBSTR(a.area_id, 8, 5) = '99999' THEN '00000' ELSE SUBSTR(a.area_id, 8, 5) END fips_city     -- crapp-3069, making 00000 instead of 99999
                           , CASE WHEN SUBSTR(a.area_id, 8, 5) = '99999' THEN SUBSTR(RPAD(REPLACE(SUBSTR(a.area_id, 1, 12),'-',''), 10, '0'), 1, 5)||'00000'
                                  ELSE RPAD(REPLACE(SUBSTR(a.area_id, 1, 12),'-',''), 10, '0')
                             END geocode
                           , TRIM('n/a') state_effective_date
                           , TRIM('N')   state_taxable_max
                           , TRIM('n/a') state_tax_over_max
                           , a.area_id
                           , NULL default_flag  -- 07/21/17, changed from "a."
                           , a.acceptable_city  -- crapp-3244
                           , TRIM('0.000000') county_sales_tax
                           , TRIM('0.000000') county_use_tax
                           , TRIM('0.000000') city_sales_tax
                           , TRIM('0.000000') city_use_tax
                           , TRIM('0.000000') mta_sales_tax
                           , TRIM('0.000000') mta_use_tax
                           , TRIM('0.000000') spd_sales_tax
                           , TRIM('0.000000') spd_use_tax
                           , TRIM('n/a')  county_number
                           , TRIM('n/a')  city_number
                           , TRIM('n/a')  mta_number
                           , TRIM('n/a')  mta_name
                           , TRIM('n/a')  spd_number
                           , TRIM('n/a')  spd_name
                           , TRIM('N')    tax_shipping_alone
                           , TRIM('N')    tax_shipping_and_handling
                           , TRIM('n/a')  county_effective_date
                           , TRIM('n/a')  city_effective_date
                           , TRIM('n/a')  mta_effective_date
                           , TRIM('n/a')  spd_effective_date
                           , TRIM('n/a')  county_tax_collected_by
                           , TRIM('n/a')  city_tax_collected_by
                           , TRIM('N')    county_taxable_max
                           , TRIM('n/a')  county_tax_over_max
                           , TRIM('N')    city_taxable_max
                           , TRIM('n/a')  city_tax_over_max
                           , TRIM('0000000000') mta_geocode
                           , TRIM('0000000000') spd_geocode
                           , TRIM('0.000000')   other1_sales_tax
                           , TRIM('0.000000')   other1_use_tax
                           , TRIM('0.000000')   other2_sales_tax
                           , TRIM('0.000000')   other2_use_tax
                           , TRIM('0.000000')   other3_sales_tax
                           , TRIM('0.000000')   other3_use_tax
                           , TRIM('0.000000')   other4_sales_tax
                           , TRIM('0.000000')   other4_use_tax
                           , TRIM('0.000000')   other5_sales_tax
                           , TRIM('0.000000')   other5_use_tax
                           , TRIM('0.000000')   other6_sales_tax
                           , TRIM('0.000000')   other6_use_tax
                           , TRIM('0.000000')   other7_sales_tax
                           , TRIM('0.000000')   other7_use_tax
                           , TRIM('n/a')        other1_name
                           , TRIM('n/a')        other1_number
                           , TRIM('n/a')        other2_name
                           , TRIM('n/a')        other2_number
                           , TRIM('n/a')        other3_name
                           , TRIM('n/a')        other3_number
                           , TRIM('n/a')        other4_name
                           , TRIM('n/a')        other4_number
                           , TRIM('n/a')        other5_name
                           , TRIM('n/a')        other5_number
                           , TRIM('n/a')        other6_name
                           , TRIM('n/a')        other6_number
                           , TRIM('n/a')        other7_name
                           , TRIM('n/a')        other7_number
                           , TRIM('0000000000') other1_geocode
                           , TRIM('0000000000') other2_geocode
                           , TRIM('0000000000') other3_geocode
                           , TRIM('0000000000') other4_geocode
                           , TRIM('0000000000') other5_geocode
                           , TRIM('0000000000') other6_geocode
                           , TRIM('0000000000') other7_geocode
                           , TRIM('n/a')        other1_effective_date
                           , TRIM('n/a')        other2_effective_date
                           , TRIM('n/a')        other3_effective_date
                           , TRIM('n/a')        other4_effective_date
                           , TRIM('n/a')        other5_effective_date
                           , TRIM('n/a')        other6_effective_date
                           , TRIM('n/a')        other7_effective_date
                           , TRIM('N')          sales_tax_holiday
                           , TRIM('n/a')        sales_tax_holiday_dates
                           , TRIM('n/a')        sales_tax_holiday_items
                    FROM  osr_zone_detail_tmp a         --osr_zone_area_list_tmp
                    WHERE a.state_code = stcode_i
                          AND a.zip IS NOT NULL
                          AND a.zip4 IS NULL   -- Exclude Zip4 records to eliminate duplicate Defaults -- crapp-3153
                    ORDER BY a.zip, a.county_name, a.city_name;
                COMMIT;
            END IF;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current State rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Validate all Zip codes are represented --- 07/23/17
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate any missing Zip codes - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);
            INSERT INTO osr_as_complete_plus_tmp
                (state_code, zip_code, county_name, city_name, state_sales_tax, state_use_tax, fips_state
                 , fips_county, fips_city, geocode, state_effective_date, state_taxable_max, state_tax_over_max, uaid, default_flag, acceptable_city
                 , county_sales_tax, county_use_tax, city_sales_tax, city_use_tax, mta_sales_tax, mta_use_tax, spd_sales_tax, spd_use_tax
                 , county_number, city_number, mta_number, mta_name, spd_number, spd_name, tax_shipping_alone, tax_shipping_and_handling
                 , county_effective_date, city_effective_date, mta_effective_date, spd_effective_date
                 , county_tax_collected_by, city_tax_collected_by, county_taxable_max, county_tax_over_max, city_taxable_max, city_tax_over_max
                 , mta_geocode, spd_geocode
                 , other1_sales_tax, other1_use_tax, other2_sales_tax, other2_use_tax, other3_sales_tax, other3_use_tax, other4_sales_tax, other4_use_tax
                 , other5_sales_tax, other5_use_tax, other6_sales_tax, other6_use_tax, other7_sales_tax, other7_use_tax
                 , other1_name, other1_number, other2_name, other2_number, other3_name, other3_number, other4_name, other4_number
                 , other5_name, other5_number, other6_name, other6_number, other7_name, other7_number
                 , other1_geocode, other2_geocode, other3_geocode, other4_geocode, other5_geocode, other6_geocode, other7_geocode
                 , other1_effective_date, other2_effective_date, other3_effective_date, other4_effective_date
                 , other5_effective_date, other6_effective_date, other7_effective_date
                 , sales_tax_holiday, sales_tax_holiday_dates, sales_tax_holiday_items
                )
                SELECT DISTINCT
                       a.state_code
                       , a.zip
                       , a.county_name
                       , a.city_name
                       , TRIM('0.000000')   state_sales_tax
                       , TRIM('0.000000')   state_use_tax
                       , SUBSTR(a.area_id,1, 2)  fips_state
                       , SUBSTR(a.area_id,4, 3)  fips_county
                       , CASE WHEN SUBSTR(a.area_id, 8, 5) = '99999' THEN '00000' ELSE SUBSTR(a.area_id, 8, 5) END fips_city     -- crapp-3069, making 00000 instead of 99999
                       , CASE WHEN SUBSTR(a.area_id, 8, 5) = '99999' THEN SUBSTR(RPAD(REPLACE(SUBSTR(a.area_id, 1, 12),'-',''), 10, '0'), 1, 5)||'00000'
                              ELSE RPAD(REPLACE(SUBSTR(a.area_id, 1, 12),'-',''), 10, '0')
                         END geocode
                       , TRIM('n/a') state_effective_date
                       , TRIM('N')   state_taxable_max
                       , TRIM('n/a') state_tax_over_max
                       , a.area_id
                       , NULL default_flag  -- 07/21/17, changed from "a."
                       , a.acceptable_city  -- crapp-3244
                       , TRIM('0.000000')   county_sales_tax
                       , TRIM('0.000000')   county_use_tax
                       , TRIM('0.000000')   city_sales_tax
                       , TRIM('0.000000')   city_use_tax
                       , TRIM('0.000000')   mta_sales_tax
                       , TRIM('0.000000')   mta_use_tax
                       , TRIM('0.000000')   spd_sales_tax
                       , TRIM('0.000000')   spd_use_tax
                       , TRIM('n/a')        county_number
                       , TRIM('n/a')        city_number
                       , TRIM('n/a')        mta_number
                       , TRIM('n/a')        mta_name
                       , TRIM('n/a')        spd_number
                       , TRIM('n/a')        spd_name
                       , TRIM('N')          tax_shipping_alone
                       , TRIM('N')          tax_shipping_and_handling
                       , TRIM('n/a')        county_effective_date
                       , TRIM('n/a')        city_effective_date
                       , TRIM('n/a')        mta_effective_date
                       , TRIM('n/a')        spd_effective_date
                       , TRIM('n/a')        county_tax_collected_by
                       , TRIM('n/a')        city_tax_collected_by
                       , TRIM('N')          county_taxable_max
                       , TRIM('n/a')        county_tax_over_max
                       , TRIM('N')          city_taxable_max
                       , TRIM('n/a')        city_tax_over_max
                       , TRIM('0000000000') mta_geocode
                       , TRIM('0000000000') spd_geocode
                       , TRIM('0.000000')   other1_sales_tax
                       , TRIM('0.000000')   other1_use_tax
                       , TRIM('0.000000')   other2_sales_tax
                       , TRIM('0.000000')   other2_use_tax
                       , TRIM('0.000000')   other3_sales_tax
                       , TRIM('0.000000')   other3_use_tax
                       , TRIM('0.000000')   other4_sales_tax
                       , TRIM('0.000000')   other4_use_tax
                       , TRIM('0.000000')   other5_sales_tax
                       , TRIM('0.000000')   other5_use_tax
                       , TRIM('0.000000')   other6_sales_tax
                       , TRIM('0.000000')   other6_use_tax
                       , TRIM('0.000000')   other7_sales_tax
                       , TRIM('0.000000')   other7_use_tax
                       , TRIM('n/a')        other1_name
                       , TRIM('n/a')        other1_number
                       , TRIM('n/a')        other2_name
                       , TRIM('n/a')        other2_number
                       , TRIM('n/a')        other3_name
                       , TRIM('n/a')        other3_number
                       , TRIM('n/a')        other4_name
                       , TRIM('n/a')        other4_number
                       , TRIM('n/a')        other5_name
                       , TRIM('n/a')        other5_number
                       , TRIM('n/a')        other6_name
                       , TRIM('n/a')        other6_number
                       , TRIM('n/a')        other7_name
                       , TRIM('n/a')        other7_number
                       , TRIM('0000000000') other1_geocode
                       , TRIM('0000000000') other2_geocode
                       , TRIM('0000000000') other3_geocode
                       , TRIM('0000000000') other4_geocode
                       , TRIM('0000000000') other5_geocode
                       , TRIM('0000000000') other6_geocode
                       , TRIM('0000000000') other7_geocode
                       , TRIM('n/a')        other1_effective_date
                       , TRIM('n/a')        other2_effective_date
                       , TRIM('n/a')        other3_effective_date
                       , TRIM('n/a')        other4_effective_date
                       , TRIM('n/a')        other5_effective_date
                       , TRIM('n/a')        other6_effective_date
                       , TRIM('n/a')        other7_effective_date
                       , TRIM('N')          sales_tax_holiday
                       , TRIM('n/a')        sales_tax_holiday_dates
                       , TRIM('n/a')        sales_tax_holiday_items
                FROM osr_zone_area_list_tmp a
                     JOIN (
                            SELECT DISTINCT state_code, zip, county_name, city_name -- 385
                            FROM   osr_zone_area_list_tmp
                            MINUS
                            SELECT DISTINCT state_code, zip_code, county_name, city_name
                            FROM   osr_as_complete_plus_tmp
                            WHERE  state_code = stcode_i
                          ) z ON (
                                       a.state_code  = z.state_code
                                   AND a.county_name = a.county_name
                                   AND a.city_name   = a.city_name
                                   AND a.zip         = z.zip
                                 );
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate any missing Zip codes - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- 07/21/17 - added to update Default Flag based on GIS Zip5
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Zip Default Flag - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            SELECT DISTINCT
                   d.state_code
                   , d.state_name
                   , d.county_name
                   , d.city_name
                   , d.zip
                   , NULL zip4
                   , NULL zip9
                   , CASE WHEN cb.zip9rank != 1 THEN NULL ELSE d.default_flag END default_flag   -- crapp-3971
                   , d.area_id
                   , NULL geo_polygon_id
            BULK COLLECT INTO v_detail
            FROM   (
                    SELECT DISTINCT
                           state_code
                           , state_name
                           , county_name
                           , city_name
                           , zip
                           , CASE WHEN override_rank = 1 THEN TRIM('Y') ELSE NULL END default_flag
                           , area_id
                    FROM   geo_usps_lookup
                    WHERE state_Code = stcode_i
                          AND zip IS NOT NULL
                          AND zip9 IS NULL
                   ) d
                   LEFT JOIN osr_crossborder_zips_tmp cb ON (d.state_code  = cb.state_code
                                                             AND d.zip     = cb.zip
                                                             AND d.county_name = cb.county_name -- added 08/18/17
                                                             AND d.city_name   = cb.city_name   -- added 08/18/17
                                                             --AND d.area_id = cb.area_id       -- removed 08/18/17
                                                            )
            ORDER BY d.zip, d.area_id;

            FORALL d IN v_detail.first..v_detail.last
                UPDATE osr_as_complete_plus_tmp z
                    SET default_flag = v_detail(d).default_flag
                WHERE     z.state_code = v_detail(d).state_code
                      AND z.zip_code   = v_detail(d).zip
                      AND z.uaid       = v_detail(d).area_id;
            COMMIT;
            v_detail := t_detail();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Zip Default Flag - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'ALTER INDEX osr_as_complete_plus_tmp_n1 REBUILD PARTITION OS_CMPT_' ||stcode_i|| '';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_as_complete_plus_tmp_n2 REBUILD PARTITION OS_CMPT_' ||stcode_i|| '';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_as_complete_plus_tmp', cascade => TRUE);
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Rebuild indexes and stats - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update County Rates --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current County rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR cr IN countyrates LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET county_sales_tax = cr.county_sales_tax,
                        county_use_tax   = cr.county_use_tax,
                        county_number    = cr.county_number,
                        county_effective_date   = cr.county_effective_date,
                        county_tax_collected_by = cr.county_tax_collected_by,
                        county_taxable_max      = cr.county_taxable_max,
                        county_tax_over_max     = cr.county_tax_over_max
                    WHERE state_code    = cr.state_code
                        AND zip_code    = cr.zip
                        AND county_name = cr.county_name
                        AND city_name   = cr.city_name
                        AND uaid        = cr.area_id;   -- 07/12/17, added per meeting
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current County rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update County Unabated Rates -- crapp-3416
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current County Unabated rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR cr IN countyrates_unbated LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET county_sales_tax = cr.county_sales_tax,
                        county_use_tax   = cr.county_use_tax,
                        county_number    = cr.county_number,
                        county_effective_date   = cr.county_effective_date,
                        county_tax_collected_by = cr.county_tax_collected_by,
                        county_taxable_max      = cr.county_taxable_max,
                        county_tax_over_max     = cr.county_tax_over_max
                    WHERE state_code    = cr.state_code
                        AND zip_code    = cr.zip
                        AND county_name = cr.county_name
                        AND uaid        = cr.area_id;   -- 07/12/17, added per meeting
                        --AND city_name   = cr.city_name;   -- crapp-3456, 03/30/17 removed
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current County Unabated rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update City Rates --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current City rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR cr IN cityrates LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET city_sales_tax = cr.city_sales_tax,
                        city_use_tax   = cr.city_use_tax,
                        city_number    = cr.city_number,
                        city_effective_date   = cr.city_effective_date,
                        city_tax_collected_by = cr.city_tax_collected_by,
                        city_taxable_max      = cr.city_taxable_max,
                        city_tax_over_max     = cr.city_tax_over_max
                    WHERE state_code    = cr.state_code
                        AND zip_code    = cr.zip
                        AND county_name = cr.county_name
                        AND city_name   = cr.city_name
                        AND uaid        = cr.area_id;   -- 07/12/17, added per meeting
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current City rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update City Rate values based on Zone Alias values - Currently for NY only -- crapp-4200
            IF stcode_i = 'NY' THEN
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update City rates for Zone Alias values - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
                FOR a IN (
                          SELECT DISTINCT
                                 o.state_code
                                 , o.zip_code
                                 , o.county_name
                                 , o.city_name
                                 , o.uaid
                                 , TO_NUMBER(o.city_sales_tax) city_sales
                                 , TO_NUMBER(o.city_use_tax)   city_use
                          FROM   osr_as_complete_plus_tmp o
                          WHERE  o.state_code = stcode_i
                                 AND o.county_name IN (SELECT alias FROM osr_zone_alias WHERE state_code = stcode_i)
                                 AND o.city_name IN (SELECT zone_name FROM osr_zone_alias WHERE state_code = stcode_i)
                                 AND o.acceptable_city = 'N'
                          ORDER BY o.county_name, o.zip_code
                         )
                LOOP
                    UPDATE osr_as_complete_plus_tmp o
                        SET o.city_sales_tax  = TRIM(TO_CHAR(a.city_sales, '90.999999')),
                            o.city_use_tax    = TRIM(TO_CHAR(a.city_use, '90.999999'))
                            --o.total_sales_tax = TRIM(TO_CHAR( TO_NUMBER(o.total_sales_tax) + a.city_sales, '90.999999')) -- totals calulated later in process
                            --o.total_use_tax   = TRIM(TO_CHAR( TO_NUMBER(o.total_use_tax) + a.city_use, '90.999999'))
                    WHERE o.state_code = a.state_code
                          AND o.zip_code = a.zip_code
                          AND o.county_name = a.county_name
                          AND o.city_name != a.city_name
                          AND o.uaid = a.uaid
                          AND o.acceptable_city = 'Y';
                END LOOP;
                COMMIT;
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update City rates for Zone Alias values - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);
            END IF;


            -- Update MTA Rates --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current MTA rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR mr IN mtarates LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET mta_sales_tax = mr.mta_sales_tax,
                        mta_use_tax   = mr.mta_use_tax,
                        mta_name      = mr.mta_name,
                        mta_number    = mr.mta_number,
                        mta_geocode   = mr.mta_geocode,
                        mta_effective_date = mr.mta_effective_date
                    WHERE   state_code  = mr.state_code
                        AND zip_code    = mr.zip
                        AND county_name = mr.county_name    -- crapp-3456 added county/city and removed area_id
                        AND city_name   = mr.city_name
                        AND uaid        = mr.area_id;         -- 07/12/17, added back in
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current MTA rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update SPD Rates --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current SPD rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR sr IN spdrates LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET spd_sales_tax = sr.spd_sales_tax,
                        spd_use_tax   = sr.spd_use_tax,
                        spd_name      = sr.spd_name,
                        spd_number    = sr.spd_number,
                        spd_geocode   = sr.spd_geocode,
                        spd_effective_date = sr.spd_effective_date
                    WHERE   state_code  = sr.state_code
                        AND zip_code    = sr.zip
                        AND county_name = sr.county_name    -- crapp-3416 added county/city and removed area_id
                        AND city_name   = sr.city_name
                        AND uaid        = sr.area_id;       -- 07/12/17, added back in
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current SPD rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update Other Rates --
            FOR i IN 1..7 LOOP
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current Other'||i||' rates - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
                l_sql := 'WITH st_rates AS '||
                            '( '||
                             'SELECT /*+index(r osr_rates_tmp_n1)*/ '||
                                    'state_code, reference_code, tax_structure, value_type, min_threshold, max_limit'||
                                    ', tax_value, r.official_name, jurisdiction_id, jurisdiction_nkid'||
                                    ', TO_CHAR(start_date, ''fmmm/dd/yyyy'') effective_date, end_date'||
                                    ', reporting_code, admin_name '||
                             'FROM osr_rates_tmp r '||
                             'WHERE state_code = '''||stcode_i||''' '||
                                   'AND reference_code = ''ST'' '||
                                   'AND location_category = ''District'' '||
                            '), '||
                            'su_rates AS '||
                            '( '||
                             'SELECT /*+index(r osr_rates_tmp_n1)*/ '||
                                    'state_code, reference_code, tax_structure, value_type, min_threshold, max_limit'||
                                    ', tax_value, official_name, jurisdiction_id, jurisdiction_nkid'||
                                    ', TO_CHAR(start_date, ''fmmm/dd/yyyy'') effective_date, end_date'||
                                    ', reporting_code, admin_name '||
                             'FROM osr_rates_tmp r '||
                             'WHERE state_code = '''||stcode_i||''' '||
                                   'AND reference_code = ''SU'' '||
                                   'AND location_category = ''District'' '||
                            '), '||
                            'exclusions AS '|| -- crapp-3416, created to exclude non-District overrides
                            '( '||
                             'SELECT DISTINCT area_id '||
                             'FROM   osr_zone_area_list_tmp z '||
                                    'JOIN osr_rate_level_overrides rlo ON (z.official_name = rlo.official_name) '||
                             'WHERE  rlo.rate_level != ''District'' '||
                                    'AND NVL(rlo.unabated,''N'') != ''Y'' '||
                            ') '||
                            -- No Overrides --
                            'SELECT DISTINCT '||
                                   'oth.state_code'||
                                   ', oth.zip'||
                                   ', oth.county_name'||
                                   ', oth.city_name'||
                                   ', TRIM(TO_CHAR(NVL(SUM(oth.sales_tax), 0), ''90.999999'')) sales_tax'||
                                   ', TRIM(TO_CHAR(NVL(SUM(oth.use_tax), 0), ''90.999999''))   use_tax'||
                                   ', oth.stj_name'||
                                   ', NVL(MIN(oth.stj_number), ''n/a'')     stj_number'||
                                   ', MIN(oth.stj_geocode)                  stj_geocode'||
                                   ', NVL(MIN(oth.effective_date), ''n/a'') effective_date'||
                                   ', oth.area_id '||                  -- 07/12/17
                                   ', NULL acceptable_city '||         -- crapp-3456, changed to NULL from oth.
                            'FROM ( '||
                                    'SELECT DISTINCT '||
                                           'a.state_code'||
                                           ', a.zip'||
                                           ', a.county_name'||
                                           ', a.city_name'||
                                           ', NVL(st.tax_value, 0)  sales_tax'||
                                           ', NVL(su.tax_value, 0)  use_tax'||
                                           ', o.other'||i||'_name   stj_name'||
                                           ', COALESCE(st.reporting_code, su.reporting_code, NULL) stj_number'||
                                           ', RPAD(o.other'||i||'_id, 10, ''0'') stj_geocode'||
                                           ', COALESCE(TO_CHAR(st.effective_date), TO_CHAR(su.effective_date), NULL) effective_date'||
                                           ', a.official_name '||
                                           ', a.area_id '||        -- 07/12/17
                                    'FROM osr_zone_area_list_tmp a '||
                                         'JOIN ( SELECT t.uaid, t.other'||i||'_id, t.other'||i||'_name, p.geo_area_key, p.rid, p.nkid '||
                                                'FROM   osr_final_spd_placement_lt_tmp t '||
                                                       'JOIN geo_polygons p ON (t.other'||i||'_id = SUBSTR(p.geo_area_key,4, 6)) '||
                                                'WHERE  p.hierarchy_level_id = 7 '||
                                                       'AND p.next_rid IS NULL '||
                                                       'AND t.other'||i||'_id IS NOT NULL '||
                                              ') o ON (    a.area_id = o.uaid '||
                                                      'AND a.rid = o.rid '||
                                                      ') '||
                                         -- 07/12/17 added --
                                         'JOIN osr_zone_authorities_tmp za ON (    a.state_name = za.zone_3_name '||
                                                                              'AND a.official_name = za.authority_name '||
                                                                              ') '||
                                         'LEFT JOIN st_rates st ON (a.state_code = st.state_code '||
                                                                   'AND a.jurisdiction_id = st.jurisdiction_id) '||
                                         'LEFT JOIN su_rates su ON (a.state_code = su.state_code '||
                                                                   'AND a.jurisdiction_id = su.jurisdiction_id) '||
                                    'WHERE a.state_code = '''||stcode_i||''' '||
                                          'AND a.zip4 IS NULL '||
                                          'AND a.area_id NOT IN (SELECT area_id FROM exclusions) '|| -- crapp-3416, exclude non-District overrides
                                          'AND a.geo_area = ''District'' '||    -- crapp-3456, added
                                          'AND a.geoarea_updated IS NULL '||    -- 07/17/17 - indicate no overrides
                                  ') oth '||
                        'GROUP BY oth.state_code'||
                               ', oth.zip'||
                               ', oth.county_name'||
                               ', oth.city_name'||
                               ', oth.stj_name '||
                               ', oth.area_id '||            -- crapp-3456, removed  -- 07/12/17, added back in

                        'UNION '||

                            -- With Overrides --    07/17/17, added
                            'SELECT DISTINCT '||
                                   'oth.state_code'||
                                   ', oth.zip'||
                                   ', oth.county_name'||
                                   ', oth.city_name'||
                                   ', TRIM(TO_CHAR(NVL(SUM(oth.sales_tax), 0), ''90.999999'')) sales_tax'||
                                   ', TRIM(TO_CHAR(NVL(SUM(oth.use_tax), 0), ''90.999999''))   use_tax'||
                                   ', oth.stj_name'||
                                   ', NVL(MIN(oth.stj_number), ''n/a'')     stj_number'||
                                   ', MIN(oth.stj_geocode)                  stj_geocode'||
                                   ', NVL(MIN(oth.effective_date), ''n/a'') effective_date'||
                                   ', oth.area_id '||                  -- 07/12/17
                                   ', NULL acceptable_city '||         -- crapp-3456, changed to NULL from oth.
                            'FROM ( '||
                                    'SELECT DISTINCT '||
                                           'a.state_code'||
                                           ', a.zip'||
                                           ', a.county_name'||
                                           ', a.city_name'||
                                           ', NVL(st.tax_value, 0)  sales_tax'||
                                           ', NVL(su.tax_value, 0)  use_tax'||
                                           ', o.other'||i||'_name   stj_name'||
                                           ', COALESCE(st.reporting_code, su.reporting_code, NULL) stj_number'||
                                           ', RPAD(o.other'||i||'_id, 10, ''0'') stj_geocode'||
                                           ', COALESCE(TO_CHAR(st.effective_date), TO_CHAR(su.effective_date), NULL) effective_date'||
                                           ', a.official_name '||
                                           ', a.area_id '||        -- 07/12/17
                                    'FROM osr_zone_area_list_tmp a '||
                                         'JOIN ( SELECT DISTINCT t.uaid, t.other'||i||'_id, t.other'||i||'_name, p.geo_area_key, p.rid, p.nkid '||
                                                'FROM   osr_final_spd_placement_lt_tmp t '||
                                                       'JOIN geo_polygons p ON (t.other'||i||'_id = SUBSTR(p.geo_area_key,4, 6)) '||
                                                'WHERE  p.hierarchy_level_id = 7 '||
                                                       'AND p.next_rid IS NULL '||
                                                       'AND t.other'||i||'_id IS NOT NULL '||
                                              ') o ON (a.area_id = o.uaid) '||
                                         -- 07/17/17 added --
                                         'JOIN osr_zone_authorities_tmp za ON (    a.state_name    = za.zone_3_name '||
                                                                              'AND a.county_name   = za.zone_4_name '||
                                                                              'AND a.city_name     = za.zone_5_name '||
                                                                              'AND a.zip           = za.zone_6_name '||
                                                                              'AND a.official_name = za.authority_name '||
                                                                              'AND a.official_name LIKE ''%''||TRIM(other'||i||'_name)||''%'' '||
                                                                              ') '||
                                         'LEFT JOIN st_rates st ON (a.state_code = st.state_code '||
                                                                   'AND a.jurisdiction_id = st.jurisdiction_id) '||
                                         'LEFT JOIN su_rates su ON (a.state_code = su.state_code '||
                                                                   'AND a.jurisdiction_id = su.jurisdiction_id) '||
                                    'WHERE a.state_code = '''||stcode_i||''' '||
                                          'AND a.zip4 IS NULL '||
                                          'AND a.area_id NOT IN (SELECT area_id FROM exclusions) '|| -- crapp-3416, exclude non-District overrides
                                          'AND a.geo_area = ''District'' '||    -- crapp-3456
                                          'AND a.geoarea_updated = 1 '||        -- 07/17/17 - indicates overrides
                                  ') oth '||
                        'GROUP BY oth.state_code'||
                               ', oth.zip'||
                               ', oth.county_name'||
                               ', oth.city_name'||
                               ', oth.stj_name '||
                               ', oth.area_id '||            -- crapp-3456, removed  -- 07/12/17, added back in
                       'ORDER BY zip, county_name, city_name';

                EXECUTE IMMEDIATE l_sql
                BULK COLLECT INTO v_districts;

                l_rates := v_districts.COUNT;

                -- Process Other Rates --
                IF l_rates > 0 THEN
                    IF i = 1 THEN
                        FORALL o IN 1..v_districts.COUNT
                            UPDATE osr_as_complete_plus_tmp
                                SET other1_sales_tax = v_districts(o).sales_tax,
                                    other1_use_tax   = v_districts(o).use_tax,
                                    other1_name      = v_districts(o).stj_name,
                                    other1_number    = v_districts(o).stj_number,
                                    other1_geocode   = v_districts(o).stj_geocode,
                                    other1_effective_date = v_districts(o).effective_date
                                WHERE   state_code  = v_districts(o).state_code
                                    AND zip_code    = v_districts(o).zip
                                    AND county_name = v_districts(o).county_name
                                    AND city_name   = v_districts(o).city_name
                                    AND uaid     = v_districts(o).area_id;    -- 07/12/17, added back in
                        COMMIT;
                    ELSIF i = 2 THEN
                        FORALL o IN 1..v_districts.COUNT
                            UPDATE osr_as_complete_plus_tmp
                                SET other2_sales_tax = v_districts(o).sales_tax,
                                    other2_use_tax   = v_districts(o).use_tax,
                                    other2_name      = v_districts(o).stj_name,
                                    other2_number    = v_districts(o).stj_number,
                                    other2_geocode   = v_districts(o).stj_geocode,
                                    other2_effective_date = v_districts(o).effective_date
                                WHERE   state_code  = v_districts(o).state_code
                                    AND zip_code    = v_districts(o).zip
                                    AND county_name = v_districts(o).county_name
                                    AND city_name   = v_districts(o).city_name
                                    AND uaid     = v_districts(o).area_id;    -- 07/12/17, added back in
                        COMMIT;
                    ELSIF i = 3 THEN
                        FORALL o IN 1..v_districts.COUNT
                            UPDATE osr_as_complete_plus_tmp
                                SET other3_sales_tax = v_districts(o).sales_tax,
                                    other3_use_tax   = v_districts(o).use_tax,
                                    other3_name      = v_districts(o).stj_name,
                                    other3_number    = v_districts(o).stj_number,
                                    other3_geocode   = v_districts(o).stj_geocode,
                                    other3_effective_date = v_districts(o).effective_date
                                WHERE   state_code  = v_districts(o).state_code
                                    AND zip_code    = v_districts(o).zip
                                    AND county_name = v_districts(o).county_name
                                    AND city_name   = v_districts(o).city_name
                                    AND uaid     = v_districts(o).area_id;    -- 07/12/17, added back in
                        COMMIT;
                    ELSIF i = 4 THEN
                        FORALL o IN 1..v_districts.COUNT
                            UPDATE osr_as_complete_plus_tmp
                                SET other4_sales_tax = v_districts(o).sales_tax,
                                    other4_use_tax   = v_districts(o).use_tax,
                                    other4_name      = v_districts(o).stj_name,
                                    other4_number    = v_districts(o).stj_number,
                                    other4_geocode   = v_districts(o).stj_geocode,
                                    other4_effective_date = v_districts(o).effective_date
                                WHERE   state_code  = v_districts(o).state_code
                                    AND zip_code    = v_districts(o).zip
                                    AND county_name = v_districts(o).county_name
                                    AND city_name   = v_districts(o).city_name
                                    AND uaid     = v_districts(o).area_id;    -- 07/12/17, added back in
                        COMMIT;
                    ELSIF i = 5 THEN
                        FORALL o IN 1..v_districts.COUNT
                            UPDATE osr_as_complete_plus_tmp
                                SET other5_sales_tax = v_districts(o).sales_tax,
                                    other5_use_tax   = v_districts(o).use_tax,
                                    other5_name      = v_districts(o).stj_name,
                                    other5_number    = v_districts(o).stj_number,
                                    other5_geocode   = v_districts(o).stj_geocode,
                                    other5_effective_date = v_districts(o).effective_date
                                WHERE   state_code  = v_districts(o).state_code
                                    AND zip_code    = v_districts(o).zip
                                    AND county_name = v_districts(o).county_name
                                    AND city_name   = v_districts(o).city_name
                                    AND uaid     = v_districts(o).area_id;    -- 07/12/17, added back in
                        COMMIT;
                    ELSIF i = 6 THEN
                        FORALL o IN 1..v_districts.COUNT
                            UPDATE osr_as_complete_plus_tmp
                                SET other6_sales_tax = v_districts(o).sales_tax,
                                    other6_use_tax   = v_districts(o).use_tax,
                                    other6_name      = v_districts(o).stj_name,
                                    other6_number    = v_districts(o).stj_number,
                                    other6_geocode   = v_districts(o).stj_geocode,
                                    other6_effective_date = v_districts(o).effective_date
                                WHERE   state_code  = v_districts(o).state_code
                                    AND zip_code    = v_districts(o).zip
                                    AND county_name = v_districts(o).county_name
                                    AND city_name   = v_districts(o).city_name
                                    AND uaid     = v_districts(o).area_id;    -- 07/12/17, added back in
                        COMMIT;
                    ELSIF i = 7 THEN
                        FORALL o IN 1..v_districts.COUNT
                            UPDATE osr_as_complete_plus_tmp
                                SET other7_sales_tax = v_districts(o).sales_tax,
                                    other7_use_tax   = v_districts(o).use_tax,
                                    other7_name      = v_districts(o).stj_name,
                                    other7_number    = v_districts(o).stj_number,
                                    other7_geocode   = v_districts(o).stj_geocode,
                                    other7_effective_date = v_districts(o).effective_date
                                WHERE   state_code  = v_districts(o).state_code
                                    AND zip_code    = v_districts(o).zip
                                    AND county_name = v_districts(o).county_name
                                    AND city_name   = v_districts(o).city_name
                                    AND uaid     = v_districts(o).area_id;    -- 07/12/17, added back in
                        COMMIT;
                    END IF;
                END IF; -- l_rates

                v_districts := t_districts();
                gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate current Other'||i||' rates - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);
            END LOOP;
            COMMIT;


            -- Update State Shipping-Shipping and Handling --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate State Shipping and Handling - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR sh IN state_shipping LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET tax_shipping_alone        = sh.tax_shipping_alone,
                        tax_shipping_and_handling = sh.tax_shipping_and_handling
                    WHERE state_code      = sh.state_code
                          AND zip_code    = sh.zip
                          AND county_name = sh.county_name
                          AND city_name   = sh.city_name
                          AND uaid        = sh.area_id;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate State Shipping and Handling - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update County Shipping-Shipping and Handling --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate County Shipping and Handling - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR sh IN county_shipping LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET tax_shipping_alone        = sh.tax_shipping_alone,
                        tax_shipping_and_handling = sh.tax_shipping_and_handling
                    WHERE state_code      = sh.state_code
                          AND zip_code    = sh.zip
                          AND county_name = sh.county_name
                          AND city_name   = sh.city_name
                          AND uaid        = sh.area_id;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate County Shipping and Handling - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update City Shipping-Shipping and Handling --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate City Shipping and Handling - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR sh IN city_shipping LOOP
                UPDATE osr_as_complete_plus_tmp
                    SET tax_shipping_alone        = sh.tax_shipping_alone,
                        tax_shipping_and_handling = sh.tax_shipping_and_handling
                    WHERE state_code      = sh.state_code
                          AND zip_code    = sh.zip
                          AND county_name = sh.county_name
                          AND city_name   = sh.city_name
                          AND uaid        = sh.area_id;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Populate City Shipping and Handling - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update Totals -- crapp-3015, added 5-7 values
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Totals - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            UPDATE osr_as_complete_plus_tmp
                SET total_sales_tax = TRIM(TO_CHAR(TO_NUMBER(state_sales_tax) + TO_NUMBER(county_sales_tax) + TO_NUMBER(city_sales_tax) + TO_NUMBER(mta_sales_tax) + TO_NUMBER(spd_sales_tax) +
                                              TO_NUMBER(other1_sales_tax) + TO_NUMBER(other2_sales_tax) + TO_NUMBER(other3_sales_tax) + TO_NUMBER(other4_sales_tax) +
                                              TO_NUMBER(other5_sales_tax) + TO_NUMBER(other6_sales_tax) + TO_NUMBER(other7_sales_tax), '90.999999')),
                    total_use_tax   = TRIM(TO_CHAR(TO_NUMBER(state_use_tax) + TO_NUMBER(county_use_tax) + TO_NUMBER(city_use_tax) + TO_NUMBER(mta_use_tax) + TO_NUMBER(spd_use_tax) +
                                              TO_NUMBER(other1_use_tax) + TO_NUMBER(other2_use_tax) + TO_NUMBER(other3_use_tax) + TO_NUMBER(other4_use_tax) +
                                              TO_NUMBER(other5_use_tax) + TO_NUMBER(other6_use_tax) + TO_NUMBER(other7_use_tax), '90.999999')),
                    geocode_long    = geocode || mta_geocode || spd_geocode || other1_geocode || other2_geocode || other3_geocode || other4_geocode
                WHERE state_code = stcode_i;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Totals - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            -- Update Sales Tax Holiday --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Sales Tax Holiday - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR s IN sth LOOP   -- crapp-4170 --
                UPDATE osr_as_complete_plus_tmp
                    SET sales_tax_holiday = 'Y'
                WHERE state_code = s.state_code;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Sales Tax Holiday - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);


            /* -- 07/20/17 - Removed, now handling in DETERMINE_ZIP_DATA procedures --
            -- Update Acceptable City Defaults -- crapp-3416
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Acceptable City Defaults - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);
            FOR df IN (
                        SELECT n.state_code, n.zip_code, n.county_name, n.city_name, n.uaid
                        FROM   osr_as_complete_plus_tmp n
                               JOIN (
                                      SELECT DISTINCT state_code, zip_code, county_name, city_name, default_flag
                                      FROM   osr_as_complete_plus_tmp
                                      WHERE  state_code = stcode_i
                                          AND default_flag = 'Y'
                                    ) d ON (    n.state_code  = d.state_code
                                            AND n.zip_code    = d.zip_code
                                            AND n.county_name = d.county_name
                                            AND n.city_name   = d.city_name
                                            AND NVL(n.default_flag,'N') <> d.default_flag
                                           )
                        --ORDER BY n.zip_code, n.county_name, n.city_name, n.uaid
            ) LOOP
                UPDATE osr_as_complete_plus_tmp p
                    SET default_flag = 'Y'
                WHERE     p.state_code  = df.state_code
                      AND p.zip_code    = df.zip_code
                      AND p.county_name = df.county_name
                      AND p.city_name   = df.city_name
                      AND p.uaid        = df.uaid
                      AND p.default_flag IS NULL;
            END LOOP;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Acceptable City Defaults - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);
            */


            -- crapp-3416 - Added section to update the City_Fips values for Preferred Mailing Cities
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Preferred Mailing City Fips - osr_zone_detail_tmp', paction=>0, puser=>user_i);
            SELECT DISTINCT state_code, city_name, code_fips
            BULK COLLECT INTO v_fips
            FROM  osr_zone_detail_tmp
            WHERE state_code = stcode_i
                  AND code_fips != '00000'
                  AND city_name != 'UNINCORPORATED';

            FORALL f IN 1..v_fips.COUNT
                UPDATE osr_as_complete_plus_tmp d
                    SET fips_city = v_fips(f).code_fips,
                        --geocode   = REPLACE(d.geocode, SUBSTR(d.geocode,6,5), v_fips(f).code_fips)
                        geocode = fips_state||fips_county||v_fips(f).code_fips  -- 07/11/17, modified per meeting
                WHERE     d.state_code = v_fips(f).state_code
                      AND d.city_name  = v_fips(f).city_name
                      AND d.fips_city != v_fips(f).code_fips;
                COMMIT;
            v_fips := t_fips();


            -- Update FIPS for Existing cities being replaced by Preferred cities  which have no FIPS values -- crapp-3416 (new 03/06/17)
            SELECT DISTINCT state_code, city_name, code_fips
            BULK COLLECT INTO v_fips
            FROM  osr_zone_detail_tmp z
            WHERE state_code = stcode_i
                  AND code_fips  = '00000'
                  AND city_name != 'UNINCORPORATED'
                  AND acceptable_city = 'Y'
                  AND NOT EXISTS (SELECT 1
                                  FROM   osr_zone_detail_tmp o
                                  WHERE  o.state_code = stcode_i
                                         AND o.code_fips != '00000'
                                         AND o.city_name = z.city_name
                                 )
            ORDER BY z.city_name;

            FORALL f IN 1..v_fips.COUNT
                UPDATE osr_as_complete_plus_tmp d
                    SET fips_city = v_fips(f).code_fips,
                        geocode   = fips_state||fips_county||v_fips(f).code_fips  -- 07/11/17, modified per meeting
                        --geocode   = REPLACE(d.geocode, SUBSTR(d.geocode,6,5), v_fips(f).code_fips)
                WHERE     d.state_code = v_fips(f).state_code
                      AND d.city_name  = v_fips(f).city_name
                      AND d.fips_city != v_fips(f).code_fips;
                COMMIT;
            v_fips := t_fips();


            -- Update GeoCode_Long --
            UPDATE osr_as_complete_plus_tmp d
                SET geocode_long = d.geocode||SUBSTR(d.geocode_long,11)
            WHERE d.state_code = stcode_i;
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Preferred Mailing City Fips - osr_zone_detail_tmp', paction=>1, puser=>user_i);


            -- Update Duplicate City Names -- crapp-3370
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Duplicate City Names - osr_as_complete_plus_tmp', paction=>0, puser=>user_i);

            SELECT *
            BULK COLLECT INTO v_cities
            FROM (
                  SELECT  state_code
                        , default_flag  -- 07/20/17, added
                        , zip_code, county_name, city_name
                        , county_number, city_number -- 07/12/17, added county_number and city_number
                        , state_sales_tax, state_use_tax, county_sales_tax, county_use_tax, city_sales_tax, city_use_tax
                        , mta_sales_tax, mta_use_tax, spd_sales_tax, spd_use_tax, other1_sales_tax, other1_use_tax
                        , other2_sales_tax, other2_use_tax, other3_sales_tax, other3_use_tax, other4_sales_tax, other4_use_tax
                        , mta_name, mta_number, spd_name, spd_number, other1_name, other1_number
                        , other2_name, other2_number, other3_name, other3_number, other4_name, other4_number
                        , (RANK( ) OVER(PARTITION BY zip_code, county_name, city_name ORDER BY stjnames DESC)) - 1 stj_rank
                  FROM (
                        SELECT DISTINCT state_code, zip_code, county_name, city_name
                               , county_number, city_number -- 07/12/17, added
                               , default_flag               -- 07/20/17, added
                               , state_sales_tax, state_use_tax, county_sales_tax, county_use_tax, city_sales_tax, city_use_tax
                               , mta_sales_tax, mta_use_tax, spd_sales_tax, spd_use_tax, other1_sales_tax, other1_use_tax
                               , other2_sales_tax, other2_use_tax, other3_sales_tax, other3_use_tax, other4_sales_tax, other4_use_tax
                               , total_sales_tax, total_use_tax  -- 07/18/17, added totals
                               , mta_name, mta_number, spd_name, spd_number, other1_name, other1_number, other2_name, other2_number
                               , other3_name, other3_number, other4_name, other4_number
                               , (NVL(default_flag,'N')||'|'||
                                  county_number||'|'||city_number||'|'||mta_name||'|'||mta_sales_tax||'|'||spd_name||'|'||spd_sales_tax||'|'||spd_use_tax||'|'||
                                  other1_name||'|'||other1_sales_tax||'|'||other1_use_tax||'|'||other2_name||'|'||other2_sales_tax||'|'||other2_use_tax||'|'||
                                  other3_name||'|'||other3_sales_tax||'|'||other3_use_tax||'|'||other4_name||'|'||other4_sales_tax||'|'||other4_use_tax||'|'||
                                  total_sales_tax||'|'||total_use_tax) stjnames
                               , uaid
                        FROM   osr_as_complete_plus_tmp
                        WHERE  state_code = stcode_i
                        ORDER BY zip_code, county_name, city_name, uaid, default_flag, county_number, city_number, mta_name, spd_name, other1_name, other2_name, other3_name, other4_name
                       )
                 )
            WHERE stj_rank > 0
            ORDER BY zip_code, county_name, city_name, stj_rank;

            FORALL i IN 1..v_cities.COUNT
                UPDATE osr_as_complete_plus_tmp a
                    SET city_name = TRIM(a.city_name)||' ('||v_cities(i).rnk||')'
                WHERE     a.state_code       = v_cities(i).state_code
                      AND a.zip_code         = v_cities(i).zip_code
                      AND a.county_name      = v_cities(i).county_name
                      AND a.city_name        = v_cities(i).city_name
                      AND a.county_number    = v_cities(i).county_number
                      AND a.city_number      = v_cities(i).city_number
                      AND a.state_sales_tax  = v_cities(i).state_sales_tax
                      AND a.state_use_tax    = v_cities(i).state_use_tax
                      AND a.county_sales_tax = v_cities(i).county_sales_tax
                      AND a.county_use_tax   = v_cities(i).county_use_tax
                      AND a.city_sales_tax   = v_cities(i).city_sales_tax
                      AND a.city_use_tax     = v_cities(i).city_use_tax
                      AND a.mta_sales_tax    = v_cities(i).mta_sales_tax
                      AND a.mta_use_tax      = v_cities(i).mta_use_tax
                      AND a.spd_sales_tax    = v_cities(i).spd_sales_tax
                      AND a.spd_use_tax      = v_cities(i).spd_use_tax
                      AND a.other1_sales_tax = v_cities(i).other1_sales_tax
                      AND a.other1_use_tax   = v_cities(i).other1_use_tax
                      AND a.other2_sales_tax = v_cities(i).other2_sales_tax
                      AND a.other2_use_tax   = v_cities(i).other2_use_tax
                      AND a.other3_sales_tax = v_cities(i).other3_sales_tax
                      AND a.other3_use_tax   = v_cities(i).other3_use_tax
                      AND a.other4_sales_tax = v_cities(i).other4_sales_tax
                      AND a.other4_use_tax   = v_cities(i).other4_use_tax
                      AND a.mta_name         = v_cities(i).mta_name
                      AND a.mta_number       = v_cities(i).mta_number
                      AND a.spd_name         = v_cities(i).spd_name
                      AND a.spd_number       = v_cities(i).spd_number
                      AND a.other1_name      = v_cities(i).other1_name
                      AND a.other1_number    = v_cities(i).other1_number
                      AND a.other2_name      = v_cities(i).other2_name
                      AND a.other2_number    = v_cities(i).other2_number
                      AND a.other3_name      = v_cities(i).other3_name
                      AND a.other3_number    = v_cities(i).other3_number
                      AND a.other4_name      = v_cities(i).other4_name
                      AND a.other4_number    = v_cities(i).other4_number
                      AND NVL(a.default_flag, 'N') = NVL(v_cities(i).default_flag,'N');    -- 07/20/17, added
                COMMIT;

            v_cities := t_cities();
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Update Duplicate City Names - osr_as_complete_plus_tmp', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' populate_osr_rates', paction=>1, puser=>user_i);
        END populate_osr_rates;



   PROCEDURE extract_rate_files    -- 11/08/17 - crapp-4169
    (
        stcode_i IN VARCHAR2,
        pID_i    IN NUMBER,
        user_i   IN NUMBER
    )
    IS
            l_stcode  VARCHAR2(2 CHAR)  := CASE WHEN stcode_i = 'AS' THEN NULL ELSE stcode_i END;
            l_dir     VARCHAR2(100 CHAR):= 'EXTRACT_FILES';
            l_delimit VARCHAR2(1 CHAR)  := CHR(9);  -- Tab
            l_ftype   UTL_FILE.FILE_TYPE;

            -- Prefixing filenames with ProcessID value to make files unique --
            l_file_complete      VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_complete.txt';
            l_file_complete_plus VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_complete+.txt';
            l_file_basic         VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_basic.txt';
            l_file_basic_plus    VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_basic+.txt';
            l_file_basic2        VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_basicII.txt';
            l_file_basic2_plus   VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_basicII+.txt';
            l_file_expanded      VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_expanded.txt';
            l_file_expanded_plus VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_expanded+.txt';
            l_file_zip4          VARCHAR2(50 CHAR) := pID_i||'-'||stcode_i||'_zip4.txt';        --crapp-3407

        -- **************************************************************************************************************************************************** --
        -- File Specifics - Updated 02/13/17 per CRAPP-3370                                                                                                     --
        --  Complete+   - All multi-point Zips, Include Fips and Effective Dates, Include additional tax columns, Supports Unincorporated and Cities with (1..) --
        --  Complete    - All multi-point Zips                                                                                                                  --
        --  Basic       - Default Zips only, Preferred Mailing City only                                                                                        --
        --  Basic+      - Default Zips only, Include Fips and Effective Dates, Preferred Mailing City only                                                      --
        --  BasicII     - All multi-point Zips                                                                                                                  --
        --  BasicII+    - All multi-point Zips, Include Fips and Effective Dates, Supports Unincorporated and Cities with (1..)                                 --
        --  Expanded    - Default Zips only, Preferred Mailing City only                                                                                        --
        --  Expanded+   - Default Zips only, Include Fips and Effective Dates, Include additional tax columns, Preferred Mailing City only                      --
        --  Zip4        - Same specs as Complete+, No leading zeoes in Tax values, Column to indicate Zip or Zip4 (RECORD_TYPE)                                 --
        --                                                                                                                                                      --
        --  NOTE: Territories do not get separate files, they are included in the ALL STATES file - AA, AE, AP, AS, FM, MH, MP, PW, VI                          --
        -- **************************************************************************************************************************************************** --

        BEGIN
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' extract_rate_files', paction=>0, puser=>user_i);

            -- Complete+ -- All multi-point Zips, Include Fips and Effective Dates, Includes additional tax columns, Supports Unincorporated and Cities with (1..)
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_complete_plus||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_complete_plus, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'MTA_SALES_TAX'
                 ||l_delimit||'MTA_USE_TAX'
                 ||l_delimit||'SPD_SALES_TAX'
                 ||l_delimit||'SPD_USE_TAX'
                 ||l_delimit||'OTHER1_SALES_TAX'
                 ||l_delimit||'OTHER1_USE_TAX'
                 ||l_delimit||'OTHER2_SALES_TAX'
                 ||l_delimit||'OTHER2_USE_TAX'
                 ||l_delimit||'OTHER3_SALES_TAX'
                 ||l_delimit||'OTHER3_USE_TAX'
                 ||l_delimit||'OTHER4_SALES_TAX'
                 ||l_delimit||'OTHER4_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'COUNTY_NUMBER'
                 ||l_delimit||'CITY_NUMBER'
                 ||l_delimit||'MTA_NAME'
                 ||l_delimit||'MTA_NUMBER'
                 ||l_delimit||'SPD_NAME'
                 ||l_delimit||'SPD_NUMBER'
                 ||l_delimit||'OTHER1_NAME'
                 ||l_delimit||'OTHER1_NUMBER'
                 ||l_delimit||'OTHER2_NAME'
                 ||l_delimit||'OTHER2_NUMBER'
                 ||l_delimit||'OTHER3_NAME'
                 ||l_delimit||'OTHER3_NUMBER'
                 ||l_delimit||'OTHER4_NAME'
                 ||l_delimit||'OTHER4_NUMBER'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                 ||l_delimit||'FIPS_STATE'
                 ||l_delimit||'FIPS_COUNTY'
                 ||l_delimit||'FIPS_CITY'
                 ||l_delimit||'GEOCODE'
                 ||l_delimit||'MTA_GEOCODE'
                 ||l_delimit||'SPD_GEOCODE'
                 ||l_delimit||'OTHER1_GEOCODE'
                 ||l_delimit||'OTHER2_GEOCODE'
                 ||l_delimit||'OTHER3_GEOCODE'
                 ||l_delimit||'OTHER4_GEOCODE'
                 ||l_delimit||'GEOCODE_LONG'
                 ||l_delimit||'STATE_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_EFFECTIVE_DATE'
                 ||l_delimit||'CITY_EFFECTIVE_DATE'
                 ||l_delimit||'MTA_EFFECTIVE_DATE'
                 ||l_delimit||'SPD_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER1_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER2_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER3_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER4_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_TAX_COLLECTED_BY'
                 ||l_delimit||'CITY_TAX_COLLECTED_BY'
                 ||l_delimit||'STATE_TAXABLE_MAX'
                 ||l_delimit||'STATE_TAX_OVER_MAX'
                 ||l_delimit||'COUNTY_TAXABLE_MAX'
                 ||l_delimit||'COUNTY_TAX_OVER_MAX'
                 ||l_delimit||'CITY_TAXABLE_MAX'
                 ||l_delimit||'CITY_TAX_OVER_MAX'
                 ||l_delimit||'SALES_TAX_HOLIDAY'
                 ||l_delimit||'SALES_TAX_HOLIDAY_DATES'
                 ||l_delimit||'SALES_TAX_HOLIDAY_ITEMS'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||MTA_SALES_TAX
                        ||l_delimit||MTA_USE_TAX
                        ||l_delimit||SPD_SALES_TAX
                        ||l_delimit||SPD_USE_TAX
                        ||l_delimit||OTHER1_SALES_TAX
                        ||l_delimit||OTHER1_USE_TAX
                        ||l_delimit||OTHER2_SALES_TAX
                        ||l_delimit||OTHER2_USE_TAX
                        ||l_delimit||OTHER3_SALES_TAX
                        ||l_delimit||OTHER3_USE_TAX
                        ||l_delimit||OTHER4_SALES_TAX
                        ||l_delimit||OTHER4_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||COUNTY_NUMBER
                        ||l_delimit||CITY_NUMBER
                        ||l_delimit||MTA_NAME
                        ||l_delimit||MTA_NUMBER
                        ||l_delimit||SPD_NAME
                        ||l_delimit||SPD_NUMBER
                        ||l_delimit||OTHER1_NAME
                        ||l_delimit||OTHER1_NUMBER
                        ||l_delimit||OTHER2_NAME
                        ||l_delimit||OTHER2_NUMBER
                        ||l_delimit||OTHER3_NAME
                        ||l_delimit||OTHER3_NUMBER
                        ||l_delimit||OTHER4_NAME
                        ||l_delimit||OTHER4_NUMBER
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING
                        ||l_delimit||FIPS_STATE
                        ||l_delimit||FIPS_COUNTY
                        ||l_delimit||FIPS_CITY
                        ||l_delimit||GEOCODE
                        ||l_delimit||MTA_GEOCODE
                        ||l_delimit||SPD_GEOCODE
                        ||l_delimit||OTHER1_GEOCODE
                        ||l_delimit||OTHER2_GEOCODE
                        ||l_delimit||OTHER3_GEOCODE
                        ||l_delimit||OTHER4_GEOCODE
                        ||l_delimit||GEOCODE_LONG
                        ||l_delimit||STATE_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_EFFECTIVE_DATE
                        ||l_delimit||CITY_EFFECTIVE_DATE
                        ||l_delimit||MTA_EFFECTIVE_DATE
                        ||l_delimit||SPD_EFFECTIVE_DATE
                        ||l_delimit||OTHER1_EFFECTIVE_DATE
                        ||l_delimit||OTHER2_EFFECTIVE_DATE
                        ||l_delimit||OTHER3_EFFECTIVE_DATE
                        ||l_delimit||OTHER4_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_TAX_COLLECTED_BY
                        ||l_delimit||CITY_TAX_COLLECTED_BY
                        ||l_delimit||STATE_TAXABLE_MAX
                        ||l_delimit||STATE_TAX_OVER_MAX
                        ||l_delimit||COUNTY_TAXABLE_MAX
                        ||l_delimit||COUNTY_TAX_OVER_MAX
                        ||l_delimit||CITY_TAXABLE_MAX
                        ||l_delimit||CITY_TAX_OVER_MAX
                        ||l_delimit||SALES_TAX_HOLIDAY
                        ||l_delimit||SALES_TAX_HOLIDAY_DATES
                        ||l_delimit||SALES_TAX_HOLIDAY_ITEMS  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_complete_plus  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_complete_plus||' rate file', paction=>1, puser=>user_i);



            -- Complete -- All multi-point Zips
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_complete||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_complete, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'MTA_SALES_TAX'
                 ||l_delimit||'MTA_USE_TAX'
                 ||l_delimit||'SPD_SALES_TAX'
                 ||l_delimit||'SPD_USE_TAX'
                 ||l_delimit||'OTHER1_SALES_TAX'
                 ||l_delimit||'OTHER1_USE_TAX'
                 ||l_delimit||'OTHER2_SALES_TAX'
                 ||l_delimit||'OTHER2_USE_TAX'
                 ||l_delimit||'OTHER3_SALES_TAX'
                 ||l_delimit||'OTHER3_USE_TAX'
                 ||l_delimit||'OTHER4_SALES_TAX'
                 ||l_delimit||'OTHER4_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'COUNTY_NUMBER'
                 ||l_delimit||'CITY_NUMBER'
                 ||l_delimit||'MTA_NAME'
                 ||l_delimit||'MTA_NUMBER'
                 ||l_delimit||'SPD_NAME'
                 ||l_delimit||'SPD_NUMBER'
                 ||l_delimit||'OTHER1_NAME'
                 ||l_delimit||'OTHER1_NUMBER'
                 ||l_delimit||'OTHER2_NAME'
                 ||l_delimit||'OTHER2_NUMBER'
                 ||l_delimit||'OTHER3_NAME'
                 ||l_delimit||'OTHER3_NUMBER'
                 ||l_delimit||'OTHER4_NAME'
                 ||l_delimit||'OTHER4_NUMBER'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||MTA_SALES_TAX
                        ||l_delimit||MTA_USE_TAX
                        ||l_delimit||SPD_SALES_TAX
                        ||l_delimit||SPD_USE_TAX
                        ||l_delimit||OTHER1_SALES_TAX
                        ||l_delimit||OTHER1_USE_TAX
                        ||l_delimit||OTHER2_SALES_TAX
                        ||l_delimit||OTHER2_USE_TAX
                        ||l_delimit||OTHER3_SALES_TAX
                        ||l_delimit||OTHER3_USE_TAX
                        ||l_delimit||OTHER4_SALES_TAX
                        ||l_delimit||OTHER4_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||COUNTY_NUMBER
                        ||l_delimit||CITY_NUMBER
                        ||l_delimit||MTA_NAME
                        ||l_delimit||MTA_NUMBER
                        ||l_delimit||SPD_NAME
                        ||l_delimit||SPD_NUMBER
                        ||l_delimit||OTHER1_NAME
                        ||l_delimit||OTHER1_NUMBER
                        ||l_delimit||OTHER2_NAME
                        ||l_delimit||OTHER2_NUMBER
                        ||l_delimit||OTHER3_NAME
                        ||l_delimit||OTHER3_NUMBER
                        ||l_delimit||OTHER4_NAME
                        ||l_delimit||OTHER4_NUMBER
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_complete  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_complete||' rate file', paction=>1, puser=>user_i);



            -- Basic -- Default Zips only, Preferred Mailing City only (crapp-3244) - crapp-3416, updated
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_basic, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_basic  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic||' rate file', paction=>1, puser=>user_i);



            -- Basic+ -- Default Zips only, Include Fips and Effective Dates, Preferred Mailing City only (crapp-3244) - crapp-3416, updated
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic_plus||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_basic_plus, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                 ||l_delimit||'FIPS_STATE'
                 ||l_delimit||'FIPS_COUNTY'
                 ||l_delimit||'FIPS_CITY'
                 ||l_delimit||'FIPS_GEOCODE'
                 ||l_delimit||'STATE_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_EFFECTIVE_DATE'
                 ||l_delimit||'CITY_EFFECTIVE_DATE'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING
                        ||l_delimit||FIPS_STATE
                        ||l_delimit||FIPS_COUNTY
                        ||l_delimit||FIPS_CITY
                        ||l_delimit||GEOCODE
                        ||l_delimit||STATE_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_EFFECTIVE_DATE
                        ||l_delimit||CITY_EFFECTIVE_DATE  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_basic_plus  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic_plus||' rate file', paction=>1, puser=>user_i);




            -- BasicII -- All multi-point Zips
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic2||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_basic2, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_basic_2  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic2||' rate file', paction=>1, puser=>user_i);



            -- BasicII+ -- All multi-point Zips, Include Fips and Effective Dates, Supports Unincorporated and Cities with (1..) in the name
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic2_plus||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_basic2_plus, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                 ||l_delimit||'FIPS_STATE'
                 ||l_delimit||'FIPS_COUNTY'
                 ||l_delimit||'FIPS_CITY'
                 ||l_delimit||'FIPS_GEOCODE'
                 ||l_delimit||'STATE_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_EFFECTIVE_DATE'
                 ||l_delimit||'CITY_EFFECTIVE_DATE'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING
                        ||l_delimit||FIPS_STATE
                        ||l_delimit||FIPS_COUNTY
                        ||l_delimit||FIPS_CITY
                        ||l_delimit||GEOCODE
                        ||l_delimit||STATE_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_EFFECTIVE_DATE
                        ||l_delimit||CITY_EFFECTIVE_DATE  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_basic_2_plus  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_basic2_plus||' rate file', paction=>1, puser=>user_i);



            -- Expanded -- Default Zips only, Preferred Mailing City only (crapp-3244) - crapp-3416, updated
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_expanded||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_expanded, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'MTA_SALES_TAX'
                 ||l_delimit||'MTA_USE_TAX'
                 ||l_delimit||'SPD_SALES_TAX'
                 ||l_delimit||'SPD_USE_TAX'
                 ||l_delimit||'OTHER1_SALES_TAX'
                 ||l_delimit||'OTHER1_USE_TAX'
                 ||l_delimit||'OTHER2_SALES_TAX'
                 ||l_delimit||'OTHER2_USE_TAX'
                 ||l_delimit||'OTHER3_SALES_TAX'
                 ||l_delimit||'OTHER3_USE_TAX'
                 ||l_delimit||'OTHER4_SALES_TAX'
                 ||l_delimit||'OTHER4_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'COUNTY_NUMBER'
                 ||l_delimit||'CITY_NUMBER'
                 ||l_delimit||'MTA_NAME'
                 ||l_delimit||'MTA_NUMBER'
                 ||l_delimit||'SPD_NAME'
                 ||l_delimit||'SPD_NUMBER'
                 ||l_delimit||'OTHER1_NAME'
                 ||l_delimit||'OTHER1_NUMBER'
                 ||l_delimit||'OTHER2_NAME'
                 ||l_delimit||'OTHER2_NUMBER'
                 ||l_delimit||'OTHER3_NAME'
                 ||l_delimit||'OTHER3_NUMBER'
                 ||l_delimit||'OTHER4_NAME'
                 ||l_delimit||'OTHER4_NUMBER'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||MTA_SALES_TAX
                        ||l_delimit||MTA_USE_TAX
                        ||l_delimit||SPD_SALES_TAX
                        ||l_delimit||SPD_USE_TAX
                        ||l_delimit||OTHER1_SALES_TAX
                        ||l_delimit||OTHER1_USE_TAX
                        ||l_delimit||OTHER2_SALES_TAX
                        ||l_delimit||OTHER2_USE_TAX
                        ||l_delimit||OTHER3_SALES_TAX
                        ||l_delimit||OTHER3_USE_TAX
                        ||l_delimit||OTHER4_SALES_TAX
                        ||l_delimit||OTHER4_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||COUNTY_NUMBER
                        ||l_delimit||CITY_NUMBER
                        ||l_delimit||MTA_NAME
                        ||l_delimit||MTA_NUMBER
                        ||l_delimit||SPD_NAME
                        ||l_delimit||SPD_NUMBER
                        ||l_delimit||OTHER1_NAME
                        ||l_delimit||OTHER1_NUMBER
                        ||l_delimit||OTHER2_NAME
                        ||l_delimit||OTHER2_NUMBER
                        ||l_delimit||OTHER3_NAME
                        ||l_delimit||OTHER3_NUMBER
                        ||l_delimit||OTHER4_NAME
                        ||l_delimit||OTHER4_NUMBER
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_expanded  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_expanded||' rate file', paction=>1, puser=>user_i);



            -- Expanded+ -- Default Zips only, Include Fips and Effective Dates, Includes additional tax columns, Preferred Mailing City only (crapp-3244) - crapp-3416, updated
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_expanded_plus||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_expanded_plus, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'MTA_SALES_TAX'
                 ||l_delimit||'MTA_USE_TAX'
                 ||l_delimit||'SPD_SALES_TAX'
                 ||l_delimit||'SPD_USE_TAX'
                 ||l_delimit||'OTHER1_SALES_TAX'
                 ||l_delimit||'OTHER1_USE_TAX'
                 ||l_delimit||'OTHER2_SALES_TAX'
                 ||l_delimit||'OTHER2_USE_TAX'
                 ||l_delimit||'OTHER3_SALES_TAX'
                 ||l_delimit||'OTHER3_USE_TAX'
                 ||l_delimit||'OTHER4_SALES_TAX'
                 ||l_delimit||'OTHER4_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'COUNTY_NUMBER'
                 ||l_delimit||'CITY_NUMBER'
                 ||l_delimit||'MTA_NAME'
                 ||l_delimit||'MTA_NUMBER'
                 ||l_delimit||'SPD_NAME'
                 ||l_delimit||'SPD_NUMBER'
                 ||l_delimit||'OTHER1_NAME'
                 ||l_delimit||'OTHER1_NUMBER'
                 ||l_delimit||'OTHER2_NAME'
                 ||l_delimit||'OTHER2_NUMBER'
                 ||l_delimit||'OTHER3_NAME'
                 ||l_delimit||'OTHER3_NUMBER'
                 ||l_delimit||'OTHER4_NAME'
                 ||l_delimit||'OTHER4_NUMBER'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING'
                 ||l_delimit||'FIPS_STATE'
                 ||l_delimit||'FIPS_COUNTY'
                 ||l_delimit||'FIPS_CITY'
                 ||l_delimit||'GEOCODE'
                 ||l_delimit||'MTA_GEOCODE'
                 ||l_delimit||'SPD_GEOCODE'
                 ||l_delimit||'OTHER1_GEOCODE'
                 ||l_delimit||'OTHER2_GEOCODE'
                 ||l_delimit||'OTHER3_GEOCODE'
                 ||l_delimit||'OTHER4_GEOCODE'
                 ||l_delimit||'GEOCODE_LONG'
                 ||l_delimit||'STATE_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_EFFECTIVE_DATE'
                 ||l_delimit||'CITY_EFFECTIVE_DATE'
                 ||l_delimit||'MTA_EFFECTIVE_DATE'
                 ||l_delimit||'SPD_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER1_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER2_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER3_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER4_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_TAX_COLLECTED_BY'
                 ||l_delimit||'CITY_TAX_COLLECTED_BY'
                 ||l_delimit||'STATE_TAXABLE_MAX'
                 ||l_delimit||'STATE_TAX_OVER_MAX'
                 ||l_delimit||'COUNTY_TAXABLE_MAX'
                 ||l_delimit||'COUNTY_TAX_OVER_MAX'
                 ||l_delimit||'CITY_TAXABLE_MAX'
                 ||l_delimit||'CITY_TAX_OVER_MAX'
                 ||l_delimit||'SALES_TAX_HOLIDAY'
                 ||l_delimit||'SALES_TAX_HOLIDAY_DATES'
                 ||l_delimit||'SALES_TAX_HOLIDAY_ITEMS'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||MTA_SALES_TAX
                        ||l_delimit||MTA_USE_TAX
                        ||l_delimit||SPD_SALES_TAX
                        ||l_delimit||SPD_USE_TAX
                        ||l_delimit||OTHER1_SALES_TAX
                        ||l_delimit||OTHER1_USE_TAX
                        ||l_delimit||OTHER2_SALES_TAX
                        ||l_delimit||OTHER2_USE_TAX
                        ||l_delimit||OTHER3_SALES_TAX
                        ||l_delimit||OTHER3_USE_TAX
                        ||l_delimit||OTHER4_SALES_TAX
                        ||l_delimit||OTHER4_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||COUNTY_NUMBER
                        ||l_delimit||CITY_NUMBER
                        ||l_delimit||MTA_NAME
                        ||l_delimit||MTA_NUMBER
                        ||l_delimit||SPD_NAME
                        ||l_delimit||SPD_NUMBER
                        ||l_delimit||OTHER1_NAME
                        ||l_delimit||OTHER1_NUMBER
                        ||l_delimit||OTHER2_NAME
                        ||l_delimit||OTHER2_NUMBER
                        ||l_delimit||OTHER3_NAME
                        ||l_delimit||OTHER3_NUMBER
                        ||l_delimit||OTHER4_NAME
                        ||l_delimit||OTHER4_NUMBER
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING
                        ||l_delimit||FIPS_STATE
                        ||l_delimit||FIPS_COUNTY
                        ||l_delimit||FIPS_CITY
                        ||l_delimit||GEOCODE
                        ||l_delimit||MTA_GEOCODE
                        ||l_delimit||SPD_GEOCODE
                        ||l_delimit||OTHER1_GEOCODE
                        ||l_delimit||OTHER2_GEOCODE
                        ||l_delimit||OTHER3_GEOCODE
                        ||l_delimit||OTHER4_GEOCODE
                        ||l_delimit||GEOCODE_LONG
                        ||l_delimit||STATE_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_EFFECTIVE_DATE
                        ||l_delimit||CITY_EFFECTIVE_DATE
                        ||l_delimit||MTA_EFFECTIVE_DATE
                        ||l_delimit||SPD_EFFECTIVE_DATE
                        ||l_delimit||OTHER1_EFFECTIVE_DATE
                        ||l_delimit||OTHER2_EFFECTIVE_DATE
                        ||l_delimit||OTHER3_EFFECTIVE_DATE
                        ||l_delimit||OTHER4_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_TAX_COLLECTED_BY
                        ||l_delimit||CITY_TAX_COLLECTED_BY
                        ||l_delimit||STATE_TAXABLE_MAX
                        ||l_delimit||STATE_TAX_OVER_MAX
                        ||l_delimit||COUNTY_TAXABLE_MAX
                        ||l_delimit||COUNTY_TAX_OVER_MAX
                        ||l_delimit||CITY_TAXABLE_MAX
                        ||l_delimit||CITY_TAX_OVER_MAX
                        ||l_delimit||SALES_TAX_HOLIDAY
                        ||l_delimit||SALES_TAX_HOLIDAY_DATES
                        ||l_delimit||SALES_TAX_HOLIDAY_ITEMS  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_expanded_plus  -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_expanded_plus||' rate file', paction=>1, puser=>user_i);



            --  Zip4 -- All multi-point Zips, Include Fips and Effective Dates, Include additional tax columns, Supports Unincorporated and Cities with (1..) -- crapp-3407
            --       -- Also No leading zeoes in Tax values, Column to indicate Zip or Zip4 (RECORD_TYPE) --
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_zip4||' rate file', paction=>0, puser=>user_i);

            l_ftype := UTL_FILE.FOPEN(l_dir, l_file_zip4, 'W', max_linesize => 32767);
            UTL_FILE.put_line
                (l_ftype,
                 'ZIP_CODE'
                 ||l_delimit||'PLUS_4_LOW'
                 ||l_delimit||'PLUS_4_HIGH'
                 ||l_delimit||'RECORD_TYPE'
                 ||l_delimit||'STATE_ABBREV'
                 ||l_delimit||'COUNTY_NAME'
                 ||l_delimit||'CITY_NAME'
                 ||l_delimit||'STATE_SALES_TAX'
                 ||l_delimit||'STATE_USE_TAX'
                 ||l_delimit||'COUNTY_SALES_TAX'
                 ||l_delimit||'COUNTY_USE_TAX'
                 ||l_delimit||'CITY_SALES_TAX'
                 ||l_delimit||'CITY_USE_TAX'
                 ||l_delimit||'MTA_SALES_TAX'
                 ||l_delimit||'MTA_USE_TAX'
                 ||l_delimit||'SPD_SALES_TAX'
                 ||l_delimit||'SPD_USE_TAX'
                 ||l_delimit||'OTHER1_SALES_TAX'
                 ||l_delimit||'OTHER1_USE_TAX'
                 ||l_delimit||'OTHER2_SALES_TAX'
                 ||l_delimit||'OTHER2_USE_TAX'
                 ||l_delimit||'OTHER3_SALES_TAX'
                 ||l_delimit||'OTHER3_USE_TAX'
                 ||l_delimit||'OTHER4_SALES_TAX'
                 ||l_delimit||'OTHER4_USE_TAX'
                 ||l_delimit||'TOTAL_SALES_TAX'
                 ||l_delimit||'TOTAL_USE_TAX'
                 ||l_delimit||'COUNTY_RPT_CODE'
                 ||l_delimit||'CITY_RPT_CODE'
                 ||l_delimit||'MTA_NAME'
                 ||l_delimit||'MTA_NUMBER'
                 ||l_delimit||'SPD_NAME'
                 ||l_delimit||'SPD_NUMBER'
                 ||l_delimit||'OTHER1_NAME'
                 ||l_delimit||'OTHER1_NUMBER'
                 ||l_delimit||'OTHER2_NAME'
                 ||l_delimit||'OTHER2_NUMBER'
                 ||l_delimit||'OTHER3_NAME'
                 ||l_delimit||'OTHER3_NUMBER'
                 ||l_delimit||'OTHER4_NAME'
                 ||l_delimit||'OTHER4_NUMBER'
                 ||l_delimit||'TAX_SHIPPING_ALONE'
                 ||l_delimit||'TAX_SHIPPING_AND_HANDLING_TOGETHER'
                 ||l_delimit||'FIPS_STATE'
                 ||l_delimit||'FIPS_COUNTY'
                 ||l_delimit||'FIPS_CITY'
                 ||l_delimit||'FIPS_GEOCODE'
                 ||l_delimit||'STATE_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_EFFECTIVE_DATE'
                 ||l_delimit||'CITY_EFFECTIVE_DATE'
                 ||l_delimit||'MTA_EFFECTIVE_DATE'
                 ||l_delimit||'SPD_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER1_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER2_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER3_EFFECTIVE_DATE'
                 ||l_delimit||'OTHER4_EFFECTIVE_DATE'
                 ||l_delimit||'COUNTY_TAX_COLLECTED_BY'
                 ||l_delimit||'CITY_TAX_COLLECTED_BY'
                 ||l_delimit||'COUNTY_TAXABLE_MAX'
                 ||l_delimit||'COUNTY_TAX_OVER_MAX'
                 ||l_delimit||'CITY_TAXABLE_MAX'
                 ||l_delimit||'CITY_TAX_OVER_MAX'
                );

            FOR r IN
                ( SELECT
                        ZIP_CODE
                        ||l_delimit||PLUS_4_LOW
                        ||l_delimit||PLUS_4_HIGH
                        ||l_delimit||RECORD_TYPE
                        ||l_delimit||STATE_CODE
                        ||l_delimit||COUNTY_NAME
                        ||l_delimit||CITY_NAME
                        ||l_delimit||STATE_SALES_TAX
                        ||l_delimit||STATE_USE_TAX
                        ||l_delimit||COUNTY_SALES_TAX
                        ||l_delimit||COUNTY_USE_TAX
                        ||l_delimit||CITY_SALES_TAX
                        ||l_delimit||CITY_USE_TAX
                        ||l_delimit||MTA_SALES_TAX
                        ||l_delimit||MTA_USE_TAX
                        ||l_delimit||SPD_SALES_TAX
                        ||l_delimit||SPD_USE_TAX
                        ||l_delimit||OTHER1_SALES_TAX
                        ||l_delimit||OTHER1_USE_TAX
                        ||l_delimit||OTHER2_SALES_TAX
                        ||l_delimit||OTHER2_USE_TAX
                        ||l_delimit||OTHER3_SALES_TAX
                        ||l_delimit||OTHER3_USE_TAX
                        ||l_delimit||OTHER4_SALES_TAX
                        ||l_delimit||OTHER4_USE_TAX
                        ||l_delimit||TOTAL_SALES_TAX
                        ||l_delimit||TOTAL_USE_TAX
                        ||l_delimit||COUNTY_RPT_CODE
                        ||l_delimit||CITY_RPT_CODE
                        ||l_delimit||MTA_NAME
                        ||l_delimit||MTA_NUMBER
                        ||l_delimit||SPD_NAME
                        ||l_delimit||SPD_NUMBER
                        ||l_delimit||OTHER1_NAME
                        ||l_delimit||OTHER1_NUMBER
                        ||l_delimit||OTHER2_NAME
                        ||l_delimit||OTHER2_NUMBER
                        ||l_delimit||OTHER3_NAME
                        ||l_delimit||OTHER3_NUMBER
                        ||l_delimit||OTHER4_NAME
                        ||l_delimit||OTHER4_NUMBER
                        ||l_delimit||TAX_SHIPPING_ALONE
                        ||l_delimit||TAX_SHIPPING_AND_HANDLING
                        ||l_delimit||FIPS_STATE
                        ||l_delimit||FIPS_COUNTY
                        ||l_delimit||FIPS_CITY
                        ||l_delimit||FIPS_GEOCODE
                        ||l_delimit||STATE_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_EFFECTIVE_DATE
                        ||l_delimit||CITY_EFFECTIVE_DATE
                        ||l_delimit||MTA_EFFECTIVE_DATE
                        ||l_delimit||SPD_EFFECTIVE_DATE
                        ||l_delimit||OTHER1_EFFECTIVE_DATE
                        ||l_delimit||OTHER2_EFFECTIVE_DATE
                        ||l_delimit||OTHER3_EFFECTIVE_DATE
                        ||l_delimit||OTHER4_EFFECTIVE_DATE
                        ||l_delimit||COUNTY_TAX_COLLECTED_BY
                        ||l_delimit||CITY_TAX_COLLECTED_BY
                        ||l_delimit||COUNTY_TAXABLE_MAX
                        ||l_delimit||COUNTY_TAX_OVER_MAX
                        ||l_delimit||CITY_TAXABLE_MAX
                        ||l_delimit||CITY_TAX_OVER_MAX  line
                  FROM (
                         SELECT *
                         FROM   vosr_extract_zip4   -- crapp-4169, now using view
                         WHERE  state_code = l_stcode
                                OR l_stcode IS NULL
                         ORDER BY state_code, zip_code, plus_4_low, county_name, city_name
                       )
                )
            LOOP
                UTL_FILE.put_line (l_ftype, r.line);
            END LOOP;

            UTL_FILE.FFLUSH(l_ftype);
            UTL_FILE.FCLOSE(l_ftype);
            COMMIT;
            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' - Extracting '||l_file_zip4||' rate file', paction=>1, puser=>user_i);

            gis_etl_p(pid=>pID_i, pstate=>stcode_i, ppart=>' extract_rate_files', paction=>1, puser=>user_i);
        END extract_rate_files;




    -- ****************************************************************************************** --
    -- Main procedure to extract the ONCESOURCE rate files - called by the UI                     --
    --                                                                                            --
    -- NOTE: Territories do not get separate files, they are included in the ALL STATES file only --
    --       AA, AE, AP, AS, FM, MH, MP, PW, VI                                                   --
    --                                                                                            --
    -- CRAPP-3654 - Added state name "- ALL -" (XX) to GEO_STATES                                 --
    -- ****************************************************************************************** --
    PROCEDURE generate_osr_rate_file
    (
        stcode_i   IN VARCHAR2,
        user_i     IN NUMBER,
        start_dt_i IN DATE,
        tag_grp_i  IN NUMBER
    )
    IS
            l_stcode  VARCHAR2(2 CHAR) := CASE WHEN (stcode_i IS NULL OR stcode_i = 'XX') THEN 'XX' ELSE stcode_i END;
            l_dir     VARCHAR2(100 CHAR):= 'EXTRACT_FILES';
            l_logid   NUMBER;
            l_pid     NUMBER := gis_etl_process_log_sq.nextval;

            CURSOR states IS
                SELECT state_code, NAME state_name
                FROM   geo_states
                WHERE  (state_code = stcode_i
                        OR stcode_i IS NULL
                       )
                       AND state_code != 'XX'
                ORDER BY state_code;

        BEGIN
            gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>'generate_osr_rate_file', paction=>0, puser=>user_i);

            -- Create Action_Log entry --
            INSERT INTO crapp_admin.action_log (status, referrer, entered_by, parameters)
                VALUES (  0 -- start
                        , 'extract_rate_files'
                        , user_i
                        , '{"Extacting ONESOURCE rates files for ":"'||NVL(stcode_i, 'All States')||'","Folder":"'||l_dir||'"}'
                       )
                RETURNING id INTO l_logid;
            COMMIT;

            -- Determine the location of the STJs --
            build_osr_spd_basic(l_stcode, l_pid, user_i);   -- This is only required once per extract run

            -- Determine the jurisdictions by tag group --
            get_tag_data(l_stcode, l_pid, user_i);   -- 01/13/17

            -- Extract the Peferred Mailing City --
            extract_preferred_city(l_stcode, l_pid, user_i);

            -- Populate the Rate staging table --
            get_rates(l_stcode, l_pid, user_i, start_dt_i);


            -- crapp-3971 --
            gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>' - Determine crossborder zips - osr_crossborder_zips_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_crossborder_zips_tmp DROP STORAGE';
            EXECUTE IMMEDIATE 'ALTER INDEX osr_crossborder_zips_tmp_n1 UNUSABLE';
            INSERT INTO osr_crossborder_zips_tmp
                WITH cbzip AS
                    (
                     SELECT DISTINCT zip, COUNT(DISTINCT state_code) statecount
                     FROM   geo_usps_lookup u
                     WHERE  zip IS NOT NULL
                     GROUP BY zip
                     HAVING COUNT(DISTINCT state_code) > 1
                    )
                    SELECT DISTINCT
                           u.state_code
                           , u.county_name
                           , u.city_name
                           , u.zip
                           , u.override_rank
                           , u.area_id
                           , z.zip9count
                           , RANK( ) OVER( PARTITION BY u.zip ORDER BY z.zip9count DESC ) zip9rank
                    FROM   geo_usps_lookup u
                           JOIN (
                                  SELECT DISTINCT state_code, zip, area_id, COUNT(DISTINCT zip9) zip9count
                                  FROM   geo_usps_mv_staging
                                  WHERE  zip9 IS NOT NULL
                                         AND zip IN (SELECT zip FROM cbzip)
                                  GROUP BY state_code, zip, area_id
                                ) z ON ( z.zip = u.zip
                                         AND z.area_id = u.area_id
                                       )
                    WHERE  u.zip9 IS NULL
                           AND u.override_rank = 1  -- defaults only
                           AND u.zip IN (SELECT zip FROM cbzip)
                    ORDER BY u.state_code, u.area_id;
            COMMIT;
            EXECUTE IMMEDIATE 'ALTER INDEX osr_crossborder_zips_tmp_n1 REBUILD';
            DBMS_STATS.gather_table_stats('CONTENT_REPO', 'osr_crossborder_zips_tmp', cascade => TRUE);
            gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>' - Determine crossborder zips - osr_crossborder_zips_tmp', paction=>1, puser=>user_i);


            -- 09/29/17 - added staging table for performance --
            gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>' - Determine area overrides - osr_zone_area_ovrd_tmp', paction=>0, puser=>user_i);
            EXECUTE IMMEDIATE 'TRUNCATE TABLE osr_zone_area_ovrd_tmp DROP STORAGE';
            INSERT INTO osr_zone_area_ovrd_tmp
                (
                  unique_area_id
                , unique_area_nkid
                , unique_area_rid
                , value_id
                , value
                )
                SELECT DISTINCT
                       unique_area_id, unique_area_nkid, unique_area_rid, value_id, value
                FROM   vunique_area_attributes
                WHERE  attribute_id = 18 -- NAME = 'Jurisdiction Override'
                       AND next_rid IS NULL;
            COMMIT;
            gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>' - Determine area overrides - osr_zone_area_ovrd_tmp', paction=>1, puser=>user_i);


            -- Loop through specific state --
            FOR s IN states LOOP
                -- Determine the zip data for the given state --
                determine_zip_data(s.state_code, l_pid, user_i);

                -- Determine the zip4 data for the given state --   01/13/17
                determine_zip4_data(s.state_code, l_pid, user_i);

                -- Populate the Rate table by zip --
                populate_osr_rates(s.state_code, l_pid, user_i, start_dt_i);    -- crapp-4170, added start_dt_i

                -- Check for invalid rate amounts -- crapp-3456
                datacheck_rate_amounts(s.state_code, l_pid, user_i);

                -- Check for duplicate Zip records -- crapp-3153
                datacheck_zip_dupes(s.state_code, l_pid, user_i);

                -- Check file counts -- crapp-3329
                datacheck_file_counts(s.state_code, l_pid, user_i);

                -- Export the rate files --
                -- Territories do not get separate files, they are included in the ALL STATES file only
                IF s.state_code NOT IN ('AA', 'AE', 'AP', 'AS', 'FM', 'MH', 'MP', 'PW', 'VI') THEN
                    extract_rate_files(s.state_code, l_pid, user_i);
                END IF;
            END LOOP;


            -- Export the ALL State rate files --
            IF l_stcode = 'XX' THEN
                -- Single All State File --
                extract_rate_files('AS', l_pid, user_i);
            END IF;


            -- Update Action_Log entry --
            UPDATE crapp_admin.action_log
                SET status = 1
            WHERE id = l_logid;
            COMMIT;

            gis_etl_p(pid=>l_pid, pstate=>l_stcode, ppart=>'generate_osr_rate_file', paction=>1, puser=>user_i);
        END generate_osr_rate_file;

END osr_rate_extract;
/