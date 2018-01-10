CREATE TABLE content_repo.geo_polygon_usps (
  "ID" NUMBER NOT NULL,
  geo_polygon_id NUMBER NOT NULL,
  state_name VARCHAR2(64 CHAR) NOT NULL,
  state_code VARCHAR2(2 CHAR) NOT NULL,
  state_fips VARCHAR2(4 CHAR),
  county_name VARCHAR2(64 CHAR),
  county_fips VARCHAR2(4 CHAR),
  city_name VARCHAR2(64 CHAR),
  city_fips VARCHAR2(8 CHAR),
  zip VARCHAR2(5 CHAR),
  plus4_range VARCHAR2(16 CHAR),
  start_date DATE NOT NULL,
  end_date DATE,
  entered_date TIMESTAMP NOT NULL,
  status_modified_date TIMESTAMP NOT NULL,
  entered_by NUMBER NOT NULL,
  status NUMBER DEFAULT 0 NOT NULL,
  multiple_states NUMBER DEFAULT 0 NOT NULL,
  multiple_counties NUMBER DEFAULT 0 NOT NULL,
  multiple_cities NUMBER DEFAULT 0 NOT NULL,
  plus4_min NUMBER,
  plus4_max NUMBER,
  geo_polygon_nkid NUMBER NOT NULL,
  area_id VARCHAR2(60 CHAR),
  CONSTRAINT geo_polygon_usps_pk PRIMARY KEY ("ID",state_code) USING INDEX (CREATE UNIQUE INDEX content_repo.geo_poly_usps_pk ON content_repo.geo_polygon_usps("ID",state_code)
    
    LOCAL (PARTITION lu_usps_al
      TABLESPACE content_repo,
    PARTITION lu_usps_ak
      TABLESPACE content_repo,
    PARTITION lu_usps_ar
      TABLESPACE content_repo,
    PARTITION lu_usps_az
      TABLESPACE content_repo,
    PARTITION lu_usps_ca
      TABLESPACE content_repo,
    PARTITION lu_usps_co
      TABLESPACE content_repo,
    PARTITION lu_usps_ct
      TABLESPACE content_repo,
    PARTITION lu_usps_de
      TABLESPACE content_repo,
    PARTITION lu_usps_dc
      TABLESPACE content_repo,
    PARTITION lu_usps_fl
      TABLESPACE content_repo,
    PARTITION lu_usps_ga
      TABLESPACE content_repo,
    PARTITION lu_usps_hi
      TABLESPACE content_repo,
    PARTITION lu_usps_id
      TABLESPACE content_repo,
    PARTITION lu_usps_il
      TABLESPACE content_repo,
    PARTITION lu_usps_in
      TABLESPACE content_repo,
    PARTITION lu_usps_ia
      TABLESPACE content_repo,
    PARTITION lu_usps_ks
      TABLESPACE content_repo,
    PARTITION lu_usps_ky
      TABLESPACE content_repo,
    PARTITION lu_usps_la
      TABLESPACE content_repo,
    PARTITION lu_usps_me
      TABLESPACE content_repo,
    PARTITION lu_usps_md
      TABLESPACE content_repo,
    PARTITION lu_usps_ma
      TABLESPACE content_repo,
    PARTITION lu_usps_mi
      TABLESPACE content_repo,
    PARTITION lu_usps_mn
      TABLESPACE content_repo,
    PARTITION lu_usps_ms
      TABLESPACE content_repo,
    PARTITION lu_usps_mo
      TABLESPACE content_repo,
    PARTITION lu_usps_mt
      TABLESPACE content_repo,
    PARTITION lu_usps_ne
      TABLESPACE content_repo,
    PARTITION lu_usps_nv
      TABLESPACE content_repo,
    PARTITION lu_usps_nh
      TABLESPACE content_repo,
    PARTITION lu_usps_nj
      TABLESPACE content_repo,
    PARTITION lu_usps_nm
      TABLESPACE content_repo,
    PARTITION lu_usps_ny
      TABLESPACE content_repo,
    PARTITION lu_usps_nc
      TABLESPACE content_repo,
    PARTITION lu_usps_nd
      TABLESPACE content_repo,
    PARTITION lu_usps_oh
      TABLESPACE content_repo,
    PARTITION lu_usps_ok
      TABLESPACE content_repo,
    PARTITION lu_usps_or
      TABLESPACE content_repo,
    PARTITION lu_usps_pa
      TABLESPACE content_repo,
    PARTITION lu_usps_ri
      TABLESPACE content_repo,
    PARTITION lu_usps_sc
      TABLESPACE content_repo,
    PARTITION lu_usps_sd
      TABLESPACE content_repo,
    PARTITION lu_usps_tn
      TABLESPACE content_repo,
    PARTITION lu_usps_tx
      TABLESPACE content_repo,
    PARTITION lu_usps_ut
      TABLESPACE content_repo,
    PARTITION lu_usps_vt
      TABLESPACE content_repo,
    PARTITION lu_usps_va
      TABLESPACE content_repo,
    PARTITION lu_usps_wa
      TABLESPACE content_repo,
    PARTITION lu_usps_wv
      TABLESPACE content_repo,
    PARTITION lu_usps_wi
      TABLESPACE content_repo,
    PARTITION lu_usps_wy
      TABLESPACE content_repo,
    PARTITION lu_usps_us
      TABLESPACE content_repo,
    PARTITION lu_usps_gu
      TABLESPACE content_repo,
    PARTITION lu_usps_pr
      TABLESPACE content_repo,
    PARTITION lu_usps_as
      TABLESPACE content_repo,
    PARTITION lu_usps_aa
      TABLESPACE content_repo,
    PARTITION lu_usps_ae
      TABLESPACE content_repo,
    PARTITION lu_usps_ap
      TABLESPACE content_repo,
    PARTITION lu_usps_fm
      TABLESPACE content_repo,
    PARTITION lu_usps_vi
      TABLESPACE content_repo,
    PARTITION lu_usps_mh
      TABLESPACE content_repo,
    PARTITION lu_usps_mp
      TABLESPACE content_repo,
    PARTITION lu_usps_pw
      TABLESPACE content_repo,
    PARTITION lu_usps_x0
      TABLESPACE content_repo)),
  CONSTRAINT geo_polygon_usps_dtf2 FOREIGN KEY (geo_polygon_id) REFERENCES content_repo.geo_polygons ("ID")
) TABLESPACE content_repo
PARTITION BY LIST (state_code)
(PARTITION lu_usps_al VALUES ('AL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ak VALUES ('AK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ar VALUES ('AR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_az VALUES ('AZ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ca VALUES ('CA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_co VALUES ('CO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ct VALUES ('CT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_de VALUES ('DE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_dc VALUES ('DC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_fl VALUES ('FL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ga VALUES ('GA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_hi VALUES ('HI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_id VALUES ('ID')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_il VALUES ('IL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_in VALUES ('IN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ia VALUES ('IA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ks VALUES ('KS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ky VALUES ('KY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_la VALUES ('LA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_me VALUES ('ME')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_md VALUES ('MD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ma VALUES ('MA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_mi VALUES ('MI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_mn VALUES ('MN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ms VALUES ('MS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_mo VALUES ('MO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_mt VALUES ('MT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ne VALUES ('NE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_nv VALUES ('NV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_nh VALUES ('NH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_nj VALUES ('NJ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_nm VALUES ('NM')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ny VALUES ('NY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_nc VALUES ('NC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_nd VALUES ('ND')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_oh VALUES ('OH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ok VALUES ('OK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_or VALUES ('OR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_pa VALUES ('PA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ri VALUES ('RI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_sc VALUES ('SC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_sd VALUES ('SD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_tn VALUES ('TN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_tx VALUES ('TX')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ut VALUES ('UT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_vt VALUES ('VT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_va VALUES ('VA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_wa VALUES ('WA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_wv VALUES ('WV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_wi VALUES ('WI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_wy VALUES ('WY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_us VALUES ('US')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_gu VALUES ('GU')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_pr VALUES ('PR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_as VALUES ('AS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_aa VALUES ('AA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ae VALUES ('AE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_ap VALUES ('AP')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_fm VALUES ('FM')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_vi VALUES ('VI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_mh VALUES ('MH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_mp VALUES ('MP')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_pw VALUES ('PW')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION lu_usps_x0 VALUES (DEFAULT)
  INDEXING ON
  TABLESPACE content_repo)
PARALLEL 4;