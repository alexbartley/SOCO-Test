CREATE OR REPLACE FUNCTION sbxtax4."ZONE_SET_FIPS"
  ( zone_level_i IN VARCHAR2, state_i IN VARCHAR2, county_i IN VARCHAR2, city_i IN VARCHAR2, zip_i IN VARCHAR2, plus4_range_i IN VARCHAR2, fips_i IN VARCHAR2)
  RETURN  VARCHAR2 IS
    l_r VARCHAR2(1000);
    e_invalid_zone_level EXCEPTION;
    e_zone_required EXCEPTION;
BEGIN
    IF (state_i IS NULL) THEN
        RAISE e_zone_required;
    END IF;
    IF (upper(zone_level_i) = 'STATE') THEN
        UPDATE tb_zones z
        SET z.code_fips = fips_i
        WHERE z.zone_level_id = -4
        AND z.name = UPPER(state_i);
        IF (SQL%ROWCOUNT = 0) THEN
            RAISE no_data_found;
        END IF;
        l_r := 'STATE: '||state_i||' FIPS: '||fips_i;
    ELSIF (upper(zone_level_i) = 'COUNTY') THEN
        IF (county_i IS NULL) THEN
            RAISE e_zone_required;
        END IF;
        UPDATE tb_zones z
        SET z.code_fips = fips_i
        WHERE z.zone_level_id = -5
        AND z.name = UPPER(county_i)
        AND z.parent_zone_id = (
            SELECT state.zone_id
            FROM tb_zones state
            WHERE state.zone_level_id = -4
            AND state.name = UPPER(state_i)
            );
        IF (SQL%ROWCOUNT = 0) THEN
            RAISE no_data_found;
        END IF;
        l_r := 'COUNTY: '||state_i||', '||county_i||' FIPS: '||fips_i;
    ELSIF (upper(zone_level_i) = 'CITY') THEN
        IF (county_i IS NULL OR city_i IS NULL) THEN
            RAISE e_zone_required;
        END IF;
        UPDATE tb_zones z
        SET z.code_fips = fips_i
        WHERE z.zone_level_id = -6
        AND z.name = UPPER(city_i)
        AND z.parent_zone_id = (
            SELECT County.zone_id
            FROM tb_zones state
            JOIN tb_zones county ON (state.zone_id = county.parent_zone_id AND county.zone_level_id = -5)
            WHERE state.zone_level_id = -4
            AND state.name = UPPER(state_i)
            AND county.name = UPPER(county_i)
            );
        IF (SQL%ROWCOUNT = 0) THEN
            RAISE no_data_found;
        END IF;
        l_r := 'CITY: '||state_i||', '||county_i||', '||city_i||' FIPS: '||fips_i;
    ELSIF (upper(zone_level_i) = 'ZIP') THEN
        IF (county_i IS NULL OR city_i IS NULL OR zip_i IS NULL) THEN
            RAISE e_zone_required;
        END IF;
        UPDATE tb_zones z
        SET z.code_fips = fips_i
        WHERE z.zone_level_id = -7
        AND z.name = UPPER(zip_i)
        AND z.parent_zone_id = (
            SELECT City.zone_id
            FROM tb_zones state
            JOIN tb_zones county ON (state.zone_id = county.parent_zone_id AND county.zone_level_id = -5)
            JOIN tb_zones city ON (county.zone_id = city.parent_zone_id AND city.zone_level_id = -6)
            WHERE state.zone_level_id = -4
            AND state.name = UPPER(state_i)
            AND county.name = UPPER(county_i)
            AND city.name = UPPER(city_i)
            );
        IF (SQL%ROWCOUNT = 0) THEN
            RAISE no_data_found;
        END IF;
        l_r := 'ZIP: '||state_i||', '||county_i||', '||city_i||', '||zip_i||' FIPS: '||fips_i;
    ELSIF (upper(zone_level_i) = 'PLUS4') THEN
        IF (county_i IS NULL OR city_i IS NULL OR zip_i IS NULL OR plus4_range_i IS NULL) THEN
            RAISE e_zone_required;
        END IF;
        UPDATE tb_zones z
        SET z.code_fips = fips_i
        WHERE z.zone_level_id = -8
        AND z.name = UPPER(plus4_range_i)
        AND z.parent_zone_id = (
            SELECT zip.zone_id
            FROM tb_zones state
            JOIN tb_zones county ON (state.zone_id = county.parent_zone_id AND county.zone_level_id = -5)
            JOIN tb_zones city ON (county.zone_id = city.parent_zone_id AND city.zone_level_id = -6)
            JOIN tb_zones zip ON (city.zone_id = zip.parent_zone_id AND zip.zone_level_id = -7)
            WHERE state.zone_level_id = -4
            AND state.name = UPPER(state_i)
            AND county.name = UPPER(county_i)
            AND city.name = UPPER(city_i)
            AND zip.name = UPPER(zip_i)
            );
        IF (SQL%ROWCOUNT = 0) THEN
            RAISE no_data_found;
        END IF;
        l_r := 'PLUS4: '||state_i||', '||county_i||', '||city_i||', '||zip_i||', '||plus4_range_i||' FIPS: '||fips_i;
    ELSE
        RAISE e_invalid_zone_level;
    END IF;
    COMMIT;
    RETURN l_r ;
EXCEPTION
    WHEN e_invalid_zone_level THEN
        raise_application_error(-20000,'Zone_level_i provided is not a valid Zone Level: '||zone_level_i);
    WHEN e_zone_required THEN
        raise_application_error(-20001,'Zone element missing.');
    WHEN others THEN
        ROLLBACK;
        RAISE;
END ZONE_SET_FIPS;


 
 
 
/