CLASS zcl_cs1_setupclass DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " --- Factory-Methode ---
    " Erzeugt eine Instanz von lcl_setup_handler und gibt sie als Interface zurück
    " Damit kann man das Setup von außen starten ohne die lokale Klasse zu kennen
    CLASS-METHODS init_setup
      RETURNING VALUE(ro_setup) TYPE REF TO zif_system_setup1.

    " --- Interface für ADT Run-Konsole ---
    " Ermöglicht Ausführung über F9 in ABAP Development Tools
    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cs1_setupclass IMPLEMENTATION.

  METHOD init_setup.
    " -----------------------------------------------------------------
    " Factory-Pattern: Erzeugt Handler-Instanz
    " LCL_SETUP_HANDLER implementiert ZIF_SYSTEM_SETUP1
    " Rückgabe als Interface -> Lose Kopplung
    " -----------------------------------------------------------------
    ro_setup = NEW lcl_setup_handler( ).
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    " -----------------------------------------------------------------
    " Wird aufgerufen wenn du die Klasse in ADT mit F9 startest
    " Startet den kompletten Setup-Prozess:
    " 1. init_setup( ) -> Holt Handler-Instanz
    " 2. ->run_setup( out ) -> Führt Setup aus und schreibt Log in Konsole
    " -----------------------------------------------------------------
    init_setup( )->run_setup( out ).
  ENDMETHOD.
ENDCLASS.
