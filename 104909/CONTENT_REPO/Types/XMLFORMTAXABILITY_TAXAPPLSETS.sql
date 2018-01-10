CREATE OR REPLACE TYPE content_repo."XMLFORMTAXABILITY_TAXAPPLSETS"                                          AS OBJECT
(
sysGenCommoditiesId number,
sysGenQualifiersId number,
Id number,
Rid number,
Nkid number,
Type_id number,
jta_id number,
com_grpId number,
trans_tx_Id  number,
taxability_output_id number,
applicability_type_id number,
applicability_type_name varchar2(256),
start_date date,
end_date date,
tax_group_name varchar2(64),
short_text varchar2(256),
full_text varchar2(256),
status  number,
modified number,
deleted  number
);
/