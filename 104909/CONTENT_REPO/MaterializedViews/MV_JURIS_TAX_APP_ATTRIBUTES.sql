CREATE MATERIALIZED VIEW content_repo.mv_juris_tax_app_attributes ("ID",juris_tax_applicability_id,attribute_id,"VALUE",start_date,end_date,entered_by,entered_date,status,status_modified_date,rid,nkid,next_rid,juris_tax_applicability_nkid) 
TABLESPACE content_repo
LOB ("VALUE") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
AS select jtaa.* from   ( select distinct nkid, max(id) id from mv_juris_tax_app_revisions group by nkid )jtr JOIN juris_tax_app_attributes jtaa
  on jtr.nkid = jtaa.juris_tax_applicability_nkid
  and jtaa.rid <= jtr.id;