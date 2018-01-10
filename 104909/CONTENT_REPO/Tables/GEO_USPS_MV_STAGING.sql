CREATE TABLE content_repo.geo_usps_mv_staging (
  geo_area_key VARCHAR2(100 CHAR) NOT NULL,
  hierarchy_level_id NUMBER NOT NULL,
  state_code VARCHAR2(2 CHAR) NOT NULL,
  state_name VARCHAR2(64 CHAR) NOT NULL,
  state_fips VARCHAR2(4 CHAR),
  county_name VARCHAR2(64 CHAR),
  county_fips VARCHAR2(4 CHAR),
  city_name VARCHAR2(122 CHAR),
  city_fips VARCHAR2(8 CHAR),
  zip VARCHAR2(5 CHAR),
  zip9 VARCHAR2(21 CHAR),
  stj_fips VARCHAR2(97 CHAR),
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  mt_union_section NUMBER,
  area_id VARCHAR2(60 CHAR)
) TABLESPACE content_repo
PARTITION BY LIST (state_code)
(PARTITION mk_usps_al VALUES ('AL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ak VALUES ('AK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ar VALUES ('AR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_az VALUES ('AZ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ca VALUES ('CA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_co VALUES ('CO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ct VALUES ('CT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_de VALUES ('DE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_dc VALUES ('DC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_fl VALUES ('FL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ga VALUES ('GA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_hi VALUES ('HI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_id VALUES ('ID')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_il VALUES ('IL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_in VALUES ('IN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ia VALUES ('IA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ks VALUES ('KS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ky VALUES ('KY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_la VALUES ('LA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_me VALUES ('ME')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_md VALUES ('MD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ma VALUES ('MA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_mi VALUES ('MI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_mn VALUES ('MN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ms VALUES ('MS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_mo VALUES ('MO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_mt VALUES ('MT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ne VALUES ('NE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_nv VALUES ('NV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_nh VALUES ('NH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_nj VALUES ('NJ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_nm VALUES ('NM')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ny VALUES ('NY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_nc VALUES ('NC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_nd VALUES ('ND')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_oh VALUES ('OH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ok VALUES ('OK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_or VALUES ('OR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_pa VALUES ('PA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ri VALUES ('RI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_sc VALUES ('SC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_sd VALUES ('SD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_tn VALUES ('TN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_tx VALUES ('TX')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ut VALUES ('UT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_vt VALUES ('VT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_va VALUES ('VA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_wa VALUES ('WA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_wv VALUES ('WV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_wi VALUES ('WI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_wy VALUES ('WY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_us VALUES ('US')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_gu VALUES ('GU')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_pr VALUES ('PR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_as VALUES ('AS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_aa VALUES ('AA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ae VALUES ('AE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_ap VALUES ('AP')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_fm VALUES ('FM')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_vi VALUES ('VI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_mh VALUES ('MH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_mp VALUES ('MP')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_pw VALUES ('PW')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION mk_usps_x0 VALUES (DEFAULT)
  INDEXING ON
  TABLESPACE content_repo)
PARALLEL 4;