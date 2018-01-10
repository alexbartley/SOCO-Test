CREATE INDEX content_repo.idx_impl_expl_raw_i1 ON content_repo.impl_expl_raw_ds(processid)

TABLESPACE content_repo PARALLEL 6;