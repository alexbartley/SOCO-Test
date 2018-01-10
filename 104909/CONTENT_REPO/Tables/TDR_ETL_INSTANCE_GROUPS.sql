CREATE TABLE content_repo.tdr_etl_instance_groups (
  "ID" NUMBER NOT NULL,
  tdr_etl_instance_id NUMBER,
  tdr_etl_tag_group_id NUMBER,
  gis_flag VARCHAR2(1 BYTE),
  CONSTRAINT tdr_etl_instance_groups_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT tdr_etl_instance_groups_fk1 FOREIGN KEY (tdr_etl_instance_id) REFERENCES content_repo.tdr_etl_instances ("ID"),
  CONSTRAINT tdr_etl_instance_groups_fk2 FOREIGN KEY (tdr_etl_tag_group_id) REFERENCES content_repo.tdr_etl_tag_groups ("ID")
) 
TABLESPACE content_repo;