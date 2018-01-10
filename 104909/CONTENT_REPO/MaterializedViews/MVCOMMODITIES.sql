CREATE MATERIALIZED VIEW content_repo.mvcommodities ("NAME","ID",rid,nkid,commodity_rid,next_rid,description,commodity_code,product_tree_id,product_tree_short_name,h_code,start_date,end_date,status,status_modified_date,entered_by,entered_date) 
TABLESPACE content_repo
AS SELECT c.name,
          c.id,
          c.rid,
          c.nkid,
          r.id,
          r.next_rid,
          c.description,
          c.commodity_code,
          c.product_tree_id,
          pt.short_name product_tree_short_name,
          c.h_code,
          TO_CHAR (c.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (c.end_date, 'mm/dd/yyyy') end_date,
          c.status,
          c.status_modified_date,
          c.entered_by,
          c.entered_date
     FROM MV_commodity_revisions r
          JOIN MV_commodities c
             ON (    r.nkid = c.nkid
                 AND r.id >= c.rid
                 AND r.id < NVL (c.next_rid, 999999999))
          JOIN product_trees pt
             ON (c.product_tree_id = pt.id);