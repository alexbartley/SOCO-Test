CREATE OR REPLACE TRIGGER sbxtax4.del_a_authority_types
    BEFORE DELETE
    ON sbxtax4.tb_authority_types
    REFERENCING NEW AS new OLD AS old
    FOR EACH ROW
BEGIN
    INSERT INTO a_authority_types (authority_type_id_o,
                                   merchant_id_o,
                                   name_o,
                                   description_o,
                                   created_by_o,
                                   creation_date_o,
                                   last_updated_by_o,
                                   last_update_date_o,
                                   synchronization_timestamp_o,
                                   change_type,
                                   change_date)
    VALUES (:old.authority_type_id,
            :old.merchant_id,
            :old.name,
            :old.description,
            :old.created_by,
            :old.creation_date,
            :old.last_updated_by,
            :old.last_update_date,
            :old.synchronization_timestamp,
            'DELETED',
            SYSDATE);
END;
/