CREATE OR REPLACE FORCE VIEW content_repo.vosr_extract_zip4 (zip_code,plus_4_low,plus_4_high,record_type,state_code,county_name,city_name,state_sales_tax,state_use_tax,county_sales_tax,county_use_tax,city_sales_tax,city_use_tax,mta_sales_tax,mta_use_tax,spd_sales_tax,spd_use_tax,other1_sales_tax,other1_use_tax,other2_sales_tax,other2_use_tax,other3_sales_tax,other3_use_tax,other4_sales_tax,other4_use_tax,total_sales_tax,total_use_tax,county_rpt_code,city_rpt_code,mta_name,mta_number,spd_name,spd_number,other1_name,other1_number,other2_name,other2_number,other3_name,other3_number,other4_name,other4_number,tax_shipping_alone,tax_shipping_and_handling,fips_state,fips_county,fips_city,fips_geocode,state_effective_date,county_effective_date,city_effective_date,mta_effective_date,spd_effective_date,other1_effective_date,other2_effective_date,other3_effective_date,other4_effective_date,county_tax_collected_by,city_tax_collected_by,county_taxable_max,county_tax_over_max,city_taxable_max,city_tax_over_max) AS
SELECT DISTINCT
        o.zip_code
        , z.range_min   plus_4_low
        , z.range_max   plus_4_high
        , z.rec_type    record_type
        , o.state_code
        , o.county_name
        , o.city_name
        , TRIM(TO_CHAR(TO_NUMBER(o.state_sales_tax), '.999999'))  state_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.state_use_tax), '.999999'))    state_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.county_sales_tax), '.999999')) county_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.county_use_tax), '.999999'))   county_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.city_sales_tax), '.999999'))   city_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.city_use_tax), '.999999'))     city_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.mta_sales_tax), '.999999'))    mta_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.mta_use_tax), '.999999'))      mta_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.spd_sales_tax), '.999999'))    spd_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.spd_use_tax), '.999999'))      spd_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other1_sales_tax), '.999999')) other1_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other1_use_tax), '.999999'))   other1_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other2_sales_tax), '.999999')) other2_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other2_use_tax), '.999999'))   other2_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other3_sales_tax), '.999999')) other3_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other3_use_tax), '.999999'))   other3_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other4_sales_tax), '.999999')) other4_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other4_use_tax), '.999999'))   other4_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.total_sales_tax), '.999999'))  total_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.total_use_tax), '.999999'))    total_use_tax
        , o.county_number   county_rpt_code
        , o.city_number     city_rpt_code
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
        , o.geocode     fips_geocode
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
        , o.county_taxable_max
        , o.county_tax_over_max
        , o.city_taxable_max
        , o.city_tax_over_max
 FROM   osr_as_complete_plus_tmp o
        JOIN osr_zone_zip4_ranges_tmp z ON ( o.state_code   = z.state_code
                                             AND o.zip_code = z.zip
                                             AND o.uaid     = z.area_id
                                             AND z.rec_type = 'Z'
                                           )
        JOIN ( -- Based on the Basic File specs --
              SELECT DISTINCT
                     state_code
                     , zip_code
                     , county_name
                     , city_name
                     , uaid
              FROM  (
                     SELECT DISTINCT
                            zip_code
                            , state_code
                            , county_name
                            , city_name
                            , acceptable_city
                            , RANK( ) OVER(PARTITION BY state_code, zip_code, county_name ORDER BY acceptable_city DESC) acpt_rnk
                            , uaid
                     FROM   osr_as_complete_plus_tmp
                     WHERE  city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities
                            AND default_flag = 'Y'
                            AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
                     ORDER BY state_code, zip_code, county_name, city_name
                    )
              WHERE acpt_rnk = 1
             ) a ON (     o.state_code  = a.state_code
                      AND o.zip_code    = a.zip_code
                      AND o.county_name = a.county_name
                      AND o.city_name   = a.city_name
                      AND o.uaid        = a.uaid
                    )
 -- Range Records --
 UNION

 SELECT DISTINCT
        o.zip_code
        , z.range_min   plus_4_low
        , z.range_max   plus_4_high
        , z.rec_type    record_type
        , o.state_code
        , o.county_name
        , o.city_name
        , TRIM(TO_CHAR(TO_NUMBER(o.state_sales_tax), '.999999'))  state_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.state_use_tax), '.999999'))    state_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.county_sales_tax), '.999999')) county_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.county_use_tax), '.999999'))   county_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.city_sales_tax), '.999999'))   city_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.city_use_tax), '.999999'))     city_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.mta_sales_tax), '.999999'))    mta_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.mta_use_tax), '.999999'))      mta_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.spd_sales_tax), '.999999'))    spd_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.spd_use_tax), '.999999'))      spd_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other1_sales_tax), '.999999')) other1_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other1_use_tax), '.999999'))   other1_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other2_sales_tax), '.999999')) other2_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other2_use_tax), '.999999'))   other2_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other3_sales_tax), '.999999')) other3_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other3_use_tax), '.999999'))   other3_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other4_sales_tax), '.999999')) other4_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.other4_use_tax), '.999999'))   other4_use_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.total_sales_tax), '.999999'))  total_sales_tax
        , TRIM(TO_CHAR(TO_NUMBER(o.total_use_tax), '.999999'))    total_use_tax
        , o.county_number   county_rpt_code
        , o.city_number     city_rpt_code
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
        , o.geocode     fips_geocode
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
        , o.county_taxable_max
        , o.county_tax_over_max
        , o.city_taxable_max
        , o.city_tax_over_max
 FROM   osr_as_complete_plus_tmp o
        JOIN osr_zone_zip4_ranges_tmp z ON (    o.state_code = z.state_code
                                            AND o.zip_code   = z.zip
                                            AND o.uaid       = z.area_id
                                            AND z.rec_type   = '4'
                                           )
        JOIN (
                SELECT DISTINCT state_code, zip_code, county_name, city_name, uaid
                FROM   osr_as_complete_plus_tmp
                WHERE  acceptable_city = 'N'
             ) cp ON (     o.state_code  = cp.state_code
                       AND o.zip_code    = cp.zip_code
                       AND o.county_name = cp.county_name
                       AND o.city_name   = cp.city_name
                       AND o.uaid        = cp.uaid
                     )
        JOIN vosr_extract_basic b ON (o.state_code = b.state_code
                                      AND o.zip_code = b.zip_code
                                     );