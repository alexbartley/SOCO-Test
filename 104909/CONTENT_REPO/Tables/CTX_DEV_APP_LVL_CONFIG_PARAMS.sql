CREATE TABLE content_repo.ctx_dev_app_lvl_config_params (
  app_id VARCHAR2(20 CHAR) NOT NULL,
  "NAME" VARCHAR2(20 CHAR) NOT NULL,
  "VALUE" VARCHAR2(20 CHAR),
  PRIMARY KEY (app_id,"NAME") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;