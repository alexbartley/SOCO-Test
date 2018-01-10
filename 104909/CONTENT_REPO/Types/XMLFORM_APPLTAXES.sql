CREATE OR REPLACE TYPE content_repo."XMLFORM_APPLTAXES"                                          as object
(
  id number
, rid number
, nkid number
, next_rid number
, juris_tax_impsoition_id number
, juris_tax_impsoition_nkid number
, juris_tax_applicability_id number
, juris_tax_applicability_nkid number
, ref_rule_order number
, tax_type varchar2(20 char)
, startdate date
, enddate date
, entered_by number
, status number
, status_modified_date date
, entered_date date
, deleted varchar2(1)
);
/