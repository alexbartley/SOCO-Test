CREATE OR REPLACE FORCE VIEW content_repo.vjurisdiction_types ("ID",nkid,rid,next_rid,juris_type_rid,juris_type_next_rid,"NAME",description,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT ad.id,
       ad.nkid,
       ad.rid,
       ad.next_rid,
       r.id,
       r.next_rid,
       ad.name,
       ad.description,
       ad.start_date,
       ad.end_date,
       ad.status,
       ad.status_modified_date,
       ad.entered_by,
       ad.entered_date
  FROM jurisdiction_type_revisions r
       JOIN jurisdiction_types ad
          ON (    r.nkid = ad.nkid
              AND r.id >= ad.rid
              AND r.id < NVL (ad.next_rid, 99999999));