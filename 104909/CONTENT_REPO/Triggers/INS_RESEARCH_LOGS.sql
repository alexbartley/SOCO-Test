CREATE OR REPLACE TRIGGER content_repo."INS_RESEARCH_LOGS" 
 BEFORE
  INSERT
 ON content_repo.research_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_RESEARCH_LOGS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/