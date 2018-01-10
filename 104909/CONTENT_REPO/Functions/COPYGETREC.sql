CREATE OR REPLACE FUNCTION content_repo."COPYGETREC" (pId in number) return TCopyTaxab
as
  vResult TCopyTaxab;
begin
  select copy_jta_records(id, calculation_method_id, basis_percent, recoverable_percent,
                             recoverable_amount, start_date, end_date,
                             status, rid, nkid, next_rid, jurisdiction_id,
                             jurisdiction_nkid,
all_taxes_apply                ,
applicability_type_id          ,
charge_type_id              ,
unit_of_measure                ,
ref_rule_order                 ,
default_taxability             ,
product_tree_id                ,
commodity_id                   ,
tax_type
--related_charge
)
  bulk collect into vResult
  from juris_tax_applicabilities jta
  where jta.id = pId;

  return vResult;

  -- CRAPP-1775
  -- Non-specified error. It is either success or fail.
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    errlogger.report_and_stop (SQLCODE,'No taxabilities found for id '||pId);
  WHEN OTHERS THEN
    errlogger.report_and_stop (SQLCODE,'Copy function failed');

end;
/