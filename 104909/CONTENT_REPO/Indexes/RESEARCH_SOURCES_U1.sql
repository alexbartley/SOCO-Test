CREATE UNIQUE INDEX content_repo.research_sources_u1 ON content_repo.research_sources(UPPER("DESCRIPTION"))

TABLESPACE content_repo;