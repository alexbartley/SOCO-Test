CREATE OR REPLACE TYPE content_repo."GEN_APPLTAXES"                                          is object
(
atx_id number
, atx_juris_tax_imposition_id number
, atx_juris_tax_applicability_id number
, atx_ref_rule_order number
, atx_tax_type_id number
, atx_startdate date
, atx_enddate date
, atx_entered_by number
, atx_deleted varchar2(1)
, atx_invoice_statement varchar2(200 char)
);
/