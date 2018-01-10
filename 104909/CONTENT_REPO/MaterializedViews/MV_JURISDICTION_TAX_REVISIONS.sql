CREATE MATERIALIZED VIEW content_repo.mv_jurisdiction_tax_revisions ("ID",nkid,entered_by,entered_date,status,status_modified_date,next_rid,summ_ass_status)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS select a.id, a.nkid, a.entered_by, a.entered_date, a.status, a.status_modified_date, a.next_rid, a.summ_ass_status
 from jurisdiction_tax_revisions a, tdr_etl_extract_list b 
where a.nkid = b.nkid and a.id <= b.rid;