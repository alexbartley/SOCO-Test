CREATE OR REPLACE PACKAGE content_repo."CONTACT"
  IS
-- *****************************************************************
-- Description: Handle operations related to managing Content record changes
--
-- Revision History
-- Date            Author           Reason for Change
-- ----------------------------------------------------------------
--                 u0126589/genesam
-- *8/1/2014       tnn              -
-- *****************************************************************
-- Notes
--
--
-- Additional
-- 10/27/2014 : referenced objects


    PROCEDURE contact_log(
        source_contact_id IN NUMBER,
        contact_method_id_c IN CLOB,
        note_i IN VARCHAR2,
        entered_by_i IN NUMBER,
        inext_contact_date IN VARCHAR2,
        contact_log_id_o OUT NUMBER,
        success_o OUT NUMBER
        );

    PROCEDURE XMLProcess_Form_UpdContact(
        sx IN CLOB,
        update_success OUT NUMBER,
        res_id_o OUT number
        );

    PROCEDURE delete_all_sources;

    PROCEDURE delete_source(
       source_id_i IN NUMBER
       );

    PROCEDURE delete_source_contact(
      source_contact_id_i IN NUMBER
      );

    PROCEDURE upd_owners(
        research_source_id_c IN CLOB, --list of contact method_id's
        owner_id_i IN NUMBER,
        success_o OUT NUMBER
        );

    PROCEDURE upd_contacts(
        source_id_i IN NUMBER,
        name_i IN VARCHAR2,
        frequency_i IN VARCHAR2,
        next_contact_date_i IN DATE,
        owner_i IN NUMBER,
        contact_usage_type_id_i IN NUMBER,
        start_date_i IN DATE,
        end_date_i IN DATE,
        entered_by_i IN NUMBER,
        contact_methods_i IN xmlform_contact_tt,
        administrators_i IN xmlform_admi_tt,
        status_i IN NUMBER,
        resSourceId out number
        );

    PROCEDURE setContactStatus(iStatus IN NUMBER DEFAULT -2,
                               iSource_contact_id IN NUMBER,
                               sNext_contact_date IN VARCHAR2 DEFAULT NULL,
                               success_o OUT NUMBER);



END contact;
 
/