CREATE TABLE sbxtax3.tb_alloc_buckets (
  alloc_bucket_id NUMBER(10) NOT NULL,
  allocation_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  previous_alloc_bucket_id NUMBER(10) NOT NULL,
  allocation_percent NUMBER(31,10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;