CREATE GLOBAL TEMPORARY TABLE sbxtax.pt_temp_authority_columns (
  column_name VARCHAR2(50 BYTE),
  authority_name VARCHAR2(100 BYTE)
)
ON COMMIT PRESERVE ROWS;