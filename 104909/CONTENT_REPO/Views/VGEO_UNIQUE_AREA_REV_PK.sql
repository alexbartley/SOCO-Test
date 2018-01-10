CREATE OR REPLACE FORCE VIEW content_repo.vgeo_unique_area_rev_pk ("ID",rid,nkid,next_rid,entered_by,entered_date,status,status_modified_date) AS
select /*+ index(r geo_unique_area_rev_n1) */
    gp.id, r.id rid, r.nkid, r.next_rid, r.entered_by, r.entered_date, r.status, r.status_modified_Date
from geo_unique_area_revisions r
join geo_unique_areas gp on (
    r.nkid = gp.nkid
    and COALESCE(gp.next_rid,r.next_rid,99999999999) <= NVL(r.next_rid,99999999999)
    )
 
 ;