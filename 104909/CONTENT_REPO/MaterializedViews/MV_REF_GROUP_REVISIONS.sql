CREATE MATERIALIZED VIEW content_repo.mv_ref_group_revisions ("ID",nkid,entered_by,entered_date,status,status_modified_date,next_rid,summ_ass_status)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS SELECT a.id, a.nkid, a.entered_by, a.entered_date, a.status, a.status_modified_date, a.next_rid, a.summ_ass_status
      FROM ref_group_revisions a
           JOIN tdr_etl_extract_list b
               ON     a.nkid = b.nkid
                  AND a.id = b.rid
                  AND b.entity = 'REFERENCE_GROUPS';