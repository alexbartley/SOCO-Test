CREATE TABLE sbxtax.tb_allocations (
  allocation_id NUMBER NOT NULL,
  alloc_group_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  distribution_type VARCHAR2(20 CHAR),
  is_integer_quantity VARCHAR2(1 CHAR),
  distribution_method VARCHAR2(20 CHAR),
  rounding_rule VARCHAR2(20 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;