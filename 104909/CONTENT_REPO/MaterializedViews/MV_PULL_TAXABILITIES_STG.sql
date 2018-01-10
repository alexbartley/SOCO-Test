CREATE MATERIALIZED VIEW content_repo.mv_pull_taxabilities_stg (r_rowid,jt_rowid,nkid,"ID",tag_id,status_modified_date)
ORGANIZATION HEAP  
TABLESPACE content_repo
REFRESH FAST 
AS select r.rowid r_rowid, jt.rowid jt_rowid, r.nkid, r.id, jt.tag_id, r.status_modified_date 
  from juris_tax_app_revisions r, juris_tax_app_tags jt
 where r.nkid = jt.ref_nkid
   and r.ready_for_staging = 1;