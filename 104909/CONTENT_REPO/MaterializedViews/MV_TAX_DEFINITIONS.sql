CREATE MATERIALIZED VIEW content_repo.mv_tax_definitions ("ID",rid,min_threshold,max_limit,value_type,"VALUE",defer_to_juris_tax_id,currency_id,entered_by,entered_date,nkid,next_rid,status,status_modified_date,tax_outline_id,defer_to_juris_tax_nkid,tax_outline_nkid)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS select td.* from tdr_etl_extract_list b join juris_tax_impositions jti on b.nkid = jti.nkid 
join tax_outlines tou on jti.nkid = tou.juris_tax_imposition_nkid
join tax_definitions td on td.tax_outline_nkid = tou.nkid
where td.rid <= b.rid;