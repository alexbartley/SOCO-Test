CREATE OR REPLACE FORCE VIEW content_repo.copy_lookup_jta (jta_id,jurisdiction_id,reference_code,commodity_id,start_date,end_date,default_taxability,applicability_type_id) AS
Select
  jta.id jta_id, 
  jta.jurisdiction_id, 
  jti.reference_code, 
  jta.commodity_id, 
  jta.start_date, jta.end_date,
  jta.default_taxability,
  jta.applicability_type_id
From 
  juris_tax_applicabilities jta
Left join tax_applicability_taxes txt on (txt.juris_tax_applicability_id = jta.id)
Left join juris_tax_impositions jti on (jti.id = txt.juris_tax_imposition_id);