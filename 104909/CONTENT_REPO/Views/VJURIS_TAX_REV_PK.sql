CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_rev_pk ("ID",rid,nkid,next_rid,entered_by,entered_date,status,status_modified_date) AS
select /*+ index(r juris_tax_rev_n1) */jt.id, r.id rid, r.nkid, r.next_rid, r.entered_by, r.entered_date, r.status, r.status_modified_Date
from jurisdiction_tax_revisions r
join juris_tax_impositions jt on (
    r.nkid = jt.nkid
    and COALESCE(jt.next_rid,r.next_rid,99999999999) <= NVL(r.next_rid,99999999999)
    )
 
 
 ;