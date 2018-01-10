CREATE OR REPLACE PROCEDURE sbxtax4."GEN_SCENARIOS_INSERT_LINE"
   ( scenarioId IN NUMBER, lineNumber IN NUMBER, quantity IN NUMBER, productName IN VARCHAR2, productCode IN VARCHAR2, lineAmount IN NUMBER,
   commodityCode IN VARCHAR2, createdBy IN NUMBER, scenarioLineId IN OUT NUMBER)
   IS
BEGIN
    SELECT MAX(NVL(scenario_line_id,0))+1
    INTO scenarioLineId
    FROM tb_scenario_lines;

   	INSERT INTO tb_scenario_lines (
        scenario_line_id, header_scenario_id, line_number, product_code, commodity_code, quantity, gross_amount,
        created_by, creation_date, last_updated_by, last_update_date, description
        )
    VALUES (
        scenarioLineId, scenarioId, lineNumber, productCode, commodityCode, quantity, lineAmount,
        createdBy, SYSDATE, createdBy, SYSDATE, productName);
    COMMIT;

END; -- Procedure


 
 
 
/