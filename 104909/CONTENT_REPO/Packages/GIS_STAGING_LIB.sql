CREATE OR REPLACE PACKAGE content_repo."GIS_STAGING_LIB" as
  -- possible more secure/stable to use a For loop - not sure about speed though.
  type r_feed is record(usps_id NUMBER, recno NUMBER);
  type t_feed is table of r_feed;
  --
  function f_GetFeed(pState_code IN VARCHAR2) return t_feed pipelined;

  -- Create the Staging MT table : note that this one grabs all
  procedure P_ProcessMT(pState_code IN VARCHAR2);

  -- Create the lookup : note that this one grabs all
  procedure P_ProcessLookup(pState IN VARCHAR2);

  -- Refresh the Partitioned Materialzied View
  procedure P_RefreshMV(pState_code IN VARCHAR2); -- crapp-2794

end GIS_STAGING_LIB;
 
/