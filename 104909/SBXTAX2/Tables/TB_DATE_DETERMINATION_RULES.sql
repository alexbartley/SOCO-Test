CREATE TABLE sbxtax2.tb_date_determination_rules (
  date_determination_rule_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  rule_order NUMBER(31,10) NOT NULL,
  authority_type_id NUMBER(10),
  authority_id NUMBER(10),
  document_type VARCHAR2(50 BYTE),
  movement_type VARCHAR2(100 BYTE),
  product_category_id NUMBER(10),
  start_date DATE NOT NULL,
  end_date DATE,
  date_determination_logic_id NUMBER(10) NOT NULL,
  date_type VARCHAR2(50 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  customer_name VARCHAR2(100 BYTE),
  customer_number VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;