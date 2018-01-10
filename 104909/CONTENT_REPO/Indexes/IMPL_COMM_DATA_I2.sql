CREATE INDEX content_repo.impl_comm_data_i2 ON content_repo.impl_comm_data_t(child_id)

TABLESPACE content_repo PARALLEL 4;