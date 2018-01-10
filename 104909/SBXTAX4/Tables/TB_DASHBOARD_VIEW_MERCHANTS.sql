CREATE TABLE sbxtax4.tb_dashboard_view_merchants (
  dashboard_view_merchant_id NUMBER NOT NULL,
  dashboard_view_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  creation_date DATE,
  created_by NUMBER,
  last_update_date DATE,
  last_updated_by NUMBER
) 
TABLESPACE ositax;