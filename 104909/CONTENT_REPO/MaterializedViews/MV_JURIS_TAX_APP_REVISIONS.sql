CREATE MATERIALIZED VIEW content_repo.mv_juris_tax_app_revisions ("ID",nkid,entered_by,entered_date,status,status_modified_date,next_rid,summ_ass_status)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS select distinct jtr.id, jtr.nkid, jtr.entered_by, jtr.entered_date, jtr.status, jtr.status_modified_date, jtr.next_rid, jtr.summ_ass_status
 from juris_tax_app_revisions jtr, tdr_etl_extract_list tel
where jtr.nkid = tel.nkid 
  and jtr.id <= tel.rid;