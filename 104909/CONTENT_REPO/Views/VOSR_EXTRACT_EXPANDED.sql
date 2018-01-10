CREATE OR REPLACE FORCE VIEW content_repo.vosr_extract_expanded (zip_code,state_code,county_name,city_name,state_sales_tax,state_use_tax,county_sales_tax,county_use_tax,city_sales_tax,city_use_tax,mta_sales_tax,mta_use_tax,spd_sales_tax,spd_use_tax,other1_sales_tax,other1_use_tax,other2_sales_tax,other2_use_tax,other3_sales_tax,other3_use_tax,other4_sales_tax,other4_use_tax,total_sales_tax,total_use_tax,county_number,city_number,mta_name,mta_number,spd_name,spd_number,other1_name,other1_number,other2_name,other2_number,other3_name,other3_number,other4_name,other4_number,tax_shipping_alone,tax_shipping_and_handling) AS
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
         WHERE  o.city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities - crapp-3416
                AND o.default_flag = 'Y'
                AND (NOT REGEXP_LIKE(o.city_name, '[0-9]') AND o.city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
                --AND o.acceptable_city = 'N'   -- crapp-3416, removed
         ORDER BY o.state_code, o.zip_code, o.county_name, o.city_name
 )
 WHERE acpt_rnk = 1;