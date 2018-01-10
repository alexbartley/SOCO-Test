CREATE OR REPLACE PACKAGE content_repo.kpmg_import
AS
    PROCEDURE step4_taxdescription;
    PROCEDURE kpmg_ins_juris_latest (officialname VARCHAR2);
    FUNCTION getgeoareacategory (categoryname VARCHAR2) RETURN NUMBER;
    PROCEDURE jurisdiction_tags (tagname VARCHAR2);
    PROCEDURE juris_tax_imposition_tags (tagname VARCHAR2);
    PROCEDURE commodity_tags (tagname VARCHAR2);
    PROCEDURE add_tags (tagname_i VARCHAR2);
    PROCEDURE generate_juris_geo_areas (official_name_i VARCHAR2);
    PROCEDURE ins_tax_administrators (administrator_name VARCHAR2,tax_id NUMBER);
    PROCEDURE fix_duplicate_taxes (officialname VARCHAR2, state_name VARCHAR2);
END;
/