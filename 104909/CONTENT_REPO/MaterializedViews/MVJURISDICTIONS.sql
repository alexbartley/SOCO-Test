CREATE MATERIALIZED VIEW content_repo.mvjurisdictions ("ID",nkid,rid,next_rid,juris_entity_rid,juris_next_rid,official_name,description,location_category_id,location_category,currency,currency_id,start_date,end_date,status,status_modified_date,entered_by,entered_date,default_admin_id,default_admin_name,default_admin_collects_tax)
ORGANIZATION HEAP  
TABLESPACE content_repo
AS SELECT j.id,
           j.nkid,
           j.rid rid,
           j.next_rid,
           r.id juris_entity_rid,
           r.next_rid,
           j.official_name,
           j.description,
           lc.id,
           lc.name location_category,
           c.currency_code,
           c.id currency_id,
           TO_CHAR (j.start_date, 'mm/dd/yyyy') start_date,
           TO_CHAR (j.end_date, 'mm/dd/yyyy') end_date,
           j.status,
           j.status_modified_date,
           j.entered_by,
           j.entered_date,
           j.default_admin_id,
           a.name default_admin_name,
           a.collects_tax default_admin_collects_tax
      FROM jurisdiction_revisions r,
           jurisdictions j,
           geo_area_categories lc,
           currencies c,
           administrators a,
           tdr_etl_extract_list tel
     WHERE     (    r.nkid = j.nkid
                AND r.id >= j.rid
                AND r.id < NVL (j.next_rid, 999999999))
           AND lc.id = j.geo_area_category_id
           AND c.id = j.currency_id
           AND j.default_admin_id = a.id(+)
           AND tel.nkid = r.nkid 
           AND tel.rid = r.id
           AND tel.entity = 'JURISDICTION';