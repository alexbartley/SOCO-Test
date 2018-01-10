CREATE OR REPLACE TRIGGER content_repo."INS_PRODUCT_TREES" 
 BEFORE
  INSERT
 ON content_repo.product_trees
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_product_trees.nextval;
:new.entered_Date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/