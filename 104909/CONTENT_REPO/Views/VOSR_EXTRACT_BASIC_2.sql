CREATE OR REPLACE FORCE VIEW content_repo.vosr_extract_basic_2 (zip_code,state_code,county_name,city_name,state_sales_tax,state_use_tax,county_sales_tax,county_use_tax,city_sales_tax,city_use_tax,total_sales_tax,total_use_tax,tax_shipping_alone,tax_shipping_and_handling) AS
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
 FROM   (
         SELECT DISTINCT
                b.zip_code
                , b.state_code
                , b.county_name
                , b.city_name
                , b.state_sales_tax
                , b.state_use_tax
                , CASE WHEN TO_NUMBER(b.city_sales_tax) = 0 THEN TO_NUMBER(b.county_sales_tax) + NVL(s.stj_salestax,0)
                       ELSE TO_NUMBER(b.county_sales_tax)
                  END county_sales_tax
                , CASE WHEN TO_NUMBER(b.city_use_tax) = 0 THEN TO_NUMBER(b.county_use_tax) + NVL(s.stj_usetax,0)
                       ELSE TO_NUMBER(b.county_use_tax)
                  END county_use_tax
                , CASE WHEN TO_NUMBER(b.city_sales_tax) > 0 THEN TO_NUMBER(b.city_sales_tax) + NVL(s.stj_salestax,0)
                       ELSE TO_NUMBER(b.city_sales_tax)
                  END city_sales_tax
                , CASE WHEN TO_NUMBER(b.city_use_tax) > 0 THEN TO_NUMBER(b.city_use_tax) + NVL(s.stj_usetax,0)
                       ELSE TO_NUMBER(b.city_use_tax)
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
                     WHERE  city_name <> 'UNINCORPORATED'
                            AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3416, added to exclude cities with (1..n) in the name
                     GROUP BY uaid  -- crapp-3416, added group by due to SUM
                            ,zip_code
                            ,state_code
                            ,county_name
                            ,city_name
                     ) s ON (     b.state_code  = s.state_code
                              AND b.county_name = s.county_name -- crapp-3416, added
                              AND b.city_name   = s.city_name   -- crapp-3416, added
                              AND b.zip_code    = s.zip_code
                              --AND b.uaid = s.uaid             -- crapp-3416, removed
                            )
         WHERE  b.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities
                AND (NOT REGEXP_LIKE(b.city_name, '[0-9]') AND b.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
        );