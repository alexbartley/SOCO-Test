CREATE OR REPLACE PACKAGE content_repo."CONSUMER_KEY_MAP"
  IS
    FUNCTION get_key(consumer_i IN VARCHAR2, CR_Entity_i IN VARCHAR2, CR_NKID_i IN NUMBER, Table_i IN VARCHAR2, Field_i IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE set_key(consumer_i IN VARCHAR2, CR_Entity_i IN VARCHAR2,Table_i IN VARCHAR2, Field_i IN VARCHAR2, CR_NKID_i IN NUMBER, consumer_value_i IN VARCHAR2);
    PROCEDURE register_type(consumer_i IN VARCHAR2,Table_i IN VARCHAR2, Field_i IN VARCHAR2, CR_Entity_i IN VARCHAR2);

    /*

    create table consumer_key_mapping (
        id number not null,
        consumer_tag varchar2(250) not null,
        table_name varchar2(30) not null,
        field varchar2(128) not null,
        cr_entity varchar2(128) not null);
    CREATE SEQUENCE pk_consumer_key_map
      INCREMENT BY 1
      START WITH 1
      NOCYCLE
      NOCACHE;
*/
END CONSUMER_KEY_MAP;
/