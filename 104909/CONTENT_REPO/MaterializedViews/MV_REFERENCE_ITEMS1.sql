CREATE MATERIALIZED VIEW content_repo.mv_reference_items1 ("ID","VALUE",description,value_type,ref_nkid,entered_by,status,entered_date,status_modified_date,reference_group_id,rid,next_rid,nkid,start_date,end_date,reference_group_nkid) 
TABLESPACE content_repo
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
AS SELECT a.*
      FROM reference_items a, 
          ( select nkid, max(id) id from mv_ref_group_revisions1 group by nkid) b
where a.reference_group_nkid = b.nkid and a.rid <= b.id;