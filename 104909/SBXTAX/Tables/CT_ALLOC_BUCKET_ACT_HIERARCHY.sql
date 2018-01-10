CREATE TABLE sbxtax.ct_alloc_bucket_act_hierarchy (
  alloc_bucket_act_id NUMBER NOT NULL,
  alloc_bucket_act_value VARCHAR2(100 BYTE) NOT NULL,
  alloc_bucket_act_xmle VARCHAR2(100 BYTE) NOT NULL,
  alloc_bucket_act_oper VARCHAR2(100 BYTE) NOT NULL,
  prev_alloc_bucket_act_1_id NUMBER,
  prev_alloc_bucket_act_1_value VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_1_xmle VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_1_oper VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_2_id NUMBER,
  prev_alloc_bucket_act_2_value VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_2_xmle VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_2_oper VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_3_id NUMBER,
  prev_alloc_bucket_act_3_value VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_3_xmle VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_3_oper VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_4_id NUMBER,
  prev_alloc_bucket_act_4_value VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_4_xmle VARCHAR2(100 BYTE),
  prev_alloc_bucket_act_4_oper VARCHAR2(100 BYTE)
) 
TABLESPACE ositax;