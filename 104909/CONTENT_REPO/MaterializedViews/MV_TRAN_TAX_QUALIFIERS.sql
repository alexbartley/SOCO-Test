CREATE MATERIALIZED VIEW content_repo.mv_tran_tax_qualifiers ("ID",juris_tax_applicability_id,taxability_element_id,logical_qualifier,"VALUE",element_qual_group,start_date,end_date,entered_by,entered_date,status,status_modified_date,rid,nkid,next_rid,jurisdiction_id,reference_group_id,qualifier_type,juris_tax_applicability_nkid,reference_group_nkid,jurisdiction_nkid) 
TABLESPACE content_repo
AS select ttq.* from ( select distinct nkid, max(id) id from mv_juris_tax_app_revisions group by nkid )jtr , mv_juris_tax_applicabilities jta, tran_tax_qualifiers ttq
where jtr.nkid = jta.nkid
  and jta.nkid = ttq.juris_tax_applicability_nkid 
  and ttq.rid <= jtr.id;