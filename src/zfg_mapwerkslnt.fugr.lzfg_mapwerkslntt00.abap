*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZMAPWERKSLNT....................................*
DATA:  BEGIN OF STATUS_ZMAPWERKSLNT                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZMAPWERKSLNT                  .
CONTROLS: TCTRL_ZMAPWERKSLNT
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZMAPWERKSLNT                  .
TABLES: ZMAPWERKSLNT                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
