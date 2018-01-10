CREATE OR REPLACE FORCE VIEW content_repo.vappl_tax_appl_inv (juris_tax_applicability_id,juris_tax_applicability_rid,juris_tax_applicability_nkid,applicability_type_id,reference_code,juris_tax_imposition_id,juris_tax_imposition_nkid,start_date,end_date,"ID",nkid,rid,entered_by,status,status_modified_date,entered_date,next_rid,ref_rule_order,tax_type_id,invoice_statement) AS
SELECT  DISTINCT
        jta.id juris_tax_applicability_id,
        jtr.id juris_tax_applicability_rid,
        jta.nkid juris_tax_applicability_nkid,
        jta.applicability_type_id,  
        jti.reference_code,         
        tat.juris_tax_imposition_id,
        tat.juris_tax_imposition_nkid,
        NVL(tat.start_date,jta.start_date) start_date,  
        NVL(tat.end_date,jta.end_date) end_date,        
        tat.id,
        tat.nkid,
        NVL(tat.rid, jtr.id) rid, 
        tat.entered_by,
        tat.status,
        tat.status_modified_date,
        tat.entered_date,
        tat.next_rid,
        NVL(tat.ref_rule_order, jta.ref_rule_order) ref_rule_order, 
        tat.tax_type_id,  
        NVL(tot1.short_text, tot2.short_text) invoice_statement
FROM juris_tax_app_revisions jtr
        JOIN juris_tax_applicabilities jta -- crapp-2662/2263, added CASE to handle Exempt and Taxable Applicable Taxes
        ON (JTR.NKID = JTA.NKID and 
            rev_join (jta.rid, jtr.id, COALESCE (jta.next_rid, 999999999)) = 1 
            ) 
        LEFT JOIN tax_applicability_taxes tat ON (rev_join (tat.rid, jtr.id, COALESCE (tat.next_rid, 999999999)) = 1
                                                 AND jta.nkid = tat.juris_tax_applicability_nkid)
        LEFT JOIN juris_tax_impositions jti ON (jti.id = tat.juris_tax_imposition_id)          -- added 05/12/16
        LEFT JOIN taxability_outputs tot1 ON ( tat.nkid = tot1.tax_applicability_tax_nkid AND jti.id IS NOT NULL     -- Added this to fix CRAPP-2682
                                               AND rev_join(tot1.rid, jtr.id, COALESCE (tot1.next_rid, 9999999999)) = 1
                                             ) 
        LEFT JOIN taxability_outputs tot2 ON ( jta.nkid = tot2.juris_tax_applicability_nkid AND jti.id IS NULL
                                               AND rev_join(tot2.rid, jtr.id, COALESCE (tot2.next_rid, 9999999999)) = 1
                                             );