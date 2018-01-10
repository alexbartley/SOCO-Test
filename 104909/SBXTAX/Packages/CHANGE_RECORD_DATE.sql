CREATE OR REPLACE PACKAGE sbxtax."CHANGE_RECORD_DATE" AS

  PROCEDURE generate_change_record(content_type IN VARCHAR2, content_consumer IN VARCHAR2,
      content_description IN VARCHAR2, oracle_directory IN VARCHAR2, overwrite_existing IN NUMBER, change_date_after IN DATE, change_date_before IN DATE, id_o OUT NUMBER, success_o OUT NUMBER);
  PROCEDURE run_query(p_sql IN VARCHAR2);
  PROCEDURE start_workbook;
  PROCEDURE end_workbook;
  PROCEDURE start_worksheet(p_sheetname IN VARCHAR2);
  PROCEDURE end_worksheet;
  PROCEDURE set_date_style;
  PROCEDURE create_simple_rates_file(v_content_type IN OUT VARCHAR2, v_content_version IN OUT VARCHAR2, v_change_date_after IN OUT DATE, v_change_date_before IN OUT DATE);
  PROCEDURE create_full_change_clob(v_content_type IN OUT VARCHAR2, v_content_version IN OUT VARCHAR2, v_change_date_after IN OUT DATE, v_change_date_before IN OUT DATE);
END CHANGE_RECORD_DATE;
 
/