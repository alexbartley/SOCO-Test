CREATE OR REPLACE FORCE VIEW content_repo.vtaxability_elements ("ID",element_name,"TYPE") AS
SELECT ID
        , ELEMENT_NAME
        , '1' AS TYPE
     FROM TAXABILITY_ELEMENTS
    UNION
   SELECT ID
        , OFFICIAL_NAME AS ELEMENT_NAME
        , '2' AS TYPE
     FROM JURISDICTIONS
 
 
 ;