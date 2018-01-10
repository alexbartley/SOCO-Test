CREATE MATERIALIZED VIEW content_repo.mv_juris_tax_applicabilities ("ID",reference_code,calculation_method_id,basis_percent,recoverable_percent,start_date,end_date,entered_by,entered_date,status,status_modified_date,rid,nkid,next_rid,jurisdiction_id,jurisdiction_nkid,all_taxes_apply,recoverable_amount,applicability_type_id,unit_of_measure,ref_rule_order,default_taxability,product_tree_id,commodity_id,tax_type,is_local,"EXEMPT",no_tax,commodity_nkid,charge_type_id) 
TABLESPACE content_repo
AS select jta.* from ( select distinct nkid, max(id) id from mv_juris_tax_app_revisions group by nkid )jtr, juris_tax_applicabilities jta
where jtr.nkid = jta.nkid 
  and jta.rid <= jtr.id;