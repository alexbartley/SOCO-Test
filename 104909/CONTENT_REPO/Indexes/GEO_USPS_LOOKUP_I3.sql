CREATE INDEX content_repo.geo_usps_lookup_i3 ON content_repo.geo_usps_lookup(geo_polygon_id)

LOCAL (PARTITION lk_usps_al
  TABLESPACE content_repo,
PARTITION lk_usps_ak
  TABLESPACE content_repo,
PARTITION lk_usps_ar
  TABLESPACE content_repo,
PARTITION lk_usps_az
  TABLESPACE content_repo,
PARTITION lk_usps_ca
  TABLESPACE content_repo,
PARTITION lk_usps_co
  TABLESPACE content_repo,
PARTITION lk_usps_ct
  TABLESPACE content_repo,
PARTITION lk_usps_de
  TABLESPACE content_repo,
PARTITION lk_usps_dc
  TABLESPACE content_repo,
PARTITION lk_usps_fl
  TABLESPACE content_repo,
PARTITION lk_usps_ga
  TABLESPACE content_repo,
PARTITION lk_usps_hi
  TABLESPACE content_repo,
PARTITION lk_usps_id
  TABLESPACE content_repo,
PARTITION lk_usps_il
  TABLESPACE content_repo,
PARTITION lk_usps_in
  TABLESPACE content_repo,
PARTITION lk_usps_ia
  TABLESPACE content_repo,
PARTITION lk_usps_ks
  TABLESPACE content_repo,
PARTITION lk_usps_ky
  TABLESPACE content_repo,
PARTITION lk_usps_la
  TABLESPACE content_repo,
PARTITION lk_usps_me
  TABLESPACE content_repo,
PARTITION lk_usps_md
  TABLESPACE content_repo,
PARTITION lk_usps_ma
  TABLESPACE content_repo,
PARTITION lk_usps_mi
  TABLESPACE content_repo,
PARTITION lk_usps_mn
  TABLESPACE content_repo,
PARTITION lk_usps_ms
  TABLESPACE content_repo,
PARTITION lk_usps_mo
  TABLESPACE content_repo,
PARTITION lk_usps_mt
  TABLESPACE content_repo,
PARTITION lk_usps_ne
  TABLESPACE content_repo,
PARTITION lk_usps_nv
  TABLESPACE content_repo,
PARTITION lk_usps_nh
  TABLESPACE content_repo,
PARTITION lk_usps_nj
  TABLESPACE content_repo,
PARTITION lk_usps_nm
  TABLESPACE content_repo,
PARTITION lk_usps_ny
  TABLESPACE content_repo,
PARTITION lk_usps_nc
  TABLESPACE content_repo,
PARTITION lk_usps_nd
  TABLESPACE content_repo,
PARTITION lk_usps_oh
  TABLESPACE content_repo,
PARTITION lk_usps_ok
  TABLESPACE content_repo,
PARTITION lk_usps_or
  TABLESPACE content_repo,
PARTITION lk_usps_pa
  TABLESPACE content_repo,
PARTITION lk_usps_ri
  TABLESPACE content_repo,
PARTITION lk_usps_sc
  TABLESPACE content_repo,
PARTITION lk_usps_sd
  TABLESPACE content_repo,
PARTITION lk_usps_tn
  TABLESPACE content_repo,
PARTITION lk_usps_tx
  TABLESPACE content_repo,
PARTITION lk_usps_ut
  TABLESPACE content_repo,
PARTITION lk_usps_vt
  TABLESPACE content_repo,
PARTITION lk_usps_va
  TABLESPACE content_repo,
PARTITION lk_usps_wa
  TABLESPACE content_repo,
PARTITION lk_usps_wv
  TABLESPACE content_repo,
PARTITION lk_usps_wi
  TABLESPACE content_repo,
PARTITION lk_usps_wy
  TABLESPACE content_repo,
PARTITION lk_usps_us
  TABLESPACE content_repo,
PARTITION lk_usps_gu
  TABLESPACE content_repo,
PARTITION lk_usps_pr
  TABLESPACE content_repo,
PARTITION lk_usps_as
  TABLESPACE content_repo,
PARTITION lk_usps_aa
  TABLESPACE content_repo,
PARTITION lk_usps_ae
  TABLESPACE content_repo,
PARTITION lk_usps_ap
  TABLESPACE content_repo,
PARTITION lk_usps_fm
  TABLESPACE content_repo,
PARTITION lk_usps_vi
  TABLESPACE content_repo,
PARTITION lk_usps_mh
  TABLESPACE content_repo,
PARTITION lk_usps_mp
  TABLESPACE content_repo,
PARTITION lk_usps_pw
  TABLESPACE content_repo,
PARTITION lk_usps_x0
  TABLESPACE content_repo) PARALLEL 4;