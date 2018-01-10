CREATE MATERIALIZED VIEW content_repo.mv_pull_juris_prod (r_rowid,jt_rowid,nkid,"ID",tag_id,status_modified_date) 
TABLESPACE content_repo
REFRESH FAST 
AS SELECT r.ROWID r_rowid,
           jt.ROWID jt_rowid,
           r.nkid,
           r.id,
           jt.tag_id,
           r.status_modified_date
      FROM jurisdiction_revisions r, jurisdiction_tags jt
     WHERE r.nkid = jt.ref_nkid
       AND r.status = 2;