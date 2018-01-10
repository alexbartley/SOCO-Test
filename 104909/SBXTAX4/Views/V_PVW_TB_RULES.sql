CREATE OR REPLACE FORCE VIEW sbxtax4.v_pvw_tb_rules (authority,uuid,product,prodcode,rule_order,rate_code,"EXEMPT",no_tax,input_recovery_percent,basis_percent,start_date,end_date,code,tax_type,calc_method,invoice_description,is_local,"ELEMENT","VALUE",rq_start_date,rq_end_date,"OPERATOR",reference_list_name,rq_authority,rq_authority_uuid,rule_qualifier_type) AS
select distinct a.name, a.uuid, pc.name product, pc.prodcode, r.rule_order, r.rate_code, r.exempt, r.no_tax, r.input_recovery_percent, r.basis_percent, r.start_date, r.end_Date,
    r.code, r.tax_type, cm.description calc_method, r.invoice_description, r.is_local, q.element, q.value, RQ_START_DATE, RQ_END_DATE, q.operator,
    q.reference_list_name, RQ_AUTHORITY, RQ_AUTHORITY_UUID, q.rule_qualifier_type
from pvw_tb_rules r
left outer join tb_product_categories pc on (pc.product_category_id = nvl(r.product_category_id,-1))
left outer join tb_lookups cm on (cm.code_group = 'TBI_CALC_METH' and cm.code = r.calculation_method)
left outer join v_pvw_tb_rule_quals q on (q.rule_order = r.rule_order and r.authority_uuid = q.UUID)
join (
    select name, authority_uuid uuid
    from tmp_tb_authorities
    union
    select name, uuid
    from tb_authorities
    ) a on (a.uuid = r.authority_uuid)
order by a.name, r.rate_code, prodcode, r.rule_order
 
 ;