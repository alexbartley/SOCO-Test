CREATE OR REPLACE FORCE VIEW content_repo.vtax_registrations ("ID",nkid,rid,next_rid,admin_id,admin_nkid,admin_rid,admin_next_rid,registration_mask,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT tr.id,
          tr.nkid,
          tr.rid,
          tr.next_rid,
          a.id admin_id,
          a.nkid admin_nkid,
          ar.id admin_rid,
          ar.next_rid,
          tr.registration_mask,
          TO_CHAR(tr.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR(tr.end_date, 'mm/dd/yyyy') end_date,
          tr.status,
          tr.status_modified_date,
          tr.entered_by,
          tr.entered_date
     FROM tax_registrations tr
          JOIN vadmin_ids a
             ON (tr.administrator_id = a.id)
          JOIN administrator_revisions ar
             ON (ar.nkid = a.nkid AND rev_join(tr.rid,ar.id,COALESCE(tr.next_rid,99999999)) = 1)
 
 
 ;