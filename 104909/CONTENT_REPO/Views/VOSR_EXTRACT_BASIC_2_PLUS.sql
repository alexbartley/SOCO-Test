CREATE OR REPLACE FORCE VIEW content_repo.vosr_extract_basic_2_plus (zip_code,state_code,county_name,city_name,state_sales_tax,state_use_tax,county_sales_tax,county_use_tax,city_sales_tax,city_use_tax,total_sales_tax,total_use_tax,tax_shipping_alone,tax_shipping_and_handling,fips_state,fips_county,fips_city,geocode,state_effective_date,county_effective_date,city_effective_date) AS
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
                , bp.city_name
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
                     GROUP BY uaid -- crapp-3416, added group by due to SUM
                            ,zip_code
                            ,state_code
                            ,county_name
                            ,city_name
                     ) s ON (    bp.state_code  = s.state_code
                             AND bp.county_name = s.county_name  -- crapp-3416, added
                             AND bp.city_name   = s.city_name    -- crapp-3416, added
                             AND bp.zip_code    = s.zip_code
                             --AND bp.uaid = s.uaid              -- crapp-3416, removed
                            )
        )
 GROUP BY   -- 07/19/17
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
        , geocode;