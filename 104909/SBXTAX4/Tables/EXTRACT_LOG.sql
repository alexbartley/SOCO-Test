CREATE TABLE sbxtax4.extract_log (
  "ID" NUMBER NOT NULL,
  tag_group VARCHAR2(128 CHAR) NOT NULL,
  entity VARCHAR2(128 CHAR) NOT NULL,
  nkid NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  extract_date TIMESTAMP,
  queued_date TIMESTAMP NOT NULL,
  transformed DATE,
  not_transformed DATE,
  loaded DATE,
  not_loaded DATE
) 
TABLESPACE ositax;