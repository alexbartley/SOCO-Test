CREATE OR REPLACE PACKAGE content_repo.dev_piped_results IS
/** DEV ONLY **/

    TYPE t_col IS RECORD(
        i NUMBER,
        n VARCHAR2(30));
    TYPE t_nested_table IS TABLE OF t_col;


    FUNCTION return_table RETURN t_nested_table PIPELINED;
    --FUNCTION return_commd RETURN t_commod_table PIPELINED;

    -- Ref Cursor -> JSON including pagination
    -- Returns a CLOB
    FUNCTION refcursjson(p_ref_cursor in sys_refcursor,
                         p_max_rows in number := null,
                         p_skip_rows in number := null) RETURN CLOB;

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

  END dev_piped_results;
 
 
 
 
/