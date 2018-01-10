CREATE OR REPLACE PACKAGE content_repo."TAX_APPLICABILITY" AS

FUNCTION get_revision (
    entity_id_io IN OUT NUMBER,
    entity_nkid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER;

FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER;

function get_current_revision(p_nkid IN NUMBER) RETURN NUMBER;

END TAX_APPLICABILITY;
/