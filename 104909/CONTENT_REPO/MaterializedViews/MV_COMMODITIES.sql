CREATE MATERIALIZED VIEW content_repo.mv_commodities ("ID","NAME",description,commodity_code,entered_by,entered_date,rid,nkid,next_rid,status,status_modified_date,product_tree_id,start_date,end_date,h_code) 
TABLESPACE content_repo
AS select distinct a.* from commodities a , 
( select nkid, max(id) id from mv_commodity_revisions group by nkid) b
where a.nkid = b.nkid and a.rid <= b.id;