CREATE OR REPLACE FORCE VIEW content_repo.vtax_search (juris_tax_entity_rid,juris_tax_id,juris_tax_nkid,juris_tax_next_rid,tax_rid,tax_next_rid,out_rid,out_next_rid,def_id,def_rid,def_next_rid,reference_code,start_date,end_date,taxation_type_id,taxation_type,spec_applicability_type_id,specific_applicability_type,transaction_type,transaction_type_id,revenue_purpose_description,revenue_purpose_id,tax_calc_structure_id,tax_structure,amount_type,tax_value_type,tax_value,min_threshold,max_limit,jurisdiction_nkid,ref_juris_tax_rid) AS
SELECT jti.juris_tax_entity_rid "JURIS_TAX_ENTITY_RID",
          jti.id "JURIS_TAX_ID",
          jti.nkid "JURIS_TAX_NKID",
          jti.juris_tax_next_rid "JURIS_TAX_NEXT_RID",
          jti.rid "TAX_RID",
          jti.next_rid,
          tou.rid,
          tou.next_rid,
          td2.id,
          td2.rid,
          td2.next_rid,
          jti.reference_code,
          tou.start_date,              --to_date(tou.start_date,'MM/DD/YYYY'),
          tou.end_date,                  --to_date(tou.end_date,'MM/DD/YYYY'),
          td.taxation_type_id,
          td.taxation_type,
          td.spec_applicability_type_id,
          td.specific_applicability_type,
          td.transaction_type,
          td.transaction_type_id,
          rp.description AS revenue_purpose_description,
          rp.id AS revenue_purpose_id,
          tcs.id tax_calc_structure_id,
          tcs.TAX_STRUCTURE,
          tcs.amount_type,
          td2.value_type,
          COALESCE (jtr.reference_code, TO_CHAR (td2.VALUE)),
          td2.min_threshold,
          td2.max_limit,
          jti.jurisdiction_nkid,
          JTR.RID
     FROM vjuris_tax_impositions jti
          JOIN vtax_outlines tou
             ON (tou.juris_tax_rid = jti.juris_tax_entity_rid)
          JOIN vtax_calc_structures tcs
             ON (tou.calculation_structure_id = tcs.id)
          JOIN vtax_descriptions td
             ON (td.id = jti.tax_description_id)
          JOIN vtax_definitions2 td2
             ON (    TD2.TAX_OUTLINE_nkid = tou.nkid and
             td2.juris_tax_rid = tou.juris_tax_rid)
          LEFT OUTER JOIN revenue_purposes rp
             ON (rp.id = NVL (jti.revenue_purpose_id, -1))
          left JOIN vjuris_tax_impositions jtr
             ON (td2.ref_juris_tax_id = jtr.id
             and jtr.rid = jtr.juris_tax_entity_rid
             )
    WHERE jti.juris_tax_next_rid IS NULL;