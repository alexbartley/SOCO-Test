CREATE MATERIALIZED VIEW content_repo.mv_administrators ("ID",rid,"NAME",start_date,end_date,requires_registration,collects_tax,notes,entered_by,entered_date,nkid,next_rid,description,administrator_type_id,status,status_modified_date) 
TABLESPACE content_repo
LOB (notes) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
AS SELECT a.*
      FROM administrators a, 
          ( select nkid, max(id) id from mv_administrator_revisions group by nkid) b
where a.nkid = b.nkid and a.rid <= b.id;