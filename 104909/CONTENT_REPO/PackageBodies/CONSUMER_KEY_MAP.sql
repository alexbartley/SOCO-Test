CREATE OR REPLACE PACKAGE BODY content_repo."CONSUMER_KEY_MAP"
IS
    FUNCTION get_ckm(consumer_i IN VARCHAR2, CR_Entity_i IN VARCHAR2, Table_i IN VARCHAR2, Field_i IN VARCHAR2) RETURN NUMBER
    IS
        l_ret_val NUMBEr;
    BEGIN
        BEGIN
            select id
            into l_ret_val
            from consumer_key_mapping
            where upper(consumer_tag) = upper(consumer_i)
            and upper(cr_entity) = upper(cr_entity_i)
            and upper(table_name) = upper(table_i)
            and upper(field) = upper(field_i);
        EXCEPTION WHEN no_data_found THEN
            l_ret_val := NULL;
        END;
        RETURN l_ret_val;
    END get_ckm;

    FUNCTION get_key(consumer_i IN VARCHAR2, CR_Entity_i IN VARCHAR2, CR_NKID_i IN NUMBER, Table_i IN VARCHAR2, Field_i IN VARCHAR2) RETURN VARCHAR2
    IS
        l_ckm_id NUMBER;
        l_ret_val VARCHAR2(256) := NULL;
    BEGIN
        l_ckm_id := get_ckm(consumer_i, CR_Entity_i,Table_i, Field_i);
        BEGIN
            execute immediate 'select consumer_value from ckm_'||lpad(l_ckm_id,4,'0')||' where cr_nkid = '||cr_nkid_i into l_ret_val;
        EXCEPTION WHEN no_data_found THEN
            l_ret_val := NULL;
        END;
        RETURN l_ret_val;
    END get_key;

    PROCEDURE set_key(consumer_i IN VARCHAR2, CR_Entity_i IN VARCHAR2,Table_i IN VARCHAR2, Field_i IN VARCHAR2, CR_NKID_i IN NUMBER, consumer_value_i IN VARCHAR2)
    IS
        l_ckm_id NUMBER;
    BEGIN
        l_ckm_id := get_ckm(consumer_i, CR_Entity_i,Table_i, Field_i);
        execute immediate 'insert into ckm_'||lpad(l_ckm_id,4,'0')||' (consumer_value, cr_nkid) values ('''||consumer_value_i||''','||cr_nkid_i||')';
        commit;
    END set_key;

    PROCEDURE register_type(consumer_i IN VARCHAR2,Table_i IN VARCHAR2, Field_i IN VARCHAR2, CR_Entity_i IN VARCHAR2)
    IS
        l_ckm_id NUMBER;
    BEGIN
        l_ckm_id := get_ckm(consumer_i, CR_Entity_i,Table_i, Field_i);
        IF (l_ckm_id IS NULL) THEN
            insert into consumer_key_mapping(id,consumer_tag, table_name, field, cr_entity) values (pk_consumer_key_map.nextval,upper(consumer_i),upper(table_i),upper(field_i),upper(cr_entity_i))
                returning id INTO l_ckm_id;
            execute immediate 'create table ckm_'||lpad(l_ckm_id,4,'0')||' (consumer_value varchar2(250) not null, cr_nkid number not null) ';
        END IF;
    END register_Type;
END;
/