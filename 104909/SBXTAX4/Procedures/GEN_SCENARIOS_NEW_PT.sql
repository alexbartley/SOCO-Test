CREATE OR REPLACE PROCEDURE sbxtax4."GEN_SCENARIOS_NEW_PT" (qaUserId IN NUMBER)
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

    -- return all the authority ids and names for our tax data provider
    CURSOR auths(stateCode VARCHAR2) IS
    SELECT a.authority_id, a.name auth_name , COALESCE(MAX(z.zone_6_id),MAX(z.zone_5_id),MAX(z.zone_4_id),MAX(z.zone_3_id)) newest_zone_mapping
    FROM tb_authorities a, tb_merchants m, tb_authority_types ay, tb_rules r, ct_zone_authorities z
    WHERE a.merchant_id = m.merchant_id
    AND a.name LIKE (stateCode || ' - %')
    AND a.authority_type_id = ay.authority_type_id
    AND (ay.name LIKE '%Sales/Use' OR ay.name = 'EXC')
    AND m.merchant_id = tdpId
    AND r.merchant_id = a.merchant_id
    AND r.authority_id = a.authority_id
    AND r.end_Date IS NULL
    AND r.product_category_id IS NOT NULL
    AND r.rule_order BETWEEN 5001 AND 9989
    AND z.authority_name = a.name
    AND z.zone_7_id IS NULL
    group by a.authority_id, a.name;

    CURSOR prods(authorityId NUMBER, authName VARCHAR2) IS
    SELECT  pc.name rule_product, pc.prodcode rule_prodcode, MAX(childpc.product_category_id) child_product_category_id
    FROM tb_rules r
    JOIN tb_product_categories pc ON (pc.product_category_id = r.product_category_id)
    LEFT OUTER JOIN tb_product_Categories childpc ON (pc.product_Category_id = childpc.parent_product_category_id)
    WHERE r.authority_id = authorityId
    AND r.end_Date IS NULL
    AND r.merchant_id = tdpId
    AND NOT EXISTS (
        SELECT 1
        FROM tb_scenarios s, tb_merchants m
        WHERE s.merchant_id = m.merchant_id
        AND m.name LIKE 'US-'||SUBSTR(authName,1,2)||'%PT%'
        AND SUBSTR(authName,1,75) = SUBSTR(s.scenario_name,1,LENGTH(SUBSTR(authName,1,75)))
        AND SUBSTR(s.scenario_name,INSTR(s.scenario_name,' - ',4)+3,(INSTR(s.scenario_name,' (',INSTR(s.scenario_name,' - ',4))-INSTR(s.scenario_name,' - ',4))-3) = pc.prodcode
        AND s.scenario_name LIKE SUBSTR(authName,1,2)||' - %'
        AND instr(replace(scenario_name, SUBSTR(authName,1,75)),'-') = 2
        )
    AND NOT EXISTS (
        SELECT 1
        FROM tb_scenarios s, tb_merchants m, tb_Scenario_lines sl
        WHERE s.merchant_id = m.merchant_id
        AND s.scenario_id = sl.header_Scenario_id
        AND m.name IN ('US-NY Utility Rate Test Company','US-MO Utility Rate Test Company')
        AND pc.prodcode = sl.commodity_code
        AND SUBSTR(authName,1,75) = SUBSTR(s.scenario_name,1,LENGTH(SUBSTR(authName,1,75)))
        AND s.scenario_name LIKE SUBSTR(authName,1,2)||' - %'
        )
    GROUP BY  pc.name, pc.prodcode;


    CURSOR testMerchants is
    SELECT merchant_id, SUBSTR(name, 4, 2) stateCode, name
    FROM tb_merchants
    WHERE name LIKE 'US-%PT%'
    AND name NOT LIKE '%Prior%';


BEGIN

    SELECT merchant_id
    INTO tdpId
    FROM tb_merchants
    WHERE name = 'Sabrix US Tax Data';

    SELECT MAX(scenario_id)+10
    INTO scenarioId
    FROM tb_scenarios;

    <<merchantLoop>>
    FOR mer IN testMerchants LOOP
	   qaMerchId := mer.merchant_id;

        <<authorityLoop>>
        FOR auth IN auths(mer.stateCode) LOOP
            --reset ShipTo Information
            stGeo := '';
            stZip := '';
            stCity := '';
            stCounty := '';
            stState := '';

            --set Line Amount
            lineAmt := 10000;
            --set Line Amount for Tennessee
            IF (auth.auth_name LIKE 'TN - %') THEN
            	lineAmt := 5000;
            END IF;

            --set ShipTo information

            --Set ShipTo to KENAI for Alaska State Authority
            IF (auth.auth_name LIKE 'AK%STATE%') THEN
                SELECT  zone_5_name, zone_4_name, zone_3_name
                INTO stCity, stCounty, stState
                FROM ct_zone_authorities
                WHERE zone_5_name = 'KENAI'
                AND zone_6_id IS NULL
                AND ROWNUM < 2;
            --Set ShipTo to the newest Zone mapping for given Authority
            ELSE
                SELECT  zone_6_name, zone_5_name, zone_4_name, zone_3_name
                INTO  stZip, stCity, stCounty, stState
                FROM ct_zone_authorities
                WHERE COALESCE(zone_6_id,zone_5_id ,zone_4_id ,zone_3_id) = auth.newest_zone_mapping
                AND authority_name = auth.auth_name
                AND ROWNUM < 2;

                --If the selected Zone is UNINCORPORATED, ensure that the ShipTo information has ZipCode populated
                IF (stCity = 'UNINCORPORATED' AND stZip IS NULL) THEN
                    SELECT  t.zone_6_name, t.zone_5_name, t.zone_4_name, t.zone_3_name
                    INTO  stZip, stCity, stCounty, stState
                    FROM ct_zone_authorities za, ct_zone_tree t
                    WHERE COALESCE(za.zone_6_id,za.zone_5_id ,za.zone_4_id ,za.zone_3_id) = auth.newest_zone_mapping
                    AND t.zone_5_id = auth.newest_zone_mapping
                    AND t.zone_7_id IS NULL
                    AND authority_name = auth.auth_name
                    AND za.zone_5_name = 'UNINCORPORATED'
                    AND t.zone_6_name IS NOT NULL
                    AND ROWNUM < 2;
                END IF;

            END IF;

            --Create product rule scenarios for each Authority
            <<productLoop>>
            FOR prod IN prods(auth.authority_id, auth.auth_name) LOOP
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
    	 		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_geocode, sf_postcode, sf_city, sf_county, sf_state, sf_country
                    )
                VALUES (
                    scenarioId, substr(auth.auth_name,1,75) || ' - ' || prod.rule_prodcode || ' (SA)',
                    substr(auth.auth_name,1,75) || ' - ' || prod.rule_prodcode || ' (SA)',
                    'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, sysdate, qaUserId, sysdate,
                    stGeo, stZip,stCity, stCounty, stState, 'US',
                    stGeo, stZip,stCity, stCounty, stState, 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, lineAmt, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, lineAmt, child_prodCode, qaUserId, scenarioLineId);
            	END IF;


                --Create PT scenario for Seller's Use Tax
                --Label scenario with Authority Name, Commodity Code, AND '(US)'
                --Company Role = S (Seller)
                --ShipTo = Authority Zone mapping
                --ShipFrom = PORTLAND, MULTNOMAH, OREGON, US (No Tax Liability location that is != ShipTo)

            	scenarioId := scenarioId + 1;
        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country,
                    sf_city, sf_county, sf_state, sf_country
                    )
                    VALUES (
                    scenarioId, SUBSTR(auth.auth_name,1,75) || ' - ' || prod.rule_prodcode || ' (US)',
                    SUBSTR(auth.auth_name,1,75) || ' - ' || prod.rule_prodcode || ' (US)',
                    'GS', invoiceDate, qaMerchId, 'S',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    stGeo, stZip,stCity, stCounty, stState, 'US',
                    'PORTLAND', 'MULTNOMAH', 'OREGON', 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, lineAmt, prod.rule_prodCode, qaUserId, scenarioLineId);
                --Insert another line for a child Product if there is one
                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, lineAmt, child_prodCode, qaUserId, scenarioLineId);
            	END IF;

                --Create PT scenario for Consumer's Use Tax
                --Label scenario with Authority Name, Commodity Code, AND '(CU)'
                --Company Role = B (Buyer)
                --ShipTo = Authority Zone mapping
                --ShipFrom = null
            	scenarioId := scenarioId + 1;
        		INSERT INTO tb_scenarios (
                    scenario_id, scenario_name, invoice_number, transaction_type, invoice_date, merchant_id, merchant_role,
                    calculation_direction, currency_code, created_by, creation_date, last_updated_by, last_update_date,
                    st_geocode, st_postcode, st_city, st_county, st_state, st_country
                    )
                    VALUES (
                    scenarioId, SUBSTR(auth.auth_name,1,75) || ' - ' || prod.rule_prodcode || ' (CU)',
                    SUBSTR(auth.auth_name,1,75) || ' - ' || prod.rule_prodcode || ' (CU)',
                    'GS', invoiceDate, qaMerchId, 'B',
                    'F', 'USD', qaUserId, SYSDATE, qaUserId, SYSDATE,
                    stGeo, stZip,stCity, stCounty, stState, 'US'
                    );
                COMMIT;
                GEN_SCENARIOS_INSERT_LINE(scenarioId, 1, 1, prod.rule_product, NULL, lineAmt, prod.rule_prodCode, qaUserId, scenarioLineId);


                IF (child_prodcode != 'NO_CHILD') THEN
            	   GEN_SCENARIOS_INSERT_LINE(scenarioId, 2, 1, child_product, NULL, lineAmt, child_prodCode, qaUserId, scenarioLineId);
            	END IF;

            	scenarioId := scenarioId + 1;


            END LOOP productLoop;
            scenarioId := scenarioId + 1;

        END LOOP authorityLoop;
    END LOOP merchantLoop;

UPDATE tb_counters
SET value = (
    SELECT NVL(MAX(scenario_id),1)
    FROM tb_scenarios
)
WHERE name = 'TB_SCENARIOS';
COMMIT;

END; -- Procedure


 
 
 
/