CREATE OR REPLACE FORCE VIEW content_repo.vosr_extract_complete_plus (zip_code,state_code,county_name,city_name,state_sales_tax,state_use_tax,county_sales_tax,county_use_tax,city_sales_tax,city_use_tax,mta_sales_tax,mta_use_tax,spd_sales_tax,spd_use_tax,other1_sales_tax,other1_use_tax,other2_sales_tax,other2_use_tax,other3_sales_tax,other3_use_tax,other4_sales_tax,other4_use_tax,total_sales_tax,total_use_tax,county_number,city_number,mta_name,mta_number,spd_name,spd_number,other1_name,other1_number,other2_name,other2_number,other3_name,other3_number,other4_name,other4_number,tax_shipping_alone,tax_shipping_and_handling,fips_state,fips_county,fips_city,geocode,mta_geocode,spd_geocode,other1_geocode,other2_geocode,other3_geocode,other4_geocode,geocode_long,state_effective_date,county_effective_date,city_effective_date,mta_effective_date,spd_effective_date,other1_effective_date,other2_effective_date,other3_effective_date,other4_effective_date,county_tax_collected_by,city_tax_collected_by,state_taxable_max,state_tax_over_max,county_taxable_max,county_tax_over_max,city_taxable_max,city_tax_over_max,sales_tax_holiday,sales_tax_holiday_dates,sales_tax_holiday_items) AS
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
        ,sales_tax_holiday_items;