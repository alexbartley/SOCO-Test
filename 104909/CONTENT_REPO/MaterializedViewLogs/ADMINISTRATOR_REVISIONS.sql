CREATE MATERIALIZED VIEW LOG ON content_repo.administrator_revisions
TABLESPACE content_repo
  WITH PRIMARY KEY, ROWID;