CREATE OR REPLACE TYPE content_repo."COPY_JTA_RECORDS"                                          as object(
id                             number,
calculation_method_id          number,
basis_percent                  number,
recoverable_percent            number,
recoverable_amount             number,
start_date                     date,
end_date                       date,
status number,
rid                            number,
nkid                           number,
next_rid                       number,
jurisdiction_id                number,
jurisdiction_nkid              number,
all_taxes_apply                number(1,0),
applicability_type_id          number,
charge_type_id              number(1,0),
unit_of_measure                varchar2(16 char),
ref_rule_order                 number,
default_taxability             varchar2(1 char),
product_tree_id                number,
commodity_id                   number,
tax_type                       varchar2(8 byte)
--related_charge                 varchar2(1 char)
);
/