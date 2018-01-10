CREATE OR REPLACE PACKAGE content_repo."TIMER" AS
-- Purpose: Timing package for testing durations of alternative coding approaches.
-- Based on Steven Feuerstein's original timer package
--------------------------------------------------------------------------------
   secs  CONSTANT PLS_INTEGER := 1;
   mins  CONSTANT PLS_INTEGER := 2;
   hrs   CONSTANT PLS_INTEGER := 3;
   days  CONSTANT PLS_INTEGER := 4;

   PROCEDURE startit (
             show_stack_in IN BOOLEAN DEFAULT FALSE
             );

   PROCEDURE display (
             prefix_in IN VARCHAR2 DEFAULT NULL,
             format_in IN PLS_INTEGER DEFAULT timer.secs
             );

END timer;
 
/