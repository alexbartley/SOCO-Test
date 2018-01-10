CREATE OR REPLACE TRIGGER content_repo.ins_juris_type_revisions
 BEFORE
  INSERT
 ON content_repo.jurisdiction_type_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_juris_type_revisions.nextval;
END IF;
:new.id := pk_juris_type_revisions.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;


INSERT INTO tdr_etl_entity_status ( entity, nkid, rid)
VALUES (
        'JURISDICTION_TYPE',
        :new.nkid,
        :new.id
        );

END;
/