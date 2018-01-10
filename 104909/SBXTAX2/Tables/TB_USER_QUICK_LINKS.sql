CREATE TABLE sbxtax2.tb_user_quick_links (
  user_quick_link_id NUMBER(10) NOT NULL,
  user_id NUMBER(10) NOT NULL,
  app_component_id NUMBER(10) NOT NULL,
  display_order NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;