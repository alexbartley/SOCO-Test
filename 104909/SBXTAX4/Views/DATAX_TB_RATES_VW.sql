CREATE OR REPLACE FORCE VIEW sbxtax4.datax_tb_rates_vw (data_check_id,reviewed_approved,verified,record_key,authority_name,rate_code,start_date,end_date,flat_fee,rate,split_type,split_amount_type,description,tier_low,tier_high,tier_rate,tier_rate_code,primary_key,approved_date) AS
SELECT c.data_check_id, o.reviewed_Approved||' '||to_char(o.approved_date,'DD-Mon-yyyy') reviewed_Approved, o.verified||' '||to_char(o.verified_date,'DD-Mon-yyyy'), 'AuthorityName='||a.name||'| RateCode='||r.rate_code||'| StartDate='||to_char(r.start_Date,'MM/DD/YYYY')||'| IsCascading='||NVL(r.is_local,'N') record_key, a.name authority_name, r.rate_code, r.start_Date, r.end_Date, r.flat_fee, r.rate, ls.description split_type, lsa.description split_amount_type, r.description,
    rt.amount_low, rt.amount_high, rt.rate, rt.rate_code, o.primary_key, o.approved_Date
FROM datax_check_output o
JOIN datax_checks c ON (o.data_check_id = c.data_Check_id AND c.data_owner_table = 'TB_RATES')
JOIN tb_rates r ON (o.primary_key = r.rate_id)
JOIN tb_authorities a ON (a.authority_id = r.authority_id)
LEFT OUTER JOIN tb_lookups ls ON (ls.code = NVL(r.split_type,'XXXX') AND ls.code_Group = 'SPLIT_TYPE')
LEFT OUTER JOIN tb_lookups lsa ON (lsa.code = NVL(r.split_amount_type,'XXXX') AND lsa.code_Group = 'SPLIT_AMT_TYPE')
LEFT OUTER JOIN tb_rate_tiers rt ON (rt.rate_id = r.rate_id)
ORDER BY NVL(o.approved_Date,'31-DEC-9999') DESC
 
 
 
 ;