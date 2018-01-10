CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_descriptions ("ID",nkid,rid,next_rid,juris_id,juris_nkid,juris_rid,juris_next_rid,tax_description_id,start_date,end_date,status,status_modified_date,entered_by,entered_date) AS
SELECT jtd.id,
       jtd.nkid,
       jtd.rid,
       jtd.next_rid,
       ji.id juris_id,
       ji.nkid juris_nkid,
       r.id juris_entity_rid,
       r.next_rid,
       jtd.tax_description_id,
       TO_CHAR (jtd.start_date, 'mm/dd/yyyy') start_date,
       TO_CHAR (jtd.end_date, 'mm/dd/yyyy') end_date,
       jtd.status,
       jtd.status_modified_date,
       jtd.entered_by,
       jtd.entered_date
  FROM juris_tax_descriptions jtd
       JOIN vjuris_ids ji
          ON (ji.id = jtd.jurisdiction_id)
       JOIN jurisdiction_revisions r
          ON (    r.nkid = ji.nkid
              AND rev_join (jtd.rid, r.id, COALESCE (jtd.next_rid, 99999999)) =
                     1--AND j.rid >= jtd.rid
                      --and j.rid < COALESCE(jtd.next_rid,99999999)
             )
 
 
 ;