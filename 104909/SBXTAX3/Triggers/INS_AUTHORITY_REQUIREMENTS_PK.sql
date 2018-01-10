CREATE OR REPLACE TRIGGER sbxtax3.ins_authority_requirements_pk
 BEFORE
  INSERT
 ON sbxtax3.tb_authority_requirements
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.authority_requirement_id IS NULL) THEN
        :new.authority_requirement_id := pk_authority_requirements.nextval;
    END IF;
END;
/