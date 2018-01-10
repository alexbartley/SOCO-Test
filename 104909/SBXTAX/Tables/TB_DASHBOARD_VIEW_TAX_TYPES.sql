CREATE TABLE sbxtax.tb_dashboard_view_tax_types (
  dashboard_view_tax_type_id NUMBER NOT NULL,
  dashboard_view_id NUMBER NOT NULL,
  tax_type_name VARCHAR2(10 CHAR),
  creation_date DATE,
  created_by NUMBER,
  last_update_date DATE,
  last_updated_by NUMBER
) 
TABLESPACE ositax;