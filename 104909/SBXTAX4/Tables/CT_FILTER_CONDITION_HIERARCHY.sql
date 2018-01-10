CREATE TABLE sbxtax4.ct_filter_condition_hierarchy (
  filter_condition_id NUMBER NOT NULL,
  filter_condition_value VARCHAR2(100 BYTE) NOT NULL,
  filter_condition_xmle VARCHAR2(100 BYTE) NOT NULL,
  filter_condition_oper VARCHAR2(100 BYTE) NOT NULL,
  filter_condition_1_id NUMBER,
  filter_condition_1_value VARCHAR2(100 BYTE),
  filter_condition_1_xmle VARCHAR2(100 BYTE),
  filter_condition_1_oper VARCHAR2(100 BYTE),
  filter_condition_2_id NUMBER,
  filter_condition_2_value VARCHAR2(100 BYTE),
  filter_condition_2_xmle VARCHAR2(100 BYTE),
  filter_condition_2_oper VARCHAR2(100 BYTE),
  filter_condition_3_id NUMBER,
  filter_condition_3_value VARCHAR2(100 BYTE),
  filter_condition_3_xmle VARCHAR2(100 BYTE),
  filter_condition_3_oper VARCHAR2(100 BYTE),
  filter_condition_4_id NUMBER,
  filter_condition_4_value VARCHAR2(100 BYTE),
  filter_condition_4_xmle VARCHAR2(100 BYTE),
  filter_condition_4_oper VARCHAR2(100 BYTE)
) 
TABLESPACE ositax;