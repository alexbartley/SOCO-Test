CREATE OR REPLACE FORCE VIEW sbxtax.v_pvw_tb_rates (result_type,authority,rate_code,start_date,end_date,rate,split_type,split_amount_type,flat_fee,description,is_local,tier_amount_low,tier_amount_high,tier_rate,tier_rate_code,tier_flat_fee) AS
select case when r.rate_id is null then 'add' else 'update' end result_type, a.name, r.rate_code, r.start_date, r.end_Date, r.rate, st.description split_type, sat.description split_amount_type, r.flat_fee, r.description, r.is_local, rt.amount_low, rt.amount_high, rt.rate, rt.ref_rate_code, rt.flat_fee
from pvw_tb_rates r
left outer join pvw_tb_rate_tiers rt on (rt.rate_code = r.rate_code and rt.authority_uuid = r.authority_uuid and rt.is_local = r.is_local and r.start_date = rt.start_date)
left outer join tb_lookups st on (st.code_group = 'SPLIT_TYPE' and st.code = nvl(r.split_type,'x'))
left outer join tb_lookups sat on (sat.code_group = 'SPLIT_AMT_TYPE' and sat.code = nvl(r.split_amount_type,'x'))
join (
    select name, authority_uuid uuid
    from tmp_tb_authorities
    union
    select name, uuid
    from tb_authorities
    ) a on (a.uuid = r.authority_uuid)
 
 ;