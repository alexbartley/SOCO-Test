CREATE OR REPLACE FORCE VIEW sbxtax2.datax_tb_rules_vw (data_check_id,reviewed_approved,verified,record_key,authority_name,rule_orer,start_date,end_date,rate_code,"EXEMPT",no_tax,invoice_description,rule_comment,input_recovery_percent,calculation_method,tax_type,basis_percent,exempt_reason_code,tax_code,product_name,product_commodity_code,last_update_date,primary_key) AS
SELECT c.data_Check_id, o.reviewed_Approved||' '||to_char(o.approved_date,'DD-Mon-yyyy') reviewed_Approved, o.verified||' '||to_char(o.verified_date,'DD-Mon-yyyy'), 'AuthorityName='||a.name||'| RuleOrder='||r.rule_order||'| StartDate='||to_char(r.start_Date,'MM/DD/YYYY')||'| ProductName='||pc.name||'| IsCascading='||NVL(r.is_local,'N') record_key,  a.name authority_name, rule_order, start_date, end_date, rate_code, exempt, no_tax, r.invoice_description, rule_comment, input_recovery_percent,
lc.description calculation_method, lt.description tax_type, basis_percent, exempt_reason_code, r.code tax_code, pc.name product_name, pc.prodcode product_commodity_Code, r.last_update_date, primary_key
FROM tb_authorities a
JOIN tb_rules r ON (a.authority_id = r.authority_id)
JOIN tb_lookups lc ON (lc.code = r.calculation_method AND lc.code_Group = 'TBI_CALC_METH')
LEFT OUTER JOIN tb_lookups lt ON (lt.code = r.tax_type AND lt.code_Group = 'US_TAX_TYPE')
LEFT OUTER JOIN tb_product_Categories pc ON (pc.product_category_id = NVL(r.product_category_id,-222222))
JOIN datax_check_output o ON (o.primary_key = r.rule_id)
JOIN datax_checks c ON (o.data_check_id = c.data_Check_id)
WHERE c.data_owner_table = 'TB_RULES'
ORDER BY NVL(o.reviewed_approved,'0');