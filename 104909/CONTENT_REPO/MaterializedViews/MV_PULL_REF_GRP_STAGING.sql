CREATE MATERIALIZED VIEW content_repo.mv_pull_ref_grp_staging (r_rowid,jt_rowid,nkid,"ID",tag_id,status_modified_date)
ORGANIZATION HEAP  
TABLESPACE content_repo
REFRESH FAST 
AS SELECT r.ROWID r_rowid,
           jt.ROWID jt_rowid,
           r.nkid,
           r.id,
           jt.tag_id,
           r.status_modified_date
      FROM ref_group_revisions r, ref_group_tags jt
     WHERE r.nkid = jt.ref_nkid
       AND r.ready_for_staging = 1;