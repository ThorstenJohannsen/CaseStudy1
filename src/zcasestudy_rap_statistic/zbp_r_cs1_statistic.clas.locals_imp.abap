CLASS lhc_zr_cs1_statistic DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ZrCs1Statistic
        RESULT result,
      SetExclusiveActive FOR DETERMINE ON save
        IMPORTING keys FOR ZrCs1Statistic~SetExclusiveActive,
      validateActiveExists FOR VALIDATE ON SAVE
            IMPORTING keys FOR ZrCs1Statistic~validateActiveExists.
ENDCLASS.

CLASS lhc_zr_cs1_statistic IMPLEMENTATION.

  METHOD get_global_authorizations.

  ENDMETHOD.

METHOD SetExclusiveActive.

READ ENTITIES OF zr_cs1_statistic IN LOCAL MODE
      ENTITY ZrCs1Statistic
        FIELDS ( StatID Active )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_changed).

  LOOP AT lt_changed INTO DATA(ls_changed) WHERE Active = abap_true.
    SELECT FROM zcs1_statistic
      FIELDS stat_id
      WHERE active  = @abap_true
      INTO TABLE @DATA(lt_others).

    DELETE lt_others WHERE stat_id = ls_changed-StatID.
    CHECK lt_others IS NOT INITIAL.

    MODIFY ENTITIES OF zr_cs1_statistic IN LOCAL MODE
      ENTITY ZrCs1Statistic
        UPDATE FIELDS ( Active )
        WITH VALUE #( FOR ls_other IN lt_others
                      ( %tky     = VALUE #( StatID = ls_other-stat_id )
                        Active   = abap_false
                        %control = VALUE #( Active = if_abap_behv=>mk-on ) ) )
        REPORTED DATA(lt_reported).
  ENDLOOP.

*READ ENTITIES OF zr_cs1_statistic IN LOCAL MODE
*    ENTITY ZrCs1Statistic
*      FIELDS ( StatID Active ClassName InterfaceName )
*      WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_changed).
*
*  LOOP AT lt_changed INTO DATA(ls_changed) WHERE Active = abap_true.
*
*    SELECT FROM zcs1_statistic
*      FIELDS stat_id, class_name, interface_name
*      WHERE active  = @abap_true  " <- StatID Filter entfernt
*      INTO TABLE @DATA(lt_others).
*
*    DELETE lt_others WHERE stat_id        = ls_changed-StatID
*                       AND class_name     = ls_changed-ClassName
*                       AND interface_name = ls_changed-InterfaceName.
*
*    CHECK lt_others IS NOT INITIAL.
*
*
*    MODIFY ENTITIES OF zr_cs1_statistic IN LOCAL MODE
*      ENTITY ZrCs1Statistic
*        UPDATE FIELDS ( Active )
*        WITH VALUE #( FOR ls_other IN lt_others
*                      ( %tky     = VALUE #( StatID = ls_other-stat_id )
*                        Active   = abap_false
*                        %control = VALUE #( Active = if_abap_behv=>mk-on ) ) )
*        REPORTED DATA(lt_reported).
*
*  ENDLOOP.


ENDMETHOD.


METHOD validateActiveExists.
  " =======================================================================
  " STUFE 1: Aktuelle Instanzen aus den übergebenen Keys lesen
  " =======================================================================
  READ ENTITIES OF zr_cs1_statistic IN LOCAL MODE
      ENTITY ZrCs1Statistic
        FIELDS ( StatID Active )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_changed)
        FAILED DATA(lt_failed_read).

  " Absturzschutz für den initialen Create-Klick
  IF keys IS INITIAL.
    RETURN.
  ENDIF.

  " =======================================================================
  " STUFE 2: Den globalen Zustand der gesamten Draft-Tabelle auslesen
  " =======================================================================
  SELECT FROM zcs1_statistic_d
    FIELDS statid, active
    INTO TABLE @DATA(lt_all_drafts).


  " =======================================================================
  " STUFE 3: ABSICHERUNG GEGEN LÖSCHEN VON AKTIVEN EINTRÄGEN
  " =======================================================================
  " Wir prüfen, ob die übergebenen Keys überhaupt noch in lt_changed existieren.
  " Wenn ein Key in 'keys' steht, aber NICHT in 'lt_all_drafts', wird er gerade GELÖSCHT.
  LOOP AT keys INTO DATA(ls_key).

    " Liest den aktuellen Zustand dieses spezifischen Eintrags aus dem Draft
    READ TABLE lt_all_drafts INTO DATA(ls_current_draft) WITH KEY statid = ls_key-StatID.

    " Fall A: Der Eintrag ist im Puffer aktiv, soll aber laut Framework gelöscht werden
    " (Bei einer reinen Löschung ist er in 'keys', aber wir prüfen seinen Zustand im Draft)
    IF sy-subrc = 0 AND ls_current_draft-active = abap_true.

      " Nun müssen wir sicherstellen, dass es kein UPDATE von False auf True ist:
      " Wenn er im aktuellen lt_changed auf True steht, ist es ein Edit.
      " Wenn er dort NICHT auf True steht (oder fehlt), ist es ein Löschversuch!
      READ TABLE lt_changed INTO DATA(ls_chg) WITH KEY StatID = ls_key-StatID.

      IF sy-subrc <> 0 OR ls_chg-Active = abap_false.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-zrcs1statistic.
        APPEND VALUE #(
            %tky            = ls_key-%tky
            %msg            = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Ein aktiver Eintrag darf nicht gelöscht werden. Deaktivieren Sie ihn zuerst.' )
          ) TO reported-zrcs1statistic.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Falls das Löschen blockiert wurde, beenden wir sofort
  IF failed-zrcs1statistic IS NOT INITIAL.
    RETURN.
  ENDIF.


  " =======================================================================
  " STUFE 4: Absicherung gegen das Anlegen des allerersten Eintrags
  " =======================================================================
  IF lines( lt_all_drafts ) = 1.
    SELECT SINGLE FROM zcs1_statistic FIELDS active WHERE active = @abap_true INTO @DATA(lv_db_has_active).
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
  ENDIF.


  " =======================================================================
  " STUFE 5: Absicherung gegen Doppel-Aktivierung (Maximal 1 aktiv)
  " =======================================================================
  DATA(lt_active_drafts) = lt_all_drafts.
  DELETE lt_active_drafts WHERE active = abap_false.

  IF lines( lt_active_drafts ) > 1.
    LOOP AT lt_changed INTO DATA(ls_error) WHERE Active = abap_true.
      APPEND VALUE #( %tky = ls_error-%tky ) TO failed-zrcs1statistic.
      APPEND VALUE #(
          %tky            = ls_error-%tky
          %element-active = if_abap_behv=>mk-on
          %msg            = new_message_with_text(
                              severity = if_abap_behv_message=>severity-error
                              text     = 'Es darf maximal ein Eintrag gleichzeitig aktiv sein.' )
        ) TO reported-zrcs1statistic.
    ENDLOOP.
    RETURN.
  ENDIF.


  " =======================================================================
  " STUFE 6: Absicherung gegen absolute Inaktivität (Mindestens 1 aktiv)
  " =======================================================================
  IF lines( lt_all_drafts ) > 1.
    IF NOT line_exists( lt_all_drafts[ active = abap_true ] ).
      LOOP AT lt_changed INTO DATA(ls_uncheck) WHERE Active = abap_false.
        APPEND VALUE #( %tky = ls_uncheck-%tky ) TO failed-zrcs1statistic.
        APPEND VALUE #(
            %tky            = ls_uncheck-%tky
            %element-active = if_abap_behv=>mk-on
            %msg            = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Es muss mindestens ein Eintrag aktiv bleiben.' )
          ) TO reported-zrcs1statistic.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDMETHOD.

ENDCLASS.


CLASS lhc_ZrCs1Statistic DEFINITION INHERITING FROM cl_abap_behavior_handler.
  private SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZrCs1Statistic RESULT result.

    " Hier stehen deine anderen Methoden-Definitionen (z. B. validateActiveExists)...
ENDCLASS.


CLASS lhc_ZrCs1Statistic IMPLEMENTATION.

  METHOD get_instance_features.
    " 1. Zustand der vom Benutzer markierten Zeilen lesen
    READ ENTITIES OF zr_cs1_statistic IN LOCAL MODE
      ENTITY ZrCs1Statistic
        FIELDS ( StatID Active )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_statistics).

    " 2. Lösch-Buttons auf der UI dynamisch sperren
    " Wenn Active = True ist, wird %delete auf 'disabled' (ausgegraut) gesetzt.
    result = VALUE #( FOR ls_stat IN lt_statistics
                      ( %tky   = ls_stat-%tky
                        %delete = COND #( WHEN ls_stat-Active = abap_true
                                          THEN if_abap_behv=>fc-o-disabled
                                          ELSE if_abap_behv=>fc-o-enabled )
                      ) ).
  ENDMETHOD.

  " Hier folgen die Implementierungen deiner anderen Methoden (z. B. validateActiveExists)...
ENDCLASS.
