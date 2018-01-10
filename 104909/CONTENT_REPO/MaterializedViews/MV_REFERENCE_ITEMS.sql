CREATE MATERIALIZED VIEW content_repo.mv_reference_items ("ID","VALUE",description,value_type,ref_nkid,entered_by,status,entered_date,status_modified_date,reference_group_id,rid,next_rid,nkid,start_date,end_date,reference_group_nkid)
ORGANIZATION HEAP  
TABLESPACE content_repo
LOB (description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
AS SELECT a.*
      FROM reference_items a
           JOIN mv_reference_groups b ON a.reference_group_nkid = b.nkid
           JOIN tdr_etl_extract_list c
               ON     b.nkid = c.nkid
                  AND a.rid <= c.rid
                  AND c.entity = 'REFERENCE_GROUPS';