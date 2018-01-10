CREATE OR REPLACE TRIGGER content_repo."INS_RESEARCH_SOURCE_TAGS" 
 BEFORE
  INSERT
 ON content_repo.research_source_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_research_source_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/