CREATE OR REPLACE PROCEDURE sbxtax4."CT_ANALYZE_COMBINED_RATES" (taxDataProvider IN VARCHAR2, effectiveDate IN VARCHAR)
   IS
    rateDate DATE := sysdate;
BEGIN
    IF effectiveDate IS NOT NULL THEN
        rateDate := to_date(effectiveDate, 'dd-MON-YYYY');
    END IF;
    delete from ct_combined_rates;
    commit;
    delete from ct_combined_rates_td;
    commit;
    delete from ct_combined_rates_bu;
    commit;
    insert into ct_combined_rates_td (state, county, city, zip, state_authority, state_rate,
        county_authority, county_rate, city_authority, city_rate, zip_authority, zip_rate) (
    select distinct za.zone_3_name, countyz.name zone_4_name,cityz.name zone_5_name,zipz.name zone_6_name,
        state_rate.authority_id state_auth, state_rate.rate state_rate,
        county_rate.authority_id county_auth, county_rate.rate county_rate,
        city_rate.authority_id city_auth, city_Rate.rate city_Rate,
        zip_rate.authority_id zip_auth, zip_rate.rate zip_rate
    from ct_zone_tree zt
    left outer join ct_zone_authorities za ON (zt.primary_key = za.primary_key)
    join tb_authorities a on (za.authority_name = a.name and za.merchant_id = a.merchant_id
    and a.name not in ('TN - OUT-OF-STATE LOCAL OPTION SALES/USE TAX (SERVICES)',
                       'AL - OUT-OF-STATE SIMPLIFIED SELLERS USE TAX'
                      )
    )
    join tb_rates state_rate on (
        state_rate.authority_id = a.authority_id
         and a.merchant_id = state_rate.merchant_id
        and state_rate.start_date <= rateDate
        and NVL(state_rate.end_Date,'31-Dec-9999') >= rateDate
         and state_rate.rate_code = 'ST'
         and NVL(state_rate.is_local,'N') = 'N'
         and state_rate.split_Amount_type is null)
    join tb_zones countyz ON (countyz.parent_zone_id = za.primary_key  and NVL(countyz.reverse_flag,'N') = 'N')
    left outer join tb_zone_authorities county ON (county.zone_id = countyz.zone_id)
    left outer join tb_rates county_rate ON (
        county_rate.authority_id = county.authority_id
       and county_rate.start_date <= rateDate
        and NVL(county_rate.end_Date,'31-Dec-9999') >=rateDate
        and county_rate.rate_code = 'ST'
        and NVL(county_rate.is_local,'N') = 'N'
        and county_rate.split_Amount_type is null)
    join tb_zones cityz ON (cityz.parent_zone_id = countyz.zone_id  and NVL(cityz.reverse_flag,'N') = 'N')
    left outer join tb_zone_authorities city ON (city.zone_id = cityz.zone_id)
    left outer join tb_rates city_rate ON (
        city_rate.authority_id = city.authority_id
        and city_rate.start_date <= rateDate
        and NVL(city_rate.end_Date,'31-Dec-9999') >= rateDate
        and city_rate.rate_code = 'ST'
        and NVL(city_rate.is_local,'N') = 'N'
        and city_rate.split_Amount_type is null)
    join tb_zones zipz ON (zipz.parent_zone_id = cityz.zone_id  and NVL(zipz.reverse_flag,'N') = 'N')
    left outer join tb_zone_authorities zip ON (zip.zone_id = zipz.zone_id)
    left outer join tb_rates zip_rate ON (
        zip_rate.authority_id = zip.authority_id
        and zip_rate.start_date <= rateDate
        and NVL(zip_rate.end_Date,'31-Dec-9999') >= rateDate
        and zip_rate.rate_code = 'ST'
        and NVL(zip_rate.is_local,'N') = 'N'
        and zip_rate.split_Amount_type is null)
    where za.zone_3_name is not null
    and za.zone_4_name is null
    and NVL(za.reverse_flag,'N') = 'N'
    and za.authority_name is not null
    AND exists (
        select 1
        from tb_merchants
        where name = taxDataProvider
        and merchant_id = zt.merchant_id)
    );
    commit;

    insert into ct_combined_rates_bu (state, county, city, zip, plus4, rate) (
    select zone_3_name, zone_4_name,zone_5_name,zone_6_name, zone_7_name, sum(r.rate) rate
    from ct_zone_authorities za
    join tb_authorities a on (a.name = za.authority_name
    and a.name not in ('TN - OUT-OF-STATE LOCAL OPTION SALES/USE TAX (SERVICES)',
                       'AL - OUT-OF-STATE SIMPLIFIED SELLERS USE TAX'
                      )
    )
    join tb_rates r on (
        r.authority_id = a.authority_id
        and r.start_date <= rateDate
        and NVL(r.end_Date,'31-Dec-9999') >= rateDate
        and r.rate_code = 'ST'
        and r.split_Amount_type is null)
    where za.zone_6_name is not null
    and NVL(r.is_local,'N') = 'N'
    and NVL(za.reverse_flag,'N') = 'Y'
    and NVL(za.terminator_flag,'N') = 'Y'
    AND exists (
        select 1
        from tb_merchants
        where name = taxDataProvider
        and merchant_id = za.merchant_id)
    group by zone_3_name, zone_4_name,zone_5_name,zone_6_name,zone_7_name
    );
    commit;

    insert into ct_combined_rates (state, county, city, zip, plus4, rate) (
    select state, county, city, zip, zone_7_name, rate
    from (
        select state, county, city, zip, null zone_7_name,
            sum(NVL(state_rate,0)) over (partition by state_authority, county_authority, city_authority, zip_authority, state, county, city, zip)+
            sum(NVL(county_rate,0)) over (partition by state_authority, city_authority, zip_authority, state, county, city, zip)+
            sum(NVL(city_rate,0)) over (partition by state_authority, county_authority, zip_authority, state, county, city, zip)+
            sum(NVL(zip_rate,0)) over (partition by state_authority, county_authority, city_authority, state, county, city, zip) rate
        from ct_combined_rates_td
        union
        select distinct state, county, city, zip, plus4, rate
        from ct_combined_rates_bu
        where plus4 is null
    )
    );
    commit;

END; -- Procedure





 
/