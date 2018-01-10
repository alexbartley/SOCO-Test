CREATE TABLE sbxtax4.tb_date_determination_rules (
  date_determination_rule_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  rule_order NUMBER(31,10) NOT NULL,
  authority_type_id NUMBER,
  authority_id NUMBER,
  document_type VARCHAR2(50 CHAR),
  movement_type VARCHAR2(100 CHAR),
  product_category_id NUMBER,
  start_date DATE NOT NULL,
  end_date DATE,
  date_determination_logic_id NUMBER NOT NULL,
  date_type VARCHAR2(50 CHAR) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  customer_name VARCHAR2(100 CHAR),
  customer_number VARCHAR2(100 CHAR),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;