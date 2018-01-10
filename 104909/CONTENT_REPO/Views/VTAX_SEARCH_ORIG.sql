CREATE OR REPLACE FORCE VIEW content_repo.vtax_search_orig (juris_tax_entity_rid,juris_tax_id,juris_tax_nkid,juris_tax_next_rid,tax_rid,tax_next_rid,out_rid,out_next_rid,def_rid,def_next_rid,reference_code,start_date,end_date,taxation_type_id,taxation_type,spec_applicability_type_id,specific_applicability_type,transaction_type,transaction_type_id,revenue_purpose_description,revenue_purpose_id,tax_calc_structure_id,tax_structure,amount_type,tax_value_type,tax_value,min_threshold,max_limit,administrator_name,admin_rid,reporting_code,jurisdiction_nkid) AS
SELECT DISTINCT jti.juris_tax_entity_rid,
                   jti.id,
                   jti.nkid,
                   jti.juris_tax_next_rid,
                   jti.rid,
                   jti.next_rid,
                   tou.rid,
                   tou.next_rid,
                   td.rid,
                   td.next_rid,
                   jti.reference_code,
                   tou.start_date,
                   tou.end_date,
                   ts.taxation_type_id,
                   ts.taxation_type,
                   ts.spec_applicability_type_id,
                   ts.specific_applicability_type,
                   ts.transaction_type,
                   ts.transaction_type_id,
                   rp.description AS revenue_purpose_description,
                   rp.id AS revenue_purpose_id,
                   tcs.id tax_calc_structure_id,
                   tcs.TAX_STRUCTURE,
                   tcs.amount_type,
                   td.value_type,
                   td.VALUE,
                   td.min_threshold,
                   td.max_limit,
                   /*ta.administrator_name,
                   ta.admin_rid,
                   tat.VALUE reporting_code,*/
                   '' administrator_name,
                   '' admin_rid,
                   '' reporting_code,
                   jpk.nkid jurisdiction_nkid
     FROM vjuris_tax_impositions jti
          JOIN vjuris_ids jpk
             ON (jpk.id = jti.jurisdiction_id)
         /* LEFT OUTER JOIN vtax_administrators ta
             ON (    ta.juris_tax_nkid = jti.nkid
                 AND jti.juris_tax_entity_rid = ta.juris_tax_rid)*/
          JOIN vtax_outlines tou
             ON (    tou.juris_tax_nkid = jti.nkid
                 AND jti.juris_tax_entity_rid = tou.rid
                 --AND jti.juris_tax_entity_rid = tou.juris_tax_rid
                 --AND tou.juris_tax_id = jti.id --this may have fixed the search results 09/12/2013 12:27
                                              )
          JOIN vtax_definitions2 td
             ON (    td.juris_tax_nkid = jti.nkid
                 AND td.tax_outline_nkid = tou.nkid
                 AND td.juris_tax_rid = tou.rid
                 --AND jti.juris_tax_entity_rid = td.juris_tax_rid
                 --and td.tax_outline_id = tou.id this may have fixed the search results 09/12/2013 12:27
                                              )
          /*LEFT OUTER JOIN vtax_attributes tat
             ON (    tat.juris_tax_nkid = jti.nkid
                 AND jti.juris_tax_entity_rid = tat.juris_tax_rid
                 AND tat.attribute_name = 'Reporting Code')*/
          JOIN vtax_calc_structures tcs
             ON (tcs.id = tou.calculation_structure_id)
          JOIN vtax_descriptions ts
             ON (ts.id = jti.tax_description_id)
          LEFT OUTER JOIN revenue_purposes rp
             ON (rp.id = NVL (jti.revenue_purpose_id, -1))
--WHERE jti.juris_tax_next_rid is NULL  1/27/2014
WHERE tou.next_rid IS NULL
-- 9/18/2014 tnn: Made a little test for the NKID 31634 and removed the
-- ''AND jti.juris_tax_entity_rid = td.juris_tax_rid'' for the time being from td
-- only using nkid and jti.id for tou
-- (How is the UI specifying the where statement when this view is used?)
 
 
 ;