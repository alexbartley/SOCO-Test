CREATE OR REPLACE PROCEDURE content_repo."TAGS_ENTRY" (
    tag_list in xmlform_tags_tt
    )
IS
  PRAGMA autonomous_transaction;
  TYPE sectionRecord IS RECORD
   (tag_table varchar2(32));
  TYPE sectionTable IS TABLE OF sectionRecord; -- INDEX BY BINARY_INTEGER;
    sections sectionTable;
BEGIN
  -- (could be generic table data)
  -- and it would be better to do this in the main package;
  sections := sectionTable();
  sections.extend();
  sections(1).tag_table :='administrator_tags';
  sections.extend();
  sections(2).tag_table :='jurisdiction_tags';
  sections.extend();
  sections(3).tag_table :='juris_tax_imposition_tags';
  sections.extend();
  sections(4).tag_table :='juris_tax_app_tags';
  sections.extend();
  sections(5).tag_table :='commodity_tags';
  sections.extend();
  sections(6).tag_table :='commodity_group_tags';
  sections.extend();
  sections(7).tag_table :='attachment_tags';
  sections.extend();
  sections(8).tag_table :='research_source_tags';
  sections.extend();
  sections(9).tag_table :='dev_testtags';

  FOR i IN 1 .. tag_list.count LOOP
    EXECUTE IMMEDIATE '
      MERGE INTO '||sections(tag_list(i).entity_type).tag_table
      ||' ccv USING (select :ref_nkid as ref_nkid, :tag_id as tag_id, :entity as entity
               , :deleted as deleted
               , :status as status
               FROM DUAL) n
          ON (ccv.ref_nkid = n.ref_nkid and ccv.tag_id = n.tag_id)
        WHEN MATCHED
        THEN UPDATE
            SET ccv.status = n.status
            DELETE WHERE n.deleted = 1
        WHEN NOT MATCHED
        THEN INSERT
            ( ref_nkid, tag_id, entered_by, status)
        VALUES
            (:iref_nkid, :itag_id, :ientered_By, :istatus)'
      USING tag_list(i).ref_nkid,
            tag_list(i).tag_id,
            tag_list(i).entity_type,
            tag_list(i).deleted,
            tag_list(i).status,
            tag_list(i).ref_nkid,
            tag_list(i).tag_id,
            tag_list(i).entered_by,
            tag_list(i).status;
  end loop;

  -- CRAPP-1775
  -- Non-specified error. It is either success or fail.
  EXCEPTION
  WHEN TIMEOUT_ON_RESOURCE THEN
    errlogger.report_and_stop (SQLCODE,'Tag table locked');
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Modifying tag failed');


end;
/