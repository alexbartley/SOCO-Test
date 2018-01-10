CREATE OR REPLACE TRIGGER sbxtax.ins_a_authority_types
    BEFORE INSERT
    ON sbxtax.tb_authority_types
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
BEGIN
    INSERT INTO a_authority_types (authority_type_id,
                                   merchant_id,
                                   name,
                                   description,
                                   created_by,
                                   creation_date,
                                   last_updated_by,
                                   last_update_date,
                                   synchronization_timestamp,
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
            :new.synchronization_timestamp,
            'CREATED',
            SYSDATE);
END;
/