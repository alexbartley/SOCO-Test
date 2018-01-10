CREATE TABLE sbxtax4.tb_dashboard_views (
  "INTERVAL" VARCHAR2(20 CHAR),
  dashboard_view_id NUMBER NOT NULL,
  view_name VARCHAR2(100 CHAR) NOT NULL,
  merchant_id NUMBER NOT NULL,
  private_flag VARCHAR2(1 CHAR),
  currency_id NUMBER NOT NULL,
  tax_direction VARCHAR2(1 CHAR),
  date_type VARCHAR2(1 CHAR),
  from_date DATE,
  "TO_DATE" DATE,
  tax_amount VARCHAR2(1 CHAR),
  taxable_amount VARCHAR2(1 CHAR),
  exempt_amount VARCHAR2(1 CHAR),
  gross_amount VARCHAR2(1 CHAR),
  recoverable_amount VARCHAR2(1 CHAR),
  creation_date DATE,
  created_by NUMBER,
  last_update_date DATE,
  last_updated_by NUMBER,
  tax_data_type VARCHAR2(5 CHAR),
  external_flag VARCHAR2(1 CHAR),
  "ROLE" VARCHAR2(2 CHAR),
  top_regions VARCHAR2(2 CHAR)
) 
TABLESPACE ositax;