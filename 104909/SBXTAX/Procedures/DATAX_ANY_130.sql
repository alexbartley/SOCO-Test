CREATE OR REPLACE PROCEDURE sbxtax."DATAX_ANY_130"
   (runId IN OUT NUMBER)
   IS
   --<data_check id="130" name="Check for Invalid Characters" >
   dataCheckId NUMBER := -711;
   vlocal_step varchar2(100);
   err_num number;
   err_msg varchar2(4000);

BEGIN

    vlocal_step := 'DATAX_ANY_130 STEP 0';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_130 started.',runId) RETURNING run_id INTO runId;
    COMMIT;

    vlocal_step := 'DATAX_ANY_130 STEP 1';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT pc.product_category_id, dataCheckId, runId, SYSDATE
    from tb_product_categories pc
    where (length(CONVERT(pc.name, 'AL32UTF8', 'WE8MSWIN1252'))  > 100 or
                 length(CONVERT(pc.description, 'AL32UTF8', 'WE8MSWIN1252'))  > 250)
    );

    vlocal_step := 'DATAX_ANY_130 STEP 2';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT pc.product_category_id, dataCheckId, runId, SYSDATE
    FROM tb_product_categories pc
    WHERE pc.name LIKE '%"%');

    vlocal_step := 'DATAX_ANY_130 STEP 3';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    from tb_zones z
    where (length(CONVERT(z.name, 'AL32UTF8', 'WE8MSWIN1252'))  > 50)
    );

    vlocal_step := 'DATAX_ANY_130 STEP 4';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT z.zone_id, dataCheckId, runId, SYSDATE
    FROM tb_zones z
    WHERE z.name LIKE '%"%');

    vlocal_step := 'DATAX_ANY_130 STEP 5';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    from tb_authorities a
    where (length(CONVERT(a.name, 'AL32UTF8', 'WE8MSWIN1252'))  > 100)
    );

    vlocal_step := 'DATAX_ANY_130 STEP 6';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT a.authority_id, dataCheckId, runId, SYSDATE
    FROM tb_authorities a
    WHERE a.name LIKE '%"%');

    vlocal_step := 'DATAX_ANY_130 STEP 7';
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT r.rule_id, dataCheckId, runId, SYSDATE
    from tb_rules r
    where (length(CONVERT(r.invoice_description, 'AL32UTF8', 'WE8MSWIN1252'))  > 100)
    );

    vlocal_step := 'DATAX_ANY_130 STEP 8';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_ANY_130 finished.',runId);
    COMMIT;

EXCEPTION
WHEN OTHERS THEN
      err_num := SQLCODE;
      err_msg := SUBSTR(SQLERRM, 1, 4000);

    INSERT INTO data_check_err_log(dataCheckId, runId, errcode, errmsg, step_number, entered_date, entered_by)
    VALUES( dataCheckId, runId, err_num, err_msg, vlocal_step, SYSDATE, -1);
    COMMIT;

END;



/