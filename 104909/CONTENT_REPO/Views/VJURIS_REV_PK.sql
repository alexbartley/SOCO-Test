CREATE OR REPLACE FORCE VIEW content_repo.vjuris_rev_pk ("ID",rid,nkid,next_rid,entered_by,entered_date,status,status_modified_date) AS
select j.id, r.id rid, r.nkid, r.next_rid, r.entered_by, r.entered_date, r.status, r.status_modified_Date
from jurisdiction_revisions r
join jurisdictions j on (
    r.nkid = j.nkid
    --and j.rid >= r.id
    --and COALESCE(j.next_rid,r.next_rid,99999999999) <= NVL(r.next_rid,99999999999)
    
    and rev_join(j.rid,r.id,COALESCE(j.next_rid,9999999999)) = 1
    )
 
 
 ;