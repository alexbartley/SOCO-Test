CREATE OR REPLACE FORCE VIEW content_repo.impl_expl_v (implicit,implexpl_auth_level,impl_cm_order,"ID",reference_code,calculation_method_id,basis_percent,recoverable_percent,recoverable_amount,start_date,end_date,entered_by,entered_date,status,status_modified_date,rid,nkid,next_rid,jurisdiction_id,jurisdiction_nkid,jurisdiction_rid,jurisdiction_official_name,all_taxes_apply,applicability_type_id,charge_type_id,unit_of_measure,ref_rule_order,default_taxability,product_tree_id,commodity_id,commodity_nkid,commodity_rid,commodity_name,commodity_code,h_code,conditions,tax_type,tax_applicabilities,verification,change_count,commodity_tree_id,is_local,legal_statement,canbedeleted,maxstatus,tag_collection,condition_collection,applicable_tax_collection,processing_order,verifylist,source_h_code) AS
SELECT CASE WHEN override_order > 2 AND implicit = 0 THEN 1 ELSE implicit END "IMPLICIT"   -- crapp-2754
      ,"IMPLEXPL_AUTH_LEVEL"
      ,"IMPL_CM_ORDER"
      ,"ID"
      ,"REFERENCE_CODE"
      ,"CALCULATION_METHOD_ID"
      ,"BASIS_PERCENT"
      ,"RECOVERABLE_PERCENT"
      ,"RECOVERABLE_AMOUNT"
      ,"START_DATE"
      ,"END_DATE"
      ,"ENTERED_BY"
      ,"ENTERED_DATE"
      ,"STATUS"
      ,"STATUS_MODIFIED_DATE"
      ,"RID"
      ,"NKID"
      ,"NEXT_RID"
      ,"JURISDICTION_ID"
      ,"JURISDICTION_NKID"
      ,"JURISDICTION_RID"
      ,"JURISDICTION_OFFICIAL_NAME"
      ,"ALL_TAXES_APPLY"
      ,"APPLICABILITY_TYPE_ID"
      ,"CHARGE_TYPE_ID"
      ,"UNIT_OF_MEASURE"
      ,"REF_RULE_ORDER"
      ,"DEFAULT_TAXABILITY"
      ,"PRODUCT_TREE_ID"
      ,"COMMODITY_ID"
      ,"COMMODITY_NKID"
      ,"COMMODITY_RID"
      ,"COMMODITY_NAME"
      ,"COMMODITY_CODE"
      ,"H_CODE"
      ,"CONDITIONS"
      ,"TAX_TYPE"
      ,"TAX_APPLICABILITIES"
      ,"VERIFICATION"
      ,"CHANGE_COUNT"
      ,"COMMODITY_TREE_ID"
      ,"IS_LOCAL"
      ,"LEGAL_STATEMENT"
      ,"CANBEDELETED"
      ,"MAXSTATUS"
      ,"TAG_COLLECTION"
      ,"CONDITION_COLLECTION"
      ,"APPLICABLE_TAX_COLLECTION"
      ,"OVERRIDE_ORDER" -- output column PROCESSING_ORDER - crapp-2792
      ,"VERIFYLIST"
	  ,"SOURCE_H_CODE"
    FROM TABLE(taxability_grid.FN_IMPLEXPL_XOUT());