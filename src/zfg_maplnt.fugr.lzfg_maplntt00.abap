*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZMAPLNT.........................................*
DATA:  BEGIN OF STATUS_ZMAPLNT                       .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZMAPLNT                       .
CONTROLS: TCTRL_ZMAPLNT
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZMAPLNT                       .
TABLES: ZMAPLNT                        .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
