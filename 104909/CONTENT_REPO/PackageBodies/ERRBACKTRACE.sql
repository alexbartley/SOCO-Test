CREATE OR REPLACE PACKAGE BODY content_repo."ERRBACKTRACE"
IS
   -- Strings that delimit different parts of line in stack.
   c_name_delim   CONSTANT CHAR (1) := '"';
   c_dot_delim    CONSTANT CHAR (1) := '.';
   c_line_delim   CONSTANT CHAR (4) := 'line';
   c_eol_delim    CONSTANT CHAR (1) := CHR (10);

   --
   FUNCTION info (backtrace_in IN VARCHAR2)
      RETURN error_rt
   IS
      -- Lots of INSTRs to come; these variables keep track
      -- of the start and end points of various portions of the string.
      l_at_loc           PLS_INTEGER;
      l_dot_loc          PLS_INTEGER;
      l_name_start_loc   PLS_INTEGER;
      l_name_end_loc     PLS_INTEGER;
      l_line_loc         PLS_INTEGER;
      l_eol_loc          PLS_INTEGER;
      --
      retval             error_rt;

      PROCEDURE initialize_values
      IS
      BEGIN
         l_name_start_loc := INSTR (backtrace_in, c_name_delim, 1, 1);
         l_dot_loc := INSTR (backtrace_in, c_dot_delim);
         l_name_end_loc := INSTR (backtrace_in, c_name_delim, 1, 2);
         l_line_loc := INSTR (backtrace_in, c_line_delim);
         l_eol_loc := INSTR (backtrace_in, c_eol_delim);

         IF l_eol_loc = 0
         THEN
            l_eol_loc := LENGTH (backtrace_in) + 1;
         END IF;
      END initialize_values;
   BEGIN
      initialize_values;
      --
      retval.program_owner :=
         SUBSTR (backtrace_in
               , l_name_start_loc + 1
               , l_dot_loc - l_name_start_loc - 1
                );
      --
      retval.program_name :=
          SUBSTR (backtrace_in, l_dot_loc + 1, l_name_end_loc - l_dot_loc - 1);
      --
      retval.line_number :=
             SUBSTR (backtrace_in, l_line_loc + 5, l_eol_loc - l_line_loc - 5);
      RETURN retval;
   END info;

   PROCEDURE show_info (backtrace_in IN VARCHAR2)
   IS
      l_line   error_rt;
   BEGIN
      l_line := info (backtrace_in);
      DBMS_OUTPUT.put_line ('Program owner = ' || l_line.program_owner);
      DBMS_OUTPUT.put_line ('Program name = ' || l_line.program_name);
      DBMS_OUTPUT.put_line ('Line number = ' || l_line.line_number);
   END show_info;
END errbacktrace;
/