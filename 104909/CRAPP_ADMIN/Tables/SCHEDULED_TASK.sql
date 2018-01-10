CREATE TABLE crapp_admin.scheduled_task (
  "ID" NUMBER,
  "METHOD" VARCHAR2(4000 CHAR),
  scheduled_start TIMESTAMP(7),
  "PARAMETERS" VARCHAR2(4000 CHAR) CONSTRAINT scheduled_task_parameters_json CHECK (
	"PARAMETERS" IS JSON STRICT
),
  entered_by NUMBER,
  service VARCHAR2(4000 CHAR),
  task_start TIMESTAMP,
  task_end TIMESTAMP,
  status NUMBER(1),
  message VARCHAR2(4000 CHAR)
) 
TABLESPACE crapp_admin
LOB (message) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB ("METHOD") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB ("PARAMETERS") STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (service) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);