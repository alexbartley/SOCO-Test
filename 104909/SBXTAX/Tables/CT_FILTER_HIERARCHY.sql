CREATE TABLE sbxtax.ct_filter_hierarchy (
  filter_id NUMBER NOT NULL,
  filter_name VARCHAR2(100 BYTE) NOT NULL,
  filter_1_id NUMBER,
  filter_1_name VARCHAR2(100 BYTE),
  filter_2_id NUMBER,
  filter_2_name VARCHAR2(100 BYTE),
  filter_3_id NUMBER,
  filter_3_name VARCHAR2(100 BYTE),
  filter_4_id NUMBER,
  filter_4_name VARCHAR2(100 BYTE)
) 
TABLESPACE ositax;