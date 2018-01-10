CREATE MATERIALIZED VIEW content_repo.mv_ref_group_revisions1 ("ID",nkid,entered_by,entered_date,status,status_modified_date,next_rid,summ_ass_status)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS select a.id, a.nkid, a.entered_by, a.entered_date, a.status, a.status_modified_date, a.next_rid, a.summ_ass_status
 from ref_group_revisions a join tdr_reference_group_extract b on ( a.nkid = b.nkid and a.id = b.id);