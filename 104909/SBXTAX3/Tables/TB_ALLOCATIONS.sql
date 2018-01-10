CREATE TABLE sbxtax3.tb_allocations (
  allocation_id NUMBER(10) NOT NULL,
  alloc_group_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  distribution_type VARCHAR2(20 BYTE),
  is_integer_quantity VARCHAR2(1 BYTE),
  distribution_method VARCHAR2(20 BYTE),
  rounding_rule VARCHAR2(20 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;