CREATE UNIQUE INDEX content_repo.tags_un ON content_repo.tags("NAME",tag_type_id)

TABLESPACE content_repo;