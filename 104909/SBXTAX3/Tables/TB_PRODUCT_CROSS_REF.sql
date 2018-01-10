CREATE TABLE sbxtax3.tb_product_cross_ref (
  product_cross_ref_id NUMBER(10) NOT NULL,
  product_cross_ref_group_id NUMBER(10) NOT NULL,
  product_category_id NUMBER(10) NOT NULL,
  source_product_code VARCHAR2(100 BYTE) NOT NULL,
  input_recovery_type VARCHAR2(2 BYTE),
  output_recovery_type VARCHAR2(2 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  start_date DATE DEFAULT TO_DATE('01/01/1900 12:00 AM', 'mm/dd/yyyy hh:mi am') NOT NULL,
  end_date DATE
) 
TABLESPACE ositax;