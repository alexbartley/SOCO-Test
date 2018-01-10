CREATE OR REPLACE TYPE content_repo."O_LOOKUPCHANGELOGTABLES"                                          as object(
  validation_table varchar2(30),
  log_table varchar2(30),
  index_column varchar2(30)
);
/