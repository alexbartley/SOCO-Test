CREATE MATERIALIZED VIEW LOG ON content_repo.ref_group_revisions
TABLESPACE content_repo
  WITH PRIMARY KEY, ROWID;