CREATE TABLE sbxtax.tb_authority_logic_group_xref (
  authority_logic_group_xref_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  authority_logic_group_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  process_order NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;