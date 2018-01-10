CREATE TABLE sbxtax3.tb_dashboard_view_zones (
  dashboard_view_zone_id NUMBER(10) NOT NULL,
  dashboard_view_id NUMBER(10) NOT NULL,
  zone_id NUMBER(10) NOT NULL,
  creation_date DATE,
  created_by NUMBER(10),
  last_update_date DATE,
  last_updated_by NUMBER(10)
) 
TABLESPACE ositax;