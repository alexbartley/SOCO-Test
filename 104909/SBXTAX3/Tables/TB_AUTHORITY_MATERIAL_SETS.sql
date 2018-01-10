CREATE TABLE sbxtax3.tb_authority_material_sets (
  authority_material_set_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10) NOT NULL,
  material_set_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;