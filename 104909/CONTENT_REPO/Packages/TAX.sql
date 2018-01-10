CREATE OR REPLACE PACKAGE content_repo."TAX"
  IS
FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER;

FUNCTION get_revision (
    entity_id_io IN OUT NUMBER,
    entity_nkid_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER;

FUNCTION get_revision_taxout (
    entity_id_i IN NUMBER,
    entered_by_i IN NUMBER
) RETURN NUMBER;

FUNCTION get_current_revision (p_nkid IN NUMBER) RETURN NUMBER;
PROCEDURE unique_check(juris_nkid_i IN NUMBER, ref_code_i IN VARCHAR2, nkid_i IN NUMBER);
END; -- Package spec
 
/