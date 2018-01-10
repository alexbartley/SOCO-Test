CREATE OR REPLACE FORCE VIEW content_repo.reference_groups_v ("ID",nkid,rid,next_rid,ref_grp_rid,ref_grp_next_rid,"NAME",description,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT ad.id,
          ad.nkid,
          ad.rid,
          ad.next_rid,
          r.id,
          r.next_rid,
          ad.name,
          ad.description,
          TO_CHAR (ad.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (ad.end_date, 'mm/dd/yyyy') end_date,
          ad.status,
          ad.status_modified_date,
          ad.entered_by,
          ad.entered_date
     FROM    ref_group_revisions r
          JOIN
             reference_groups ad
          ON (    r.nkid = ad.nkid
              AND r.id >= ad.rid
              AND r.id < NVL (ad.next_rid, 99999999))
 
 
 ;