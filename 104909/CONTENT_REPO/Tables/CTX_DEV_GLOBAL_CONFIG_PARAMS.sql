CREATE TABLE content_repo.ctx_dev_global_config_params (
  "NAME" VARCHAR2(20 CHAR) NOT NULL,
  "VALUE" VARCHAR2(20 CHAR),
  PRIMARY KEY ("NAME") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;