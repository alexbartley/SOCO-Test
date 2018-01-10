CREATE TABLE content_repo.ctx_dev_role_lvl_config_params (
  role_id VARCHAR2(20 CHAR) NOT NULL,
  "NAME" VARCHAR2(20 CHAR) NOT NULL,
  "VALUE" VARCHAR2(20 CHAR),
  PRIMARY KEY (role_id,"NAME") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;