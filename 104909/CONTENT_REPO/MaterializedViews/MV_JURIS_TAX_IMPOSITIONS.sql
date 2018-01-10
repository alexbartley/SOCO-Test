CREATE MATERIALIZED VIEW content_repo.mv_juris_tax_impositions ("ID",jurisdiction_id,tax_description_id,reference_code,start_date,end_date,entered_by,entered_date,rid,nkid,next_rid,status,status_modified_date,description,revenue_purpose_id,jurisdiction_nkid,a_rowid,b_rowid)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS select a.*, a.rowid a_rowid, b.rowid b_rowid from juris_tax_impositions a, tdr_etl_extract_list b 
where a.nkid = b.nkid and a.rid <= b.rid;