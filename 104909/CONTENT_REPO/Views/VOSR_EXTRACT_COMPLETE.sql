CREATE OR REPLACE FORCE VIEW content_repo.vosr_extract_complete (zip_code,state_code,county_name,city_name,state_sales_tax,state_use_tax,county_sales_tax,county_use_tax,city_sales_tax,city_use_tax,mta_sales_tax,mta_use_tax,spd_sales_tax,spd_use_tax,other1_sales_tax,other1_use_tax,other2_sales_tax,other2_use_tax,other3_sales_tax,other3_use_tax,other4_sales_tax,other4_use_tax,total_sales_tax,total_use_tax,county_number,city_number,mta_name,mta_number,spd_name,spd_number,other1_name,other1_number,other2_name,other2_number,other3_name,other3_number,other4_name,other4_number,tax_shipping_alone,tax_shipping_and_handling) AS
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
 WHERE  city_name <> 'UNINCORPORATED'   -- Exclude records that are in Unincorporated cities
        AND (NOT REGEXP_LIKE(city_name, '[0-9]') AND city_name NOT LIKE '%(%)') -- crapp-3370, exclude cities with (1..n) in the name
;