CREATE OR REPLACE FORCE VIEW content_repo.taxability_conditions_main_v ("ID",tmprid,nkid,trans_id,trans_nkid,trans_rid,trans_next_rid,juris_tax_applicability_id,applicability_type_id,reference_code,trans_taxability_status,taxability_element_id,element_name,description,element_value_type,logical_qualifier,logical_qualifier_id,"VALUE",element_qual_group,jurisdiction_id,official_name,reference_group_id,reference_group_name,start_date,end_date,entered_by,status,rid) AS
(SELECT trq.id,
           trq.rid tmprid,
           trq.nkid,
           jta.id trans_id,
           jta.nkid trans_nkid,
           jta.rid trans_rid,
           jta.next_rid trans_next_rid,
           jta.id juris_tax_applicability_id,
           NULL applicability_type_id,
           jta.reference_code,
           jta.status trans_taxability_status,
           trq.taxability_element_id,
           txe.element_name,
           txe.description,
           txe.element_value_type,
           trq.logical_qualifier,
           lq.id,
           --tlq.NAME logical_name,
           trq.VALUE,
           trq.element_qual_group,
           trq.jurisdiction_id,
           j.official_name,
           rg.id reference_group_id,
           rg.name reference_group_name,
           TO_CHAR (trq.start_date, 'mm/dd/yyyy') start_date,
           TO_CHAR (trq.end_date, 'mm/dd/yyyy') end_date,
           trq.entered_by,
           trq.status,
           jtr.id rid
      FROM
tran_tax_qualifiers trq
join juris_tax_applicabilities jta on (jta.id = trq.juris_tax_applicability_id)
join juris_tax_app_revisions jtr on (
    jtr.nkid = jta.nkid
    and rev_join(trq.rid,jtr.id,trq.next_rid) = 1
    )
      LEFT OUTER JOIN logical_qualifiers lq
           ON (lq.name = trq.logical_qualifier)
      LEFT OUTER JOIN taxability_elements txe
           ON (txe.id = trq.taxability_element_id)
      LEFT OUTER JOIN jurisdictions j
           ON (j.id = trq.jurisdiction_id)
      LEFT OUTER JOIN reference_groups rg
           ON (rg.id = trq.reference_group_id))
 
 
 ;