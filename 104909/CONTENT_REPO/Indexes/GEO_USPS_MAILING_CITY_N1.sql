CREATE INDEX content_repo.geo_usps_mailing_city_n1 ON content_repo.geo_usps_mailing_city(state_code,zip)

TABLESPACE content_repo;