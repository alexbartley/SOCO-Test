CREATE OR REPLACE FORCE VIEW content_repo.administrators_v ("ID",nkid,rid,next_rid,admin_rid,admin_next_rid,"NAME",description,requires_registration,collects_tax,administrator_type_id,administrator_type,start_date,end_date,status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT ad.id,
       ad.nkid,
       ad.rid,
       ad.next_rid,
       ais.entity_rid,
       ais.entity_next_rid,
       ad.name,
       ad.description,
       ad.requires_registration,
       ad.collects_tax,
       ad.administrator_type_id,
       aty.name,
       TO_CHAR(ad.start_date, 'mm/dd/yyyy') start_date,
       TO_CHAR(ad.end_date, 'mm/dd/yyyy') end_date,
       ad.status,
       ad.status_modified_date,
       ad.entered_by,
       ad.entered_date,
       is_current(ad.rid,ais.entity_next_rid,ad.next_rid) is_current
  FROM admin_id_sets ais
  join administrators ad on (ad.id = ais.id)
       JOIN administrator_types aty
          ON (aty.id = ad.administrator_type_id)
 
 
 ;