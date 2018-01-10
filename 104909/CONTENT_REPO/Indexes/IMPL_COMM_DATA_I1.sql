CREATE INDEX content_repo.impl_comm_data_i1 ON content_repo.impl_comm_data_t(process_id,jta_id)

TABLESPACE content_repo PARALLEL 2;