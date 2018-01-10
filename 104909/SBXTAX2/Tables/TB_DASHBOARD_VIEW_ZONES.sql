CREATE TABLE sbxtax2.tb_dashboard_view_zones (
  dashboard_view_zone_id NUMBER NOT NULL,
  dashboard_view_id NUMBER NOT NULL,
  zone_id NUMBER NOT NULL,
  creation_date DATE,
  created_by NUMBER,
  last_update_date DATE,
  last_updated_by NUMBER
) 
TABLESPACE ositax;