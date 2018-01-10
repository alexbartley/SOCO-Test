CREATE OR REPLACE PACKAGE content_repo.TDR_ETL_LIB IS
/*******************************************************************************
/* ETL process library
/* Work in progress
/*
/*
/* $1.01
/******************************************************************************/
  runno  PLS_INTEGER := 0;

  -- Main etl procedure (either return something or use this one for writing to status table)
  /*
  PROCEDURE tdretlprocess(vInstance in CLOB-- , dbProcess OUT CLOB
            ,stag_or_prod varchar2 default 'P');
  */

  procedure tdretlprocess( instancegroupid number, preview_i number default 0, truncate_i number default 0
  );

  procedure tdretlprocess_advanced(vInstance in CLOB--, dbProcess OUT CLOB,
            ,stag_or_prod varchar2 default 'P'
  );

END TDR_ETL_LIB;
/