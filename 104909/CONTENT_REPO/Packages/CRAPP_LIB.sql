CREATE OR REPLACE PACKAGE content_repo."CRAPP_LIB" 
IS
-- *****************************************************************
-- Description: Content Repo functions and procedures library
--
-- Revision History
-- Date            Author       Reason for Change
-- ----------------------------------------------------------------
--
--
-- *****************************************************************
-- function fnNoHtml; remove html from clob
-- function fmtdate;  return Ora-date from mm/dd/yyyy format
-- procedure refcursjson; return JSON using reference cursor
-- procedure sql_to_json; retutn JSON using simple sql statement
--
-- Dev/Test Procedures and Functions
-- procedure change_log_search() - index hints
-- function return_table() - pipe multiple records

-- Additional
-- Referenced objects
/*
REFERENCED_OWNER    REFERENCED_NAME             REFERENCED_TYPE
----------------    ------------------------    ---------------
CONTENT_REPO_006    CRAPP_LIB_JSON_STR_ARRAY    TYPE
*/

    -- Returned set of data for nested pipe
    TYPE t_col IS RECORD
    (
      i NUMBER,
      n VARCHAR2(30)
    );
    TYPE t_nested_table IS TABLE OF t_col;

    -- Nested piped results
    FUNCTION return_table RETURN t_nested_table PIPELINED;

    -- Ref Cursor -> JSON including pagination
    FUNCTION refcursjson(p_ref_cursor in sys_refcursor,
                         p_max_rows in number := null,
                         p_skip_rows in number := null) RETURN CLOB;

    -- Development only
    PROCEDURE change_log_search(
              entity IN VARCHAR2,
              search_ModifBy IN VARCHAR2,
              search_Reason  IN VARCHAR2,
              search_Doc     IN VARCHAR2,
              search_Verif   IN VARCHAR2,
              search_Data    IN VARCHAR2,
              search_Tags    IN VARCHAR2,
              modifAfter     IN VARCHAR2 DEFAULT NULL,
              modifBefore    IN VARCHAR2 DEFAULT NULL,
              pagenum IN NUMBER,
              pagerecs IN NUMBER,
              column_order IN VARCHAR2,
              ordertype IN VARCHAR2,
              rfCurs OUT SYS_REFCURSOR
    );

    /* SQL To JSON minimal */
    function sql_to_json (p_sql in varchar2,
                          p_param_names in crapp_lib_json_str_array := null,
                          p_param_values in crapp_lib_json_str_array := null,
                          p_max_rows in number := null,
                          p_skip_rows in number := null) return clob;

    function fmtdate(dt_sort_col in varchar2) return date;
    function fnNoHtml(p_string IN CLOB) RETURN CLOB;

    /*
    || Row generator
    || DEP: numtabletype
    */
    function row_generator (rows_in IN PLS_INTEGER) RETURN numtabletype PIPELINED;

END crapp_lib;
 
/