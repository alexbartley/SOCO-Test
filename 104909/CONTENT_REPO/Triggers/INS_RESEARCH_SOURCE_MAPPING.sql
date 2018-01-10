CREATE OR REPLACE TRIGGER content_repo."INS_RESEARCH_SOURCE_MAPPING" 
 BEFORE
  INSERT
 ON content_repo.research_source_mapping
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_RESEARCH_SOURCE_MAPPING.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/