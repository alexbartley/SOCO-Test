CREATE OR REPLACE FORCE VIEW content_repo.transaction_taxabilities_v ("ID",nkid,rid,next_rid,entity_rid,entity_nkid,entity_next_rid,juris_tax_app_id,reference_code,applicability_type_id,start_date,end_date,status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT tas.id,
          tas.nkid,
          tas.rid,
          tas.next_rid,
          tis.entity_rid,
          tis.entity_nkid,
          tis.entity_next_rid,
          tas.juris_tax_applicability_id,
          tas.reference_code,
          tas.applicability_type_id,
          TO_CHAR (tas.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (tas.end_date, 'mm/dd/yyyy') end_date,
          tas.status,
          tas.status_modified_date,
          tas.entered_by,
          tas.entered_date,
          is_current(tas.rid,tis.entity_next_rid,tas.next_rid) is_current
     FROM tran_tax_id_sets tis
          JOIN transaction_taxabilities tas
             ON (  tas.id = tis.id)
 
 
 ;