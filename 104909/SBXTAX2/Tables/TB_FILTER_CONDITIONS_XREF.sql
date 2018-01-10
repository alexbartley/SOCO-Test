CREATE TABLE sbxtax2.tb_filter_conditions_xref (
  fc_xref_id NUMBER NOT NULL,
  filter_id NUMBER NOT NULL,
  condition_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  parent_fc_xref_id NUMBER,
  ordering NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  last_updated_from NUMBER(10) NOT NULL
) 
TABLESPACE ositax;