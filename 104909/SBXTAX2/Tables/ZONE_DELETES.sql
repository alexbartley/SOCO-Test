CREATE TABLE sbxtax2.zone_deletes (
  content_journal_id NUMBER,
  primary_key NUMBER,
  parent_zone_id VARCHAR2(4000 BYTE),
  zone_level_id VARCHAR2(8 BYTE)
) 
TABLESPACE ositax;