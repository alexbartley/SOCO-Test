CREATE OR REPLACE PROCEDURE sbxtax."CT_REP_ALCOUNTYDET"
   ( filename IN VARCHAR2, countyName IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    merchId NUMBER;
    outputHeader VARCHAR2(4000) :=
    'zone_4_name,zone_5_name,zone_6_name,zone_7_name,state_auths,county_auths,city_auths,state_rental_auths,county_rental_auths,city_rental_auths,all_auths';
BEGIN
    SELECT merchant_id
    INTO merchId
    FROM tb_merchants
    WHERE name = 'Sabrix US Tax Data';
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');

    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
            SELECT t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, NVL(state_maps.num_of,0) state_auths, NVL(county_maps.num_of,0) county_auths, NVL(city_maps.num_of,0) city_auths,
            NVL(state_rental_maps.num_of,0) state_rental_auths, NVL(county_rental_maps.num_of,0) county_rental_auths, NVL(city_rental_maps.num_of,0) city_rental_auths, NVL(all_maps.num_of,0) all_auths
            FROM ct_zone_Tree t
            LEFT OUTER JOIN  (
                SELECT COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id) zone_id, COUNT(*) num_of
                FROM ct_zone_authorities a, tb_authorities au
                WHERE zone_3_name = 'ALABAMA'
                AND au.name = a.authority_name
                AND au.merchant_id = a.merchant_id
                AND authority_type_id = 3
                GROUP BY COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id)
                ) state_maps on (state_maps.zone_id = t.primary_key)
            LEFT OUTER JOIN  (
                SELECT COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id) zone_id, COUNT(*) num_of
                FROM ct_zone_authorities a, tb_authorities au
                WHERE zone_3_name = 'ALABAMA'
                AND au.name = a.authority_name
                AND au.merchant_id = a.merchant_id
                AND authority_type_id = 2
                GROUP BY COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id)
                ) county_maps on (county_maps.zone_id = t.primary_key)
            LEFT OUTER JOIN  (
                SELECT COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id) zone_id, COUNT(*) num_of
                FROM ct_zone_authorities a, tb_authorities au
                WHERE zone_3_name = 'ALABAMA'
                AND au.name = a.authority_name
                AND au.merchant_id = a.merchant_id
                AND authority_type_id = 1
                GROUP BY COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id)
                ) city_maps on (city_maps.zone_id = t.primary_key)
            LEFT OUTER JOIN  (
                SELECT COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id) zone_id, COUNT(*) num_of
                FROM ct_zone_authorities a, tb_authorities au
                WHERE zone_3_name = 'ALABAMA'
                AND au.name = a.authority_name
                AND au.merchant_id = a.merchant_id
                AND authority_type_id = 7
                GROUP BY COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id)
                ) state_rental_maps on (state_rental_maps.zone_id = t.primary_key)
            LEFT OUTER JOIN  (
                SELECT COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id) zone_id, COUNT(*) num_of
                FROM ct_zone_authorities a, tb_authorities au
                WHERE zone_3_name = 'ALABAMA'
                AND au.name = a.authority_name
                AND au.merchant_id = a.merchant_id
                AND authority_type_id = 6
                GROUP BY COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id)
                ) county_rental_maps on (county_rental_maps.zone_id = t.primary_key)
            LEFT OUTER JOIN  (
                SELECT COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id) zone_id, COUNT(*) num_of
                FROM ct_zone_authorities a, tb_authorities au
                WHERE zone_3_name = 'ALABAMA'
                AND au.name = a.authority_name
                AND au.merchant_id = a.merchant_id
                AND authority_type_id = 5
                GROUP BY COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id)
                ) city_rental_maps on (city_rental_maps.zone_id = t.primary_key)
            LEFT OUTER JOIN  (
                SELECT COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id) zone_id, COUNT(*) num_of
                FROM ct_zone_authorities a
                WHERE zone_3_name = 'ALABAMA'
                GROUP BY COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id)
                ) all_maps on (all_maps.zone_id = t.primary_key)
            WHERE t.zone_3_name = 'ALABAMA'
            AND UPPER(t.zone_4_name) LIKE UPPER(countyName)
            ORDER BY t.zone_4_name, t.zone_6_name, t.zone_5_name, t.zone_7_name
        ) LOOP
        fileLine :=
            '"'||r.zone_4_name||'",'||
            '"'||r.zone_5_name||'",'||
            '="'||r.zone_6_name||'",'||
            '="'||r.zone_7_name||'",'||
            '"'||r.state_auths||'",'||
            '"'||r.county_auths||'",'||
            '"'||r.city_auths||'",'||
            '"'||r.state_rental_auths||'",'||
            '"'||r.county_rental_auths||'",'||
            '"'||r.city_rental_auths||'",'||
            '"'||r.all_auths||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_ALCOUNTYDET',SYSDATE,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W',32000);
    UTL_FILE.put_line(ftype,'Report did not finish properly because Oracle encountered an error.');
    UTL_FILE.put_line(ftype,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED BUT FAILED');
END; -- Procedure


 
 
/