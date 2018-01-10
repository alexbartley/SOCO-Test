CREATE OR REPLACE FORCE VIEW content_repo.jurisdictions_v ("ID",nkid,rid,next_rid,juris_entity_rid,juris_next_rid,official_name,description,location_category_id,location_category,currency,currency_id,start_date,end_date,status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT j.id,
       j.nkid,
       j.rid rid,
       j.next_rid,
       s.entity_rid,
       s.entity_next_rid,
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
       is_current(j.rid,s.entity_next_rid,j.next_rid) is_current
  FROM juris_id_sets s
       JOIN jurisdictions j
          ON ( s.id = j.id)
       JOIN geo_area_categories lc
          ON (lc.id = j.geo_area_category_id)
       JOIN currencies c
          ON (c.id = j.currency_id)
 
 
 ;