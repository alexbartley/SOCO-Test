CREATE MATERIALIZED VIEW content_repo.mv_reference_groups1 ("ID","NAME",status_modified_date,status,entered_by,entered_date,rid,next_rid,nkid,start_date,end_date,description) 
TABLESPACE content_repo
AS SELECT a.*
      FROM reference_groups a, 
          ( select nkid, max(id) id from mv_ref_group_revisions1 group by nkid) b
where a.nkid = b.nkid and a.rid <= b.id;