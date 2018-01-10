CREATE INDEX content_repo.official_name_index ON content_repo.cx_text_search_t(official_name)
INDEXTYPE IS ctxsys."CONTEXT";