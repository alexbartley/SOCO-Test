CREATE OR REPLACE FORCE VIEW content_repo.vinvoice_statement (juris_tax_applicability_id,juris_tax_applicability_rid,juris_tax_applicability_nkid,reference_code,juris_tax_imposition_id,juris_tax_imposition_nkid,start_date,end_date,"ID",nkid,rid,entered_by,status,status_modified_date,entered_date,next_rid,ref_rule_order,tax_type,invoice_statement) AS
SELECT DISTINCT jta.id juris_tax_applicability_id,
                jta.rid juris_tax_applicability_rid,
                jta.nkid juris_tax_applicability_nkid,
                jta.reference_code,
                tat.juris_tax_imposition_id,
                tat.juris_tax_imposition_nkid,
                tat.start_date,
                tat.end_date,
                tat.id,
                tat.nkid,
                jta.rid,
                tat.entered_by,
                tat.status,
                tat.status_modified_date,
                tat.entered_date,
                tat.next_rid,
                tat.ref_rule_order,
                tat.tax_type,
                nvl(tot1.short_text, tot2.short_text) invoice_statement
  FROM juris_tax_applicabilities jta
       LEFT JOIN tax_applicability_taxes tat ON (tat.juris_tax_applicability_nkid = jta.nkid)    -- changed to nkid 04/29/16 dlg
      LEFT JOIN taxability_outputs tot1
           ON (   tat.id = tot1.tax_applicability_tax_id )
       LEFT JOIN taxability_outputs tot2
           ON (   jta.id = tot2.juris_tax_applicability_id and tat.id is NULL );