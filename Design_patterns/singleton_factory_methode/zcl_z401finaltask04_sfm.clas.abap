CLASS zcl_z401finaltask04_sfm DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_z401finaltask04_sfm IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " 1. Fuhrpark-Manager über das Singleton abrufen
    DATA(lo_rental_manager) = lcl_rental=>get_instance( ).

    " Erstbefüllung (Die ursprünglichen 10 Fahrzeuge)
    lo_rental_manager->collect_vehicles( ).


    " =========================================================================
    " ERSTE AUSGABE: Der initiale Fuhrpark (10 Einträge)
    " =========================================================================
    out->write( '--- AUFGABE 3: Initialer Fuhrpark (10 Fahrzeuge) ---' ).

    LOOP AT lo_rental_manager->get_sorted_vehicles( ) INTO DATA(ls_flat_init).
      out->write( |[{ ls_flat_init-vehicle_type }] { ls_flat_init-producer } { ls_flat_init-model } | &&

                  |Zulassung: { ls_flat_init-make DATE = ISO }, Preis: { ls_flat_init-price } EUR, | &&
                  |Farbe: { ls_flat_init-color } ({ ls_flat_init-specifics })| ).
    ENDLOOP.
    out->write( |\n| ).


    " =========================================================================
    " UPDATE-PHASE: Jeweils zwei neue LKWs und Busse hinzufügen
    " =========================================================================
    " LKW 1: DAF XG+ (Gültig, wird hinzugefügt)
    lo_rental_manager->add_vehicle( iv_type = 'TRUCK' iv_producer = 'DAF' iv_make = '20240115' iv_model = 'XG+'
                                    iv_price = 160000 iv_color = 'Gelb'   iv_cargo = '28.0' ).

    " LKW 2: Renault T-High wird ZWEIMAL aufgerufen (Erzeugt ein neues Duplikat)
    lo_rental_manager->add_vehicle( iv_type = 'TRUCK' iv_producer = 'Renault' iv_make = '20230510'
                                    iv_model = 'T-High' iv_price = 115000 iv_color = 'Rot'    iv_cargo = '22.0' ).
    lo_rental_manager->add_vehicle( iv_type = 'TRUCK' iv_producer = 'Renault' iv_make = '20230510'
                                    iv_model = 'T-High' iv_price = 115000 iv_color = 'Rot'    iv_cargo = '22.0' ).

    " Bus 1: BYD B12 (Gültig, wird hinzugefügt)
    lo_rental_manager->add_vehicle( iv_type = 'BUS'   iv_producer = 'BYD'     iv_make = '20240320'
                                    iv_model = 'B12'    iv_price = 320000 iv_color = 'Grün'   iv_seats = 85 ).

    " Bus 2: Irizar i8 wird ZWEIMAL aufgerufen (Erzeugt ein neues Duplikat)
    lo_rental_manager->add_vehicle( iv_type = 'BUS'   iv_producer = 'Irizar'  iv_make = '20220915'
                                    iv_model = 'i8'     iv_price = 290000 iv_color = 'Weiß'   iv_seats = 58 ).
    lo_rental_manager->add_vehicle( iv_type = 'BUS'   iv_producer = 'Irizar'  iv_make = '20220915'
                                    iv_model = 'i8'     iv_price = 290000 iv_color = 'Weiß'   iv_seats = 58 ).


    " ==============================================================================================
    " AUFGABE 5: Kapazitäten prüfen & Fehlertabelle/Ausnahmetabelle ausgeben (Inkl. neuer Duplikate)
    " ==============================================================================================
    TRY.
        lo_rental_manager->check_truck_capacities( ).
        out->write( '--- Kapazitätsprüfung: Alle LKWs im grünen Bereich! ---' ).
      CATCH zcx_d401_04_failed_sfm.
        out->write( '--- AUFGABE 5: AUSNAHMETABELLE (Ausnahmen abgefangen ohne Abbruch) ---' ).
        LOOP AT lo_rental_manager->mt_exceptions INTO DATA(lo_ex).
          out->write( lo_ex->get_text( ) ).
        ENDLOOP.
    ENDTRY.
    out->write( |\n| ).


    " ===============================================================================
    " ZWEITE AUSGABE: Aktualisierter Fuhrpark nach dem Update (Mehr als 10 Einträge)
    " ===============================================================================
    out->write( '--- AUFGABE 6: Aktualisierter Fuhrpark (Inklusive neuer, fehlerfreier Fahrzeuge) ---' ).

    " Der Fuhrpark enthält jetzt exakt 14 Fahrzeuge (10 Start-Fahrzeuge + 4 neue, eindeutige Fahrzeuge)
    LOOP AT lo_rental_manager->get_sorted_vehicles( ) INTO DATA(ls_flat_updated).
      out->write( |[{ ls_flat_updated-vehicle_type }] { ls_flat_updated-producer } { ls_flat_updated-model } | &&
                  |Zulassung: { ls_flat_updated-make DATE = ISO }, Preis: { ls_flat_updated-price } EUR, | &&
                  |Farbe: { ls_flat_updated-color } ({ ls_flat_updated-specifics })| ).
    ENDLOOP.
    out->write( |\n| ).


    " =========================================================================
    " AUFGABE 4A/B: LKW mit höchster Kapazität und Bus mit höchster Sitzplatzanzahl, per Downcast ermitteln
    " =========================================================================
    out->write( '--- AUFGABE 4A: Bestimmung des LKW mit maximaler Kapazität ---' ).
    DATA(lo_max_truck) = lo_rental_manager->find_max_cargo_truck( ).

    IF lo_max_truck IS BOUND.
      out->write( lo_max_truck->display_attributes( ) ).
    ELSE.
      out->write( 'Kein gültiger LKW im Fuhrpark vorhanden.' ).
    ENDIF.

    out->write( |\n| ).

    out->write( '--- AUFGABE 4B: Bestimmung des Busses mit maximaler Sitzplatzanzahl ---' ).
    DATA(lo_max_bus) = lo_rental_manager->find_max_seats_bus( ).

    IF lo_max_bus IS BOUND.
      out->write( lo_max_bus->display_attributes( ) ).
    ELSE.
      out->write( 'Kein gültiger Bus im Fuhrpark vorhanden.' ).
    ENDIF.

  ENDMETHOD.


ENDCLASS.


