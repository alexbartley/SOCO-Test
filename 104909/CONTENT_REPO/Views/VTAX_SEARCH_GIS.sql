CREATE OR REPLACE FORCE VIEW content_repo.vtax_search_gis (official_name,juris_tax_entity_rid,juris_tax_id,juris_tax_nkid,juris_tax_next_rid,tax_rid,tax_next_rid,jurisdiction_rid,out_rid,out_next_rid,def_rid,def_next_rid,reference_code,start_date,end_date,taxation_type_id,taxation_type,spec_applicability_type_id,specific_applicability_type,transaction_type,transaction_type_id,revenue_purpose_description,revenue_purpose_id,tax_calc_structure_id,tax_structure,amount_type,tax_value_type,referenced_code,tax_value,min_threshold,max_limit,administrator_name,admin_rid,reporting_code,jurisdiction_nkid,ref_juris_tax_rid,state_code) AS
SELECT  ja.official_name,
        jti.juris_tax_entity_rid "JURIS_TAX_ENTITY_RID",
        jti.id                   "JURIS_TAX_ID",
        jti.nkid                 "JURIS_TAX_NKID",
        jti.juris_tax_next_rid   "JURIS_TAX_NEXT_RID",
        jti.rid                  "TAX_RID",
        jti.next_rid,
        jti.jurisdiction_rid,
        tou.rid,
        tou.next_rid,
        td2.rid,
        td2.next_rid,
        jti.reference_code,
        
        --tou.start_date, --to_date(tou.start_date,'MM/DD/YYYY'),   -- removed 02/26/15 - dlg crapp-1314
        --tou.end_date,   --to_date(tou.end_date,'MM/DD/YYYY'),     -- removed 02/26/15 - dlg crapp-1314
        
        COALESCE(tou2.start_date, tou.start_date) start_date,       -- added 02/26/15 - dlg crapp-1314
        COALESCE(tou2.end_date, tou.end_date)     end_date,         -- added 02/26/15 - dlg crapp-1314
        
        td.taxation_type_id,
        td.taxation_type,
        td.spec_applicability_type_id,
        td.specific_applicability_type,
        td.transaction_type,
        td.transaction_type_id,
        rp.description AS revenue_purpose_description,
        rp.id          AS revenue_purpose_id,
        tcs.id tax_calc_structure_id,
        tcs.TAX_STRUCTURE,
        tcs.amount_type,
        td2.value_type,
        jtr.reference_code,
        coalesce(td3.value, td2.VALUE),
        td2.min_threshold,
        td2.max_limit,
         '' administrator_name,
         '' admin_rid,
         '' reporting_code,
        jti.jurisdiction_nkid,
        JTR.RID,
        ja.state_code
FROM vjuris_tax_impositions jti
     JOIN vtax_outlines tou ON (tou.juris_tax_rid = jti.JURIS_TAX_ENTITY_RID)
     JOIN vtax_calc_structures tcs ON (tou.calculation_structure_id = tcs.id)
     JOIN vtax_descriptions td ON (td.id = jti.tax_description_id)
     JOIN vtax_definitions2 td2 ON ( TD2.JURIS_TAX_RID = tou.JURIS_TAX_RID AND TD2.TAX_OUTLINE_NKID = tou.NKID  )
     JOIN vjuris_geo_areas ja ON (jti.jurisdiction_rid = ja.juris_entity_rid)     
     
     LEFT OUTER JOIN revenue_purposes rp  ON (rp.id = NVL (jti.revenue_purpose_id, -1))
     LEFT OUTER JOIN vjuris_tax_impositions jtr ON (td2.ref_juris_tax_id = jtr.id)
        
     LEFT JOIN vtax_outlines tou2 ON (tou2.juris_tax_rid = jtr.JURIS_TAX_ENTITY_RID
                                      AND tou.START_DATE > tou2.START_DATE AND NVL(tou2.END_DATE, '31-DEC-2099') > NVL(tou.END_DATE, '31-DEC-2098')
                                     )
     LEFT JOIN vtax_definitions2 td3 ON ( TD3.JURIS_TAX_RID = tou2.JURIS_TAX_RID AND TD3.TAX_OUTLINE_NKID = tou2.NKID  )
        
WHERE jti.juris_tax_next_rid IS NULL
      AND JTR.juris_tax_next_rid IS NULL
 ;