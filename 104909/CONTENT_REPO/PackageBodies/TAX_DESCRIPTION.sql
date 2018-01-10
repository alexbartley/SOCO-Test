CREATE OR REPLACE PACKAGE BODY content_repo."TAX_DESCRIPTION"
IS

   PROCEDURE create_record (
    pk_o OUT NUMBER,
    transaction_type_id_i IN NUMBER,
    taxation_type_id_i IN NUMBER,
    spec_app_type_id_i IN NUMBER,
    entered_by_i IN NUMBER
    )
    IS
    l_tran_type_id NUMBER := transaction_type_id_i;
    l_tax_type_id NUMBER := taxation_type_id_i;
    l_spec_app_type_id NUMBER := spec_app_type_id_i;
    l_entered_by NUMBER := entered_by_i;
   BEGIN

        INSERT INTO tax_descriptions(name, transaction_type_id, taxation_type_id, spec_applicability_type_id, entered_by)
        VALUES (l_tran_type_id||l_tax_type_id||l_spec_app_type_id, l_tran_type_id, l_tax_type_id, l_spec_app_type_id, l_entered_by) RETURNING id INTO pk_o;
   EXCEPTION
      WHEN OTHERS THEN
          ROLLBACK;
          errlogger.report_and_stop(SQLCODE,SQLERRM);
   END create_record;

    FUNCTION find (
    transaction_type_id_i IN NUMBER,
    taxation_type_id_i IN NUMBER,
    spec_app_type_id_i IN NUMBER
    )
    RETURN NUMBER
    IS
        l_tax_desc_id NUMBER := NULL;
    BEGIN
        SELECT id
        INTO l_tax_desc_id
        FROM tax_descriptions
        WHERE transaction_type_id = NVL(transaction_type_id_i,-1)
        AND taxation_type_id = NVL(taxation_type_id_i,-1)
        AND spec_applicability_type_id = NVL(spec_app_type_id_i,-1);
    RETURN l_tax_desc_id;
    EXCEPTION
      WHEN no_data_found THEN
            RETURN l_tax_desc_id;
      WHEN OTHERS THEN
          ROLLBACK;
          errlogger.report_and_stop(SQLCODE,SQLERRM);
    END find;
END tax_description;
/