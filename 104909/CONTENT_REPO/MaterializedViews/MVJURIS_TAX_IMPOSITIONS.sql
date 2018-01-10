CREATE MATERIALIZED VIEW content_repo.mvjuris_tax_impositions ("ID",nkid,rid,next_rid,juris_tax_entity_rid,juris_tax_entity_nkid,juris_tax_next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,tax_description_id,reference_code,start_date,end_date,description,status,status_modified_date,entered_by,entered_date,revenue_purpose_id,is_current) 
TABLESPACE content_repo
AS SELECT jts.id,
           jts.nkid,
           jts.rid,
           jts.next_rid,
           r.id,
           r.nkid,
           r.next_rid,
           j.id,
           j.nkid,
           j.rid,
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
      FROM jurisdiction_tax_revisions r,
           MV_JURIS_TAX_IMPOSITIONS jts,
           jurisdictions j,
           tax_descriptions ts
     WHERE     (    r.nkid = jts.nkid
                AND rev_join (jts.rid,
                              r.id,
                              COALESCE (jts.next_rid, 9999999999)) = 1)
           AND j.id = jts.jurisdiction_id
           AND ts.id = jts.tax_description_id;