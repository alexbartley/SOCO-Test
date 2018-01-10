CREATE TABLE sbxtax.ct_alloc_bucket_hierarchy (
  allocation_bucket_id NUMBER NOT NULL,
  allocation_bucket_name VARCHAR2(100 BYTE) NOT NULL,
  prev_alloc_bucket_1_id NUMBER,
  prev_alloc_bucket_1_name VARCHAR2(100 BYTE),
  prev_alloc_bucket_2_id NUMBER,
  prev_alloc_bucket_2_name VARCHAR2(100 BYTE),
  prev_alloc_bucket_3_id NUMBER,
  prev_alloc_bucket_3_name VARCHAR2(100 BYTE),
  prev_alloc_bucket_4_id NUMBER,
  prev_alloc_bucket_4_name VARCHAR2(100 BYTE)
) 
TABLESPACE ositax;