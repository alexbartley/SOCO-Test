CREATE TABLE sbxtax4.tb_data_centers (
  data_center_id NUMBER NOT NULL,
  data_center_number NUMBER(5) NOT NULL,
  data_center_offset NUMBER(1) NOT NULL,
  creation_date DATE NOT NULL,
  created_by NUMBER(10) NOT NULL,
  last_update_date DATE,
  last_updated_by NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;