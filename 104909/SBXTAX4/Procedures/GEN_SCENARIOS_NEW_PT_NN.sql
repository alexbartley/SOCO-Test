CREATE OR REPLACE PROCEDURE sbxtax4."GEN_SCENARIOS_NEW_PT_NN" (qaUserId IN NUMBER)
   IS

    scenarioId number;
    scenarioLineId number;
    lineAmt number;
    tdpId number;         -- the tax data provider id
    qaMerchId number;       -- the qa merchant where the scenarios will be created
    stCity varchar2(100);
    stCounty varchar2(100);
    stState varchar2(25);
    stGeo varchar2(100);
    stZip varchar2(100);
    invoiceDate date := to_date('2016.03.01', 'YYYY.MM.DD');
    child_product varchar2(100);
    child_prodcode varchar2(100);



    CURSOR prods IS
    SELECT  pc.name rule_product, pc.prodcode rule_prodcode, MAX(childpc.product_category_id) child_product_category_id
    FROM tb_rules r
    JOIN tb_authorities a ON (r.authority_id = a.authority_id)
    JOIN tb_product_categories pc ON (pc.product_category_id = r.product_category_id)
    LEFT OUTER JOIN tb_product_Categories childpc ON (pc.product_Category_id = childpc.parent_product_category_id)
    WHERE a.name like 'NN - NAVAJO%'
    AND r.end_Date IS NULL
    AND r.merchant_id = tdpId
    AND NOT EXISTS (
        SELECT 1
        FROM tb_scenarios s, tb_merchants m
        WHERE s.merchant_id = m.merchant_id
        AND m.name LIKE 'US-'||SUBSTR(a.name,1,2)||'%PT%'
        AND SUBSTR(a.name,1,72) = SUBSTR(s.scenario_name,4,LENGTH(SUBSTR(a.name,1,72)))
        AND SUBSTR(s.scenario_name,INSTR(s.scenario_name,' - ',7)+3,(INSTR(s.scenario_name,' (',INSTR(s.scenario_name,' - ',7))-INSTR(s.scenario_name,' - ',7))-3) = pc.prodcode
        AND substr(s.scenario_name,4,100) LIKE SUBSTR(a.name,1,2)||' - %'
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_scenarios s, tb_merchants m, tb_Scenario_lines sl
        WHERE s.merchant_id = m.merchant_id
        AND s.scenario_id = sl.header_Scenario_id
        AND m.name IN ('US-NY Utility Rate Test Company','US-MO Utility Rate Test Company')
        AND pc.prodcode = sl.commodity_code
        AND SUBSTR(a.name,1,72) = SUBSTR(s.scenario_name,4,LENGTH(SUBSTR(a.name,1,72)))
        AND substr(s.scenario_name,4,100) LIKE SUBSTR(a.name,1,2)||' - %'
        )
    GROUP BY  pc.name, pc.prodcode;





BEGIN

    SELECT merchant_id
    INTO tdpId
    FROM tb_merchants
    WHERE name = 'Sabrix US Tax Data';

    SELECT merchant_id
    INTO qaMerchId
    FROM tb_merchants
    WHERE name like 'US-NN PT Test Company';

    SELECT MAX(scenario_id)+10
    INTO scenarioId
    FROM tb_scenarios;



            --Create product rule scenarios for each Authority
            <<productLoop>>
            FOR prod IN prods LOOP
                --Check for child products of the given Product
                IF (prod.child_product_category_id IS NOT NULL) THEN
                    SELECT prodcode, name
                    INTO child_prodcode, child_product
                    FROM tb_product_categories
                    WHERE product_category_id = prod.child_product_category_id;
                ELSE
                    child_prodcode := 'NO_CHILD';
                    child_product := 'X';
                END IF;

                --Create PT scenario for Sales Tax
                --Label scenario with Authority Name, Commodity Code, AND '(SA)'
                --Company Role = S (Seller)
                --ShipTo = ShipFrom
                --ARIZONA
                scenarioId := scenarioId + 1;
    	 		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_geocode, sf_postcode, sf_city, sf_county, sf_state, sf_country
                    )
                VALUES (
                    scenarioId, 'AZ.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (SA)',
                    'AZ.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (SA)',
                     'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, sysdate, qaUserId, sysdate,
                    null, null,'MANY FARMS', 'APACHE', 'ARIZONA', 'US',
                    null, null,'MANY FARMS', 'APACHE', 'ARIZONA', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 100, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 100, child_prodCode, qaUserId, scenarioLineId);
            	END IF;
                scenarioId := scenarioId + 1;

                --NEW MEXICO
    	 		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_geocode, sf_postcode, sf_city, sf_county, sf_state, sf_country
                    )
                VALUES (
                    scenarioId, 'NM.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (SA)',
                    'NM.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (SA)',
                    'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, sysdate, qaUserId, sysdate,
                    null, null,'SHIPROCK', 'SAN JUAN', 'NEW MEXICO', 'US',
                    null, null,'SHIPROCK', 'SAN JUAN', 'NEW MEXICO', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 10000, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 10000, child_prodCode, qaUserId, scenarioLineId);
            	END IF;
                scenarioId := scenarioId + 1;

                --UTAH
    	 		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_geocode, sf_postcode, sf_city, sf_county, sf_state, sf_country
                    )
                VALUES (
                    scenarioId, 'UT.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (SA)',
                    'UT.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (SA)',
                    'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, sysdate, qaUserId, sysdate,
                    null, null,'MONTEZUMA CREEK', 'SAN JUAN', 'UTAH', 'US',
                    null, null,'MONTEZUMA CREEK', 'SAN JUAN', 'UTAH', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 100, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 100, child_prodCode, qaUserId, scenarioLineId);
            	END IF;
                scenarioId := scenarioId + 1;
                --Create PT scenario for Seller's Use Tax
                --Label scenario with Authority Name, Commodity Code, AND '(US)'
                --Company Role = S (Seller)
                --ShipTo = Authority Zone mapping
                --ShipFrom = PORTLAND, MULTNOMAH, OREGON, US (No Tax Liability location that is != ShipTo)


        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_city, sf_county, sf_state, sf_country
                    )
                    VALUES (
                    scenarioId, 'AZ.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (US)',
                     'AZ.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (US)',
                     'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    null, null,'MANY FARMS', 'APACHE', 'ARIZONA', 'US',
                    'PORTLAND', 'MULTNOMAH', 'OREGON', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 100, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 100, child_prodCode, qaUserId, scenarioLineId);
            	END IF;
                scenarioId := scenarioId + 1;

        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_city, sf_county, sf_state, sf_country
                    )
                    VALUES (
                    scenarioId, 'NM.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (US)',
                    'NM.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (US)',
                    'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    null, null,'SHIPROCK', 'SAN JUAN', 'NEW MEXICO', 'US',
                    'PORTLAND', 'MULTNOMAH', 'OREGON', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 10000, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 10000, child_prodCode, qaUserId, scenarioLineId);
            	END IF;
                scenarioId := scenarioId + 1;


        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_city, sf_county, sf_state, sf_country
                    )
                    VALUES (
                    scenarioId, 'UT.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (US)',
                     'UT.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (US)',
                     'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    null, null,'MONTEZUMA CREEK', 'SAN JUAN', 'UTAH', 'US',
                    'PORTLAND', 'MULTNOMAH', 'OREGON', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 100, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 100, child_prodCode, qaUserId, scenarioLineId);
            	END IF;
                scenarioId := scenarioId + 1;

                --Create PT scenario for Consumer's Use Tax
                --Label scenario with Authority Name, Commodity Code, AND '(CU)'
                --Company Role = B (Buyer)
                --ShipTo = Authority Zone mapping
                --ShipFrom = null

        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country
                    )
                    VALUES (
                    scenarioId, 'AZ.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (CU)',
                    'AZ.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (CU)',
                    'GS', invoiceDate, qaMerchId, 'B',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    null, null,'MANY FARMS', 'APACHE', 'ARIZONA', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 100, prod.rule_prodCode, qaUserId, scenarioLineId);


                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 100, child_prodCode, qaUserId, scenarioLineId);
            	END IF;

            	scenarioId := scenarioId + 1;
        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country
                    )
                    VALUES (
                    scenarioId, 'NM.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (CU)',
                    'NM.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (CU)',
                    'GS', invoiceDate, qaMerchId, 'B',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    null, null,'SHIPROCK', 'SAN JUAN', 'NEW MEXICO', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 10000, prod.rule_prodCode, qaUserId, scenarioLineId);


                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 10000, child_prodCode, qaUserId, scenarioLineId);
            	END IF;

            	scenarioId := scenarioId + 1;
        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country
                    )
                    VALUES (
                    scenarioId, 'UT.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (CU)',
                    'UT.NN - NAVAJO NATION, TRIBAL SALES TAX - ' || prod.rule_prodcode || ' (CU)',
                    'GS', invoiceDate, qaMerchId, 'B',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    null, null,'MONTEZUMA CREEK', 'SAN JUAN', 'UTAH', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, 100, prod.rule_prodCode, qaUserId, scenarioLineId);


                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, 100, child_prodCode, qaUserId, scenarioLineId);
            	END IF;

            END LOOP productLoop;

UPDATE tb_counters
SET value = (
    SELECT NVL(MAX(scenario_id),1)
    FROM tb_scenarios
)
WHERE name = 'TB_SCENARIOS';
COMMIT;

END; -- Procedure


 
 
 
/