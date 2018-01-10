CREATE OR REPLACE FORCE VIEW content_repo.vtax_outline_rev_pk ("ID",rid,nkid,next_rid,entered_by,entered_date,status,status_modified_date) AS
select /*+ index(r juris_tax_rev_n1) */tao.id, r.id rid, r.nkid, r.next_rid, r.entered_by, r.entered_date, r.status, r.status_modified_Date
from jurisdiction_tax_revisions r
join vtax_ids ti on (r.nkid = ti.nkid)
join tax_outlines tao on (
    ti.id = tao.juris_tax_imposition_id
    and COALESCE(tao.next_rid,r.next_rid,99999999999) <= NVL(r.next_rid,99999999999)
    )
 
 
 ;