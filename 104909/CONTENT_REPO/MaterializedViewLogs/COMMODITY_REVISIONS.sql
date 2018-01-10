CREATE MATERIALIZED VIEW LOG ON content_repo.commodity_revisions
TABLESPACE content_repo
  WITH PRIMARY KEY, ROWID;