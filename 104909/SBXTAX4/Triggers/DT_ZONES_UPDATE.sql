CREATE OR REPLACE TRIGGER sbxtax4."DT_ZONES_UPDATE" 
 BEFORE 
 UPDATE
 ON sbxtax4.TB_ZONES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
begin
    :new.last_update_date := SYSDATE;
    IF (:old.zone_level_id = -8) THEN
        :new.code_fips := replace(:new.code_fips,:old.name,:new.name);
    END IF;
end dt_zones_update;
/