CREATE TABLE sbxtax.tb_dashboard_view_auth_types (
  dashboard_view_auth_type_id NUMBER NOT NULL,
  dashboard_view_id NUMBER NOT NULL,
  auth_type_id NUMBER NOT NULL,
  creation_date DATE,
  created_by NUMBER,
  last_update_date DATE,
  last_updated_by NUMBER
) 
TABLESPACE ositax;