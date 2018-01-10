CREATE OR REPLACE TRIGGER sbxtax4."DT_ZONES_INSERT" 
 AFTER 
 INSERT
 ON sbxtax4.TB_ZONES
 REFERENCING OLD AS OLD NEW AS NEW
BEGIN
    UPDATE tb_zones plus4
    SET code_fips = (
        SELECT zip.code_fips||plus4.name
        FROM tb_zones zip
        WHERE zip.zone_id = plus4.parent_zone_id
        )
    WHERE plus4.zone_level_id = -8
    AND plus4.code_fips IS NULL;
    
END;
/