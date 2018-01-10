CREATE TABLE content_repo.osr_as_complete_plus_tmp (
  zip_code VARCHAR2(5 CHAR),
  state_code VARCHAR2(2 CHAR),
  county_name VARCHAR2(65 CHAR),
  city_name VARCHAR2(65 CHAR),
  state_sales_tax VARCHAR2(35 CHAR),
  state_use_tax VARCHAR2(35 CHAR),
  county_sales_tax VARCHAR2(35 CHAR),
  county_use_tax VARCHAR2(35 CHAR),
  city_sales_tax VARCHAR2(35 CHAR),
  city_use_tax VARCHAR2(35 CHAR),
  mta_sales_tax VARCHAR2(35 CHAR),
  mta_use_tax VARCHAR2(35 CHAR),
  spd_sales_tax VARCHAR2(35 CHAR),
  spd_use_tax VARCHAR2(35 CHAR),
  other1_sales_tax VARCHAR2(35 CHAR),
  other1_use_tax VARCHAR2(35 CHAR),
  other2_sales_tax VARCHAR2(35 CHAR),
  other2_use_tax VARCHAR2(35 CHAR),
  other3_sales_tax VARCHAR2(35 CHAR),
  other3_use_tax VARCHAR2(35 CHAR),
  other4_sales_tax VARCHAR2(35 CHAR),
  other4_use_tax VARCHAR2(35 CHAR),
  total_sales_tax VARCHAR2(35 CHAR),
  total_use_tax VARCHAR2(35 CHAR),
  county_number VARCHAR2(35 CHAR),
  city_number VARCHAR2(35 CHAR),
  mta_name VARCHAR2(50 CHAR),
  mta_number VARCHAR2(35 CHAR),
  spd_name VARCHAR2(200 CHAR),
  spd_number VARCHAR2(35 CHAR),
  other1_name VARCHAR2(200 CHAR),
  other1_number VARCHAR2(35 CHAR),
  other2_name VARCHAR2(200 CHAR),
  other2_number VARCHAR2(35 CHAR),
  other3_name VARCHAR2(200 CHAR),
  other3_number VARCHAR2(35 CHAR),
  other4_name VARCHAR2(200 CHAR),
  other4_number VARCHAR2(35 CHAR),
  tax_shipping_alone VARCHAR2(35 CHAR),
  tax_shipping_and_handling VARCHAR2(35 CHAR),
  fips_state VARCHAR2(2 CHAR),
  fips_county VARCHAR2(3 CHAR),
  fips_city VARCHAR2(5 CHAR),
  geocode VARCHAR2(200 CHAR),
  mta_geocode VARCHAR2(50 CHAR),
  spd_geocode VARCHAR2(50 CHAR),
  other1_geocode VARCHAR2(50 CHAR),
  other2_geocode VARCHAR2(50 CHAR),
  other3_geocode VARCHAR2(50 CHAR),
  other4_geocode VARCHAR2(50 CHAR),
  geocode_long VARCHAR2(500 CHAR),
  state_effective_date VARCHAR2(15 CHAR),
  county_effective_date VARCHAR2(15 CHAR),
  city_effective_date VARCHAR2(15 CHAR),
  mta_effective_date VARCHAR2(15 CHAR),
  spd_effective_date VARCHAR2(15 CHAR),
  other1_effective_date VARCHAR2(15 CHAR),
  other2_effective_date VARCHAR2(15 CHAR),
  other3_effective_date VARCHAR2(15 CHAR),
  other4_effective_date VARCHAR2(15 CHAR),
  county_tax_collected_by VARCHAR2(250 CHAR),
  city_tax_collected_by VARCHAR2(250 CHAR),
  state_taxable_max VARCHAR2(20 CHAR),
  state_tax_over_max VARCHAR2(20 CHAR),
  county_taxable_max VARCHAR2(20 CHAR),
  county_tax_over_max VARCHAR2(20 CHAR),
  city_taxable_max VARCHAR2(20 CHAR),
  city_tax_over_max VARCHAR2(20 CHAR),
  sales_tax_holiday VARCHAR2(1 CHAR),
  sales_tax_holiday_dates VARCHAR2(50 CHAR),
  sales_tax_holiday_items VARCHAR2(250 CHAR),
  uaid VARCHAR2(60 CHAR),
  default_flag CHAR(1 CHAR),
  acceptable_city VARCHAR2(1 CHAR),
  other5_sales_tax VARCHAR2(35 CHAR),
  other5_use_tax VARCHAR2(35 CHAR),
  other6_sales_tax VARCHAR2(35 CHAR),
  other6_use_tax VARCHAR2(35 CHAR),
  other7_sales_tax VARCHAR2(35 CHAR),
  other7_use_tax VARCHAR2(35 CHAR),
  other5_name VARCHAR2(200 CHAR),
  other5_number VARCHAR2(35 CHAR),
  other6_name VARCHAR2(200 CHAR),
  other6_number VARCHAR2(35 CHAR),
  other7_name VARCHAR2(200 CHAR),
  other7_number VARCHAR2(35 CHAR),
  other5_geocode VARCHAR2(50 CHAR),
  other6_geocode VARCHAR2(50 CHAR),
  other7_geocode VARCHAR2(50 CHAR),
  other5_effective_date VARCHAR2(15 CHAR),
  other6_effective_date VARCHAR2(15 CHAR),
  other7_effective_date VARCHAR2(15 CHAR)
) TABLESPACE content_repo
PARTITION BY LIST (state_code)
(PARTITION os_cmpt_aa VALUES ('AA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ae VALUES ('AE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ak VALUES ('AK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_al VALUES ('AL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ap VALUES ('AP')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ar VALUES ('AR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_as VALUES ('AS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_az VALUES ('AZ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ca VALUES ('CA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_co VALUES ('CO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ct VALUES ('CT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_de VALUES ('DE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_dc VALUES ('DC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_fl VALUES ('FL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_fm VALUES ('FM')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ga VALUES ('GA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_gu VALUES ('GU')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_hi VALUES ('HI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_id VALUES ('ID')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_il VALUES ('IL')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_in VALUES ('IN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ia VALUES ('IA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ks VALUES ('KS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ky VALUES ('KY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_la VALUES ('LA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_me VALUES ('ME')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_md VALUES ('MD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ma VALUES ('MA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_mh VALUES ('MH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_mi VALUES ('MI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_mn VALUES ('MN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ms VALUES ('MS')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_mo VALUES ('MO')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_mp VALUES ('MP')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_mt VALUES ('MT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ne VALUES ('NE')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_nv VALUES ('NV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_nh VALUES ('NH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_nj VALUES ('NJ')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_nm VALUES ('NM')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ny VALUES ('NY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_nc VALUES ('NC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_nd VALUES ('ND')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_oh VALUES ('OH')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ok VALUES ('OK')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_or VALUES ('OR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_pa VALUES ('PA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_pr VALUES ('PR')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_pw VALUES ('PW')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ri VALUES ('RI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_sc VALUES ('SC')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_sd VALUES ('SD')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_tn VALUES ('TN')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_tx VALUES ('TX')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_ut VALUES ('UT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_va VALUES ('VA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_vi VALUES ('VI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_vt VALUES ('VT')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_wa VALUES ('WA')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_wi VALUES ('WI')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_wv VALUES ('WV')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_wy VALUES ('WY')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_us VALUES ('US')
  INDEXING ON
  TABLESPACE content_repo,
PARTITION os_cmpt_x0 VALUES (DEFAULT)
  INDEXING ON
  TABLESPACE content_repo);