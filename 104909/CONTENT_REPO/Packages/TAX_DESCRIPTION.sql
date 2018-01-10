CREATE OR REPLACE PACKAGE content_repo."TAX_DESCRIPTION"
  IS
   PROCEDURE create_record (
    pk_o OUT NUMBER,
    transaction_type_id_i IN NUMBER,
    taxation_type_id_i IN NUMBER,
    spec_app_type_id_i IN NUMBER,
    entered_by_i IN NUMBER
    );

   FUNCTION find (
    transaction_type_id_i IN NUMBER,
    taxation_type_id_i IN NUMBER,
    spec_app_type_id_i IN NUMBER
    )
     RETURN  NUMBER;

END; -- Package spec

 
 
/