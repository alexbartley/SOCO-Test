CREATE OR REPLACE FORCE VIEW content_repo.vjuris_tax_impositions ("ID",nkid,rid,next_rid,juris_tax_entity_rid,juris_tax_entity_nkid,juris_tax_next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,official_name,tax_description_id,reference_code,start_date,end_date,description,status,status_modified_date,entered_by,entered_date,revenue_purpose_id,is_current) AS
SELECT jts.id,
          jts.nkid,
          jts.rid,
          jts.next_rid,
          r.id,
          r.nkid,
          r.next_rid,
          j.id,
          j.nkid,
          j.rid,
          j.official_name,
          ts.id,
          jts.reference_code,
          TO_CHAR (jts.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (jts.end_date, 'mm/dd/yyyy') end_date,
          jts.description,
          jts.status,
          jts.status_modified_date,
          jts.entered_by,
          jts.entered_date,
          jts.revenue_purpose_id,
          is_current (jts.rid, r.next_rid, jts.next_rid) is_current
     FROM jurisdiction_Tax_revisions r
          JOIN juris_tax_impositions jts
             ON (    r.nkid = jts.nkid
                 AND rev_join (jts.rid,
                               r.id,
                               COALESCE (jts.next_rid, 9999999999)) = 1)
          --AND r.id >= jts.rid
          --AND r.id < COALESCE (jts.next_rid, 99999999))
          JOIN jurisdictions j
             ON (j.id = jts.jurisdiction_id)
          JOIN tax_descriptions ts
             ON (ts.id = jts.tax_description_id)
 
 
 ;