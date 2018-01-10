CREATE OR REPLACE PACKAGE content_repo.errnums
IS
    en_cannot_delete_record CONSTANT NUMBER := -20001;
    cannot_delete_record EXCEPTION;
    PRAGMA EXCEPTION_INIT (cannot_delete_record, -20001);

    en_cannot_update_record CONSTANT NUMBER := -20002;
    cannot_update_record EXCEPTION;
    PRAGMA EXCEPTION_INIT (cannot_update_record, -20002);

    en_duplicate_key CONSTANT NUMBER := -20004;
    duplicate_key EXCEPTION;
    PRAGMA EXCEPTION_INIT (duplicate_key, -20004);

    en_rec_has_dependencies CONSTANT NUMBER := -20003;
    rec_has_dependencies EXCEPTION;
    PRAGMA EXCEPTION_INIT (rec_has_dependencies, -20003);

    en_missing_req_val CONSTANT NUMBER := -20100;
    missing_req_val EXCEPTION;
    PRAGMA EXCEPTION_INIT (missing_req_val, -20100);

    en_delete_taxability_taxes CONSTANT NUMBER := -20101;
    delete_taxability_taxes EXCEPTION;
    PRAGMA EXCEPTION_INIT(delete_taxability_taxes, -20101);


    en_child_exists CONSTANT NUMBER := -6512;
    child_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT (child_exists, -6512);

	-- Added for CRAPP-2690
	en_cannot_update_child CONSTANT NUMBER := -20005;
    cannot_update_child EXCEPTION;
    PRAGMA EXCEPTION_INIT (cannot_update_child, -20005);

    -- Added for CRAPP-3886
	en_cannot_delete_revision CONSTANT NUMBER := -20006;
    cannot_delete_revision EXCEPTION;
    PRAGMA EXCEPTION_INIT (cannot_delete_revision, -20006);

    -- Added for CRAPP-4106
	en_cannot_change_appl_type CONSTANT NUMBER := -20007;
    cannot_change_appl_type EXCEPTION;
    PRAGMA EXCEPTION_INIT (cannot_change_appl_type, -20007);


    -- Added for CRAPP-3921
	en_recs_unlocked_in_mid_of_pub CONSTANT NUMBER := -20008;
    recs_unlocked_in_mid_of_pub EXCEPTION;
    PRAGMA EXCEPTION_INIT (recs_unlocked_in_mid_of_pub, -20008);

END ERRNUMS;
/