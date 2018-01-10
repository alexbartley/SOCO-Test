CREATE OR REPLACE FORCE VIEW content_repo.taxability_impo_applic_v (juris_tax_imp_id,jurisdiction_id,tax_description_id,juris_tax_imp_refcode,juris_tax_imp_rid,juris_tax_imp_nkid,taxation_type_id,taxation_type,spec_applicability_type_id,specific_applicability_type,transaction_type_id,transaction_type,jurisdiction_nkid) AS
(SELECT
/*jta.id juris_tax_applic_id,
jta.nkid juris_tax_applic_nkid,
jta.rid juris_tax_applic_rid,
jta.next_rid juris_tax_applic_next_rid,
jta.reference_code juris_tax_applic_refcode,
jta.calculation_method_id,
jta.start_date juris_tax_applic_start,
jta.end_date juris_tax_applic_end,
*/
jti.id juris_tax_imp_id,
jti.jurisdiction_id,
jti.tax_description_id,
jti.reference_code juris_tax_imp_refcode,
jti.rid juris_tax_imp_rid, jti.nkid juris_tax_imp_nkid,
txd.taxation_type_id, txd.taxation_type,
txd.spec_applicability_type_id, txd.specific_applicability_type,
txd.transaction_type_id, txd.transaction_type
,jti.jurisdiction_nkid
FROM
--  juris_tax_applicabilities jta
--  ON (jta.juris_tax_imposition_id=jti.id)
juris_tax_impositions jti
JOIN jurisdictions jrs ON (jrs.id = jti.jurisdiction_id)
JOIN vtax_descriptions txd ON (jti.tax_description_id = txd.id)
-- revisions
/*Juris_Tax_App_Revisions r
  ON (    r.nkid = jta.nkid
          AND r.id >= jta.rid
          AND r.id < COALESCE (jta.next_rid, 99999999))
*/
)
 
 ;