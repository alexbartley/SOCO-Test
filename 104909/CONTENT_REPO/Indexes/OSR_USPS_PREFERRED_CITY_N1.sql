CREATE INDEX content_repo.osr_usps_preferred_city_n1 ON content_repo.osr_usps_preferred_city(state_code,zip,area_id)

TABLESPACE content_repo;