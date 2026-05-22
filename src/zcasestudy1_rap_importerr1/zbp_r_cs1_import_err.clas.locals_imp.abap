CLASS lhc_ZrCs1ImportErr DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZrCs1ImportErr RESULT result.

ENDCLASS.

CLASS lhc_ZrCs1ImportErr IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

ENDCLASS.
