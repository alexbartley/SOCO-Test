CREATE OR REPLACE PACKAGE content_repo."POST_PUBLISH"
  IS

   PROCEDURE push_administrators;
   PROCEDURE push_jurisdictions;
   PROCEDURE push_taxes;
   PROCEDURE push_taxabilities;
   PROCEDURE push_reference_groups;
   PROCEDURE push_commodities;
   PROCEDURE push_tags;
   PROCEDURE push_lookups;

END post_publish;
/