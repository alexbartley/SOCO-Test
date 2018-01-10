CREATE OR REPLACE TRIGGER sbxtax4.upd_a_authority_types
    AFTER UPDATE OF merchant_id, name, description
    ON sbxtax4.tb_authority_types
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
     WHEN ( (  DECODE (new.merchant_id, old.merchant_id, 0, 1)
            + DECODE (new.name, old.name, 0, 1)
            + DECODE (new.description, old.description, 0, 1)) > 0) BEGIN
    INSERT INTO a_authority_types (authority_type_id,
                                   merchant_id,
                                   name,
                                   description,
                                   created_by,
                                   creation_date,
                                   last_updated_by,
                                   last_update_date,
                                   authority_type_id_o,
                                   merchant_id_o,
                                   name_o,
                                   description_o,
                                   created_by_o,
                                   creation_date_o,
                                   last_updated_by_o,
                                   last_update_date_o,
                                   change_type,
                                   change_date)
    VALUES (:new.authority_type_id,
            :new.merchant_id,
            :new.name,
            :new.description,
            :new.created_by,
            :new.creation_date,
            :new.last_updated_by,
            :new.last_update_date,
            :old.authority_type_id,
            :old.merchant_id,
            :old.name,
            :old.description,
            :old.created_by,
            :old.creation_date,
            :old.last_updated_by,
            :old.last_update_date,
            'UPDATED',
            SYSDATE);
END;
/