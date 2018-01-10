CREATE OR REPLACE FORCE VIEW content_repo.juris_tax_impositions_v ("ID",nkid,rid,next_rid,juris_tax_entity_rid,juris_tax_next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,tax_description_id,reference_code,start_date,end_date,description,status,status_modified_date,entered_by,entered_date,revenue_purpose_id,is_current) AS
SELECT jts.id,
          jts.nkid,
          jts.rid,
          jts.next_rid,
          tis.entity_rid,
          tis.entity_next_rid,
          juris_id,
          juris_nkid,
          juris_rid,
          jts.tax_description_id,
          jts.reference_code,
          TO_CHAR (jts.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (jts.end_date, 'mm/dd/yyyy') end_date,
          jts.description,
          jts.status,
          jts.status_modified_date,
          jts.entered_by,
          jts.entered_date,
          jts.revenue_purpose_id,
          is_current(jts.rid,tis.entity_next_rid,jts.next_rid) is_current
     FROM juris_tax_id_sets tis
        JOIN juris_tax_impositions jts
             ON ( jts.id = tis.id)
 
 
 ;