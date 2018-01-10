CREATE OR REPLACE TYPE content_repo."XMLFORM_QUALIFIERS_COND"                                          AS OBJECT
(id number,
 rid number,
 nkid number,
 entered_by number,
 taxability_element_id number,
 logical_qualifier varchar2(128),
 q_value varchar2(30),
 start_date varchar2(12),
 end_date varchar2(12),
 ref_group_id number,
 jurisdiction_id number,
 juris_tax_applicability_id number,
 modified number,
 delete_flag number);
/