CREATE TABLE content_repo.kpmg_zip5_final (
  area_id VARCHAR2(50 CHAR),
  zip VARCHAR2(5 CHAR),
  default_flag VARCHAR2(4 CHAR),
  state_code CHAR(2 BYTE)
) TABLESPACE content_repo
PARTITION BY LIST (state_code)
(PARTITION state_al VALUES ('AL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ak VALUES ('AK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_az VALUES ('AZ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ar VALUES ('AR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ca VALUES ('CA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_co VALUES ('CO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ct VALUES ('CT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_de VALUES ('DE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_dc VALUES ('DC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_fl VALUES ('FL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ga VALUES ('GA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_hi VALUES ('HI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_id VALUES ('ID')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_il VALUES ('IL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_in VALUES ('IN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ia VALUES ('IA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ks VALUES ('KS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ky VALUES ('KY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_la VALUES ('LA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_me VALUES ('ME')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_md VALUES ('MD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ma VALUES ('MA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_mi VALUES ('MI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_mn VALUES ('MN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ms VALUES ('MS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_mo VALUES ('MO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_mt VALUES ('MT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ne VALUES ('NE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_nv VALUES ('NV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_nh VALUES ('NH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_nj VALUES ('NJ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_nm VALUES ('NM')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ny VALUES ('NY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_nc VALUES ('NC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_nd VALUES ('ND')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_oh VALUES ('OH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ok VALUES ('OK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_or VALUES ('OR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_pa VALUES ('PA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ri VALUES ('RI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_sc VALUES ('SC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_sd VALUES ('SD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_tn VALUES ('TN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_tx VALUES ('TX')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_ut VALUES ('UT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_vt VALUES ('VT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_va VALUES ('VA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_wa VALUES ('WA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_wv VALUES ('WV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_wi VALUES ('WI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION state_wy VALUES ('WY')
  INDEXING ON
  TABLESPACE content_repo);