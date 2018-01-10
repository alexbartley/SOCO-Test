CREATE TABLE sbxtax.tb_user_quick_links (
  user_quick_link_id NUMBER NOT NULL,
  user_id NUMBER NOT NULL,
  app_component_id NUMBER NOT NULL,
  display_order NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;