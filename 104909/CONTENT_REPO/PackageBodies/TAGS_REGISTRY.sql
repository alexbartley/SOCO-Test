CREATE OR REPLACE PACKAGE BODY content_repo."TAGS_REGISTRY"
IS

   PROCEDURE logTagAction(paction IN NUMBER, entity IN NUMBER, tag_id IN NUMBER,
                          nkid IN NUMBER DEFAULT NULL, refId IN NUMBER,
                          entered_by IN number)
   IS
   BEGIN
     INSERT INTO tag_log(entity, entered_by, tag_action, tag_id, nkid, refId)
     values(entity, entered_by, decode(paction,0,'DELETE',1,'INSERT','*OTHER'), tag_id, nkid, refId);
   END logTagAction;

  PROCEDURE addTag
    ( id IN NUMBER DEFAULT NULL,
      nkid IN NUMBER DEFAULT NULL,
      tag_id IN NUMBER,
      entered_by IN NUMBER,
      entity IN NUMBER,
      status OUT number)
  IS
    --
    sTbl varchar2(36);
    sQ CLOB :='Insert Into <<table_name>>(ref_nkid, tag_id, entered_by)
               values( :ref_nkid, :tag_id, :entered_by )';
    recordSet tags%ROWTYPE;
   BEGIN
    CASE entity
    WHEN 7
        THEN
        Insert Into attachment_tags(attachment_id, tag_id, entered_by) VALUES
        (id, tag_id, entered_by);
    WHEN 8
        THEN
        Insert Into research_source_tags(research_source_id, tag_id, entered_by) VALUES
        (id, tag_id, entered_by);
    ELSE
        SELECT t.tbl_name INTO sTbl FROM tag_entities_t t
        WHERE t.cid = entity;
        sQ:=REGEXP_REPLACE(sQ,'<<table_name>>', sTbl);
        dbms_output.put_line(sQ);
        EXECUTE IMMEDIATE sQ USING nkid, tag_id, entered_by;
    END CASE;
    status:=1;
   EXCEPTION
        WHEN OTHERS
        THEN
            status:=0;
            ROLLBACK;
            RAISE;
   END addTag;

   -- --------------------------------------------------------------------------
   -- Remove Tag
   --
   PROCEDURE removeTag(id IN NUMBER DEFAULT NULL,
      nkid IN NUMBER DEFAULT NULL,
      tag_id IN varchar2,
      entered_by IN NUMBER,
      entity IN NUMBER,
      status OUT number)
   IS
     --
     sTbl varchar2(36);
     sQ CLOB :='Delete From <<table_name>> Where
                   ref_nkid = :ref_nkid
                 and tag_id ';
                 --(:tag_id)';
     srchI varchar2(64);
   BEGIN
      IF REGEXP_COUNT(tag_id, ',', 1, 'i') > 0 THEN
         srchI := ' IN('||tag_id||')';
      ELSE
         srchI :=' = '||tag_id;
      END IF;

    CASE entity
    WHEN 7
        THEN
        EXECUTE IMMEDIATE 'DELETE FROM attachment_tags
                           WHERE attachment_id = :id
                           AND tag_id = to_number(:tag_id)'
                           USING id, tag_id;
    WHEN 8
        THEN
        EXECUTE IMMEDIATE 'DELETE FROM research_source_tags
                           WHERE research_source_id = :id
                           AND tag_id = to_number(:tag_id)'
                           USING id, tag_id;
    ELSE
        SELECT t.tbl_name INTO sTbl FROM tag_entities_t t
        WHERE t.cid = entity;
        -- build delete here
        sQ:=REGEXP_REPLACE(sQ,'<<table_name>>', sTbl);
        sQ:=sQ||srchI;

DBMS_OUTPUT.Put_Line( sQ );

        EXECUTE IMMEDIATE sQ USING nkid;
    END CASE;
    status:=1;
   EXCEPTION
        WHEN OTHERS
        THEN
            status:=0;
            ROLLBACK;
            RAISE;
   END removeTag;

-- 5/29/2014: ToDo need to build a list from the tags (now sent as a , sep list)
  /* 4/30: added autonomous_transaction for debug purposes (duplicate tags causing issues) */
  PROCEDURE tags_entry (tag_list in xmlform_tags_tt, ref_nkid in number)
  is
    PRAGMA autonomous_transaction;
    TYPE sectionRecord IS RECORD
    (tag_table varchar2(32));
    TYPE sectionTable IS TABLE OF sectionRecord; -- INDEX BY BINARY_INTEGER;
    sections sectionTable;

  begin
    -- (could be generic table data)
    DBMS_OUTPUT.Put_Line( 'ref_nkid:'||ref_nkid );

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
    sections(9).tag_table :='ref_group_tags';
    sections.extend();
    sections(10).tag_table :='geo_polygon_tags';
    sections.extend();
    sections(11).tag_table :='geo_unique_area_tags';
    -- Changes for CRAPP-2871
    sections.extend();
    sections(12).tag_table :='juris_type_tags';

    FOR i IN 1 .. tag_list.count LOOP
        DBMS_OUTPUT.Put_Line( 'tag_list(i).tag_id:'||tag_list(i).tag_id );
        dbms_output.put_line('sections(tag_list(i).entity_type).tag_table '||sections(tag_list(i).entity_type).tag_table);
      if tag_list(i).tag_id is not null then
      EXECUTE IMMEDIATE '
      MERGE INTO '||sections(tag_list(i).entity_type).tag_table
      ||' ccv USING (select distinct :ref_nkid as ref_nkid, :tag_id as tag_id, :entity as entity
               , :deleted as deleted
               , :status as status
               FROM DUAL) n
          ON (ccv.ref_nkid = n.ref_nkid and ccv.tag_id = n.tag_id)
        WHEN MATCHED
        THEN UPDATE
            SET ccv.status = n.status
        WHEN NOT MATCHED
        THEN INSERT
            ( ref_nkid, tag_id, entered_by, status)
        VALUES
            (:iref_nkid, :itag_id, :ientered_By, :istatus)'
      USING ref_nkid,
            tag_list(i).tag_id,
            tag_list(i).entity_type,
            tag_list(i).deleted,
            tag_list(i).status,
            ref_nkid,
            tag_list(i).tag_id,
            tag_list(i).entered_by,
            tag_list(i).status;

        -- Fix in ORA 12c DeLETE/MERGE - 11.1 bug/looks like same bug in 11.2
        -- Oracle Database 12c Enterprise Edition Release 12.1.0.1.0
        if tag_list(i).deleted = 1 then
           execute immediate 'DELETE from '||sections(tag_list(i).entity_type).tag_table
                           ||' WHERE ref_nkid = :ref_nkid AND tag_id = :tag_id'
           using tag_list(i).ref_nkid, tag_list(i).tag_id;
        end if;

      end if;

    end loop;
    commit;

  end tags_entry;

END tags_registry;
/