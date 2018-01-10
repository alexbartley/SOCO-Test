CREATE OR REPLACE FORCE VIEW content_repo.taxability_search_v ("ID",reference_code,calculation_method_id,basis_percent,recoverable_percent,recoverable_amount,start_date,end_date,entered_by,entered_date,status,status_modified_date,rid,nkid,next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,jurisdiction_official_name,all_taxes_apply,applicability_type_id,charge_type_id,unit_of_measure,ref_rule_order,default_taxability,product_tree_id,commodity_id,commodity_nkid,commodity_rid,commodity_name,commodity_code,h_code,conditions,tax_type,tax_applicabilities,verification,change_count,commodity_tree_id,is_local,legal_statement,canbedeleted,maxstatus,tag_collection,condition_collection,applicable_tax_collection,processing_order,verifylist,source_h_code) AS
SELECT jta.id
,jta.reference_code
,jta.calculation_method_id
,jta.basis_percent
,jta.recoverable_percent
,jta.recoverable_amount
,jta.start_date
,jta.end_date
,jta.entered_by
,jta.entered_date
,jta.status
,jta.status_modified_date
,jta.rid
,jta.nkid
,jta.next_rid
,jta.jurisdiction_id
,jta.jurisdiction_nkid
,jta.jurisdiction_rid
,jta.jurisdiction_official_name
,jta.all_taxes_apply
,jta.applicability_type_id
,jta.charge_type_id
,jta.unit_of_measure
,jta.ref_rule_order
,jta.default_taxability
,jta.product_tree_id
,jta.commodity_id
,jta.commodity_nkid
,jta.commodity_rid
,jta.commodity_name
,jta.commodity_code
,jta.h_code
,jta.conditions
,jta.tax_type
,jta.tax_applicabilities
,jta.verification
,jta.change_count
,jta.commodity_tree_id
,jta.is_local
,jta.legal_statement
,jta.canBeDeleted
,jta.maxstatus
,tag_details
,cond_details
,tax_details
,jta.processing_order
,jta.verifylist
,jta.h_code -- source_h_code. H_CODE for non impl/expl, source for impl/expl
  FROM taxability_header_v jta
    left JOIN
        ( select juris_tax_applicability_rid,
            listagg( reference_code||'|'||invoice_statement||'|'||to_char(start_date)||'|'||to_char(end_date)||'|'||ref_rule_order||'|'||tax_type_id, chr(13) )
            within group (order by length(reference_code), 1 ) tax_details
          from vappl_tax_appl_inv
          where next_rid is null
          group by juris_tax_applicability_rid
        ) vinv
       ON (jta.rid = vinv.juris_tax_applicability_rid)
       left join
        ( select
         trans_nkid, rid, listagg( element_name||'|'|| logical_qualifier||'|'||nvl(value, reference_group_name)||'|'||to_char(start_date)||'|'||to_char(end_date), chr(13)) within group (order by 1) cond_details
         from
        taxability_conditions_v jta
        where next_rid is null -- removing for performance reasons - 07/27/16
        group by rid, trans_nkid
        ) jtc
        on jta.rid = jtc.rid and jta.nkid = jtc.trans_nkid
       left  join
        (select jtat.ref_nkid, listagg (tgs.name, chr(13)) within group (order by 1) tag_details
             from juris_tax_app_tags jtat
            join tags tgs on (tgs.id = jtat.tag_id)
            group by jtat.ref_nkid
        )  tgs
        on tgs.ref_nkid = jta.nkid;