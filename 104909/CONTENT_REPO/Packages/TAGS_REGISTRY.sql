CREATE OR REPLACE PACKAGE content_repo."TAGS_REGISTRY"
  IS
--
-- Tags
--
-- Purpose: Procedures for handling tags
--
-- MODIFICATION HISTORY
-- Person      Date    Comments
-- ---------   ------  ---------------------------------------------------------
-- nnt         140114  added removeTag instead of using addTag with additional
--                     parameter since remove MIGTH require something more
-- nnt         140116  added a quick log to trace delete and insert
-- nnt         140407  upsert tags proc added (form tags)
-- nnt         140430  ref group tags!
-- nnt         140430  Workaround 11.1/11.2 bug for merge/delete. In 12c it is fixed.
-- dlg         141022  Added GIS
--
  PROCEDURE addTag
    ( id IN NUMBER DEFAULT NULL,
      nkid IN NUMBER DEFAULT NULL,
      tag_id IN NUMBER,
      entered_by IN NUMBER,
      entity IN NUMBER,
      status OUT NUMBER);

  -- ---------------------------------------------------------------------------
  -- Remove a tag from specified entity
  PROCEDURE removeTag(id IN NUMBER DEFAULT NULL,
      nkid IN NUMBER DEFAULT NULL,
      tag_id IN varchar2,
      entered_by IN NUMBER,
      entity IN NUMBER,
      status OUT number);

  -- UPsert tags (form section tag entries)
  PROCEDURE tags_entry (tag_list in xmlform_tags_tt, ref_nkid in number);

END tags_registry;
 
 
/