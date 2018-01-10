CREATE OR REPLACE FORCE VIEW content_repo.taxab_juris_trans_header_v (juris_tax_applicability_id,transtaxid,reference_code,applicability_type_id,rid,nkid,next_rid) AS
(SELECT
 jtxapp.id juris_tax_applicability_id
,trTax.id transTaxId
,jtxapp.reference_code
,trtax.applicability_type_id
,trTax.rid
,trTax.nkid
,trTax.next_rid
FROM juris_tax_applicabilities jtxapp
JOIN transaction_taxabilities trTax ON (trTax.juris_tax_applicability_id = jtxapp.id)
)
 
 
 ;