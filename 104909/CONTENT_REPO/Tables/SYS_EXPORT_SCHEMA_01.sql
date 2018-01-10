CREATE TABLE content_repo.sys_export_schema_01 (
  process_order NUMBER,
  "DUPLICATE" NUMBER,
  dump_fileid NUMBER,
  dump_position NUMBER,
  dump_length NUMBER,
  dump_orig_length NUMBER,
  dump_allocation NUMBER,
  completed_rows NUMBER,
  error_count NUMBER,
  elapsed_time NUMBER,
  object_type_path VARCHAR2(200 CHAR),
  object_path_seqno NUMBER,
  object_type VARCHAR2(30 CHAR),
  in_progress CHAR(1 CHAR),
  object_name VARCHAR2(500 CHAR),
  object_long_name VARCHAR2(4000 CHAR),
  object_schema VARCHAR2(30 CHAR),
  original_object_schema VARCHAR2(30 CHAR),
  original_object_name VARCHAR2(4000 CHAR),
  partition_name VARCHAR2(30 CHAR),
  subpartition_name VARCHAR2(30 CHAR),
  dataobj_num NUMBER,
  flags NUMBER,
  property NUMBER,
  trigflag NUMBER,
  creation_level NUMBER,
  completion_time DATE,
  object_tablespace VARCHAR2(30 CHAR),
  size_estimate NUMBER,
  object_row NUMBER,
  processing_state CHAR(1 CHAR),
  processing_status CHAR(1 CHAR),
  base_process_order NUMBER,
  base_object_type VARCHAR2(30 CHAR),
  base_object_name VARCHAR2(30 CHAR),
  base_object_schema VARCHAR2(30 CHAR),
  ancestor_process_order NUMBER,
  domain_process_order NUMBER,
  parallelization NUMBER,
  unload_method NUMBER,
  load_method NUMBER,
  granules NUMBER,
  "SCN" NUMBER,
  grantor VARCHAR2(30 CHAR),
  xml_clob CLOB,
  parent_process_order NUMBER,
  "NAME" VARCHAR2(30 CHAR),
  value_t VARCHAR2(4000 CHAR),
  value_n NUMBER,
  is_default NUMBER,
  file_type NUMBER,
  user_directory VARCHAR2(4000 CHAR),
  user_file_name VARCHAR2(4000 CHAR),
  file_name VARCHAR2(4000 CHAR),
  extend_size NUMBER,
  file_max_size NUMBER,
  process_name VARCHAR2(30 CHAR),
  last_update DATE,
  work_item VARCHAR2(30 CHAR),
  object_number NUMBER,
  completed_bytes NUMBER,
  total_bytes NUMBER,
  metadata_io NUMBER,
  data_io NUMBER,
  cumulative_time NUMBER,
  packet_number NUMBER,
  instance_id NUMBER,
  old_value VARCHAR2(4000 CHAR),
  "SEED" NUMBER,
  last_file NUMBER,
  user_name VARCHAR2(30 CHAR),
  operation VARCHAR2(30 CHAR),
  job_mode VARCHAR2(30 CHAR),
  queue_tabnum NUMBER,
  control_queue VARCHAR2(30 CHAR),
  status_queue VARCHAR2(30 CHAR),
  remote_link VARCHAR2(4000 CHAR),
  "VERSION" NUMBER,
  job_version VARCHAR2(30 CHAR),
  "DB_VERSION" VARCHAR2(30 CHAR),
  timezone VARCHAR2(64 CHAR),
  "STATE" VARCHAR2(30 CHAR),
  phase NUMBER,
  guid RAW(16),
  start_time DATE,
  block_size NUMBER,
  metadata_buffer_size NUMBER,
  data_buffer_size NUMBER,
  "DEGREE" NUMBER,
  platform VARCHAR2(101 CHAR),
  abort_step NUMBER,
  "INSTANCE" VARCHAR2(60 CHAR),
  cluster_ok NUMBER,
  service_name VARCHAR2(100 CHAR),
  object_int_oid VARCHAR2(32 CHAR),
  UNIQUE (process_order,"DUPLICATE") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo
LOB (file_name) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (object_long_name) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (old_value) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (original_object_name) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (remote_link) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (user_directory) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (user_file_name) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (value_t) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (xml_clob) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);
COMMENT ON TABLE content_repo.sys_export_schema_01 IS 'Data Pump Master Table EXPORT                         SCHEMA                        ';