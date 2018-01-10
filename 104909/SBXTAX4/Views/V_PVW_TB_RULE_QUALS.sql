CREATE OR REPLACE FORCE VIEW sbxtax4.v_pvw_tb_rule_quals (authority,uuid,rule_order,rate_code,"EXEMPT",no_tax,start_date,end_date,code,tax_type,is_local,"ELEMENT","VALUE",rq_start_date,rq_end_date,"OPERATOR",reference_list_name,rq_authority,rq_authority_uuid,rule_qualifier_type) AS
select a.name, a.uuid, r.rule_order, r.rate_code, r.exempt, r.no_tax, r.start_date, r.end_date, r.code, r.tax_type, r.is_local, q.element, q.value, q.start_date, q.end_date, q.operator, q.reference_list_name, qa.name, q.authority, q.rule_qualifier_type
from pvw_tb_rule_qualifiers q
join pvw_tb_rules r on (r.rule_order = q.rule_order and r.authority_uuid = q.rule_authority_uuid)
join (
    select name, authority_uuid uuid
    from tmp_tb_authorities a2
    where not exists (
        select 1
        from tb_authorities a
        where a.uuid = a2.authority_uuid
        )
    union
    select name, uuid
    from tb_authorities
    ) a on (a.uuid = r.authority_uuid)
left outer join (
    select name, authority_uuid uuid
    from tmp_tb_authorities a2
    where not exists (
        select 1
        from tb_authorities a
        where a.uuid = a2.authority_uuid
        )
    union
    select name, uuid
    from tb_authorities
    ) qa on (qa.uuid = q.authority)
 
 ;