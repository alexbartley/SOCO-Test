CREATE TABLE sbxtax3.tb_dashboard_view_tax_types (
  dashboard_view_tax_type_id NUMBER(10) NOT NULL,
  dashboard_view_id NUMBER(10) NOT NULL,
  tax_type_name VARCHAR2(10 BYTE),
  creation_date DATE,
  created_by NUMBER(10),
  last_update_date DATE,
  last_updated_by NUMBER(10)
) 
TABLESPACE ositax;