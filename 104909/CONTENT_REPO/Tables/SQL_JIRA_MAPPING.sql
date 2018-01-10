CREATE TABLE content_repo.sql_jira_mapping (
  jira_id VARCHAR2(50 CHAR) NOT NULL,
  jira_title VARCHAR2(50 CHAR) NOT NULL,
  sql_file VARCHAR2(500 CHAR) NOT NULL
) 
TABLESPACE content_repo;