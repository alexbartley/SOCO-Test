CREATE OR REPLACE PROCEDURE sbxtax4."RATE_EXTRACT" (filename IN varchar2, extract_date IN varchar2, state varchar2) is

ftype utl_file.file_type;
begin
ftype := utl_file.fopen('C:\TEMP', filename, 'W');
utl_file.put_line(ftype, '"Country","State_Province","County","City","ZipCode","GeoCode","Description","Rate_Code","Has_Tiers","Fee","Rate","Start_Date","Will_Change"');

for c in (

select '"'||Country||'","'||State_Province||'","'||County||'","'||City||'","'||ZipCode||'","'||GeoCode||'","'||Description||'","'||Rate_Code||'","'||Has_Tiers||'","'||Fee||'","'||
   Rate||'","'||to_char(Start_date,'MM/DD/YYYY')||'","'||will_change||'"' line
from (
select /* +index (za CT_ZONE_AUTH_PK) */ 'UNITED STATES' Country, full_address.zone_3_name State_Province, full_address.zone_4_name County, full_address.zone_5_name City, full_address.zone_6_name ZipCode, full_address.zone_7_name GeoCode,
    rate.description, rate.rate_Code,
    case when rate.split_Amount_type is not null then 'Y' else 'N' end has_tiers,
    case when nvl(rate.flat_fee,0) > 0 then sum(rate.rate) else 0 end fee,
    case when nvl(rate.flat_fee,0) = 0 then sum(rate.rate) else 0 end  rate,
    max(rate.start_Date) start_Date,
    case when new_rate.rate_id is not null then 'Y' else 'N' end will_change
from ct_zone_tree full_address
join ct_Zone_authorities za on (
    za.primary_key = nvl(full_address.zone_7_id ,-1)
    or za.primary_key = full_address.zone_6_id
    or za.primary_key = full_address.zone_5_id
    or za.primary_key = full_address.zone_4_id
    or za.primary_key = full_address.zone_3_id
    )
join tb_authorities auth on (auth.name = za.authority_name and auth.merchant_id = za.merchant_id)
join tb_rates rate on (rate.authority_id = auth.authority_id)
join tb_merchants m on (m.merchant_id = rate.merchant_id)
left outer join tb_rates new_rate on (
    rate.authority_id = new_rate.authority_id
    and rate.rate_Code = new_rate.rate_code
    and rate.rate_id != new_rate.rate_id
    and rate.start_Date > extract_date)
where m.name = 'Sabrix US Tax Data'
and full_address.zone_3_name = state
and full_address.zone_6_id is not null
and coalesce(rate.is_local,'N') = 'N'
and rate.start_date <= extract_date
and (rate.end_date is null or rate.end_date >= extract_date)
and rate.rate_code != 'NL'
and rate.rate_code not like 'TH%'
and nvl(full_address.reverse_flag,'N') = 'N'
and nvl(za.reverse_flag,'N') = 'N'
group by full_address.zone_3_name, full_address.zone_4_name, full_address.zone_5_name, full_address.zone_6_name, full_address.zone_7_name,
    rate.description, rate.rate_Code, case when rate.split_Amount_type is not null then 'Y' else 'N' end, nvl(rate.flat_fee,0), case when new_rate.rate_id is not null then 'Y' else 'N' end
UNION ALL
select /* +index (za CT_ZONE_AUTH_PK) */ 'UNITED STATES' Country, full_address.zone_3_name State_Province, full_address.zone_4_name County, full_address.zone_5_name City, full_address.zone_6_name ZipCode, full_address.zone_7_name GeoCode,
    rate.description, rate.rate_Code,
    case when rate.split_Amount_type is not null then 'Y' else 'N' end has_tiers,
    case when nvl(rate.flat_fee,0) > 0 then sum(rate.rate) else 0 end fee,
    case when nvl(rate.flat_fee,0) = 0 then sum(rate.rate) else 0 end  rate,
    max(rate.start_Date) start_Date,
    case when new_rate.rate_id is not null then 'Y' else 'N' end will_change
from ct_zone_tree full_address
join ct_Zone_authorities za on (
    za.primary_key = nvl(full_address.zone_7_id ,-1)
    or za.primary_key = full_address.zone_6_id
    or za.primary_key = full_address.zone_5_id
    or za.primary_key = full_address.zone_4_id
    or za.primary_key = full_address.zone_3_id
    )
join tb_authorities auth on (auth.name = za.authority_name and auth.merchant_id = za.merchant_id)
join tb_rates rate on (rate.authority_id = auth.authority_id)
join tb_merchants m on (m.merchant_id = rate.merchant_id)
left outer join tb_rates new_rate on (
    rate.authority_id = new_rate.authority_id
    and rate.rate_Code = new_rate.rate_code
    and rate.rate_id != new_rate.rate_id
    and rate.start_Date > extract_date)
where m.name = 'Sabrix US Tax Data'
and full_address.zone_3_name = state
and full_address.zone_6_id is not null
and coalesce(rate.is_local,'N') = 'N'
and rate.start_date <= extract_date
and (rate.end_date is null or rate.end_date >= extract_date)
and rate.rate_code != 'NL'
and rate.rate_code not like 'TH%'
and nvl(full_address.reverse_flag,'N') = 'Y'
and nvl(za.reverse_flag,'N') = 'Y'
group by full_address.zone_3_name, full_address.zone_4_name, full_address.zone_5_name, full_address.zone_6_name, full_address.zone_7_name,
    rate.description, rate.rate_Code, case when rate.split_Amount_type is not null then 'Y' else 'N' end, nvl(rate.flat_fee,0), case when new_rate.rate_id is not null then 'Y' else 'N' end
)

) loop
utl_file.put_line(ftype, c.line);
end loop;
utl_file.fflush(ftype);
utl_file.fclose(ftype);
end;


 
 
 
/