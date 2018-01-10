CREATE TABLE content_repo.attachments (
  "ID" NUMBER NOT NULL,
  research_log_id NUMBER,
  filename VARCHAR2(300 CHAR) NOT NULL,
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  attached_file BLOB NOT NULL,
  effective_date DATE,
  expiration_date DATE,
  posted_date DATE,
  acquired_date DATE,
  language_id NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  description VARCHAR2(250 CHAR),
  display_name VARCHAR2(300 CHAR) NOT NULL,
  research_source_id NUMBER,
  CONSTRAINT attachments_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT attachments_f1 FOREIGN KEY (research_log_id) REFERENCES content_repo.research_logs ("ID"),
  CONSTRAINT attachments_f2 FOREIGN KEY (language_id) REFERENCES content_repo.languages ("ID")
) 
TABLESPACE content_repo
LOB (attached_file) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);