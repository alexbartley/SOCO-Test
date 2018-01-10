CREATE OR REPLACE TYPE content_repo."GEN_APPL_XML_TY"                                          as object (
                        ah_id number,
                        ah_applicabilityTypeId number,
                        ah_calculationMethodId number,
                        ah_recoverablePercent number,
						ah_recoverableAmount number,
                        ah_basisPercent number,
                        ah_charge_type_id number,
                        ah_unit_of_measure varchar2(100),
                        ah_ref_rule_order number, -- CRAPP-2791
                        ah_taxType varchar2(20),
                        ah_startDate date,
                        ah_endDate date,
                        ah_allTaxesApply number,
                        ah_commodityId number,
                        ah_jurisdictionId number,
                        ah_enteredBy number,
                        ah_defaultTaxability varchar2(1 char),
                        ah_productTreeId number,
                        ah_is_local    number,
                        ah_appl_taxes gen_appltaxes_ty,
                        ah_appl_attr gen_applattr_ty,
                        ah_appl_cond gen_applcond_ty,
						ah_appl_tags gen_appltags_ty
                        )
/