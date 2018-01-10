CREATE OR REPLACE PACKAGE BODY sbxtax.det_update
IS
/*

Date            Author            Comments
----------------------------------------------------------------------------------------------------------
11/01/2017      PMR               All GIS references have been removed from regular ETL processing,
                                  moved to GIS_ETL.

*/
    g_tdp varchar2(100) := 'Sabrix US Tax Data';

    PROCEDURE log_failure(ex_i IN VARCHAR2, table_name_i IN VARCHAR2, pk_i IN NUMBER, cause_i IN VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        --NULL;
        INSERT INTO etl_update_log (id, log_time, table_name, primary_key, cause, error)
        VALUES (pk_etl_update_log.nextval, SYSTIMESTAMP, table_name_i, pk_i, cause_i, ex_i);
        commit;
    END log_failure;

    PROCEDURE set_loaded_date(entity_name_i varchar2)
    IS
    BEGIN
        etl_proc_log_p('DET_UPDATE.SET_LOADED_DATE','Setting loaded date for the entity '||entity_name_i,upper(entity_name_i),NULL,NULL);
        IF entity_name_i = 'RATES'
        THEN
            UPDATE extract_log
               SET loaded = SYSDATE
             WHERE     entity = 'TAX' AND loaded is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_tb_rates
                                       UNION
                                       SELECT nkid, rid from tdr_etl_tb_rate_tiers);
        ELSIF entity_name_i = 'AUTHORITIES'
        THEN
            UPDATE extract_log
               SET loaded = SYSDATE
             WHERE     entity = 'JURISDICTION' AND loaded is null
                   AND (nkid, rid) IN (SELECT nkid, rid
                                         FROM tdr_etl_tb_authorities);
        ELSIF entity_name_i = 'RULES'
        THEN
            UPDATE extract_log
               SET loaded = SYSDATE
             WHERE     entity = 'TAXABILITY' AND loaded is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_tb_rules
                                       UNION
                                       SELECT nkid, rid FROM tdr_etl_tb_rule_qualifiers);
        ELSIF entity_name_i = 'PRODUCTS'
        THEN
            UPDATE extract_log
               SET loaded = SYSDATE
             WHERE     entity = 'COMMODITY' AND loaded is null
                   AND (nkid, rid) IN (SELECT nkid, rid
                                         FROM tdr_etl_ct_product_tree);
        ELSIF entity_name_i = 'REFERENCE GROUP'
        THEN
            UPDATE extract_log
               SET loaded = SYSDATE
             WHERE     entity = 'REFERENCE GROUP' AND loaded is null
                   AND (nkid, rid) IN (SELECT nkid, rid FROM tdr_etl_tb_reference_lists
                                       UNION
                                       SELECT nkid, rid FROM tdr_etl_tb_reference_values);
        END IF;
        etl_proc_log_p('DET_UPDATE.SET_LOADED_DATE','Loaded date has been set for  '||entity_name_i,upper(entity_name_i),NULL,NULL);

        COMMIT;
    END;

    PROCEDURE truncate_tmp_table(entity_name_i in varchar2)
    IS
    BEGIN
        if entity_name_i = 'RATES' then
            execute immediate 'truncate table tdr_etl_tb_rates';
            execute immediate 'truncate table tdr_etl_tb_rate_tiers';
        elsif entity_name_i = 'RULES' then
            execute immediate 'truncate table tdr_etl_tb_rules';
            execute immediate 'truncate table tdr_etl_tb_rule_qualifiers';
        elsif entity_name_i = 'PRODUCTS' then
            execute immediate 'truncate table tdr_etl_ct_product_tree';
        elsif entity_name_i = 'AUTHORITIES' then
            execute immediate 'truncate table tdr_etl_tb_authorities';
            execute immediate 'truncate table tdr_etl_tb_contributing_auths';
            execute immediate 'truncate table tdr_etl_tb_auth_logic_groups';
            execute immediate 'truncate table tdr_etl_tb_auth_logic_mapping';
            execute immediate 'truncate table tdr_etl_tb_auth_messages';
        elsif entity_name_i = 'REFERENCE GROUP' then
            execute immediate 'truncate table tdr_etl_tb_reference_lists';
            execute immediate 'truncate table tdr_etl_tb_reference_values';
        end if;
    END;

    PROCEDURE update_auth_logic_mapping(
        algx_id_i IN NUMBER,
        auth_id_i IN NUMBER,
        auth_logic_group_id_i IN NUMBER,
        start_date_i IN DATE,
        end_date_i IN DATE,
        proc_order_i IN NUMBER
        )
    IS
        l_exists NUMBER;
        l_record tb_Authority_logic_group_xref%rowtype;
        l_current_action VARCHAR2(500) := 'initializing';
    BEGIN

        IF (algx_id_i IS NULL) THEN
            l_record.authority_logic_group_xref_id := pk_algx_id.nextval;
            l_record.authority_id := auth_id_i;
            l_record.authority_logic_group_id := auth_logic_group_id_i;
            l_record.start_date := start_date_i;
            l_record.end_date := end_date_i;
            l_record.process_order := proc_order_i;
            l_record.creation_date := SYSDATE;
            l_record.last_update_date := SYSDATE;
            l_record.created_by := -1703;
            l_record.last_updated_by := -1703;
            l_current_action := 'creating new Authority Logic Group Mapping';
            INSERT INTO tb_authority_logic_group_xref VALUES l_record;
        ELSE
            l_current_action := 'updating Authority Logic Group Mapping';
            l_record.authority_logic_group_xref_id := algx_id_i;
            UPDATE tb_authority_logic_group_xref
            SET end_date = end_date_i,
            process_order = proc_order_i
            WHERE authority_logic_group_xref_id = algx_id_i;
        END IF;
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_AUTHORITY_LOGIC_GROUP_XREF', l_record.authority_logic_group_xref_id, l_current_action);
RAISE_APPLICATION_ERROR(-20002,'Authority logic mapping failed.');
    END update_auth_logic_mapping;

    PROCEDURE pvw_auth_logic_mapping(
        algx_id_i IN NUMBER,
        auth_id_i IN NUMBER,
        auth_uuid_i IN VARCHAR2,
        auth_logic_group_id_i IN NUMBER,
        start_date_i IN DATE,
        end_date_i IN DATE,
        proc_order_i IN NUMBER
        )
    IS
        l_record pvw_tb_auth_logic_groups_xref%rowtype;
    BEGIN
        l_record.authority_logic_group_xref_id := algx_id_i;
        l_record.authority_id := auth_id_i;
        l_record.authority_uuid := auth_uuid_i;
        l_record.authority_logic_group_id := auth_logic_group_id_i;
        l_record.start_date := start_date_i;
        l_record.end_date := end_date_i;
        l_record.process_order := proc_order_i;
        INSERT INTO pvw_tb_auth_logic_groups_xref VALUES l_record;

    END pvw_auth_logic_mapping;

    PROCEDURE pvw_contributing_auths(
        cont_auth_id_i IN NUMBER,
        auth_id_i IN NUMBER,
        auth_uuid_i IN VARCHAR2,
        this_auth_id_i IN NUMBER,
        this_auth_uuid_i IN VARCHAR2,
        start_date_i IN DATE,
        end_date_i IN DATE
        )
    IS
        l_record PVW_TB_CONTRIBUTING_AUTHS%rowtype;
    BEGIN
        l_record.contributing_Authority_id := cont_auth_id_i;
        l_record.authority_id := auth_id_i;
        l_record.authority_uuid := auth_uuid_i;
        l_record.this_authority_id := this_auth_id_i;
        l_record.this_authority_uuid := this_auth_uuid_i;
        l_record.start_date := start_date_i;
        l_record.end_date := end_date_i;
        l_record.basis_percent := 1;
        INSERT INTO PVW_TB_CONTRIBUTING_AUTHS VALUES l_record;

    END pvw_contributing_auths;

    PROCEDURE compare_authority_logic(make_changes_i IN NUMBER)
    IS
    CURSOR mmt_diffs IS
    SELECT DISTINCT
        authority_uuid,
        authority_logic_group_id,
        start_date,
        end_date,
        process_order
    FROM tdr_etl_tb_auth_logic_mapping
    MINUS
    SELECT
        a.uuid,
        x.authority_logic_group_id,
        x.start_date,
        x.end_date,
        x.process_order
    FROM tb_authority_logic_group_xref x
    JOIN tb_authorities a ON (a.authority_id = x.authority_id);
    l_auth_id NUMBER;
    l_algx_id NUMBER;
    l_record tb_authority_logic_group_xref%rowtype;
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.COMPARE_AUTHORITY_LOGIC','comparing Authority Logic Mapping, make_changes='||make_changes_i,'AUTHORITY LOGIC MAPPING',null,null);
        execute immediate 'truncate table pvw_tb_auth_logic_groups_xref';
        FOR d IN mmt_diffs LOOP <<mmt>>
            SELECT MAX(authority_id)
            INTO l_auth_id
            FROM tb_authorities
            WHERE uuid = d.authority_uuid;

            SELECT MAX(authority_logic_group_xref_id)
            INTO l_algx_id
            FROM tb_authority_logic_group_xref x
            WHERE x.authority_id = l_auth_id
            AND x.authority_logic_group_id = d.authority_logic_group_id
            AND x.start_Date = d.start_Date;

            IF (make_changes_i = 1) THEN
                --FOR d IN mmt_diffs LOOP <<mmt>>
                    update_Auth_logic_mapping(
                        l_algx_id,
                        l_auth_id,
                        d.authority_logic_group_id,
                        d.start_Date,
                        d.end_date,
                        d.process_order);
                --END LOOP mmt;
                --commit;
                -- execute immediate 'truncate table tdr_etl_tb_auth_logic_groups';
            ELSE
                --FOR d IN mmt_diffs LOOP <<mmt>>
                    pvw_Auth_logic_mapping(
                        l_algx_id,
                        l_auth_id,
                        d.authority_uuid,
                        d.authority_logic_group_id,
                        d.start_Date,
                        d.end_date,
                        d.process_order);
               --     commit;
               -- END LOOP mmt;

            END IF;

        END LOOP mmt;
        COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Compare authority logic timeout.');
    when others then
    RAISE_APPLICATION_ERROR(-20002,'Compare authority logic error.');


    END compare_authority_logic;

    PROCEDURE update_auth_messages(
        auth_id_i IN number,
        xerr_id in number,
        error_num IN varchar2,
        error_severity in varchar2,
        title in varchar2,
        description in varchar2
        )
    IS
        l_exists NUMBER;
        l_record tb_app_errors%rowtype;
        l_current_action VARCHAR2(500) := 'initializing';
    BEGIN

        IF (xerr_id IS NULL) THEN
            l_record.error_id := pk_amsgx_id.nextval;
            l_record.error_num := error_num;
            l_record.error_severity := error_severity;
            l_record.title := title;
            l_record.description := description;
            l_record.cause:=title;
            l_record.action:=title;
            l_record.created_by := -1703;
            l_record.creation_date := SYSDATE;
            l_record.last_update_date := SYSDATE;
            l_record.last_updated_by := -1703;
            l_record.category := 'JURISDICTION DETERMINATION';
            l_record.merchant_id := -1;
            l_record.authority_id := auth_id_i;

            l_current_action := 'creating new Authority Message';
            INSERT INTO tb_app_errors VALUES l_record;
        ELSE
            l_current_action := 'updating Authority Message';
            l_record.error_id := xerr_id;
            -- view data for test
            UPDATE tb_app_errors
            SET
            error_severity = l_record.error_severity,
            title = l_record.title,
            cause = l_record.cause,
            action = l_record.action,
            description = l_record.description,
            error_num = l_record.error_num,
            last_update_date = sysdate,
            last_updated_by = -1703
            WHERE error_id = xerr_id;
        END IF;
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_APP_ERRORS', l_record.error_id, l_current_action);
        RAISE_APPLICATION_ERROR(-20002,'Authority messages failed.');
    END update_auth_messages;


    PROCEDURE compare_authority_message(make_changes_i IN NUMBER)
    IS
    CURSOR mmt_diffs IS
    SELECT DISTINCT
        authority_uuid,
        error_num,
        error_severity,
        title,
        description
    FROM tdr_etl_tb_auth_messages
    MINUS
    SELECT
        a.uuid,
        x.error_num,
        x.error_severity,
        x.title,
        x.description
    FROM tb_app_errors x
    JOIN tb_authorities a ON (a.authority_id = x.authority_id);
    --ref: select * from tb_app_errors

    l_auth_id NUMBER;
    l_algx_id NUMBER;
    l_record tb_app_errors%rowtype;
    BEGIN
      INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
      VALUES ('DET_UPDATE.COMPARE_AUTHORITY_MESSAGES','comparing Authority Logic Messages, make_changes='||make_changes_i,'AUTHORITY MESSAGES',null,null);
      IF (make_changes_i = 1) THEN
      FOR d IN mmt_diffs LOOP <<mmt>>
          SELECT MAX(authority_id)
          INTO l_auth_id
          FROM tb_authorities
          WHERE uuid = d.authority_uuid;

            -- null or update record
            -- what are the changes that CAN be made from the UI?
            -- title? description + code? severity?
            SELECT MAX(error_id)
              INTO l_algx_id
            FROM tb_app_errors x
            WHERE x.authority_id = l_auth_id
            AND x.error_num = d.error_num;
            --AND x.title = d.title;

          update_auth_messages(
              l_auth_id,
              l_algx_id,
              d.error_num,
              d.error_severity,
              d.title,
              d.description
          );
      END LOOP mmt;
      COMMIT;
      END IF;

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Compare authority messages timeout.');
    when others then
    RAISE_APPLICATION_ERROR(-20002,'Compare authority messages error.');

    END compare_authority_message;

    PROCEDURE update_contributing_Auth
        (cont_auth_id_i IN NUMBER, auth_id_i IN NUMBER, this_auth_id_i IN NUMBER, start_Date_i IN DATE, end_date_i IN DATE) IS
        l_current_action VARCHAR2(500) := 'initializing';
        l_record tb_contributing_authorities%rowtype;
    BEGIN

        l_record.merchant_id := merchant_id(g_tdp);
        l_record.authority_id := auth_id_i;
        l_record.this_authority_id := this_auth_id_i;
        l_record.basis_percent := 1; -- crapp-3239
        l_record.start_date := start_Date_i;
        l_record.end_date := end_date_i;
        l_record.last_update_date := sysdate;
        l_record.creation_date := sysdate;
        l_record.last_updated_by := -1703;
        l_record.created_by := -1703;
        l_current_action := 'creating new Contributing Authority';
        IF (cont_auth_id_i IS NULL) THEN

            l_record.contributing_authority_id := pk_tb_contributing_auths.nextval; -- crapp-2172

            INSERT INTO tb_contributing_authorities VALUES l_record;

        ELSE
            l_current_action := 'updating Contributing Authority';
            l_record.contributing_authority_id := cont_auth_id_i;
            UPDATE tb_contributing_authorities
            SET end_date = end_Date_i,
                last_update_date = sysdate,
                last_updated_by = -1703
                --creation_date = sysdate,
                --created_by = -1703
            where contributing_authority_id = cont_auth_id_i;
        END IF;
        -- COMMIT;
    EXCEPTION    WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_CONTRIBUTING_AUTHORITIES', l_record.contributing_authority_id, l_current_action);
    RAISE_APPLICATION_ERROR(-20001,'Conributing auth error.');
        --RAISE;
    END update_contributing_Auth;

    PROCEDURE pvw_rule (
        rule_id_i IN NUMBER,
        auth_id_i IN NUMBER,
        auth_uuid_i IN VARCHAR2,
        rule_order_i IN VARCHAR2,
        calc_method_i IN NUMBER,
        rate_code_i IN VARCHAR2,
        exempt_i IN VARCHAR2,
        no_tax_i IN VARCHAR2,
        prod_cat_id_i IN NUMBER,
        inp_rec_per_i IN NUMBER,
        basis_percent_i IN NUMBER,
        start_date_i IN DATE,
        end_date_i IN DATE,
        tax_code_i IN VARCHAR2,
        tax_type_i IN VARCHAR2,
        is_local_i IN VARCHAR2,
        inv_desc_i IN VARCHAR2,
        allocated_charge IN VARCHAR2,
        related_charge IN VARCHAR2,
        unit_of_measure IN VARCHAR2,
        input_recovery_amount  IN NUMBER
    )
    IS
        l_record pvw_tb_rules%rowtype;
    BEGIN
            l_record.rule_id := rule_id_i;
            l_record.authority_id := auth_id_i;
            l_record.authority_uuid := auth_uuid_i;
            l_record.rule_order := rule_order_i;
            l_record.rate_code := rate_code_i;
            l_record.calculation_method := calc_method_i;
            l_record.exempt := exempt_i;
            l_record.no_tax := no_tax_i;
            l_record.product_category_id := prod_cat_id_i;
            l_record.input_recovery_percent := inp_rec_per_i;
            l_record.basis_percent := basis_percent_i;
            l_record.start_date := start_date_i;
            l_Record.end_Date := end_date_i;
            l_record.code := tax_code_i;
            l_record.tax_type := tax_type_i;
            l_record.is_local := is_local_i;
            l_record.invoice_Description := inv_desc_i;
            l_record.allocated_charge := allocated_charge;
            l_record.related_charge := related_charge;
            l_record.unit_of_measure := unit_of_measure;
            l_record.input_recovery_amount := input_recovery_amount;

            INSERT INTO pvw_tb_rules VALUES l_record;
           -- COMMIT;
    END pvw_rule;

    PROCEDURE pvw_rule_qualifier (
        rule_id_i IN NUMBER,
        auth_i IN VARCHAR2,
        rule_order_i IN VARCHAR2,
        start_date_i IN DATE,
        end_date_i IN DATE,
        qualifier_type_i IN VARCHAR,
        element_i IN VARCHAR2,
        operator_i IN VARCHAR2,
        value_i IN VARCHAR2,
        qualified_auth_id_i IN NUMBER,
        qualified_auth_i IN VARCHAR2,
        ref_list_id_i IN NUMBER,
        ref_list_name_i IN VARCHAR2
    )
    IS
        l_record pvw_tb_rule_qualifiers%rowtype;
    BEGIN
        l_record.rule_id := rule_id_i;
        l_record.authority_id := qualified_auth_id_i;
        l_record.authority := qualified_auth_i;
        l_record.start_date := start_date_i;
        l_Record.end_Date := end_date_i;
        l_record.reference_list_id := ref_list_id_i;
        l_record.reference_list_name := ref_list_name_i;
        l_record.rule_qualifier_type := qualifier_type_i;
        l_record.element := element_i;
        l_record.value := value_i;
        l_record.operator := operator_i;
        l_record.rule_authority_uuid := auth_i;
        l_record.rule_order := rule_order_i;
        INSERT INTO pvw_tb_rule_qualifiers VALUES l_record;
        -- COMMIT;
    END pvw_rule_qualifier;



    FUNCTION update_rule (
        rule_id_i IN NUMBER,
        auth_id_i IN NUMBER,
        rule_order_i IN VARCHAR2,
        calc_method_i IN NUMBER,
        rate_code_i IN VARCHAR2,
        exempt_i IN VARCHAR2,
        no_tax_i IN VARCHAR2,
        prod_cat_id_i IN NUMBER,
        inp_rec_per_i IN NUMBER,
        basis_percent_i IN NUMBER,
        start_date_i IN DATE,
        end_date_i IN DATE,
        tax_code_i IN VARCHAR2,
        tax_type_i IN VARCHAR2,
        is_local_i IN VARCHAR2, -- Added is_local CRAPP-793 dlg
        inv_desc_i IN VARCHAR2,
        allocated_charge_i VARCHAR2,
        related_charge_i varchar2,
        unit_of_measure_i varchar2,
        input_recovery_amount_i number
    ) RETURN NUMBER
    IS
        l_record tb_rules%rowtype;
        l_current_action VARCHAR2(500) := 'initializing';

    BEGIN

        dbms_output.put_line('rule_id_i value is '||rule_id_i);

        IF (rule_id_i IS NULL) THEN

            l_record.rule_id := pk_tb_rules.nextval;    -- crapp-2172

            dbms_output.put_line('After sequence '||l_record.rule_id);

            l_record.authority_id := auth_id_i;
            l_record.rule_order := rule_order_i;
            l_record.rate_code := rate_code_i;
            l_record.calculation_method := calc_method_i;
            l_record.exempt := exempt_i;
            l_record.no_tax := no_tax_i;
            l_record.product_category_id := prod_cat_id_i;
            l_record.input_recovery_percent := inp_rec_per_i;
            l_record.basis_percent := basis_percent_i;
            l_record.start_date := start_date_i;
            l_Record.end_Date := end_date_i;
            l_record.code := tax_code_i;
            l_record.tax_type := tax_type_i;
            --l_record.is_dependent_product := 'N';
            l_record.created_by := -1703;
            l_record.creation_date := SYSDATE;
            l_record.last_updated_by := -1703;
            l_record.last_update_date := SYSDATE;
            l_record.merchant_id := merchant_id(g_tdp);
            l_record.is_local := is_local_i;    -- Added CRAPP-793 dlg
            l_record.invoice_Description := inv_desc_i;
            l_record.allocated_charge := allocated_charge_i;
            l_record.is_dependent_product := nvl(related_charge_i, 'N');
            l_record.input_recovery_amount := input_recovery_amount_i;
            l_record.unit_of_measure := unit_of_measure_i;
            l_current_action := 'creating new Rule';

            INSERT INTO tb_rules VALUES l_record;
            --map new rule to something?
            -- COMMIT;
        ELSE
            l_current_action := 'updating Rule';
            l_record.rule_id := rule_id_i;
            update tb_rules r
            SET rule_order = rule_order_i,
                rate_code = rate_code_i,
                calculation_method = calc_method_i,
                exempt = exempt_i,
                no_tax = no_tax_i,
                product_category_id = prod_cat_id_i,
                input_recovery_percent = inp_rec_per_i,
                basis_percent = basis_percent_i,
                start_date = start_date_i,
                end_Date = end_date_i,
                code = tax_code_i,
                tax_type = tax_type_i,
                invoice_Description = inv_desc_i,
                unit_of_measure = unit_of_measure_i,
                allocated_charge = allocated_charge_i,
                input_recovery_amount = input_recovery_amount_i,
                is_dependent_product = related_charge_i,
                last_updated_by = -1703,
                last_update_date = SYSDATE
                --is_local = is_local_i   -- Excluding from update CRAPP-793 dlg
            WHERE rule_id = rule_id_i;
        END IF;

        RETURN nvl(rule_id_i,l_record.rule_id);
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_RULES', l_record.rule_id, l_current_action||' (Authority_Id='||auth_id_i||' '||rule_order_i||')');
        RAISE_APPLICATION_ERROR(-20001,'TB Rules error.'||' (Authority_Id='||auth_id_i||' '||rule_order_i||')');

        --RAISE;
    END update_rule;


PROCEDURE update_rule_qualifier (
        rule_id_i IN NUMBER,
        start_date_i IN DATE,
        end_date_i IN DATE,
        qualifier_type_i IN VARCHAR,
        element_i IN VARCHAR2,
        operator_i IN VARCHAR2,
        value_i IN VARCHAR2,
        qualified_auth_id_i IN NUMBER,
        qualified_auth_i IN VARCHAR2,
        ref_list_id_i IN NUMBER,
        ref_list_name_i IN VARCHAR2
    )
    IS
        l_record tb_rule_qualifiers%rowtype;
        l_current_action VARCHAR2(500) := 'initializing';
        l_rq_id NUMBER;

    BEGIN

        SELECT min(rule_qualifier_id)
        INTO l_rq_id
        FROM tb_rule_qualifiers rq
        where rq.rule_id = rule_id_i
        and rq.element = element_i
        and rq.start_date = start_date_i;

        select max(reference_list_id)
        into l_record.reference_list_id
        from tb_reference_lists
        where name = ref_list_name_i;

        select max(authority_id)
        into l_record.authority_id
        from tb_authorities
        where uuid = qualified_auth_i; -- CRAPP-3040, the parameter getting is UUID and we are checking against name which is failing
        IF (l_rq_id IS NULL) THEN

            l_record.rule_qualifier_id := pk_tb_rule_qualifiers.nextval;  -- crapp-2172

            l_record.rule_id := rule_id_i;

            l_record.start_date := start_date_i;
            l_Record.end_Date := end_date_i;

            l_record.rule_qualifier_type := qualifier_type_i;
            l_record.element := element_i;
            l_record.value := value_i;
            l_record.operator := operator_i;
            l_record.created_by := -1703;
            l_record.creation_date := SYSDATE;
            l_record.last_updated_by := -1703;
            l_record.last_update_date := SYSDATE;
            l_current_action := 'creating new Rule Qualifier';
            INSERT INTO tb_rule_qualifiers VALUES l_record;
            --map new rule to something?
         --   COMMIT;
        ELSE
            l_current_action := 'updating Rule Qualifier';
            l_record.rule_qualifier_id := l_rq_id;
            update tb_rule_qualifiers
            SET
                operator = operator_i,
                value = value_i,
                start_date = start_Date_i,
                end_date = end_date_i,
                authority_id = l_record.authority_id,
                reference_list_id = l_record.reference_list_id,
                last_updated_by = -1703,
                last_update_date = SYSDATE
                --is_local = is_local_i   -- Excluding from update CRAPP-793 dlg
            WHERE rule_qualifier_id = l_rq_id;
        END IF;
        -- COMMIT;
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_RULE_QUALIFIERS', l_record.rule_qualifier_id, l_current_action||' (Rule Qualifier='||rule_id_i||' '||element_i||')');
    RAISE_APPLICATION_ERROR(-20002,'Rule error. '||l_current_action||' (Rule Qualifier='||rule_id_i||' '||element_i||')');


    END update_rule_qualifier;

   PROCEDURE compare_rules(make_changes_i IN NUMBER)
    IS
        CURSOR mmt_diffs IS
        SELECT distinct r.rule_id, a.authority_id, authority_uuid, rule_order, rate_code, exempt, no_tax, product_category_id,
                input_recovery_percent/100 input_recovery_percent, basis_percent/100 basis_percent, start_Date, end_date,
                code, case when rate_code is not null -- and NVL(tax_type,'xx') NOT IN ('RS', 'SA')  Changes for CRAPP-2726(removed not in check)
                           then tax_type end tax_type,
                calculation_method, nvl(is_local,'N') is_local, r.invoice_description,
                r.allocated_charge,
                r.related_charge, r.unit_of_measure, r.input_recovery_amount
                 -- Added is_local CRAPP-793 dlg
            from tdr_etl_tb_rules r -- CRAPP-3174, removed schema name
            join (
                select name, uuid, authority_id
                from tb_authorities
                union
                select name, authority_uuid, null authority_id
                from tdr_etl_tb_authorities a
                where not exists (
                    select 1
                    from tb_authorities a2
                    where a2.uuid = a.authority_uuid
                    )
                ) a
                on (a.uuid = r.authority_uuid)
        MINUS
        SELECT rule_id, a.authority_id, a.uuid, rule_order, rate_code, nvl(exempt,'N'), nvl(no_tax,'N') , NVL(product_category_id,12),
            nvl(input_recovery_percent,1), nvl(basis_percent,1), start_Date, end_date, code, tax_type, calculation_method, nvl(is_local,'N') is_local,
            r.invoice_description,
            r.allocated_charge, r.is_dependent_product, r.unit_of_measure, r.input_recovery_amount
        FROM tb_rules r
        join tb_authorities a on (a.authority_id = r.authority_id);

         cursor rq_mmt_diffs(auth_uuid_i IN VARCHAR2, rule_order_i IN NUMBER, start_date_i IN DATE) is
         select rq.authority_id, rq.authority, rq.element, rq.element_type, rq.value, rq.start_date, rq.end_Date,
            rq.operator, rq.reference_list_id, replace(replace(rq.reference_list_name,' (US Determination)'),' (INTL Determination)') reference_list_name,
             rq.rule_qualifier_type
         from tdr_etl_tb_rule_qualifiers rq
         where element NOT IN ('TAX_CODE','TAX_TYPE')
         and rq.rule_authority_uuid = auth_uuid_i
         and rq.rule_order = rule_order_i
         and rq.rule_start_date = start_date_i
         minus
         select rq.authority_id, rqa.uuid, rq.element, rq.element_type, rq.value, rq.start_date, rq.end_Date, rq.operator,
            rq.reference_list_id, rl.name, rq.rule_qualifier_type
         from tb_rule_qualifiers rq
         join tb_rules r on (r.rule_id = rq.rule_id)
         join tb_authorities a on (a.authority_id = r.authority_id)
         left outer join tb_authorities rqa on (rqa.authority_id = nvl(rq.authority_id,-1))
         left outer join tb_reference_lists rl on (rl.reference_list_id = nvl(rq.reference_list_id,-1))
         where a.uuid = auth_uuid_i
         and r.rule_order = rule_order_i
         and r.start_date = start_date_i;

        cursor just_qualifiers is
        WITH s
         AS (SELECT DISTINCT r.rule_id,
                             a.authority_id,
                             authority_uuid,
                             rule_order,
                             start_date
               FROM tdr_etl_tb_rules r  -- CRAPP-3174, removed schema name
                    JOIN
                    (SELECT name, uuid, authority_id
                       FROM tb_authorities
                     UNION
                     SELECT name, authority_uuid, NULL authority_id
                       FROM tdr_etl_tb_authorities a
                      WHERE NOT EXISTS
                                (SELECT 1
                                   FROM tb_authorities a2
                                  WHERE a2.uuid = a.authority_uuid)) a
                        ON (a.uuid = r.authority_uuid))
        SELECT distinct
               rq.rule_order,
               rq.rule_id,
               rq.authority_id,
               rq.authority,
               rq.element,
               rq.element_type,
               rq.VALUE,
               rq.start_date,
               rq.end_date,
               rq.operator,
               rq.reference_list_id,
               REPLACE (REPLACE (rq.reference_list_name, ' (US Determination)'),
                        ' (INTL Determination)')
                   reference_list_name,
               rq.rule_qualifier_type
          FROM tdr_etl_tb_rule_qualifiers rq  -- CRAPP-3174, removed schema name
               JOIN s
                   ON (    rq.rule_authority_uuid = s.authority_uuid
                       AND rq.rule_order = s.rule_order
                       AND rq.rule_start_date = s.start_date)
         WHERE element NOT IN ('TAX_CODE', 'TAX_TYPE') AND rq.rule_id IS NOT NULL
        MINUS
        SELECT r.rule_order,
               rq.rule_id,
               rq.authority_id,
               rqa.uuid,
               rq.element,
               rq.element_type,
               rq.VALUE,
               rq.start_date,
               rq.end_date,
               rq.operator,
               rq.reference_list_id,
               rl.name,
               rq.rule_qualifier_type
          FROM tb_rule_qualifiers rq
               JOIN tb_rules r ON (r.rule_id = rq.rule_id)
               JOIN tb_authorities a ON (a.authority_id = r.authority_id)
               LEFT OUTER JOIN tb_authorities rqa
                   ON (rqa.authority_id = NVL (rq.authority_id, -1))
               LEFT OUTER JOIN tb_reference_lists rl
                   ON (rl.reference_list_id = NVL (rq.reference_list_id, -1))
               JOIN s
                   ON (    a.uuid = s.authority_uuid
                       AND r.rule_order = s.rule_order
                       AND r.start_date = s.start_date);
         l_rule_id number;
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.COMPARE_RULES','comparing Rules, make_changes='||make_changes_i,'RULE',null,null);
        execute immediate 'truncate table pvw_tb_rules';
        execute immediate 'truncate table pvw_tb_rule_qualifiers';
        IF (make_changes_i = 1) THEN
            FOR r IN mmt_diffs LOOP <<mmt>>

                dbms_output.put_line('calling update rule ');
                l_rule_id := update_rule(r.rule_id, r.authority_id, r.rule_order, r.calculation_method, r.rate_code, r.exempt, r.no_tax, r.product_category_id,
                r.input_recovery_percent, r.basis_percent, r.start_Date, r.end_date, r.code, r.tax_type, r.is_local, r.invoice_description,
                r.allocated_charge, r.related_charge, r.unit_of_measure, r.input_recovery_amount
                );
                dbms_output.put_line('after update rule');
                for rq in rq_mmt_diffs(r.authority_uuid, r.rule_order, r.start_date) loop
                    update_rule_qualifier(l_rule_id,rq.start_date,rq.end_date,
                    rq.rule_qualifier_type,rq.element,rq.operator,rq.value,rq.authority_id,rq.authority,rq.reference_list_id,rq.reference_list_name);
                end loop;
                --commit;
            END LOOP mmt;
            FOR i in just_qualifiers loop <<qual>>
                update_rule_qualifier(i.rule_id, i.start_date, i.end_date,
                    i.rule_qualifier_type,i.element,i.operator,i.value,i.authority_id,i.authority,i.reference_list_id,i.reference_list_name);
            END loop;

        ELSE
            FOR r IN mmt_diffs LOOP <<mmt>>

                pvw_rule(r.rule_id, r.authority_id, r.authority_uuid, r.rule_order, r.calculation_method, r.rate_code, r.exempt, r.no_tax, r.product_category_id,
                r.input_recovery_percent, r.basis_percent, r.start_Date, r.end_date, r.code, r.tax_type, r.is_local, r.invoice_description,
                r.allocated_charge, r.related_charge, r.unit_of_measure, r.input_recovery_amount
                );  -- Added is_local CRAPP-793 dlg
                for rq in rq_mmt_diffs(r.authority_uuid, r.rule_order, r.start_date) loop
                    pvw_rule_qualifier(r.rule_id,r.authority_uuid, r.rule_order, rq.start_date,rq.end_date,
                    rq.rule_qualifier_type,rq.element,rq.operator,rq.value,rq.authority_id,rq.authority,rq.reference_list_id,rq.reference_list_name);
                end loop;
               -- commit;
            END LOOP mmt;
            FOR j in just_qualifiers loop <<qual>>
                pvw_rule_qualifier(j.rule_id,j.authority, j.rule_order, j.start_date,j.end_date,
                    j.rule_qualifier_type,j.element,j.operator,j.value,j.authority_id,j.authority,j.reference_list_id,j.reference_list_name);
            END loop;
        END IF;

        set_loaded_date('RULES');
        COMMIT;

    exception
    when others then
    RAISE_APPLICATION_ERROR(-20002,'Compare rules error.');

    END compare_rules;

    PROCEDURE compare_contributing_auths(make_changes_i IN NUMBER)
    IS
        CURSOR mmt_diffs IS
        SELECT distinct a.authority_id, ca.authority_uuid, ta.Authority_id this_authority_id, ca.this_authority_uuid, start_date, end_Date
            from tdr_etl_tb_contributing_auths ca
            left outer join tb_authorities a on (ca.authority_uuid = a.uuid)
            left outer join tb_authorities ta on (ca.this_authority_uuid = ta.uuid)
        MINUS
        SELECT ca.authority_id, a.uuid, this_authority_id, ta.uuid, start_date, end_Date
        FROM tb_contributing_Authorities ca
        join tb_authorities a on (ca.authority_id = a.authority_id)
         join tb_authorities ta on (ca.this_authority_id = ta.authority_id);
        l_cont_auth_id NUMBER;
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.COMPARE_CONTRIBUTING_AUTHS','comparing Contributing Authorities, make_changes='||make_changes_i,'CONTRIBUTING AUTHORITY',null,null);
        execute immediate 'truncate table pvw_tb_contributing_auths';
        FOR ca IN mmt_diffs LOOP <<mmt>>
            SELECT MAX(contributing_authority_id)
            INTO l_cont_auth_id
            FROM tb_contributing_authorities
            where authority_id = ca.authority_id
            and this_authority_id = ca.this_authority_id
            and start_date = ca.start_date;
            IF (make_changes_i = 1) THEN
                update_contributing_Auth(l_cont_auth_id, ca.authority_id, ca.this_authority_id, ca.start_Date, ca.end_date);
             --   commit;
                --execute immediate 'truncate table tdr_etl_tb_contributing_auths';
            ELSE
                pvw_contributing_Auths(l_cont_auth_id, ca.authority_id, ca.authority_uuid, ca.this_authority_id, ca.this_authority_uuid, ca.start_Date, ca.end_date);
               -- commit;

            END IF;
        END LOOP mmt;
        COMMIT;
    END compare_contributing_auths;

    PROCEDURE update_product_category (
        name_i IN VARCHAR2,
        description_i IN VARCHAR2,
        prodcode_i IN VARCHAR2,
        prod_cat_id_i IN NUMBER,
        comm_nkid_i IN NUMBER,
        prod_group_id_i IN NUMBER
        )
    IS
        l_record tb_product_categories%rowtype;
        l_current_action VARCHAR2(500) := 'initializing';
    BEGIN

        IF (prod_cat_id_i IS NULL) THEN

            l_record.product_category_id := pk_tb_product_categories.nextval;   -- crapp-2172

            l_record.parent_product_category_id := parent_product_category_id(comm_nkid_i);
            l_record.product_group_id := prod_group_id_i;
            l_record.name := name_i;
            l_record.description := description_i;
            l_record.prodcode := prodcode_i;
            l_record.created_by := -1703;
            l_record.creation_date := SYSDATE;
            l_record.last_updated_by := -1703;
            l_record.last_update_date := SYSDATE;
            l_record.merchant_id := merchant_id(g_tdp);
            l_current_action := 'creating new Product Category';
            INSERT INTO tb_product_categories VALUES l_record;
            INSERT INTO mp_comm_prods (commodity_nkid, product_category_id) VALUEs (comm_nkid_i, l_record.product_category_id);
        ELSE
            l_current_action := 'updating Product Category';
            l_record.product_category_id := prod_cat_id_i;
            update tb_product_categories
            SET name = name_i,
                description = description_i,
                prodcode = prodcode_i,
                last_updated_by = -1703,
                last_update_date = SYSDATE
            WHERE product_category_id = prod_cat_id_i;
        END IF;
    --    COMMIT;
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_PRODUCT_CATEGORIES', l_record.product_category_id, l_current_action||' ('||name_i||' '||prodcode_i||')');
    RAISE_APPLICATION_ERROR(-20002,'Update product category error.'||l_current_action||' ('||name_i||' '||prodcode_i||')');

    END update_product_category;

    PROCEDURE pvw_product_category (
        name_i IN VARCHAR2,
        description_i IN VARCHAR2,
        prodcode_i IN VARCHAR2,
        prod_cat_id_i IN NUMBER,
        comm_nkid_i IN NUMBER,
        prod_group_id_i IN NUMBER
        )
    IS
        l_record pvw_tb_product_categories%rowtype;
    BEGIN
            l_record.product_category_id := prod_cat_id_i;
            l_record.parent_product_category_id := parent_product_category_id(comm_nkid_i);
            l_record.product_group_id := prod_group_id_i;
            l_record.name := name_i;
            l_record.description := description_i;
            l_record.prodcode := prodcode_i;
            l_record.nkid := comm_nkid_i;
            INSERT INTO pvw_tb_product_categories VALUES l_record;
    END pvw_product_category;

PROCEDURE update_rate(
        rate_id_i IN NUMBER,
        authority_uuid_i VARCHAR2,
        rate_code_i VARCHAR2,
        start_date_i DATE,
        end_date_i DATE,
        rate_i NUMBER,
        split_type_i VARCHAR2,
        split_amount_type_i VARCHAR2,
        flat_fee_i NUMBER,
        currency_id_i NUMBER,
        is_local_i VARCHAR2,
        descr_i VARCHAR2        -- CRAPP-810 dlg
        )
    IS
        l_rate_id NUMBER := rate_id_i;
        l_authority_id NUMBER;
       -- l_existing_count NUMBER;
        l_record tb_rates%rowtype;
        l_current_action VARCHAR2(500) := 'initializing';

    BEGIN

        SELECT a.authority_id
        INTO  l_authority_id
        FROM tb_authorities a
        WHERE a.uuid = authority_uuid_i;
        IF (l_rate_id is null) THEN
           -- l_record.rate_id := pk_tb_rates.nextval;
            l_record.rate_id := pk_tb_rates.nextval;    -- crapp-2172
        ELSE
            l_record.rate_id := l_rate_id;
        END IF;

        l_record.authority_id := l_authority_id;--
        l_record.merchant_id := merchant_id(g_tdp);--
        l_record.rate_code := rate_code_i;--
        l_record.start_date := start_date_i;--
        l_record.end_date := end_Date_i;
        l_record.rate := rate_i;
        l_record.is_local := is_local_i;
        l_record.split_type := split_type_i;
        l_record.split_amount_type := split_amount_type_i;
        l_record.flat_fee := flat_fee_i;
        l_record.currency_id := currency_id_i;
        l_record.creation_date := SYSDATE;
        l_record.last_update_date := SYSDATE;
        l_record.created_by := -1703;
        l_record.last_updated_by := -1703;
        l_record.unit_of_measure_code := 'each';
        l_record.description := SUBSTR(descr_i,1,100);        -- CRAPP-810 dlg

        IF (l_rate_id IS NULL) THEN
            l_current_action := 'creating new Rate';
            INSERT INTO tb_rates
            VALUES l_record;

            -- 09/14/16 CRAPP-3029, added JURIS_NKID and CREATION_DATE
            INSERT INTO mp_tax_rate (tax_nkid, outline_nkid, rate_id, juris_nkid, creation_date)
            (
             SELECT distinct jti.nkid tax_nkid, tou.nkid outline_nkid, l_record.rate_id, j.nkid juris_nkid, SYSDATE creation_date
             FROM content_repo.jurisdictions j
                -- 09/12/2016 CRAPP-3016 Added nkid join to remove duplciate authority mapping for rates
                join mp_juris_auths ja on (ja.authority_uuid = authority_uuid_i and j.nkid = ja.nkid)
                join content_repo.mv_juris_tax_impositions jti on (jti.jurisdiction_id = j.id)
                join content_repo.mv_tax_outlines tou on (tou.juris_tax_imposition_id = jti.id and tou.start_date = l_record.start_Date)
             where ((l_record.is_local = 'N' and  upper(jti.reference_Code) not like '%(LOCAL)%')
                    or
                   (l_record.is_local = 'Y' and upper(jti.reference_Code) like '%(LOCAL)%')
                   )
                   and replace(upper(jti.reference_Code),' (LOCAL)') = l_record.rate_Code
            );
        ELSE
            l_current_action := 'updating Rate';
            l_record.rate_id := l_rate_id;
            UPDATE tb_rates
            SET end_date = end_date_i,
                start_date = start_Date_i,
                split_type = split_type_i,
                split_amount_type = split_amount_type_i,
                flat_fee = flat_fee_i,
                rate = rate_i,
                currency_id = currency_id_i,
                description = SUBSTR(descr_i,1,100),          -- CRAPP-810 dlg
                last_updated_by = -1703,
                last_update_date = SYSDATE
            WHERE rate_id = l_rate_id;
        --ELSE
          --  NULL;
            --There are too many matches, why? (Cascading would be the only valid option)
            --Raise or log error. Which?
        END IF;
      --  COMMIT;
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_RATES', l_record.rate_id, l_current_action||' (Authority_UUID='||authority_uuid_i||' '||rate_Code_i||')');
    RAISE_APPLICATION_ERROR(-20002,'Update rates error.'||l_current_action||' (Authority_UUID='||authority_uuid_i||' '||rate_Code_i||')');
--        RAISE;
    END update_rate;

    PROCEDURE update_authority(
        auth_name_i IN VARCHAR2,
        auth_type_id_i IN NUMBER,
        loc_code_i IN VARCHAR2,
        off_name_i IN VARCHAR2,
        auth_category_i IN VARCHAR2,
        desc_i IN VARCHAR2,
        admin_zone_level_i IN NUMBER,
        eff_zone_level_i IN NUMBER,
        auth_uuid_i IN VARCHAR2,
        content_type_i IN VARCHAR2,
        erp_tax_code_i IN VARCHAR2,
        prod_group_id_i IN NUMBER,
        reg_mask_i IN VARCHAR2
        )
    IS
        l_exists NUMBER;
        l_authority_id NUMBER;
        l_record tb_Authorities%rowtype;
        l_no_tax NUMBER;
        l_current_action varchar2(500) := 'initializing';
        l_rule_id number;
    BEGIN
        l_record.name := auth_name_i;
        l_record.authority_type_id := auth_type_id_i;
        l_record.location_code := loc_code_i;
        l_record.official_name := off_name_i;
        l_record.authority_category := auth_category_i;
        l_record.description := desc_i;
        l_record.admin_zone_level_id := admin_zone_level_i;
        l_record.effective_zone_level_id := eff_zone_level_i;
        l_record.product_group_id := prod_group_id_i;
        l_record.registration_mask := reg_mask_i;
        l_record.merchant_id := merchant_id(g_tdp);
        l_record.uuid := auth_uuid_i;
        l_record.creation_date := SYSDATE;
        l_record.last_update_date := SYSDATE;
        l_record.created_by := -1703;
        l_record.last_updated_by := -1703;
        l_record.is_custom_authority := 'N';
        l_record.is_template := 'N';
        l_record.content_type := content_type_i;
        l_record.erp_tax_code := erp_tax_code_i;

        SELECT max(authority_id)
        INTO l_authority_id
        FROM tb_authorities
        WHERE uuid = auth_uuid_i;

        SELECT COUNT(*)
        INTO l_no_tax
        FROM tb_authority_types
        where authority_type_id = l_record.authority_type_id
        and name in (
            'Business and Occupation',
            'City Food/Beverage',
            'County Food/Beverage',
            'District Food/Beverage',
            'Gross Receipts',
            'License Tax',
            'Service Tax',
            'State Food/Beverage',
            'Surcharge',
            'Telecom',
            'Utility Users'
        );

        IF (l_authority_id IS NULL) THEN
            l_current_action := 'creating new Authority';

            l_record.authority_id := pk_tb_authorities.nextval; -- crapp-2172

            INSERT INTO tb_Authorities VALUES l_record;
            IF (g_tdp = 'Sabrix US Tax Data') THEN
            l_current_action := 'creating new Authority; creating NL Rate';
            update_rate(NULL,auth_uuid_i,'NL','01-Jan-2000',NULL,0,NULL,NULL, NULL,NULL,'N','No Liability');

            l_current_action := 'creating new Authority; creating NL Rule';
            l_rule_id := update_rule (NULL,l_record.authority_id,5000,1,'NL','N','N',NULL,1,1,'01-Jan-2000',NULL,NULL,'NL','N','No Liability', null, null, null, null);

                IF (l_no_tax > 0) THEN
                    l_rule_id :=update_rule (NULL,l_record.authority_id,10000,1,null,'N','Y',NULL,1,1,'01-Jan-2000',NULL,NULL,NULL,'N','No Tax', null, null, null, null);
                END IF;
            END IF;
        ELSE
            l_current_action := 'updating Authority';
            l_record.authority_id := l_authority_id;
            UPDATE tb_authorities a
            SET
                a.name = auth_name_i,--auth_name(d.official_name),
                a.authority_Type_id = auth_type_id_i,
                a.location_code = loc_code_i,
                a.official_name = off_name_i,
                a.authority_category = auth_Category_i,
                a.description = desc_i,
                a.admin_zone_level_id = admin_zone_level_i,
                a.effective_zone_level_id = eff_zone_level_i,
                a.erp_tax_code = erp_tax_code_i,
                a.last_updated_by = -1703,
                a.last_update_date = SYSDATE
            WHERE a.uuid = auth_uuid_i;
        END IF;
        -- COMMIT;
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_AUTHORITIES', l_record.authority_id, l_current_action||' ('||auth_name_i||')');
    RAISE_APPLICATION_ERROR(-20001,'Update authority error.'||l_current_action||' ('||auth_name_i||')');
--        RAISE;
    END update_authority;

    PROCEDURE compare_products(prod_group_id_i IN NUMBER, make_changes_i IN NUMBER)
    IS
        -- 10/24/2014 - dlg - applied SUBSTR to columns
        CURSOR mmt_diffs(prod_group_name_i IN VARCHAR2, level_i IN NUMBER) IS
        SELECT SUBSTR(pt.NAME, 1, 100) name, pt.nkid, cp.product_category_id,
            SUBSTR(pt.product_1_name, 1, 100) product_1_name, SUBSTR(pt.product_2_name, 1, 100) product_2_name,
            SUBSTR(pt.product_3_name, 1, 100) product_3_name, SUBSTR(pt.product_4_name, 1, 100) product_4_name,
            SUBSTR(pt.product_5_name, 1, 100) product_5_name, SUBSTR(pt.product_6_name, 1, 100) product_6_name,
            SUBSTR(pt.product_7_name, 1, 100) product_7_name, SUBSTR(pt.product_8_name, 1, 100) product_8_name,
            SUBSTR(pt.product_9_name, 1, 100) product_9_name, SUBSTR(pt.prodcode, 1, 50) prodcode,
            SUBSTR(pt.description, 1, 250) description
        FROM tdr_etl_ct_product_tree pt
        left outer join mp_comm_prods cp on (cp.commodity_nkid = pt.nkid)
        WHERE length(sort_key)/cr_extract.prod_level_token = level_i
            AND pt.product_tree = prod_group_name_i
        MINUS
        SELECT pc.name, cp.commodity_nkid, pc.product_category_id, pt.product_1_name, pt.product_2_name, pt.product_3_name, pt.product_4_name, pt.product_5_name,
            pt.product_6_name, pt.product_7_name, pt.product_8_name, pt.product_9_name,  pc.prodcode, pc.description
        FROM ct_product_tree pt
        JOIN tb_product_categories pc on (pc.product_category_id = pt.primary_key)
        JOIN mp_comm_prods cp on (cp.product_category_id = pc.product_category_id)
        WHERE pc.product_Group_id = prod_group_id_i;

        l_level number := 1;
        l_prod_group varchar2(50);
    BEGIN
        select name
        into l_prod_group
        from tb_product_groups
        where product_group_id = prod_group_id_i;

        SELECT max(length(sort_key))/cr_extract.prod_level_token
        into l_level
        from tdr_etl_ct_product_tree
        where length(sort_key) > 0
        and product_tree = l_prod_group;
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.COMPARE_PRODUCTS','comparing Product Categories, make_changes='||make_changes_i,'PRODUCT CATEGORY',null,null);
        execute immediate 'truncate table pvw_tb_product_categories';
        IF (l_level IS NOT NULL) THEN
            FOR l IN 1..l_level LOOP <<levels>>

                FOR r IN mmt_diffs(l_prod_group, l) LOOP <<mmt>>
                    IF (make_changes_i = 1) THEN
                    update_product_category(
                        coalesce(r.product_9_name,r.product_8_name,r.product_7_name,r.product_6_name,r.product_5_name,
                            r.product_4_name,r.product_3_name,r.product_2_name,r.product_1_name),
                        r.description,r.prodcode,r.product_category_id,r.nkid,prod_group_id_i);
                    --    commit;

                    ELSE
                        pvw_product_category (
                            coalesce(r.product_9_name,r.product_8_name,r.product_7_name,r.product_6_name,r.product_5_name,
                            r.product_4_name,r.product_3_name,r.product_2_name,r.product_1_name),
                                r.description,
                                r.prodcode,
                                r.product_category_id,
                                r.nkid,
                                prod_group_id_i
                                );
                    --    commit;
                    END IF;

                END LOOP mmt;
            END LOOP levels;
        END IF;
        IF (make_changes_i = 1) THEN
            ct_update_product_tree;
        END IF;

        set_loaded_date('PRODUCTS');

        COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Compare products timeout.');
    when others then
    RAISE_APPLICATION_ERROR(-20002,'Compare products error.'||sqlerrm);

    END compare_products;


    PROCEDURE update_reference_list(
        ref_group_nkid_i number,
        ref_list_id_i number,
        name_i VARCHAR2,
        start_date_i DATE,
        end_date_i DATE,
        descr_i VARCHAR2
        )
    IS
        l_record tb_reference_lists%rowtype;
        l_current_action varchar2(500) := 'initializing';
    BEGIN

        IF (ref_list_id_i IS NOT NULL) THEN
            l_current_action := 'updating Reference List';
            l_record.reference_list_id := ref_list_id_i;
            UPDATE tb_reference_lists
            SET name = name_i,
                start_date = start_date_i,
                end_Date = end_date_i,
                description = descr_i   -- CRAPP-809 dlg
            WHERE reference_list_id = ref_list_id_i;
        ELSE
            l_record.reference_list_id := pk_tb_reference_lists.nextval;    -- crapp-2172

            l_record.merchant_id := merchant_id(g_tdp);
            l_record.name := name_i;
            l_record.start_date := start_date_i;
            l_record.end_Date := end_date_i;
            l_record.last_updated_by := -1703;
            l_record.last_update_date := sysdate;
            l_record.created_by := -1703;
            l_record.creation_date := sysdate;
            l_record.description := descr_i;    -- CRAPP-809 dlg
            l_current_action := 'creating new Reference List';
            INSERT INTO tb_reference_lists VALUES l_record;

            INSERT INTO mp_ref_lists (ref_group_nkid, reference_list_id)
            VALUES (ref_group_nkid_i, l_record.reference_list_id);
        END IF;
        -- COMMIT;
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_REFERENCE_LISTS', l_record.reference_list_id, l_current_action||' ('||name_i||')');
    RAISE_APPLICATION_ERROR(-20002,'Update reference list error.'||l_current_action||' ('||name_i||')');

--        RAISE;
    END update_reference_list;

    PROCEDURE pvw_reference_list(
        ref_group_nkid_i number,
        ref_list_id_i number,
        name_i VARCHAR2,
        start_date_i DATE,
        end_date_i DATE,
        descr_i VARCHAR2
        )
    IS
        l_record pvw_tb_reference_lists%rowtype;
    BEGIN
        l_record.reference_list_id := ref_list_id_i;
        l_record.name := name_i;
        l_record.start_date := start_date_i;
        l_record.end_Date := end_date_i;
        l_record.ref_group_nkid := ref_group_nkid_i;
        l_record.description := descr_i;    -- CRAPP-809 dlg

        INSERT INTO pvw_tb_reference_lists VALUES l_record;
    END pvw_reference_list;

    PROCEDURE update_reference_value(
        reference_value_id_i number,
        ref_group_nkid_i number,
        value_i VARCHAR2,
        start_date_i DATE,
        end_date_i DATE,
        item_nkid_i number
        )
    IS
        l_ref_list_id number;
        l_Exists number := -1;
        l_record tb_reference_values%rowtype;
        l_current_action VARCHAR2(500):= 'initializing';
    BEGIN

        SELECT distinct reference_list_id
        INTO l_ref_list_id
        FROM mp_ref_lists
        WHERE ref_group_nkid = ref_group_nkid_i;

        IF reference_value_id_i is not null THEN
            l_current_action := 'updating Reference Value';
            l_record.reference_value_id := l_Exists;
            UPDATE tb_reference_values
               SET end_Date = end_date_i,
               value = value_i,
               start_date = start_date_i
            WHERE reference_value_id = reference_value_id_i;
        ELSE
            l_record.reference_value_id := pk_tb_reference_values.nextval;  -- crapp-2172

            l_record.reference_list_id := l_ref_list_id;
            l_record.value := value_i;
            l_record.start_date := start_date_i;
            l_record.end_Date := end_date_i;
            l_record.last_updated_by := -1703;
            l_record.last_update_date := sysdate;
            l_record.created_by := -1703;
            l_record.creation_date := sysdate;
            l_current_action := 'creating new Reference Value';
            insert into tb_reference_values values l_record;
            insert into mp_ref_values(ref_group_nkid, ref_item_nkid, ref_list_id, ref_value_id)
                values ( ref_group_nkid_i, item_nkid_i, l_record.reference_list_id, l_record.reference_value_id);
        END IF;

    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_REFERENCE_VALUES', l_record.reference_value_id, l_current_action||' ('||value_i||')');
    RAISE_APPLICATION_ERROR(-20002,'Update reference value error.'||l_current_action||' ('||value_i||')');
    END update_reference_value;

    PROCEDURE pvw_reference_value(
        ref_value_id_i IN NUMBER,
        ref_group_nkid_i IN number,
        ref_list_id_i IN NUMBER,
        value_i IN VARCHAR2,
        start_date_i IN DATE,
        end_date_i IN DATE
        )
    IS
        l_record pvw_tb_reference_values%rowtype;
    BEGIN
        dbms_output.put_line('ref_group_nkid_i value is '||ref_group_nkid_i);
        dbms_output.put_line('value_i value is '||value_i);
        l_record.reference_value_id := ref_group_nkid_i;
        l_record.ref_group_nkid := ref_group_nkid_i;
        l_record.reference_list_id := ref_list_id_i;
        l_record.value := value_i;
        l_record.start_date := start_date_i;
        l_record.end_Date := end_date_i;
        insert into pvw_tb_reference_values values l_record;
    END pvw_reference_value;

    PROCEDURE compare_reference_lists(make_changes_i IN NUMBER)
    IS
        CURSOR mmt_diffs IS
            SELECT rl.reference_list_id, rl.ref_group_nkid, case when g_tdp = 'Sabrix US Tax Data' then replace(rl.name,' (US Determination)') else rl.name end name,
                 rl.start_date, rl.end_date, rl.description
            FROM  tdr_etl_tb_reference_lists rl
            --LEFT OUTER JOIN mp_ref_lists mrl ON (mrl.ref_group_nkid = rl.ref_group_nkid)
            MINUS
            SELECT rl.reference_list_id, mrl.ref_group_nkid, name, start_date, end_Date, rl.description
            FROM  tb_reference_lists rl
            LEFT OUTER JOIN mp_ref_lists mrl ON (mrl.reference_list_id = rl.reference_list_id);

       CURSOR rv_mmt_diffs IS
            SELECT rl.reference_value_id, mrl.reference_list_id, rl.ref_group_nkid, rl.value, rl.start_date, rl.end_date, rl.item_nkid
            FROM tdr_etl_tb_reference_values rl
            LEFT OUTER join mp_ref_lists mrl ON (mrl.ref_group_nkid = rl.ref_group_nkid) -- CRAPP-803 dlg
            MINUS
            SELECT rv.reference_value_id, rv.reference_list_id, mr2.ref_group_nkid, value, start_date, end_Date, mr2.ref_item_nkid
            FROM  tb_reference_values rv
            LEFT OUTER JOIN mp_ref_values mr2 on (mr2.ref_value_id = rv.reference_value_id ); -- CRAPP-803 dlg
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.COMPARE_REFERENCE_LISTS','comparing Reference Lists, make_changes='||make_changes_i,'REFERENCE LIST',null,null);
        execute immediate 'truncate table pvw_tb_reference_lists';
        execute immediate 'truncate table pvw_tb_reference_values';
        IF (make_changes_i = 1) THEN
            FOR r IN mmt_diffs LOOP <<mmt>>
                update_reference_list(r.ref_group_nkid, r.reference_list_id, r.name, r.start_date, r.end_Date, r.description);
            END LOOP mmt;
            FOR rv IN rv_mmt_diffs LOOP <<mmt>>
                update_reference_value(rv.reference_value_id, rv.ref_group_nkid, rv.value, rv.start_date, rv.end_Date, rv.item_nkid);    -- CRAPP-803 dlg
            END LOOP mmt;

        ELSE
            FOR r IN mmt_diffs LOOP <<mmt>>
                pvw_reference_list(r.ref_group_nkid, r.reference_list_id, r.name, r.start_date, r.end_Date, r.description);
            END LOOP mmt;
            FOR rv IN rv_mmt_diffs LOOP <<mmt>>
                pvw_reference_value(rv.reference_value_id, rv.ref_group_nkid, rv.reference_list_id, rv.value, rv.start_date, rv.end_Date);
            END LOOP mmt;
        END IF;

        set_loaded_date('REFERENCE GROUP');

        COMMIT;
    END compare_reference_lists;

    PROCEDURE compare_reference_values(make_changes_i IN NUMBER)
    IS
    BEGIN
        NULL;
    END;

    PROCEDURE compare_authorities(make_changes_i IN NUMBER)
    IS
    CURSOR mmt_diffs IS
        SELECT
            nkid,
            authority_uuid,
            to_number(authority_type) authority_type,
            location_code,
            NVL(attr_official_name,official_name) official_name,   -- CRAPP_797 dlg
            authority_category,
            a.name,
            a.description,
            to_number(admin_zone_level) admin_zone_level,
            to_number(effective_zone_level) effective_zone_level,
            a.content_type,
            erp_Tax_code,
            null registration_mask,
            pg.product_group_id
        FROM tdr_etl_tb_authorities a
        left outer join tb_product_groups pg on (pg.name = a.ATTR_DEFAULT_PRODUCT_GROUP)
        WHERE authority_type IS NOT NULL
        MINUS
        SELECT
            ja.nkid,
            a.uuid,
            authority_type_id authority_type,
            location_code,
            official_name,
            authority_category,
            a.name,
            a.description,
            admin_zone_level_id admin_zone_level,
            effective_zone_level_id eff_zone_level,
            content_type,
            erp_tax_Code,
            null registration_mask,
            product_group_id
        FROM tb_authorities a
        --JOIN tb_authority_types aty ON (aty.authority_type_id = a.authority_type_id)
        --JOIN tb_zone_levels ezl ON (ezl.zone_level_id = a.effective_zone_level_id)
        --JOIN tb_zone_levels azl ON (azl.zone_level_id = a.admin_zone_level_id)
        JOIN mp_juris_auths ja ON (ja.authority_uuid = a.uuid);
        l_new_auth_uuid NUMBER;
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.COMPARE_AUTHORITIES','comparing Authorities, make_changes='||make_changes_i,'AUTHORITY',null,null);
        execute immediate 'truncate table pvw_tb_authorities';
        IF (make_changes_i = 1) THEN
            FOR d IN mmt_diffs LOOP <<mmt>>
                update_Authority(
                        d.name,
                        d.authority_type,
                        d.location_code,
                        d.official_name,
                        d.authority_category,
                        d.description,
                        d.admin_zone_level,
                        d.effective_zone_level,
                        d.authority_uuid,
                        d.content_type,
                        d.erp_tax_code,
                        d.product_group_id,
                        d.registration_mask
                        );
            END LOOP mmt;

        ELSE
            FOR d IN mmt_diffs LOOP <<mmt>>
                INSERT INTO pvw_tb_authorities(jurisdiction_nkid, name, authority_type_id, location_code, official_name,
                    authority_Category, description, admin_zone_level_id, effective_zone_level_id, uuid,
                    content_type, erp_tax_code, product_group_id, registration_mask) VALUES (
                        d.nkid,
                        d.name,
                        d.authority_type,
                        d.location_code,
                        d.official_name,
                        d.authority_category,
                        d.description,
                        d.admin_zone_level,
                        d.effective_zone_level,
                        d.authority_uuid,
                        d.content_type,
                        d.erp_tax_code,
                        d.product_group_id,
                        d.registration_mask);
            --    COMMIT;
            END LOOP mmt;
        END IF;
        compare_authority_logic(1);
        compare_authority_message(1);
        set_loaded_date('AUTHORITIES');

        COMMIT;
    END compare_authorities;

    PROCEDURE update_rate_tier(
        authority_uuid_i VARCHAR2,
        rate_code_i VARCHAR2,
        start_date_i DATE,
        amount_low_i NUMBER,
        amount_high_i NUMBER,
        rate_i NUMBER,
        ref_rate_code_i VARCHAR2,
        flat_fee_i NUMBER,
        is_local_i VARCHAR2
        )
    IS
        l_rate_tier_id NUMBER;
        l_rate_id NUMBER;
        l_existing_count NUMBER;
        l_record tb_rate_tiers%rowtype;
        l_current_action VARCHAR2(500) := 'initializing';
        l_authority_id number;

    BEGIN

        SELECT NVL(MAX(rate_tier_id),-1), MAX(r.rate_id), COUNT(*) ex_rec_count, max(a.authority_id)
        INTO l_rate_tier_id, l_rate_id, l_existing_count, l_authority_id
        FROM tb_rates r
        JOIN tb_authorities a on (a.authority_id = r.authority_id and a.uuid = authority_uuid_i)
        LEFT OUTER JOIN tb_rate_tiers rt ON (r.rate_id = rt.rate_id AND rt.amount_low = amount_low_i)
        WHERE r.rate_code = rate_code_i
        AND r.start_date = start_date_i
        and nvl(r.is_local,'N') = is_local_i;

        l_record.rate_tier_id := pk_tb_rate_tiers.nextval;  -- crapp-2172

        l_record.rate_id := l_rate_id;
        l_record.amount_low := amount_low_i;
        l_record.amount_high := amount_high_i;
        l_record.rate_code := ref_rate_code_i;
        l_record.rate := rate_i;
        l_record.flat_fee := flat_fee_i;
        l_record.creation_date := SYSDATE;
        l_record.last_update_date := SYSDATE;
        l_record.created_by := -1703;
        l_record.last_updated_by := -1703;
        IF (l_rate_tier_id = -1) THEN
            l_current_action := 'creating new Rate Tier';
            INSERT INTO tb_rate_tiers VALUES l_record;
        ELSIF (l_existing_count = 1) THEN
            l_current_action := 'updating Rate Tier';
            l_record.rate_tier_id := l_rate_tier_id;
            UPDATE tb_rate_tiers
            SET amount_high = amount_high_i,
                rate_code = ref_rate_code_i,
                rate = rate_i,
                flat_fee = flat_fee_i,
                last_updated_by = -1703,
                last_update_date = SYSDATE
            WHERE rate_tier_id = l_rate_tier_id;
        ELSE
            NULL;
            --There are too many matches, why? (Cascading would be the only valid option)
            --Raise or log error. Which?
        END IF;
        --Cleanup tiers if min_threshold/amount_low is changed
    EXCEPTION
        WHEN others THEN
        ROLLBACK;
        log_failure(SQLCODE||': '||SQLERRM, 'TB_RATE_TIERS', l_record.rate_tier_id, l_current_action||' (Authority_Id='||l_authority_id||' '||rate_Code_i||' '||amount_low_i||')');
    RAISE_APPLICATION_ERROR(-20002,'TB Rate tier error.'||l_current_action||' (Authority_Id='||l_authority_id||' '||rate_Code_i||' '||amount_low_i||')');
--        RAISE;
    END update_rate_tier;

PROCEDURE compare_rates(make_changes_i IN NUMBER) IS
        -- CRAPP-810 dlg (Add Description column)
        cursor rate_mmt_diffs is
            SELECT DISTINCT authority_uuid, rate_code, start_date, end_date, rate, split_type, split_amount_type,
                 flat_fee, currency_id, SUBSTR(description, 1, 100) description, nvl(is_local,'N') is_local, rate_id --NJV 10/31/2014 added NLV on is local
            FROM tdr_etl_tb_rates
            MINUS
            SELECT a.uuid, rate_code, start_date, end_date, rate, split_type, split_amount_type, case when nvl(flat_fee,-1) = 0 then null else flat_fee end,
                currency_id, r.description, nvl(r.is_local,'N') is_local, rate_id
            FROM tb_rates r
            JOIN tb_authorities a on (a.authority_id = r.authority_id);

        cursor rate_tier_mmt_diffs is
            SELECT DISTINCT authority_uuid, rate_code, start_date, amount_low, amount_high, rate, ref_rate_code, nvl(flat_fee,0)flat_fee, nvl(is_local,'N') is_local
            FROM tdr_etl_tb_rate_tiers
            --where (rate is not null or ref_rate_code is not null or flat_fee is not null)
            MINUS
            SELECT a.uuid, r2.rate_code, r2.start_date, amount_low, amount_high, rt2.rate, rt2.rate_code, nvl(rt2.flat_fee,0) flat_fee, nvl(is_local,'N') is_local
            FROM tb_rate_tiers rt2
            JOIN tb_rates r2 ON (r2.rate_id = rt2.rate_id)
            JOIN tb_authorities a on (a.authority_id = r2.authority_id);
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.COMPARE_RATES','comparing Rates, make_changes='||make_changes_i,'RATE',null,null);
        execute immediate 'truncate table pvw_tb_rates';
        execute immediate 'truncate table pvw_tb_rate_tiers';
        IF (make_changes_i = 1) THEN
            FOR r IN rate_mmt_diffs LOOP <<rmmt>>
                update_rate(r.rate_id, r.authority_uuid, r.rate_code, r.start_Date, r.end_date, r.rate, r.split_type, r.split_amount_type, r.flat_fee, r.currency_id, r.is_local, r.description);
             END LOOP rmmt;
            FOR rt IN rate_tier_mmt_diffs LOOP <<rtmmt>>
                update_rate_tier(rt.authority_uuid, rt.rate_code, rt.start_Date, rt.amount_low, rt.amount_high, rt.rate, rt.ref_rate_code, rt.flat_fee, rt.is_local);
            END LOOP rtmmt;

        ELSE
            FOR r IN rate_mmt_diffs LOOP <<rmmt>>
                insert into pvw_tb_rates values r;
               --- commit;
            END LOOP rmmt;
            FOR rt IN rate_tier_mmt_diffs LOOP <<rtmmt>>
                insert into pvw_tb_rate_tiers values rt;
                --commit;
            END LOOP rtmmt;
        END IF;

        set_loaded_date('RATES');

        COMMIT;

    END compare_rates;


    function merchant_id(name_i IN VARCHAR2) RETURN NUMBER
    IS
        l_ret Number := 0;
    BEGIN
        SELECT merchant_id
        INTO l_ret
        FROM tb_merchants
        WHERE name = name_i;
        RETURN l_ret;
    END merchant_id;

     function parent_product_category_id(commodity_nkid_i IN NUMBER) RETURN NUMBER
     IS
        l_ret NUMBER := NULL;
        l_comm_nkid NUMBER := commodity_nkid_i;
     BEGIN
        SELECT MAX(cp.product_category_id)
        INTO l_ret
        FROM mp_comm_prods cp
        WHERE cp.commodity_nkid = parent_commodity_nkid(l_comm_nkid);

        RETURN l_ret;

     END parent_product_category_id;

     function parent_commodity_nkid(commodity_nkid_i IN NUMBER) RETURN NUMBEr
     IS
        l_ret NUMBEr := -1;
     BEGIN
        SELECT distinct p.nkid -- Changes for CRAPP-2736
        INTO l_ret
        FROM (
            SELECT substr(h_code,1,length(h_code)-cr_extract.prod_level_token) parent_code, product_tree_short_name
            FROM content_repo.mvcommodities
            WHERE nkid = commodity_nkid_i
            and next_rid is null
            ) c
        JOIN content_repo.mvcommodities p ON (p.h_code = c.parent_code AND p.product_tree_short_name = c.product_tree_short_name);
        RETURN l_ret;
     END;
    /*
    FUNCTION get_zone_id(merch_id_i IN NUMBER , state_i IN VARCHAR2, county_i IN VARCHAR2, city_i IN VARCHAR2, postcode_i IN VARCHAR2, plus4_i IN VARCHAR)
    RETURN NUMBER
    IS
        l_ret NUMBER;
    BEGIN

        WITH ztree AS
            (
            SELECT zone_3_name,
                   coalesce(zone_7_id, zone_6_id, zone_5_id, zone_4_id, zone_3_id, zone_2_id) zone_id
            FROM   ct_zone_tree
            WHERE  zone_3_name = state_i
            AND nvl(zone_4_name,'ZONE_4_NAME') = nvl(county_i,'ZONE_4_NAME')
            AND nvl(zone_5_name,'ZONE_5_NAME') = nvl(city_i,'ZONE_5_NAME')
            AND nvl(zone_6_name,'ZONE_6_NAME') = nvl(postcode_i,'ZONE_6_NAME')
            AND nvl(zone_7_name,'ZONE_7_NAME') = nvl(plus4_i,'ZONE_7_NAME')
            AND merchant_id = merch_id_i
            ),
        changes AS
            (
            SELECT state, id
            FROM   tdr_etl_us_zone_changes zc
            WHERE  state = state_i
            AND nvl(county,'ZONE_4_NAME')   = nvl(county_i,'ZONE_4_NAME')
            AND nvl(city,'ZONE_5_NAME')     = nvl(city_i,'ZONE_5_NAME')
            AND nvl(postcode,'ZONE_6_NAME') = nvl(postcode_i,'ZONE_6_NAME')
            AND nvl(plus4,'ZONE_7_NAME')    = nvl(plus4_i,'ZONE_7_NAME')
            AND change_type = 'Add'
            ),
         changes2 AS
            (
            SELECT state, MAX(id) id
            FROM   tdr_etl_us_zone_changes zc
            WHERE  state = state_i
            AND nvl(county,'ZONE_4_NAME')   = nvl(county_i,'ZONE_4_NAME')
            AND nvl(city,'ZONE_5_NAME')     = nvl(city_i,'ZONE_5_NAME')
            AND nvl(postcode,'ZONE_6_NAME') = nvl(postcode_i,'ZONE_6_NAME')
            AND change_type = 'Add'
            GROUP BY state
            )
         SELECT COALESCE(Z1, Z2, Z3)
         INTO l_ret
         FROM (
                SELECT 'ztree' tbl, zone_id
                FROM ztree
                UNION
                SELECT 'changes' tbl, id
                FROM changes
                UNION
                SELECT 'changes2' tbl, id
                FROM changes2
              ) z pivot (MIN(zone_id) FOR tbl IN ('ztree' Z1, 'changes' Z2, 'changes2' Z3));

        l_ret := (l_ret||'.1'); -- 04/03/15 - moved decimal to end of number

        RETURN l_ret;
    END get_zone_id;

    PROCEDURE compare_zone_trees(make_changes_i IN NUMBER) IS  -- 05/31/17 - crapp-3636

        l_state          VARCHAR2(25 CHAR);
        l_jobstate       VARCHAR2(25 CHAR);
        l_merch_id       NUMBER;
        l_zone_auth_id   NUMBER;
        l_parent_zone_id NUMBER;
        l_created_by     NUMBER := -204;
        l_primary_key    NUMBER;
        l_zone_id        NUMBER;
        l_next_id        NUMBER;

        esql             VARCHAR2(50 CHAR);

        -- 01/27/16 crapp-2244 --
        l_msg            VARCHAR2(4000 CHAR);
        l_stcode         VARCHAR2(2 CHAR);
        l_auths          NUMBER := 0;

        TYPE t_pvw_tb_zones IS TABLE OF pvw_tb_zones%ROWTYPE;    -- 08/12/16 added for performance
        v_pvw_tb_zones t_pvw_tb_zones;

        CURSOR invalid_auths IS
            SELECT DISTINCT state_code, gis_name
            FROM   content_repo.gis_zone_juris_auths_tmp    -- crapp-3363
            ORDER BY gis_name;
        -------------------------

        CURSOR zone_deletes(state_i IN VARCHAR2) IS
            SELECT ctz.primary_key, ctz.merchant_id
            FROM   ct_zone_tree ctz
                JOIN (  SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   ct_zone_tree
                        WHERE  zone_3_name = state_i
                        MINUS
                        SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   tdr_etl_ct_zone_tree
                     ) d ON ctz.zone_3_name = d.state
                         AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                         AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                         AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                         AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                         AND ctz.merchant_id = d.merchant_id;

        CURSOR zone_updates(state_i IN VARCHAR2) IS
            SELECT primary_key, zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4,
                   code_2char, code_3char, code_fips, default_flag, terminator_flag, reverse_flag, range_min, range_max,
                   CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                        WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                   CASE WHEN zone_4_id IS NULL THEN zone_2_id WHEN zone_5_id IS NULL THEN zone_3_id WHEN zone_6_id IS NULL THEN zone_4_id
                        WHEN zone_7_id IS NULL THEN zone_5_id ELSE zone_6_id END parent_zone_id,
                   COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name) name, merchant_id
            FROM   tdr_etl_ct_zone_tree
            WHERE  primary_key IS NOT NULL
            MINUS
            SELECT primary_key, zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4,
                   code_2char, code_3char, code_fips, default_flag, terminator_flag, reverse_flag, range_min, range_max,
                   CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                        WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                   CASE WHEN zone_4_id IS NULL THEN zone_2_id WHEN zone_5_id IS NULL THEN zone_3_id WHEN zone_6_id IS NULL THEN zone_4_id
                        WHEN zone_7_id IS NULL THEN zone_5_id ELSE zone_6_id END parent_zone_id,
                   COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name), merchant_id
            FROM   ct_zone_tree
            WHERE  zone_3_name = state_i;

        CURSOR zone_adds IS
            SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4,
                   code_2char, code_3char, code_fips, default_flag, terminator_flag, reverse_flag, range_min, range_max,
                   CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                        WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                   COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name) name
            FROM   tdr_etl_ct_zone_tree a
            WHERE  primary_key IS NULL
                   AND NOT EXISTS (SELECT 1
                                   FROM   tdr_etl_ct_zone_tree u
                                   WHERE  a.zone_3_name = u.zone_3_name
                                          AND a.zone_4_name = u.zone_4_name
                                          AND NVL(a.zone_5_name, 'NULL zone5') = NVL(u.zone_5_name, 'NULL zone5')
                                          AND NVL(a.zone_6_name, 'NULL zone6') = NVL(u.zone_6_name, 'NULL zone6')
                                          AND NVL(a.zone_7_name, 'NULL zone7') = NVL(u.zone_7_name, 'NULL zone7')
                                          AND u.primary_key IS NOT NULL -- updates
                                  )
            ORDER BY zone_level_id DESC, a.zone_3_name, a.zone_4_name, a.zone_5_name, a.zone_6_name, a.code_fips;  -- added 08/20/15

        CURSOR zone_add_levels IS
            SELECT DISTINCT zone_level_id
            FROM (
                 SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode,
                        code_fips, zone_7_name plus4,
                        CASE WHEN zone_4_name IS NULL THEN -4 WHEN zone_5_name IS NULL THEN -5 WHEN zone_6_name IS NULL THEN -6
                             WHEN zone_7_name IS NULL THEN -7 ELSE -8 END zone_level_id,
                        COALESCE(zone_7_name,zone_6_name,zone_5_name,zone_4_name,zone_3_name) name
                 FROM   tdr_etl_ct_zone_tree a
                 WHERE  primary_key IS NULL
                        AND NOT EXISTS (SELECT 1
                                        FROM   tdr_etl_ct_zone_tree u
                                        WHERE  a.zone_3_name = u.zone_3_name
                                               AND a.zone_4_name = u.zone_4_name
                                               AND NVL(a.zone_5_name, 'NULL zone5') = NVL(u.zone_5_name, 'NULL zone5')
                                               AND NVL(a.zone_6_name, 'NULL zone6') = NVL(u.zone_6_name, 'NULL zone6')
                                               AND NVL(a.zone_7_name, 'NULL zone7') = NVL(u.zone_7_name, 'NULL zone7')
                                               AND u.primary_key IS NOT NULL -- updates
                                       )
                 )
            ORDER BY zone_level_id DESC;

        CURSOR zone_orphans IS
            SELECT z.zone_id, z.NAME, z.parent_zone_id, o.zone_id orig_zone_id, o.NAME orig_name, o.parent,  o.parent_fips
            FROM   tb_zones z
                JOIN ( SELECT zone_id, NAME, parent_zone_id, code_fips, SUBSTR(code_fips, 11, 5) parent, SUBSTR(code_fips, 1, 15) parent_fips
                       FROM   tb_zones
                       WHERE  zone_id IN ( SELECT z1.zone_id
                                           FROM   tb_zones z1
                                           WHERE  z1.name != 'WORLD'
                                                  AND NOT EXISTS (
                                                                  SELECT 1
                                                                  FROM   tb_zones z2
                                                                  WHERE  z2.zone_id = z1.parent_zone_id
                                                                         AND z2.merchant_id = z1.merchant_id
                                                                 )
                                         )
                     ) o ON z.NAME = o.parent
                            AND z.code_fips = o.parent_fips;

        CURSOR detaches(state_i IN VARCHAR2) IS
            SELECT ctz.primary_key, d.authority_id, d.authority_name
            FROM   ct_zone_tree ctz
                JOIN (
                        SELECT z.*, a.authority_id
                        FROM   (
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   ct_zone_authorities
                                WHERE  zone_3_name = state_i
                                MINUS
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   tdr_etl_ct_zone_authorities
                               ) z
                               LEFT JOIN tb_authorities a ON z.authority_name = a.NAME
                                                          AND z.merchant_id = a.merchant_id
                        WHERE  EXISTS (SELECT 1  -- 08/13/15 - added to check for records to detach
                                       FROM   tdr_etl_ct_zone_authorities
                                       WHERE  zone_3_name = state_i
                                      )
                     ) d ON ctz.zone_3_name = d.state
                         AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                         AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                         AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                         AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                         AND ctz.merchant_id = d.merchant_id
            UNION -- Exceptions if not found in ct_zone_tree
            SELECT ctz.primary_key, d.authority_id, d.authority_name
            FROM   ct_zone_authorities ctz
                JOIN (
                        SELECT z.*, a.authority_id
                        FROM   (
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   ct_zone_authorities
                                WHERE  zone_3_name = state_i
                                MINUS
                                SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                                       , authority_name, merchant_id
                                FROM   tdr_etl_ct_zone_authorities
                               ) z
                               LEFT JOIN tb_authorities a ON z.authority_name = a.NAME
                                                          AND z.merchant_id = a.merchant_id
                        WHERE  EXISTS (SELECT 1  -- 08/13/15 - added to check for records to detach
                                       FROM   tdr_etl_ct_zone_authorities
                                       WHERE  zone_3_name = state_i
                                      )
                     ) d ON ctz.zone_3_name = d.state
                         AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                         AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                         AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                         AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                         AND ctz.authority_name = d.authority_name;


        CURSOR attaches(state_i IN VARCHAR2) IS
            SELECT z.*, a.authority_id
            FROM   (
                    SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                           , authority_name, merchant_id
                    FROM   tdr_etl_ct_zone_authorities
                    MINUS
                    SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4
                           , authority_name, merchant_id
                    FROM   ct_zone_authorities
                    WHERE  zone_3_name = state_i
                   ) z
                   LEFT JOIN tb_authorities a ON z.authority_name = a.NAME
                                              AND z.merchant_id = a.merchant_id;

        CURSOR ids IS
            SELECT DISTINCT * FROM tdr_etl_us_zone_ids WHERE tbl_name = 'TB_ZONES';

    BEGIN
        SELECT merchant_id
        INTO l_merch_id
        FROM tb_merchants
        WHERE name = g_tdp;

        SELECT DISTINCT zone_3_name
        INTO l_state
        FROM tdr_etl_ct_zone_tree;

        -- 01/27/16 crapp-2244 --
        SELECT code
        INTO   l_stcode
        FROM   tb_states
        WHERE NAME = l_state;

        IF (make_changes_i = 1) THEN
            -- 04/09/15 -- Disable scheduled user jobs to refresh CT_ZONE_TREE and CT_ZONE_AUTHORITIES (runs every 15 minutes)

            LOOP    -- 12/02/15 crapp-2185
                SELECT state
                INTO   l_jobstate
                FROM   user_scheduler_jobs
                WHERE  job_name = 'UPDATE_CT_ZONE_TREE';

                EXIT WHEN l_jobstate IN ('SCHEDULED','DISABLED');
            END LOOP;
            dbms_scheduler.DISABLE('UPDATE_CT_ZONE_TREE');

            LOOP    -- 12/02/15 crapp-2185
                SELECT state
                INTO   l_jobstate
                FROM   user_scheduler_jobs
                WHERE  job_name = 'UPDATE_CT_ZONE_AUTHORITIES';

                EXIT WHEN l_jobstate IN ('SCHEDULED','DISABLED');
            END LOOP;
            dbms_scheduler.DISABLE('UPDATE_CT_ZONE_AUTHORITIES');
        ELSE
            EXECUTE IMMEDIATE 'TRUNCATE TABLE pvw_tb_zones DROP STORAGE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE pvw_tb_zone_authorities DROP STORAGE';
        END IF;

        -- Process Zone Authority Detaches
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Authority detaches - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);
        FOR d in detaches(l_state) LOOP <<detach_loop>>
            IF (make_changes_i = 1) THEN
                BEGIN
                    DELETE FROM tb_zone_authorities
                    WHERE  zone_id = d.primary_key
                           AND authority_id = d.authority_id;     -- added 04/09/15

                EXCEPTION WHEN no_data_found THEN
                    --if the Zone_ID or Authority_ID can't be found, delete whatever is in ct_zone_Authorities
                    DELETE FROM ct_zone_authorities
                    WHERE  primary_key = d.primary_key;
                END;
            ELSE
                BEGIN
                    INSERT INTO pvw_tb_zone_authorities (ZONE_ID, AUTHORITY_ID, AUTHORITY_NAME, STATE_CODE) -- 03/14/16 - crapp-2448 - Added State_Code
                        VALUES ( (d.primary_key * -1), d.authority_id, d.authority_name, l_stcode);
                END;
            END IF;
        END LOOP detach_loop;
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Authority detaches - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);


        -- Process Zone Tree Deletes
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Tree deletes - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);

        IF (make_changes_i = 1) THEN
            FOR d in zone_deletes(l_state) LOOP
                DELETE FROM tb_zones
                WHERE zone_id = d.primary_key;
            END LOOP;
        ELSE
            -- 08/12/16 - changed to bulk insert for performance improvements
            SELECT ctz.primary_key zone_id
                   , '.' name
                   , NULL parent_zone_id
                   , ctz.merchant_id
                   , NULL zone_level_id
                   , NULL eu_zone_as_of_date
                   , NULL reverse_flag
                   , NULL terminator_flag
                   , NULL default_flag
                   , NULL range_min
                   , NULL range_max
                   , NULL tax_parent_zone_id
                   , NULL code_2char
                   , NULL code_3char
                   , NULL code_iso
                   , NULL code_fips
                   , NULL synchronization_timestamp
            BULK COLLECT INTO v_pvw_tb_zones
            FROM   ct_zone_tree ctz
                JOIN (  SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   ct_zone_tree ct
                        WHERE  zone_3_name = l_state
                        MINUS
                        SELECT zone_3_name state, zone_4_name county, zone_5_name city, zone_6_name postcode, zone_7_name plus4, merchant_id
                        FROM   tdr_etl_ct_zone_tree
                     ) d ON ctz.zone_3_name = d.state
                         AND NVL(ctz.zone_4_name,'ZONE_4_NAME') = NVL(d.county,'ZONE_4_NAME')
                         AND NVL(ctz.zone_5_name,'ZONE_5_NAME') = NVL(d.city,'ZONE_5_NAME')
                         AND NVL(ctz.zone_6_name,'ZONE_6_NAME') = NVL(d.postcode,'ZONE_6_NAME')
                         AND NVL(ctz.zone_7_name,'ZONE_7_NAME') = NVL(d.plus4,'ZONE_7_NAME')
                         AND ctz.merchant_id = d.merchant_id;

            FORALL i IN v_pvw_tb_zones.first..v_pvw_tb_zones.last
                INSERT INTO pvw_tb_zones
                VALUES v_pvw_tb_zones(i);
            COMMIT;

            v_pvw_tb_zones := t_pvw_tb_zones();
        END IF;
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Tree deletes - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);


        -- Process Zone Tree Updates
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Tree updates - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);
        FOR u in zone_updates(l_state) LOOP <<zone_updates_loop>>
            IF (make_changes_i = 1) THEN

                UPDATE tb_zones
                SET    NAME              = u.NAME
                       ,zone_level_id    = u.zone_level_id
                       ,code_2char       = u.code_2char
                       ,code_3char       = u.code_3char
                       ,code_fips        = u.code_fips
                       ,default_flag     = u.default_flag
                       ,terminator_flag  = u.terminator_flag
                       ,reverse_flag     = u.reverse_flag
                       ,range_min        = u.range_min
                       ,range_max        = u.range_max
                       ,last_updated_by  = l_created_by     -- added 08/06/15
                WHERE  zone_id = u.primary_key;
            ELSE
                INSERT INTO pvw_tb_zones (zone_id, parent_zone_id, merchant_id, name, zone_level_id, code_2char,
                    code_3char, code_fips, default_flag, reverse_flag, terminator_flag, range_min, range_max)
                VALUES (u.primary_key, u.parent_zone_id, u.merchant_id, u.name, u.zone_level_id, u.code_2char,
                    u.code_3char, u.code_fips, u.default_flag, u.reverse_flag, u.terminator_flag, u.range_min, u.range_max);
            END IF;
        END LOOP zone_updates_loop;
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Tree updates - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);

        IF (make_changes_i = 1) THEN
            EXECUTE IMMEDIATE 'TRUNCATE TABLE tdr_etl_us_zone_ids DROP STORAGE'; -- 03/12/15
            l_next_id := pk_tb_zones.nextval;   -- crapp-2172
        END IF;

        -- Process Zone Tree Adds
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Tree adds - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);
        FOR l in zone_add_levels LOOP <<zone_add_level_loop>>

            FOR a in zone_adds LOOP <<zone_add_loop>>
                IF l.zone_level_id = a.zone_level_id THEN
                    -- 09/11/15 crapp-2050 - added FLOOR statements --
                    IF (a.zone_level_id = -5) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,NULL,NULL,NULL,NULL));
                    ELSIF (a.zone_level_id = -6) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,a.county,NULL,NULL,NULL));
                    ELSIF (a.zone_level_id = -7) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,a.county,a.city,NULL,NULL));
                    ELSIF (a.zone_level_id = -8) THEN
                        l_parent_zone_id := FLOOR(get_zone_id(l_merch_id,a.state,a.county,a.city,a.postcode,NULL));
                    END IF;

                    l_zone_id := get_zone_id(l_merch_id,a.state,a.county,a.city,a.postcode,a.plus4);

                    IF (make_changes_i = 1) THEN
                        dbms_output.put_line(l_zone_id ||' - '|| a.state ||' - '|| a.county ||' - '|| a.city ||' - '|| a.postcode ||' - '|| a.plus4 ||' - '|| l_parent_zone_id);

                        -- Set next ID --
                        IF l_zone_id - TRUNC(l_zone_id) = 0.1 THEN

                            l_next_id := pk_tb_zones.nextval;   -- crapp-2172

                            -- store id change -- 03/12/15
                            INSERT INTO tdr_etl_us_zone_ids
                                (tbl_name, new_primary_key, old_primary_key)
                                VALUES('TB_ZONES', l_next_id, l_zone_id);

                            l_zone_id := l_next_id;
                            dbms_output.put_line(l_zone_id);
                        END IF;

                        INSERT INTO tb_zones (zone_id, parent_zone_id, merchant_id, name, zone_level_id, code_2char,
                            code_3char, code_fips, default_flag, reverse_flag, terminator_flag, range_min, range_max,
                            created_by, creation_date, last_updated_by, last_update_date)
                        VALUES (l_zone_id, l_parent_zone_id, l_merch_id,
                            a.name, a.zone_level_id, a.code_2char, a.code_3char, a.code_fips, a.default_flag, a.reverse_flag,
                            a.terminator_flag, a.range_min, a.range_max, l_created_by, SYSDATE, l_created_by, SYSDATE);
                    ELSE
                        INSERT INTO pvw_tb_zones (zone_id, parent_zone_id, merchant_id, name, zone_level_id, code_2char,
                            code_3char, code_fips, default_flag, reverse_flag, terminator_flag, range_min, range_max)
                        VALUES (l_zone_id, l_parent_zone_id, l_merch_id,
                            a.name, a.zone_level_id, a.code_2char, a.code_3char, a.code_fips, a.default_flag, a.reverse_flag,
                            a.terminator_flag, a.range_min, a.range_max);
                    END IF;
                END IF;
            END LOOP zone_add_loop;

            IF (make_changes_i = 1) THEN
                FOR z IN ids LOOP
                    UPDATE tb_zones
                         SET  parent_zone_id = z.new_primary_key
                    WHERE parent_zone_id = z.old_primary_key;
                END LOOP;

                -- Update TAX_PARENT_ZONE_ID column -- 01/05/16
                etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES',' - Process DATAX_UTL_FKA_74 - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);
                    DATAX_UTL_FKA_74;

                    esql := 'ALTER TRIGGER DT_ZONES ENABLE';
                    EXECUTE IMMEDIATE esql;
                etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES',' - Process DATAX_UTL_FKA_74 - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);

                -- repopulate ct_update_zone_tree/ct_zone_authorities
                etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES',' - Process ct_update_zone_tree - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);
                    ct_update_zone_tree;
                etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES',' - Process ct_update_zone_tree - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);
            END IF;

        END LOOP zone_add_level_loop;
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Tree adds - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);


        -- Update Parent_Zone_IDs   -- 03/12/15
        IF (make_changes_i = 1) THEN
            etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Update CT Zone Tree - start, - '||l_stcode||'','GIS',NULL,NULL);

            -- 08/17/15 - check for orphaned zones and fix
            FOR z IN zone_orphans LOOP
                dbms_output.put_line('OrigZoneID '||z.orig_zone_id||' OrigName '||z.orig_name||' ParentZoneID '||z.zone_id);

                UPDATE tb_zones
                    SET parent_zone_id = z.zone_id
                WHERE zone_id = z.orig_zone_id
                      AND NAME = z.orig_name;
            END LOOP;

            -- repopulate ct_update_zone_tree/ct_zone_authorities
            ct_update_zone_tree;

            l_zone_auth_id := pk_tb_zone_authorities.nextval;   -- crapp-2172
            etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Update CT Zone Tree - end, - '||l_stcode||'','GIS',NULL,NULL);
        END IF;


        -- Process Zone Authority Attaches
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Authority attaches - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);
        FOR a in attaches(l_state) LOOP <<attach_loop>>
            IF (make_changes_i = 1) THEN

                BEGIN
                    l_zone_auth_id := pk_tb_zone_authorities.nextval;   -- crapp-2172

                    INSERT INTO tb_zone_authorities (zone_authority_id, zone_id, authority_id, created_by, creation_date,
                            last_updated_by, last_update_date)
                    (
                      SELECT l_zone_auth_id, primary_key, a.authority_id, l_created_by created_by, SYSDATE creation_date,
                             l_created_by last_updated_by, SYSDATE last_update_date
                      FROM   ct_zone_tree
                      WHERE  zone_3_name = a.state
                             AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                             AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                             AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                             AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                             AND merchant_id = a.merchant_id
                             AND a.authority_id IS NOT NULL -- crapp-3636
                    );
                EXCEPTION WHEN no_data_found THEN
                    dbms_output.put_line('Record not found for Authority:'||a.authority_name||' or Zone:'||a.state||','||a.county||','||a.city||','||a.postcode||','||a.plus4);
                    RAISE;
                END;
            ELSE

                l_zone_id := get_zone_id(a.merchant_id, a.state, a.county, a.city, a.postcode, a.plus4);

                BEGIN   -- Updated 06/10/15 --
                     SELECT primary_key
                     INTO   l_primary_key
                     FROM   ct_zone_tree
                     WHERE  zone_3_name = a.state
                            AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                            AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                            AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                            AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                            AND merchant_id = a.merchant_id;

                    INSERT INTO pvw_tb_zone_authorities (ZONE_ID, AUTHORITY_ID, AUTHORITY_NAME, STATE_CODE) -- 03/14/16 - crapp-2448 - Added State_Code
                        VALUES(l_primary_key, a.authority_id, a.authority_name, l_stcode);

                EXCEPTION WHEN no_data_found THEN
                    INSERT INTO pvw_tb_zone_authorities (ZONE_ID, AUTHORITY_ID, AUTHORITY_NAME, STATE_CODE) -- 03/14/16 - crapp-2448 - Added State_Code
                    (
                     SELECT NVL(primary_key, l_zone_id), a.authority_id, a.authority_name, l_stcode
                     FROM   tdr_etl_ct_zone_tree
                     WHERE  zone_3_name = a.state
                            AND NVL(zone_4_name,'ZONE_4_NAME') = NVL(a.county,'ZONE_4_NAME')
                            AND NVL(zone_5_name,'ZONE_5_NAME') = NVL(a.city,'ZONE_5_NAME')
                            AND NVL(zone_6_name,'ZONE_6_NAME') = NVL(a.postcode,'ZONE_6_NAME')
                            AND NVL(zone_7_name,'ZONE_7_NAME') = NVL(a.plus4,'ZONE_7_NAME')
                    );
                END;
            END IF;
        END LOOP attach_loop;
        etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Process Zone Authority attaches - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'','GIS',NULL,NULL);


        IF (make_changes_i = 1) THEN
            etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Update CT Zone Authorities - start, - '||l_stcode||'','GIS',NULL,NULL);

            -- Update Zone_ID if still has old_primary_key --
            FOR z IN ids LOOP       -- 08/17/15 crapp-1986
                UPDATE tb_zone_authorities
                     SET  zone_id = z.new_primary_key
                WHERE zone_id = z.old_primary_key;
            END LOOP;

            -- 05/24/17 - Removed, causing invalid attachments --
            -- Check to make sure Preview table has current state data -- crapp-2448
            SELECT COUNT(*) cnt
            INTO   l_auths
            FROM   pvw_tb_zone_authorities
            WHERE  state_code = l_stcode;

            IF l_auths > 0 THEN
                -- Insert any missed Attachments from Preview -- 08/17/15 crapp-1986
                INSERT INTO tb_zone_authorities
                    (zone_id, authority_id, creation_date, created_by, last_update_date, last_updated_by)    -- crapp-2172, let trigger handle Zone_Authority_ID
                    (
                        SELECT new_primary_key, a.authority_id, SYSDATE cd, l_created_by cb, SYSDATE, l_created_by  -- mid+rownum
                        FROM  (
                                SELECT  DISTINCT i.new_primary_key, authority_name, authority_id  -- crapp-2172 - ,mid
                                FROM    v_pvw_tb_zone_auths za
                                        JOIN tdr_etl_us_zone_ids i ON (i.old_primary_key = za.zone_id)
                                WHERE   zone_id-FLOOR(zone_id) = .1
                                        AND za.authority_id IS NOT NULL
                                        AND za.zone_3_name = l_state
                                        AND za.state_code  = l_stcode   -- crapp-2448
                              ) b
                              JOIN tb_authorities a ON ( a.name = b.authority_name
                                                         AND a.merchant_id = 2
                                                       )
                        WHERE NOT EXISTS ( SELECT 1
                                           FROM   tb_zone_authorities ta
                                           WHERE  ta.zone_id = new_primary_key
                                                  AND ta.authority_id = a.authority_id
                                         )
                    );

                l_auths := 0;
            END IF;
            */
/*
            -- repopulate ct_zone_authorities
            ct_update_zone_authorities;

            -- 04/09/15 -- Enable scheduled user jobs to refresh CT_ZONE_TREE and CT_ZONE_AUTHORITIES
            dbms_scheduler.ENABLE('UPDATE_CT_ZONE_TREE');
            dbms_scheduler.ENABLE('UPDATE_CT_ZONE_AUTHORITIES');

            etl_proc_log_p('DET_UPDATE.COMPARE_ZONE_TREES','Update CT Zone Authorities - end, - '||l_stcode||'','GIS',NULL,NULL);
        END IF;

        -- 01/27/16 crapp-2244 --
        SELECT COUNT(*) cnt
        INTO   l_auths
        FROM   content_repo.gis_zone_juris_auths_tmp -- crapp-3363
        WHERE  state_code = l_stcode;

        IF l_auths > 0 THEN
            IF (make_changes_i = 1) THEN
                FOR i IN invalid_auths LOOP
                    IF l_msg IS NULL THEN
                        l_msg := 'Export ETL LOAD did not attach the following '||l_auths||' Authorities that were not Published: '||CHR(13)||i.gis_name;
                    ELSE
                        l_msg := l_msg ||CHR(13)|| i.gis_name;
                    END IF;
                    EXIT WHEN LENGTH(l_msg) > 3800;
                END LOOP;
            ELSE
                FOR i IN invalid_auths LOOP
                    IF l_msg IS NULL THEN
                        l_msg := 'Export ETL PREVIEW found the following '||l_auths||' Jurisdictions that were not Published: '||CHR(13)||i.gis_name;
                    ELSE
                        l_msg := l_msg ||CHR(13)|| i.gis_name;
                    END IF;
                    EXIT WHEN LENGTH(l_msg) > 3800;
                END LOOP;
            END IF;

            content_repo.gis.update_sched_task(stcode_i=>l_stcode, method_i=>'export', msg_i=>l_msg);
        END IF; -- end of crapp-2244 section
        COMMIT;

    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'Compare zone tree timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'Compare zone tree error - '||SQLERRM);
    END compare_zone_trees;


    PROCEDURE compare_comp_areas(make_changes_i IN NUMBER) IS -- 03/24/17 - crapp-3363
        l_stcode       VARCHAR2(2 CHAR);
        l_fips         VARCHAR2(2 CHAR);    -- crapp-3055
        l_userid       NUMBER := -204;
        l_merch_id     NUMBER;

        CURSOR auth_deletes IS
            SELECT tcaa.compliance_area_auth_id, tcaa.compliance_area_id, tcaa.authority_id, a.NAME authority_name
            FROM   tb_comp_area_authorities tcaa
                   LEFT JOIN tb_authorities a ON (tcaa.authority_id = a.authority_id)
            WHERE  (tcaa.compliance_area_id, tcaa.authority_id) IN
                                                     (
                                                       SELECT  caa.compliance_area_id, caa.authority_id
                                                       FROM    tb_comp_area_authorities caa
                                                               JOIN tb_authorities ta ON (caa.authority_id = ta.authority_id)
                                                       WHERE   SUBSTR(ta.name, 1, 2) = l_stcode
                                                       MINUS
                                                       SELECT  compliance_area_id , authority_id
                                                       FROM    tdr_etl_tb_comp_area_auths
                                                     );


        CURSOR area_deletes IS
            SELECT compliance_area_id, NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id
            FROM   tb_compliance_areas
            WHERE  (compliance_area_uuid, NAME) IN
                         (
                           SELECT  compliance_area_uuid, name
                           FROM    tb_compliance_areas
                           WHERE   SUBSTR(name, 1, 2) = l_fips  --IN (SELECT DISTINCT SUBSTR(name, 1, 2) FROM tdr_etl_tb_compliance_areas)
                           MINUS
                           SELECT  compliance_area_uuid, name
                           FROM    tdr_etl_tb_compliance_areas
                         )
                AND EXISTS (SELECT 1 FROM tdr_etl_tb_compliance_areas WHERE SUBSTR(NAME, 1, 2) = l_fips); -- make sure there is data for this state


        CURSOR area_updates IS
           SELECT  NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, start_date, end_date, merchant_id
           FROM    tdr_etl_tb_compliance_areas
           WHERE   last_updated_by IS NOT NULL
           MINUS
           SELECT  NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, start_date, end_date, merchant_id
           FROM    tb_compliance_areas
           WHERE   SUBSTR(name, 1, 2) = l_fips; --IN (SELECT DISTINCT SUBSTR(name, 1, 2) FROM tdr_etl_tb_compliance_areas);


        CURSOR area_adds IS
           SELECT  ROWNUM id, tca.NAME, tca.compliance_area_uuid, tca.effective_zone_level_id, tca.associated_area_count, tca.start_date, tca.end_date, tca.merchant_id
           FROM    tdr_etl_tb_compliance_areas tca
                   JOIN (
                         SELECT  NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, start_date, end_date, merchant_id
                         FROM    tdr_etl_tb_compliance_areas
                         WHERE   last_updated_by IS NULL
                         MINUS
                         SELECT  NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, start_date, end_date, merchant_id
                         FROM    tb_compliance_areas
                         WHERE   SUBSTR(name, 1, 2) = l_fips --IN (SELECT DISTINCT SUBSTR(name, 1, 2) FROM tdr_etl_tb_compliance_areas)
                        ) a ON (tca.NAME = a.NAME
                                AND tca.compliance_area_uuid = a.compliance_area_uuid
                                AND tca.merchant_id = a.merchant_id
                               );


        CURSOR auth_adds IS
            SELECT ROWNUM id, a.*
                   , ta.NAME authority_name
                   , NVL(tca.NAME, ca.NAME) NAME
                   , NVL(tca.compliance_area_uuid, ca.compliance_area_uuid) compliance_area_uuid
            FROM   (
                    SELECT compliance_area_id, authority_id
                    FROM   tdr_etl_tb_comp_area_auths
                    MINUS
                    SELECT compliance_area_id, authority_id
                    FROM   tb_comp_area_authorities
                    --WHERE  compliance_area_id IN (SELECT compliance_area_id FROM tb_compliance_areas) -- crapp-3055, removed
                   ) a
                   LEFT JOIN tdr_etl_tb_compliance_areas tca ON (a.compliance_area_id = tca.compliance_area_id)
                   LEFT JOIN tb_compliance_areas ca ON (a.compliance_area_id = ca.compliance_area_id) -- crapp-3055, changed to a LEFT join and added table tdr_etl_tb_compliance_areas
                   LEFT JOIN tb_authorities ta ON (a.authority_id = ta.authority_id);

    BEGIN

        SELECT DISTINCT state_code
        INTO   l_stcode
        FROM   content_repo.gis_tb_compliance_areas;   -- crapp-3363

        SELECT DISTINCT SUBSTR(area_id, 1, 2) fips
        INTO   l_fips
        FROM   content_repo.gis_tb_compliance_areas;   -- crapp-3363

        IF (make_changes_i = 1) THEN
            dbms_output.put_line('');
        ELSE
            EXECUTE IMMEDIATE 'TRUNCATE TABLE pvw_tb_compliance_areas DROP STORAGE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE pvw_tb_comp_area_authorities DROP STORAGE';
        END IF;

        -- Process Compliance Area Authority Deletes --
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area Authority deletes - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR d IN auth_deletes LOOP
            IF (make_changes_i = 1) THEN
                DELETE FROM tb_comp_area_authorities
                WHERE  compliance_area_auth_id = d.compliance_area_auth_id
                       AND compliance_area_id  = d.compliance_area_id
                       AND authority_id        = d.authority_id;
            ELSE
                INSERT INTO pvw_tb_comp_area_authorities
                    (compliance_area_auth_id, compliance_area_id, authority_id, authority_name, change_type)
                VALUES
                    ((d.compliance_area_auth_id * -1), d.compliance_area_id, d.authority_id, d.authority_name, 'Delete');
            END IF;
        END LOOP;
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area Authority deletes - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);

        -- Process Compliance Area Deletes --
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area deletes - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR d IN area_deletes LOOP
            IF (make_changes_i = 1) THEN
                DELETE FROM tb_compliance_areas
                WHERE  compliance_area_id = d.compliance_area_id
                       AND compliance_area_uuid = d.compliance_area_uuid
                       AND name = d.name;
            ELSE
                INSERT INTO pvw_tb_compliance_areas
                    (compliance_area_id, NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id, change_type)
                VALUES
                    ((d.compliance_area_id * -1), d.name, d.compliance_area_uuid, d.effective_zone_level_id, d.associated_area_count, d.merchant_id, 'Delete');
            END IF;
        END LOOP;
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area deletes - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);

        -- Process Compliance Area Updates --
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area updates - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR u IN area_updates LOOP
            IF (make_changes_i = 1) THEN
                UPDATE tb_compliance_areas
                    SET compliance_area_uuid    = u.compliance_area_uuid,
                        effective_zone_level_id = u.effective_zone_level_id,
                        associated_area_count   = u.associated_area_count,
                        start_date              = u.start_date,
                        end_date                = u.end_date,
                        last_updated_by         = l_userid,
                        last_update_date        = SYSDATE
                WHERE NAME = u.NAME;
            ELSE
                INSERT INTO pvw_tb_compliance_areas
                    (NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id, start_date, end_date, change_type)
                VALUES
                    (u.NAME, u.compliance_area_uuid, u.effective_zone_level_id, u.associated_area_count, u.merchant_id, u.start_date, u.end_date, 'Update');
            END IF;
        END LOOP;
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area updates - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);

        -- Process Compliance Area Adds --
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area adds - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR a IN area_adds LOOP
            IF (make_changes_i = 1) THEN
                INSERT INTO tb_compliance_areas
                    (compliance_area_id, NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id, start_date, end_date
                     , created_by, creation_date, last_updated_by, last_update_date)
                VALUES
                    ( pk_tb_compliance_areas.nextval  -- crapp-2172  - (SELECT NVL(MAX(compliance_area_id),0)+1 FROM tb_compliance_areas)
                     , a.NAME, a.compliance_area_uuid, a.effective_zone_level_id, a.associated_area_count, a.merchant_id, a.start_date, a.end_date
                     , l_userid, SYSDATE, l_userid, SYSDATE);
            ELSE
                INSERT INTO pvw_tb_compliance_areas
                    (compliance_area_id, NAME, compliance_area_uuid, effective_zone_level_id, associated_area_count, merchant_id, start_date, end_date, change_type)
                VALUES
                    ( -- Inserting into the Preview Table we don't want to waste a sequence number - crapp-2172
                     NVL((SELECT MAX(compliance_area_id)+a.id FROM tb_compliance_areas), (SELECT NVL(MAX(compliance_area_id), 0)+1 FROM pvw_tb_compliance_areas))
                     , a.NAME
                     , a.compliance_area_uuid
                     , a.effective_zone_level_id
                     , a.associated_area_count
                     , a.merchant_id
                     , a.start_date
                     , a.end_date
                     , 'Add'
                    );
            END IF;
        END LOOP;
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area adds - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);

        -- Process Compliance Area Authority Adds --
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area Authority adds - start, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);
        FOR a IN auth_adds LOOP
            IF (make_changes_i = 1) THEN
                INSERT INTO tb_comp_area_authorities
                    (compliance_area_auth_id, compliance_area_id, authority_id, created_by, creation_date, last_updated_by, last_update_date)
                VALUES
                    (  pk_tb_comp_area_authorities.nextval  -- crapp-2172 - (SELECT NVL(MAX(compliance_area_auth_id), 0)+1 FROM tb_comp_area_authorities)
                     , (SELECT compliance_area_id FROM tb_compliance_areas WHERE compliance_area_uuid = a.compliance_area_uuid)
                     , a.authority_id
                     , l_userid
                     , SYSDATE
                     , l_userid
                     , SYSDATE
                    );
            ELSE
                INSERT INTO pvw_tb_comp_area_authorities
                    (compliance_area_auth_id, compliance_area_uuid, compliance_area_id, authority_id, authority_name, change_type)
                VALUES
                    ( -- Inserting into the Preview Table we don't want to waste a sequence number - crapp-2172
                     NVL( (SELECT MAX(compliance_area_auth_id)+a.id FROM tb_comp_area_authorities), (SELECT NVL(MAX(compliance_area_auth_id),0)+1 FROM pvw_tb_comp_area_authorities))
                     , a.compliance_area_uuid   -- 01/08/16 - new column
                     , a.compliance_area_id
                     , a.authority_id
                     , a.authority_name
                     , 'Add'
                    );
            END IF;
        END LOOP;
        etl_proc_log_p('DET_UPDATE.COMPARE_COMP_AREAS','Process Comp Area Authority adds - end, make_changes_i = '||make_changes_i||', - '||l_stcode||'', 'GIS', NULL, NULL);

        COMMIT;

    EXCEPTION
        WHEN TIMEOUT_ON_RESOURCE THEN
            RAISE_APPLICATION_ERROR(-20001,'Comp areas timeout.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002,'Comp areas error.');
    END compare_comp_areas;
*/

    PROCEDURE remove_rules(authority_i IN VARCHAR2) IS
        l_auth_uuid VARCHAR2(36);
    BEGIN
         INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.REMOVE_RATE','removing Rule records for Authority:'||authority_i,'RULE',null,null);
        SELECT uuid
        INTO l_auth_uuid
        FROM (
            SELECT uuid
            from tb_authorities
            WHERE name = authority_i
            UNION
            SELECT authority_uuid
            from tdr_etl_tb_authorities
            WHERE name = authority_i
            );

        DELETE FROM tdr_etl_tb_rule_qualifiers rq
        WHERE EXISTS (
            SELECT 1
            FROM tdr_etl_tb_rules r
            WHERE r.authority_uuid = l_auth_uuid
            AND r.rule_order = rq.rule_order
            and rq.rule_authority_uuid = r.authority_uuid
            and r.start_date = rq.start_Date
            );
        DELETE FROM tdr_etl_tb_rules
        WHERE authority_uuid = l_auth_uuid;
        DELETE FROM tdr_etl_rules
        WHERE authority_uuid = l_auth_uuid;
        DELETE FROM tdr_etl_rule_products
        WHERE authority_uuid = l_auth_uuid;
        COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Remove rules timeout.');

    END remove_rules;

    PROCEDURE remove_rates(authority_i IN VARCHAR2) IS
        l_auth_uuid VARCHAR2(36);
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.REMOVE_RATE','removing Rate records for Authority:'||authority_i,'RATE',null,null);
        SELECT uuid
        INTO l_auth_uuid
        FROM (
            SELECT uuid
            from tb_authorities
            WHERE name = authority_i
            UNION
            SELECT authority_uuid
            from tdr_etl_tb_authorities
            WHERE name = authority_i
            );

        DELETE FROM tdr_etl_tb_rate_tiers rt
        WHERE EXISTS (
            SELECT 1
            FROM tdr_etl_tb_rates r
            WHERE r.authority_uuid = l_auth_uuid
            AND r.rate_code = rt.rate_code
            and rt.authority_uuid = r.authority_uuid
            and r.start_date = rt.start_Date
            and r.is_local = rt.is_local
            );
        DELETE FROM tdr_etl_tb_rates
        WHERE authority_uuid = l_auth_uuid;

        COMMIT;

    exception
    when TIMEOUT_ON_RESOURCE then
    RAISE_APPLICATION_ERROR(-20001,'Remove rates timeout.');

    END remove_rates;

    PROCEDURE remove_authority(authority_i IN VARCHAR2)
    IS
        l_auth_uuid VARCHAR2(100);
    BEGIN
        SELECT uuid
        INTO l_auth_uuid
        FROM (
            SELECT uuid
            from tb_authorities
            WHERE name = authority_i
            UNION
            SELECT authority_uuid
            from tdr_etl_tb_authorities
            WHERE name = authority_i
            );
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.REMOVE_AUTHORITY','removing records for Authority:'||authority_i,'AUTHORITY',null,null);
        DELETE from tdr_etl_tb_contributing_auths where authority_uuid = l_auth_uuid;
        DELETE from tdr_etl_tb_auth_logic_mapping where authority_uuid = l_auth_uuid;
        DELETE from tdr_etl_tb_auth_logic_groups where authority_uuid = l_auth_uuid;
        --DELETE from tmp_tb_authority_requirements where authority_uuid = l_auth_uuid;
        DELETE from tdr_etl_tb_authorities where authority_uuid = l_auth_uuid;
    END remove_authority;

    PROCEDURE remove_product(comm_code_i IN VARCHAR2)
    IS
    BEGIN
        INSERT INTO etl_proc_log (action, message, entity, nkid, rid)
        VALUES ('DET_UPDATE.REMOVE_PRODUCT','removing records for Product:'||comm_code_i,'PRODUCT CATEGORY',null,null);
        DELETE FROM tdr_etl_ct_product_tree
        where prodcode = comm_code_i;
        COMMIT;
    END remove_product;
END det_update;
/