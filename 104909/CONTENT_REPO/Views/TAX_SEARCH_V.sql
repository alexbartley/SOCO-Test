CREATE OR REPLACE FORCE VIEW content_repo.tax_search_v ("ID",nkid,rid,next_rid,juris_tax_entity_rid,juris_tax_next_rid,reference_code,start_date,end_date,taxation_type_id,taxation_type,spec_applicability_type_id,spec_applicability_type,transaction_type_id,transaction_type,revenue_purpose_description,tax_structure_type_id,tax_structure,tax_value_type,tax_value,jurisdiction_nkid,jurisdiction_rid,ref_juris_tax_rid,tag_id,entered_date,entered_by,status_modified_date,status,tax_description) AS
SELECT    jti.id,
          jti.nkid,
          jti.rid,
          jti.next_rid,
          jti.juris_tax_entity_rid,
          jti.juris_tax_next_rid,
          jti.reference_code,
          to_date(to_date(tou.start_date, 'mm/dd/yyyy'), 'dd-Mon-yy'),
          to_date(to_date(tou.end_date, 'mm/dd/yyyy'), 'dd-Mon-yy'),
          td.taxation_type_id,
          td.taxation_type,
          td.spec_applicability_type_id,
          td.specific_applicability_type,
          td.transaction_type_id,
          td.transaction_type,
          rp.description,
          tcs.id,
          tcs.TAX_STRUCTURE,
          td2.value_type,
          COALESCE (jti.reference_code, TO_CHAR (td2.value)),
          jti.jurisdiction_nkid,
          jti.jurisdiction_rid,
          jti.rid,
          tt.tag_id,
          jti.entered_date,
          jti.entered_by,
          jti.status_modified_date,
          jti.status,
          jti.description tax_description
     FROM vjuris_tax_impositions jti
          JOIN vtax_outlines tou
             ON (tou.juris_tax_rid = jti.juris_tax_entity_rid )
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
          LEFT JOIN vtax_tags tt
             ON (tt.juris_tax_nkid = jti.nkid)
    WHERE jti.juris_tax_next_rid IS NULL
        AND jti.next_rid IS NULL;