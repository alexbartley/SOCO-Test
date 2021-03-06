CREATE MATERIALIZED VIEW content_repo.mv_pull_comm_prod (r_rowid,jt_rowid,c_rowid,nkid,"ID",tag_id,status_modified_date) 
TABLESPACE content_repo
REFRESH FAST 
AS SELECT r.ROWID r_rowid,
           jt.ROWID jt_rowid,
           c.rowid c_rowid,
           r.nkid,
           r.id,
           jt.tag_id,
           r.status_modified_date
      FROM commodity_revisions r, commodity_tags jt, commodities c 
     WHERE r.nkid = jt.ref_nkid
       AND c.nkid = r.nkid
       AND c.product_tree_id = 13
       AND r.status = 2;