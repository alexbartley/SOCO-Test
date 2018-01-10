CREATE OR REPLACE PACKAGE content_repo."CHANGELOG_SEARCH" IS
/*
    -- MODIFICATION HISTORY
    -- Sign        Date     Comments
    -- ---------   ------   --------------------------------------------------
    -- tnn                  Note: sectionVerif is Assignment type (wrong name)
    -- tnn         20170420 CRAPP-3296 status_modified_date exch entered_date
*/
    sectionModifyBy  VARCHAR2(512):= ' '; -- entered_by
    sectionReason    VARCHAR2(256):= ' '; -- list of values 'n,n,...n'
    sectionVerif     VARCHAR2(64) := ' '; -- list of values 'n,n,...n'
    sectionDataRange VARCHAR2(64) := ' '; -- one value or empty
    sectionDocs      VARCHAR2(128):= ' '; -- one text or empty
    sectionTags      VARCHAR2(64) := ' '; -- list of values
    sectionModAfter  VARCHAR2(8)  := ' '; -- one field value
    sectionModBefore VARCHAR2(8)  := ' '; -- one field value
    sectionCit       VARCHAR2(16) := ' '; -- Citations
    sVerifiedBy      VARCHAR2(128):= ' '; -- Validation assigned by

    -- OFFICIAL_NAME VARCHAR2(250)
    sJurisName       VARCHAR2(250):= ' '; -- Jurisdiction name

    /**
    * Out record
    */
    TYPE outSet IS record
    (
      change_logid VARCHAR2(128)
    , col_rid VARCHAR2(128)
    , col_published VARCHAR2(128)
    , col_modified VARCHAR2(128)
    , col_by VARCHAR2(128)
    , col_reason VARCHAR2(128)
    , col_verified_by VARCHAR2(256)
    , col_documents VARCHAR2(256)
    , col_sct_attribute VARCHAR2(256)
    , col_refcol VARCHAR2(256)
    , table_name VARCHAR2(256)
    , section_id VARCHAR2(128)
    , col_nkid varchar2(12)
    , col_doc_id_list VARCHAR2(512)
    , jurisdictions_rid VARCHAR2(12)
    , juris_tax_impositions_rid VARCHAR2(12)
    , jurisdictions_nkid VARCHAR2(12)
    , tag_name varchar2(1000)
    );

    TYPE outTable IS TABLE OF outSet;

    TYPE outSet_Citation IS record
    (
      change_logid VARCHAR2(128)
    , col_rid VARCHAR2(128)
    , col_published VARCHAR2(128)
    , col_modified VARCHAR2(128)
    , col_by VARCHAR2(128)
    , col_reason VARCHAR2(128)
    , col_verified_by VARCHAR2(128)
    , col_documents VARCHAR2(128)
    , col_sct_attribute VARCHAR2(256)
    , col_refcol VARCHAR2(256)
    , table_name VARCHAR2(256)
    , section_id VARCHAR2(128)
    , col_nkid varchar2(6)
    , col_doc_id_list VARCHAR2(128)
    , jurisdictions_rid VARCHAR2(8)
    , juris_tax_impositions_rid VARCHAR2(8)
    );
    TYPE outTable_CID IS TABLE OF outSet_Citation;

    -- Update Multiple record feed
    type r_feed is record(process_id number, primary_key number, eid number);
    type t_feed is table of r_feed;


    FUNCTION searchLog(entity IN VARCHAR2,
               search_ModifBy IN VARCHAR2,
               search_Reason  IN VARCHAR2,
               search_Doc     IN VARCHAR2,
               search_Verif   IN VARCHAR2,
               search_Data    IN VARCHAR2,
               search_Tags    IN VARCHAR2,
               modifAfter     IN VARCHAR2 DEFAULT NULL,
               modifBefore    IN VARCHAR2 DEFAULT NULL,
               verifiedBy     IN VARCHAR2 DEFAULT NULL,
               pOfficialName  IN VARCHAR2 DEFAULT NULL)
            RETURN outTable PIPELINED;


    FUNCTION searchCitation(search_citationID IN NUMBER) RETURN outTable_CID PIPELINED;

    -- does the parameter contain more than 1 item - build IN
    FUNCTION fnAndIs(searchVar IN VARCHAR2, dataCol IN VARCHAR2) RETURN VARCHAR2;

    -- is a text submitted - search part of name
    FUNCTION fnIsTextEntered(searchText IN VARCHAR2, dataCol IN VARCHAR2) RETURN VARCHAR2;

    -- temp dev where statement
    FUNCTION returnWhere(sdAfter IN VARCHAR2 DEFAULT NULL, sdBefore IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

    -- Administration Entity
    PROCEDURE getAdmin(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR);

    -- Jurisdiction entity proc here (same param or from main)
    PROCEDURE getJurisdiction(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL);

    -- Tax (section is here but might not be correct)
    PROCEDURE getTax(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL);

    -- Taxability
    PROCEDURE getTaxability(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL);

    PROCEDURE getGoods(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR);

    PROCEDURE getCommodities(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR);

    /*  -- Removed - CRAPP-2516
    PROCEDURE getCommGroups(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR);
    */

    PROCEDURE getRefGroups(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR);

    --
    PROCEDURE getCitation(cit_id IN number, p_ref OUT SYS_REFCURSOR);

    --
    PROCEDURE pt_search_changelog(entity IN VARCHAR2,
              search_ModifBy IN VARCHAR2,
              search_Reason  IN VARCHAR2,
              search_Doc     IN VARCHAR2,
              search_Verif   IN VARCHAR2,
              search_Data    IN VARCHAR2,
              search_Tags    IN VARCHAR2,
              modifAfter     IN VARCHAR2 DEFAULT NULL,
              modifBefore    IN VARCHAR2 DEFAULT NULL,
              verifiedBy     IN VARCHAR2 DEFAULT NULL,
              p_ref_ad OUT SYS_REFCURSOR,
              p_ref_ju OUT SYS_REFCURSOR,
              p_ref_tx OUT SYS_REFCURSOR,
              p_ref_ta OUT SYS_REFCURSOR,
              p_ref_cm OUT SYS_REFCURSOR,
              p_ref_cg OUT SYS_REFCURSOR
              );

    PROCEDURE getGeoPolygons(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL);

    PROCEDURE getGeoUniqueAreas(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
       p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL);

    --
    --procedure getUpdateMultiple(pProcessId in number, p_ref OUT SYS_REFCURSOR);
    FUNCTION retUpdateMultipleSet(pProcessId IN NUMBER) RETURN t_feed PIPELINED;

    -- Update Multiple Change Log Data
    -- Based on process id from table update_multiple_log
    --
    PROCEDURE update_multiple_log(p_process_id IN NUMBER, p_ref OUT SYS_REFCURSOR);
    PROCEDURE copy_tax_log(p_process_id IN NUMBER, p_ref OUT SYS_REFCURSOR);
    FUNCTION multi_searchLog(p_process_id IN NUMBER) RETURN outTable PIPELINED;

    -- Commodity group change log data  -- Removed - CRAPP-2516
    --procedure comm_group_logsql(p_process_id IN NUMBER, p_ref OUT SYS_REFCURSOR);
    --function comm_group_searchLog(p_process_id IN NUMBER) RETURN outTable PIPELINED;
END changelog_search;
/