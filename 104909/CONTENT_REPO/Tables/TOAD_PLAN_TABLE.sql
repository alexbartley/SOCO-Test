CREATE TABLE content_repo.toad_plan_table (
  "STATEMENT_ID" VARCHAR2(30 CHAR),
  plan_id NUMBER,
  "TIMESTAMP" DATE,
  remarks VARCHAR2(4000 CHAR),
  operation VARCHAR2(30 CHAR),
  options VARCHAR2(255 CHAR),
  object_node VARCHAR2(128 CHAR),
  object_owner VARCHAR2(30 CHAR),
  object_name VARCHAR2(30 CHAR),
  object_alias VARCHAR2(65 CHAR),
  object_instance NUMBER(*,0),
  object_type VARCHAR2(30 CHAR),
  optimizer VARCHAR2(255 CHAR),
  search_columns NUMBER,
  "ID" NUMBER(*,0),
  parent_id NUMBER(*,0),
  "DEPTH" NUMBER(*,0),
  position NUMBER(*,0),
  "COST" NUMBER(*,0),
  "CARDINALITY" NUMBER(*,0),
  bytes NUMBER(*,0),
  other_tag VARCHAR2(255 CHAR),
  partition_start VARCHAR2(255 CHAR),
  partition_stop VARCHAR2(255 CHAR),
  partition_id NUMBER(*,0),
  "OTHER" LONG,
  distribution VARCHAR2(30 CHAR),
  cpu_cost NUMBER(*,0),
  io_cost NUMBER(*,0),
  temp_space NUMBER(*,0),
  access_predicates VARCHAR2(4000 CHAR),
  filter_predicates VARCHAR2(4000 CHAR),
  projection VARCHAR2(4000 CHAR),
  "TIME" NUMBER(*,0),
  qblock_name VARCHAR2(30 CHAR),
  other_xml CLOB
) 
TABLESPACE content_repo
LOB (access_predicates) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (filter_predicates) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (other_xml) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW)
LOB (projection) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (remarks) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);