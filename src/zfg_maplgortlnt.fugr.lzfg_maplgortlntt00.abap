*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZMAPLGORTLNT....................................*
DATA:  BEGIN OF STATUS_ZMAPLGORTLNT                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZMAPLGORTLNT                  .
CONTROLS: TCTRL_ZMAPLGORTLNT
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZMAPLGORTLNT                  .
TABLES: ZMAPLGORTLNT                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
