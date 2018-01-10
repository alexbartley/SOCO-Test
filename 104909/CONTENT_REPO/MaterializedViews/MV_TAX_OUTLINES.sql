CREATE MATERIALIZED VIEW content_repo.mv_tax_outlines ("ID",juris_tax_imposition_id,calculation_structure_id,start_date,end_date,entered_by,status,entered_date,status_modified_date,nkid,rid,next_rid,juris_tax_imposition_nkid)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS select a.* from tax_outlines a, tdr_etl_extract_list b 
where a.juris_tax_imposition_nkid = b.nkid and a.rid <= b.rid;