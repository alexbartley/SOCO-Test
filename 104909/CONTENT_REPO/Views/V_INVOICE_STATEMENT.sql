CREATE OR REPLACE FORCE VIEW content_repo.v_invoice_statement (juris_tax_applicability_id,"ID",juris_tax_imposition_id,start_date,end_date,nkid,rid,entered_by,status,status_modified_date,entered_date,next_rid,jta_id,jta_nkid,juris_tax_imposition_nkid,ref_rule_order,tax_type,short_text) AS
SELECT DISTINCT jta.id juris_tax_applicability_id,
         tat.id, tat.juris_tax_imposition_id, tat.start_date, tat.end_date,
         tat.nkid, tat.rid, tat.entered_by, tat.status, tat.status_modified_date,
         tat.entered_date, tat.next_rid, tat.juris_tax_applicability_id jta_id,
         tat.juris_tax_applicability_nkid jta_nkid, tat.juris_tax_imposition_nkid,
         tat.ref_rule_order, tat.tax_type,
         tot1.short_text
  FROM juris_tax_applicabilities jta
       LEFT JOIN tax_applicability_taxes tat
           ON (tat.juris_tax_applicability_id = jta.id)
       FULL OUTER JOIN taxability_outputs tot1
           ON (   jta.id = tot1.juris_tax_applicability_id
               OR tat.id = tot1.tax_applicability_tax_id);