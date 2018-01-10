CREATE OR REPLACE FORCE VIEW content_repo.dev_taxability_conditions_v ("ID",reference_code,element_name,description,logical_qualifier,"VALUE",reference_group_name,start_date,end_date,rid,next_rid) AS
SELECT /*+index(trq tran_tax_qualifiers_n2) index(txe applicability_elements_pk) index(rq reference_groups_pk)*/
           trq.id,
           jta.reference_code,
           txe.element_name,
           txe.description,
           trq.logical_qualifier,
           trq.VALUE,
           rg.name reference_group_name,
           TO_CHAR (trq.start_date, 'mm/dd/yyyy') start_date,
           TO_CHAR (trq.end_date, 'mm/dd/yyyy') end_date,
           jtr.id rid,
           jta.next_rid-- crapp-2616 05/13/16
    FROM tran_tax_qualifiers trq
         JOIN juris_tax_applicabilities jta ON (jta.nkid = trq.juris_tax_applicability_nkid) -- changed to nkid 04/30/16 dlg
         JOIN juris_tax_app_revisions jtr ON (jtr.nkid = jta.nkid
                                              AND rev_join(trq.rid, jtr.id, trq.next_rid) = 1)  -- changed rev_join values to TRQ crapp-2616
         LEFT OUTER JOIN logical_qualifiers lq ON (lq.name = trq.logical_qualifier)
         LEFT OUTER JOIN taxability_elements txe ON (txe.id = trq.taxability_element_id)
         LEFT OUTER JOIN reference_groups rg ON (rg.id = trq.reference_group_id)
    WHERE jta.next_rid IS NULL;