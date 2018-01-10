CREATE OR REPLACE FORCE VIEW content_repo.vosr_extract_basic_plus (zip_code,state_code,county_name,city_name,state_sales_tax,state_use_tax,county_sales_tax,county_use_tax,city_sales_tax,city_use_tax,total_sales_tax,total_use_tax,tax_shipping_alone,tax_shipping_and_handling,fips_state,fips_county,fips_city,geocode,state_effective_date,county_effective_date,city_effective_date) AS
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
        , MAX(state_effective_date)  state_effective_date   -- 07/19/17
        , MAX(county_effective_date) county_effective_date
        , MAX(city_effective_date)   city_effective_date
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
                , CASE WHEN TO_NUMBER(bp.city_sales_tax) = 0 THEN TO_NUMBER(bp.county_sales_tax) + NVL(s.stj_salestax,0)
                       ELSE TO_NUMBER(bp.county_sales_tax)
                  END county_sales_tax
                , CASE WHEN TO_NUMBER(bp.city_use_tax) = 0 THEN TO_NUMBER(bp.county_use_tax) + NVL(s.stj_usetax,0)
                       ELSE TO_NUMBER(bp.county_use_tax)
                  END county_use_tax
                , CASE WHEN TO_NUMBER(bp.city_sales_tax) > 0 THEN TO_NUMBER(bp.city_sales_tax) + NVL(s.stj_salestax,0)
                       ELSE TO_NUMBER(bp.city_sales_tax)
                  END city_sales_tax
                , CASE WHEN TO_NUMBER(bp.city_use_tax) > 0 THEN TO_NUMBER(bp.city_use_tax) + NVL(s.stj_usetax,0)
                       ELSE TO_NUMBER(bp.city_use_tax)
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
                     WHERE  default_flag = 'Y'
                            AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3416, added to exclude cities with (1..n) in the name
                            --AND acceptable_city = 'N'         -- crapp-3416, removed
                    ) s ON ( bp.state_code = s.state_code
                             AND bp.uaid   = s.uaid
                             AND bp.county_name = s.county_name -- crapp-3416
                             AND bp.city_name   = s.city_name   -- 07/20/17
                             AND bp.zip_code    = s.zip_code
                           )
         WHERE  bp.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities - crapp-3416
                AND bp.default_flag = 'Y'
                AND (NOT REGEXP_LIKE(bp.city_name, '[0-9]') AND bp.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
                --AND bp.acceptable_city = 'N'   -- crapp-3416, removed
         ORDER BY bp.state_code, bp.zip_code, bp.county_name, bp.city_name
 )
 WHERE acpt_rnk = 1
 GROUP BY -- 07/19/17, added
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
        , geocode;