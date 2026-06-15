*"* use this source file for your ABAP unit test classes
CLASS lcl_test_rental DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO lcl_rental.

    METHODS setup.
    METHODS test_collect_vehicles       FOR TESTING.
    METHODS test_find_max_cargo_truck   FOR TESTING.
    METHODS test_check_truck_capacities FOR TESTING.
    METHODS text_find_max_seats_bus     FOR TESTING.
ENDCLASS.


CLASS lcl_test_rental IMPLEMENTATION.

  METHOD setup.
    " 1. Singleton-Instanz holen
    mo_cut = lcl_rental=>get_instance( ).

    " 2. KORREKTUR: Instanztabellen vor JEDEM Testlauf leeren (Isolierung für das Singleton)
    CLEAR mo_cut->mt_vehicles.
    CLEAR mo_cut->mt_exceptions.
  ENDMETHOD.

  METHOD test_collect_vehicles.
    mo_cut->collect_vehicles( ).

    " Es werden 10 eindeutige Fahrzeuge hinzugefügt. Das MAN-Duplikat wird abgelehnt.
    cl_abap_unit_assert=>assert_equals(
      act = lines( mo_cut->mt_vehicles )
      exp = 10
      msg = 'Die Fahrzeugliste muss genau 10 gültige Einträge enthalten.' ).
  ENDMETHOD.

  METHOD test_find_max_cargo_truck.
    mo_cut->collect_vehicles( ).
    DATA(lo_top_truck) = mo_cut->find_max_cargo_truck( ).

    cl_abap_unit_assert=>assert_bound(
      act = lo_top_truck
      msg = 'Es hätte ein LKW-Objekt zurückgegeben werden müssen.' ).

    " KORREKTUR: Typkonflikt behoben. Vergleichswert (exp) direkt als Zahl übergeben
    cl_abap_unit_assert=>assert_equals(
      act = lo_top_truck->get_cargo( )
      exp = CONV ty_cargo( '26.0' )
      msg = 'Der stärkste LKW müsste eine Kapazität von 26.0t besitzen (Volvo FH16).' ).
  ENDMETHOD.

  METHOD test_check_truck_capacities.
    " Initialer Zustand: mt_exceptions ist durch die setup-Methode leer.
    mo_cut->collect_vehicles( ).

    " WICHTIG: Nach collect_vehicles befindet sich bereits 1 Eintrag (das MAN-Duplikat)
    " in der Tabelle mt_exceptions.
    DATA(lv_initial_errors) = lines( mo_cut->mt_exceptions ).

    TRY.
        " Führt die Kapazitätsprüfung aus. Hier kommen 2 weitere Fehler hinzu (< 2t)
        mo_cut->check_truck_capacities( ).

        " Wenn die Methode hier ankommt, wurde fälschlicherweise keine Exception geworfen
        cl_abap_unit_assert=>fail( msg = 'Die Ausnahmeklasse zcx_d401_04_failed_sfm wurde nicht geworfen.' ).

      CATCH zcx_d401_04_failed_sfm.
        " Exception wurde wie erwartet geworfen.

        " KORREKTUR: Es müssen insgesamt 3 Fehler vorliegen (1 Duplikat + 2 untergewichtige LKWs)
        cl_abap_unit_assert=>assert_equals(
          act = lines( mo_cut->mt_exceptions )
          exp = lv_initial_errors + 2
          msg = 'Es müssten sich insgesamt 3 Ausnahmen in mt_exceptions befinden.' ).

        DATA lv_mercedes_found TYPE abap_bool VALUE abap_false.
        DATA lv_iveco_found    TYPE abap_bool VALUE abap_false.

        " Wir loopen über die Fehlertabelle des Managers
        LOOP AT mo_cut->mt_exceptions INTO DATA(lo_exc).
          " Falls deine Exception-Klasse die Attribute mv_model / mv_make besitzt:
          " Alternativ kannst du lo_exc->get_text( ) auf Teilstrings prüfen, falls die Attribute geschützt sind.
          TRY.
              " Versuchen, über ein dynamisches Auslesen oder das Attribut an den Namen zu kommen
              " Falls mv_model ein öffentliches Attribut von zcx_d401_04_failed_sfm ist:
              IF lo_exc->mv_model = 'Actros'.
                lv_mercedes_found = abap_true.
              ELSEIF lo_exc->mv_model = 'S-Way'.
                lv_iveco_found = abap_true.
              ENDIF.
            CATCH cx_sy_ref_is_initial.
          ENDTRY.
        ENDLOOP.

        " Alternativ-Überprüfung via Textinhalt, falls die Attribute in der Exception nicht öffentlich deklariert sind:
        IF lv_mercedes_found = abap_false OR lv_iveco_found = abap_false.
          LOOP AT mo_cut->mt_exceptions INTO lo_exc.
            DATA(lv_text) = lo_exc->get_text( ).
            IF lv_text CS 'Actros'.
              lv_mercedes_found = abap_true.
            ENDIF.
            IF lv_text CS 'S-Way'.
              lv_iveco_found = abap_true.
            ENDIF.
          ENDLOOP.
        ENDIF.

        " Auswertung der gefundenen Fahrzeuge
        cl_abap_unit_assert=>assert_true(
          act = lv_mercedes_found
          msg = 'Der untergewichtige Mercedes Actros fehlt in den aufgezeichneten Ausnahmen.' ).

        cl_abap_unit_assert=>assert_true(
          act = lv_iveco_found
          msg = 'Der untergewichtige Iveco S-Way fehlt in den aufgezeichneten Ausnahmen.' ).
    ENDTRY.
  ENDMETHOD.
  METHOD text_find_max_seats_bus.
    mo_cut->collect_vehicles( ).
    DATA(lo_top_bus) = mo_cut->find_max_seats_bus( ).

    cl_abap_unit_assert=>assert_bound(
      act = lo_top_bus
      msg = 'Es hätte ein Bus-Objekt zurückgegeben werden müssen.' ).

    " KORREKTUR: Typkonflikt behoben. Vergleichswert (exp) direkt als Zahl übergeben
    cl_abap_unit_assert=>assert_equals(
      act = lo_top_bus->get_seats( )
      exp =  60
      msg = 'Der Bus mit der höchsten Anzahl von 60 Sitzplätzen INNERHALB von Local Types ist Scania Interlink! ' ).
  ENDMETHOD.

ENDCLASS.



