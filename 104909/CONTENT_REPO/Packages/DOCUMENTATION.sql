CREATE OR REPLACE PACKAGE content_repo."DOCUMENTATION" 
  IS
-- *****************************************************************************
-- Description: Handle operations related to managing documentation
--
-- Revision History
-- Date            Author           Reason for Change
-- ----------------------------------------------------------------
-- -                                -
-- *****************************************************************************
-- Notes
--
--
-- Additional
-- 10/27/2014 : referenced objects

    procedure upd_document(
        document_id_i IN NUMBER,
        eff_date_i IN DATE,
        exp_date_i IN DATE,
        acquired_date_i IN DATE,
        posted_date_i IN DATE,
        language_id_i IN NUMBER,
        description_i IN VARCHAR2,
        display_name_i IN VARCHAR2,
        research_source_id_i IN NUMBER,
        research_log_id_i IN NUMBER DEFAULT null,
        success_o OUT NUMBER
    );

    -- Delete Attachment (+Citations)
    procedure del_attachment(pDocumentId in number, pEntered_by in number, rStatus out number);
    procedure del_attachment(pDocumentId in number, pEntered_by in number, rStatus out number, rList out CLOB);

END;
/