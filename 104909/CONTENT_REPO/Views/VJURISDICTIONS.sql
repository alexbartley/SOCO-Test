CREATE OR REPLACE FORCE VIEW content_repo.vjurisdictions ("ID",nkid,rid,next_rid,juris_entity_rid,juris_next_rid,official_name,description,location_category_id,location_category,currency,currency_id,start_date,end_date,status,status_modified_date,entered_by,entered_date,default_admin_id,default_admin_name,default_admin_collects_tax,jurisdiction_type,jurisdiction_type_id) AS
SELECT j.id,
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
          a.collects_tax default_admin_collects_tax,
          jt.name jurisdiction_type,
          jt.id jurisdiction_type_id
     FROM jurisdiction_revisions r
          JOIN jurisdictions j
             ON (    r.nkid = j.nkid
                 AND r.id >= j.rid
                 AND r.id < NVL (j.next_rid, 999999999))
          JOIN geo_area_categories lc
             ON (lc.id = j.geo_area_category_id)
          JOIN currencies c
             ON (c.id = j.currency_id)
          LEFT OUTER JOIN administrators a
             ON (j.default_admin_id = a.id)
          LEFT OUTER JOIN jurisdiction_types jt
             ON (j.jurisdiction_type_nkid = jt.nkid and jt.next_rid is null);