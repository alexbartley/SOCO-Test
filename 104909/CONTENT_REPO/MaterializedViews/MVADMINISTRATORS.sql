CREATE MATERIALIZED VIEW content_repo.mvadministrators ("ID",nkid,rid,next_rid,admin_rid,admin_next_rid,"NAME",description,requires_registration,collects_tax,administrator_type_id,administrator_type,start_date,end_date,status,status_modified_date,entered_by,entered_date) 
TABLESPACE content_repo
AS SELECT ad.id,
       ad.nkid,
       ad.rid,
       ad.next_rid,
       r.id,
       r.next_rid,
       ad.name,
       ad.description,
       ad.requires_registration,
       ad.collects_tax,
       ad.administrator_type_id,
       aty.name,
       to_char(ad.start_date, 'mm/dd/yyyy') start_date,
       to_char(ad.end_date, 'mm/dd/yyyy') end_date,
       ad.status,
       ad.status_modified_date,
       ad.entered_by,
       ad.entered_date
  FROM mv_administrator_revisions r
       JOIN mv_administrators ad
          ON (    r.nkid = ad.nkid
              AND r.id >= ad.rid
              AND r.id < NVL (ad.next_rid, 99999999))
       JOIN administrator_types aty
          ON (aty.id = ad.administrator_type_id);