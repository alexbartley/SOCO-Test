CREATE OR REPLACE PROCEDURE sbxtax4."DATAX_TB_RULES_155"
   ( taxDataProviderId IN NUMBER, runId IN OUT NUMBER)
   IS
   --<data_check id="155" name="Rules with exact same rule qualifiers 9679.01,.02,.03">
   dataCheckId NUMBER := -690;
BEGIN
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_155 started.',runId) RETURNING run_id INTO runId;
    COMMIT;
    INSERT INTO datax_check_output (primary_key, data_check_id, run_id, creation_date) (
    SELECT ro.rule_id, dataCheckId, runId, SYSDATE
    FROM tb_rules ro, tb_rule_qualifiers rqo, (
        select rq.authority_id, rq.element, rq.element_type, rq.element_value, rq.end_date, rq.operator, rq.reference_list_id, rq.rule_qualifier_type, rq.start_date, rq.value, rq.value_type
        from tb_rules r, tb_rule_qualifiers rq
        where r.merchant_id = taxDataProviderId
        and r.rule_order in('9679.01', '9679.02', '9679.03')
        and r.rule_id = rq.rule_id
        group by rq.authority_id, rq.element, rq.element_type, rq.element_value, rq.end_date, rq.operator, rq.reference_list_id, rq.rule_qualifier_type, rq.start_date, rq.value, rq.value_type
        HAVING COUNT(*)!=3
    ) sub
    WHERE ro.rule_order in('9679.01', '9679.02', '9679.03')
    AND ro.merchant_id = taxDataProviderId
    AND ro.rule_id = rqo.rule_id
    AND rqo.element = sub.element
    AND rqo.element_type = sub.element_type
    AND rqo.operator = sub.operator
    AND rqo.start_date = sub.start_date
    AND rqo.value = sub.value
    AND NOT EXISTS (
        SELECT 1
        FROM datax_check_output
        WHERE primary_key = ro.rule_id
        AND data_check_id = dataCheckId
        )
    );
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_RULES_155 finished.',runId);
    COMMIT;
END;


 
 
 
/