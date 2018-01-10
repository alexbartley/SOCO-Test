CREATE MATERIALIZED VIEW content_repo.mv_reference_groups ("ID","NAME",status_modified_date,status,entered_by,entered_date,rid,next_rid,nkid,start_date,end_date,description)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS SELECT a.*
      FROM reference_groups a
           JOIN tdr_etl_extract_list b
               ON     a.nkid = b.nkid
                  AND a.rid <= b.rid
                  AND b.entity = 'REFERENCE_GROUPS';