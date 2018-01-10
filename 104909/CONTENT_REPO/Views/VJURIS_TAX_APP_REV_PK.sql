CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_app_rev_pk ("ID",rid,nkid,next_rid,entered_by,entered_date,status,status_modified_date) AS
select jt.id, r.id rid, r.nkid, r.next_rid, r.entered_by, r.entered_date, r.status, r.status_modified_Date
from juris_tax_app_revisions r
join juris_tax_applicabilities jt on (
    r.nkid = jt.nkid
    and COALESCE(jt.next_rid,r.next_rid,99999999999) <= NVL(r.next_rid,99999999999)
    );