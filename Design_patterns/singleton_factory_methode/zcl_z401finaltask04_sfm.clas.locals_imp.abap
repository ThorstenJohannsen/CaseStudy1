" =========================================================================
" LOCAL TYPES - TEIL 1 (Zuerst kopieren)
" =========================================================================

TYPES ty_cargo TYPE p LENGTH 8 DECIMALS 2.

" Struktur für die flache Konsolenausgabe (Sortierung)
TYPES: BEGIN OF ty_flat_vehicle,
         vehicle_type TYPE string,
         producer     TYPE string,
         model        TYPE string,
         make         TYPE d,
         price        TYPE p LENGTH 8 DECIMALS 2,
         color        TYPE string,
         specifics    TYPE string,
       END OF ty_flat_vehicle.

TYPES ty_flat_vehicles_tt TYPE STANDARD TABLE OF ty_flat_vehicle WITH EMPTY KEY.


" --- FAHRZEUG (BASISKLASSE) ---
CLASS lcl_vehicle DEFINITION ABSTRACT.
  PUBLIC SECTION.
    METHODS display_attributes RETURNING VALUE(rv_text) TYPE string.
    METHODS get_make           RETURNING VALUE(rv_make) TYPE d.
    METHODS get_model          RETURNING VALUE(rv_model) TYPE string.
    METHODS get_producer       RETURNING VALUE(rv_producer) TYPE string.

    DATA mv_producer TYPE string READ-ONLY.
    DATA mv_make     TYPE d      READ-ONLY.
    DATA mv_model    TYPE string READ-ONLY.
    DATA mv_price    TYPE p LENGTH 8 DECIMALS 2 READ-ONLY.
    DATA mv_color    TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        iv_producer TYPE string
        iv_make     TYPE d
        iv_model    TYPE string
        iv_price    TYPE p
        iv_color    TYPE string.

  PROTECTED SECTION.

ENDCLASS.

CLASS lcl_vehicle IMPLEMENTATION.
  METHOD constructor.
    me->mv_producer = iv_producer.
    me->mv_make     = iv_make.
    me->mv_model    = iv_model.
    me->mv_price    = iv_price.
    me->mv_color    = iv_color.
  ENDMETHOD.

  METHOD display_attributes.
    rv_text = |Hersteller: { mv_producer }, Zulassung: { mv_make DATE = ISO }, Modell: { mv_model }, Preis: { mv_price } EUR, Farbe: { mv_color }|.
  ENDMETHOD.

  METHOD get_make.     rv_make = me->mv_make.     ENDMETHOD.
  METHOD get_model.    rv_model = me->mv_model.   ENDMETHOD.
  METHOD get_producer. rv_producer = me->mv_producer. ENDMETHOD.
ENDCLASS.


" --- LASTKRAFTWAGEN (FACTORY PATTERN) ---
CLASS lcl_truck DEFINITION INHERITING FROM lcl_vehicle FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS get_instance_truck
      IMPORTING
        iv_producer     TYPE string
        iv_make         TYPE d
        iv_model        TYPE string
        iv_price        TYPE p
        iv_color        TYPE string
        iv_cargo        TYPE ty_cargo
      RETURNING
        VALUE(ro_truck) TYPE REF TO lcl_truck.

    METHODS display_attributes REDEFINITION.
    METHODS get_cargo RETURNING VALUE(rv_cargo) TYPE ty_cargo.

  PRIVATE SECTION.
    METHODS constructor
      IMPORTING
        iv_producer TYPE string
        iv_make     TYPE d
        iv_model    TYPE string
        iv_price    TYPE p
        iv_color    TYPE string
        iv_cargo    TYPE ty_cargo.
    DATA mv_cargo TYPE ty_cargo.
ENDCLASS.

CLASS lcl_truck IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_producer = iv_producer iv_make = iv_make iv_model = iv_model
                        iv_price = iv_price iv_color = iv_color ).
    me->mv_cargo = iv_cargo.
  ENDMETHOD.

  METHOD get_instance_truck.
    ro_truck = NEW #( iv_producer = iv_producer iv_make = iv_make iv_model = iv_model
                      iv_price = iv_price iv_color = iv_color iv_cargo = iv_cargo ).
  ENDMETHOD.

  METHOD display_attributes.
    rv_text = |[TRUCK] { super->display_attributes( ) }, Kapazität: { mv_cargo }t|.
  ENDMETHOD.

  METHOD get_cargo.
    rv_cargo = me->mv_cargo.
  ENDMETHOD.

ENDCLASS.

" =========================================================================
" LOCAL TYPES - TEIL 2 (Direkt unter Teil 1 einfügen)
" =========================================================================

" --- OMNIBUS (FACTORY PATTERN) ---
CLASS lcl_bus DEFINITION INHERITING FROM lcl_vehicle FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS get_instance_bus
      IMPORTING
        iv_producer   TYPE string
        iv_make       TYPE d
        iv_model      TYPE string
        iv_price      TYPE p
        iv_color      TYPE string
        iv_seats      TYPE i
      RETURNING
        VALUE(ro_bus) TYPE REF TO lcl_bus.

    METHODS display_attributes REDEFINITION.
    METHODS get_seats RETURNING VALUE(rv_seats) TYPE i.

  PRIVATE SECTION.
    METHODS constructor
      IMPORTING
        iv_producer TYPE string
        iv_make     TYPE d
        iv_model    TYPE string
        iv_price    TYPE p
        iv_color    TYPE string
        iv_seats    TYPE i.
    DATA mv_seats TYPE i.
ENDCLASS.

CLASS lcl_bus IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_producer = iv_producer iv_make = iv_make iv_model = iv_model
                        iv_price = iv_price iv_color = iv_color ).
    me->mv_seats = iv_seats.
  ENDMETHOD.

  METHOD get_instance_bus.
    ro_bus = NEW #( iv_producer = iv_producer iv_make = iv_make iv_model = iv_model
                    iv_price = iv_price iv_color = iv_color iv_seats = iv_seats ).
  ENDMETHOD.

  METHOD display_attributes.
    rv_text = |[BUS] { super->display_attributes( ) }, Sitzplätze: { mv_seats }|.
  ENDMETHOD.

  METHOD get_seats.
    rv_seats = me->mv_seats.
  ENDMETHOD.

ENDCLASS.


" --- AUTOVERMIETUNG (SINGLETON PATTERN) ---
CLASS lcl_rental DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO lcl_rental.

    DATA mt_vehicles   TYPE STANDARD TABLE OF REF TO lcl_vehicle WITH EMPTY KEY.
    DATA mt_exceptions TYPE STANDARD TABLE OF REF TO zcx_d401_04_failed_sfm WITH EMPTY KEY.

    METHODS collect_vehicles.
    METHODS find_max_cargo_truck RETURNING VALUE(ro_truck) TYPE REF TO lcl_truck.
    METHODS find_max_seats_bus RETURNING VALUE(ro_bus) TYPE REF TO lcl_bus.
    METHODS check_truck_capacities RAISING zcx_d401_04_failed_sfm.
    METHODS get_sorted_vehicles  RETURNING VALUE(rt_flat_table) TYPE ty_flat_vehicles_tt.

    METHODS add_vehicle
      IMPORTING
        iv_type           TYPE string
        iv_producer       TYPE string
        iv_make           TYPE d
        iv_model          TYPE string
        iv_price          TYPE p
        iv_color          TYPE string
        iv_cargo          TYPE ty_cargo OPTIONAL
        iv_seats          TYPE i OPTIONAL
      RETURNING
        VALUE(ro_vehicle) TYPE REF TO lcl_vehicle.

  PRIVATE SECTION.
    CLASS-DATA go_instance TYPE REF TO lcl_rental.
    METHODS constructor.
ENDCLASS.

CLASS lcl_rental IMPLEMENTATION.
  METHOD constructor.
  ENDMETHOD.

  METHOD get_instance.
    IF go_instance IS NOT BOUND.
      go_instance = NEW #( ).
    ENDIF.
    ro_instance = go_instance.
  ENDMETHOD.

  METHOD collect_vehicles.
    CLEAR mt_vehicles.
    me->add_vehicle( iv_type = 'TRUCK' iv_producer = 'MAN'      iv_make = '20210515' iv_model = 'TGX'
                     iv_price = 120000 iv_color = 'Blau'   iv_cargo = '18.5' ).
    me->add_vehicle( iv_type = 'TRUCK' iv_producer = 'Scania'   iv_make = '20220820' iv_model = 'R500'
                     iv_price = 140000 iv_color = 'Rot'    iv_cargo = '24.0' ).
    me->add_vehicle( iv_type = 'TRUCK' iv_producer = 'Volvo'    iv_make = '20231102' iv_model = 'FH16'
                     iv_price = 150000 iv_color = 'Weiß'   iv_cargo = '26.0' ).
    me->add_vehicle( iv_type = 'TRUCK' iv_producer = 'Mercedes' iv_make = '20200110' iv_model = 'Actros'
                     iv_price = 135000 iv_color = 'Silber' iv_cargo = '1.8' ).
    me->add_vehicle( iv_type = 'TRUCK' iv_producer = 'Iveco'    iv_make = '20190412' iv_model = 'S-Way'
                     iv_price = 95000  iv_color = 'Grün'   iv_cargo = '1.5' ).

    " Test-Duplikat für die Fehlertabelle (Aufgabe 5)
    me->add_vehicle( iv_type = 'TRUCK' iv_producer = 'MAN'      iv_make = '20210515' iv_model = 'TGX'
                     iv_price = 120000 iv_color = 'Blau'   iv_cargo = '18.5' ).

    me->add_vehicle( iv_type = 'BUS'   iv_producer = 'Mercedes' iv_make = '20210601' iv_model = 'Citaro'
                     iv_price = 210000 iv_color = 'Gelb'    iv_seats = 45 ).
    me->add_vehicle( iv_type = 'BUS'   iv_producer = 'MAN'      iv_make = '20220228' iv_model = 'Lion Coach'
                     iv_price = 250000 iv_color = 'Grau' iv_seats = 55 ).
    me->add_vehicle( iv_type = 'BUS'   iv_producer = 'Setra'    iv_make = '20230714' iv_model = 'S 515'
                     iv_price = 280000 iv_color = 'Schwarz' iv_seats = 49 ).
    me->add_vehicle( iv_type = 'BUS'   iv_producer = 'Scania'   iv_make = '20201010' iv_model = 'Interlink'
                     iv_price = 195000 iv_color = 'Weiß'  iv_seats = 60 ).
    me->add_vehicle( iv_type = 'BUS'   iv_producer = 'Volvo'    iv_make = '20211225' iv_model = '9700'
                     iv_price = 230000 iv_color = 'Rot'     iv_seats = 52 ).
  ENDMETHOD.

  METHOD add_vehicle.
    DATA lv_exists TYPE abap_bool VALUE abap_false.

    LOOP AT mt_vehicles INTO DATA(lo_existing).
      IF lo_existing->get_producer( ) = iv_producer AND
         lo_existing->get_model( )    = iv_model    AND
         lo_existing->get_make( )     = iv_make.
        lv_exists = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF lv_exists = abap_true.
      APPEND NEW zcx_d401_04_failed_sfm(
        textid      = zcx_d401_04_failed_sfm=>instance_vorhanden
        iv_producer = iv_producer
        iv_model    = iv_model
        iv_make     = iv_make
      ) TO mt_exceptions.
      RETURN.
    ENDIF.

    IF iv_type = 'TRUCK'.
      ro_vehicle = lcl_truck=>get_instance_truck( iv_producer = iv_producer iv_make = iv_make iv_model = iv_model
                                                  iv_price = iv_price iv_color = iv_color iv_cargo = iv_cargo ).
    ELSEIF iv_type = 'BUS'.
      ro_vehicle = lcl_bus=>get_instance_bus( iv_producer = iv_producer iv_make = iv_make iv_model = iv_model
                                              iv_price = iv_price iv_color = iv_color iv_seats = iv_seats ).
    ENDIF.

    IF ro_vehicle IS BOUND.
      APPEND ro_vehicle TO mt_vehicles.
    ENDIF.
  ENDMETHOD.

  METHOD find_max_cargo_truck.
    DATA lv_max_cargo TYPE ty_cargo VALUE 0.

*    LOOP AT mt_vehicles INTO DATA(lo_vehicle).
*      TRY.
*          DATA(lo_truck) = CAST lcl_truck( lo_vehicle ).
*          IF lo_truck->get_cargo( ) > lv_max_cargo.
*            lv_max_cargo = lo_truck->get_cargo( ).
*            ro_truck = lo_truck.
*          ENDIF.
*        CATCH cx_sy_move_cast_error.
*      ENDTRY.
*    ENDLOOP.

    " 1. Filtern mittels RTTI / Typprüfung
    LOOP AT mt_vehicles INTO DATA(lo_vehicle) WHERE table_line IS INSTANCE OF lcl_truck.
      DATA(lo_truck) = CAST lcl_truck( lo_vehicle ).
      IF lo_truck->get_cargo( ) > lv_max_cargo.
        lv_max_cargo = lo_truck->get_cargo( ).
        ro_truck = lo_truck.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD check_truck_capacities.
*    LOOP AT mt_vehicles INTO DATA(lo_vehicle).
*      TRY.
*          DATA(lo_truck) = CAST lcl_truck( lo_vehicle ).
*          IF lo_truck->get_cargo( ) < 2.
*            APPEND NEW zcx_d401_04_failed_sfm(
*              textid   = zcx_d401_04_failed_sfm=>cargo_to_low
*              iv_make  = lo_truck->get_make( )
*              iv_model = CONV #( lo_truck->get_model( ) )
*            ) TO mt_exceptions.
*          ENDIF.
*        CATCH cx_sy_move_cast_error.
*      ENDTRY.
*    ENDLOOP.
    " 1. Filtern mittels RTTI / Typprüfung
    LOOP AT mt_vehicles INTO DATA(lo_vehicle) WHERE table_line IS INSTANCE OF lcl_truck.
      DATA(lo_truck) = CAST lcl_truck( lo_vehicle ).
      IF lo_truck->get_cargo( ) < 2.
        APPEND NEW zcx_d401_04_failed_sfm(
          textid   = zcx_d401_04_failed_sfm=>cargo_to_low
          iv_make  = lo_truck->get_make( )
          iv_model = CONV #( lo_truck->get_model( ) )
        ) TO mt_exceptions.
      ENDIF.
    ENDLOOP.

    IF mt_exceptions IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_d401_04_failed_sfm( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_sorted_vehicles.
*    CLEAR rt_flat_table.
*    LOOP AT mt_vehicles INTO DATA(lo_vehicle).
*      TRY.
*          DATA(lo_truck) = CAST lcl_truck( lo_vehicle ).
*          APPEND VALUE #(
*            vehicle_type = 'TRUCK'
*            producer     = lo_truck->get_producer( )
*            model        = lo_truck->get_model( )
*            make         = lo_truck->get_make( )
*            price        = lo_truck->mv_price
*            color        = lo_truck->mv_color
*            specifics    = |{ lo_truck->get_cargo( ) } t Kapazität|
*          ) TO rt_flat_table.
*        CATCH cx_sy_move_cast_error.
*          TRY.
*              DATA(lo_bus) = CAST lcl_bus( lo_vehicle ).
*              APPEND VALUE #(
*                vehicle_type = 'BUS'
*                producer     = lo_bus->get_producer( )
*                model        = lo_bus->get_model( )
*                make         = lo_bus->get_make( )
*                price        = lo_bus->mv_price
*                color        = lo_bus->mv_color
*                specifics    = |{ lo_bus->get_seats( ) } Sitzplätze|
*              ) TO rt_flat_table.
*            CATCH cx_sy_move_cast_error.
*          ENDTRY.
*      ENDTRY.
*    ENDLOOP.
    CLEAR rt_flat_table.

    " Zuerst alle Trucks verarbeiten
    " 1. Filtern mittels RTTI / Typprüfung
    LOOP AT mt_vehicles INTO DATA(lo_vehicle) WHERE table_line IS INSTANCE OF lcl_truck.
      DATA(lo_truck) = CAST lcl_truck( lo_vehicle ).
      APPEND VALUE #(
        vehicle_type = 'TRUCK'
        producer     = lo_truck->get_producer( )
        model        = lo_truck->get_model( )
        make         = lo_truck->get_make( )
        price        = lo_truck->mv_price
        color        = lo_truck->mv_color
        specifics    = |{ lo_truck->get_cargo( ) } t Kapazität|
      ) TO rt_flat_table.
    ENDLOOP.

    " Danach alle Busse verarbeiten
    " 1. Filtern mittels RTTI / Typprüfung
    LOOP AT mt_vehicles INTO lo_vehicle WHERE table_line IS INSTANCE OF lcl_bus.
      DATA(lo_bus) = CAST lcl_bus( lo_vehicle ).
      APPEND VALUE #(
        vehicle_type = 'BUS'
        producer     = lo_bus->get_producer( )
        model        = lo_bus->get_model( )
        make         = lo_bus->get_make( )
        price        = lo_bus->mv_price
        color        = lo_bus->mv_color
        specifics    = |{ lo_bus->get_seats( ) } Sitzplätze|
      ) TO rt_flat_table.
    ENDLOOP.


    SORT rt_flat_table BY vehicle_type DESCENDING
                          producer     ASCENDING
                          model        ASCENDING
                          make         ASCENDING.


  ENDMETHOD.

  METHOD find_max_seats_bus.
    DATA lv_max_seats TYPE i VALUE 0.

*    LOOP AT mt_vehicles INTO DATA(lo_vehicle).
*      TRY.
*          DATA(lo_bus) = CAST lcl_bus( lo_vehicle ).
*          IF lo_bus->get_seats( ) > lv_max_seats.
*            lv_max_seats = lo_bus->get_seats( ).
*            ro_bus = lo_bus.
*          ENDIF.
*        CATCH cx_sy_move_cast_error.
*      ENDTRY.
*    ENDLOOP.
    " 1. Filtern mittels RTTI / Typprüfung
    LOOP AT mt_vehicles INTO DATA(lo_vehicle) WHERE table_line IS INSTANCE OF lcl_bus.
      DATA(lo_bus) = CAST lcl_bus( lo_vehicle ).
      IF lo_bus->get_seats( ) > lv_max_seats.
        lv_max_seats = lo_bus->get_seats( ).
        ro_bus = lo_bus.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


