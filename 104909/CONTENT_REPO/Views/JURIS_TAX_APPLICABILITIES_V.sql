CREATE OR REPLACE FORCE VIEW content_repo.juris_tax_applicabilities_v ("ID",nkid,rid,next_rid,entity_rid,entity_next_rid,juris_id,juris_nkid,juris_rid,calculation_method_id,reference_code,start_date,end_date,basis_perecent,status,status_modified_date,entered_by,entered_date,is_current) AS
SELECT jta.id,
          jta.nkid,
          jta.rid,
          jta.next_rid,
          tis.entity_rid,
          tis.entity_next_rid,
          tis.juris_id,
          tis.juris_nkid,
          tis.juris_rid,
          jta.calculation_method_id,
          jta.reference_code,
          TO_CHAR (jta.start_date, 'mm/dd/yyyy') start_date,
          TO_CHAR (jta.end_date, 'mm/dd/yyyy') end_date,
          jta.basis_percent,
          jta.status,
          jta.status_modified_date,
          jta.entered_by,
          jta.entered_date,
          is_current(jta.rid,tis.entity_next_rid,jta.next_rid) is_current
     FROM juris_tax_app_id_sets tis
          JOIN juris_tax_applicabilities jta
             ON (  jta.id = tis.id)
 
 
 ;