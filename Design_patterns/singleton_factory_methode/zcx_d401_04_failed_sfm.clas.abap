CLASS zcx_d401_04_failed_sfm DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_message .
    INTERFACES if_t100_dyn_msg .

     " Datenattribute für die Rohdaten-Übergabe
    DATA mv_make  TYPE d READ-ONLY.
    DATA mv_model TYPE string READ-ONLY.
    DATA mv_producer TYPE string READ-ONLY.

    constants:
      begin of cargo_to_low,
        msgid type symsgid value 'Z04_FT_MSG_SFM',
        msgno type symsgno value '010',
        attr1 type scx_attrname value 'mv_model',
        attr2 type scx_attrname value 'mv_make',
        attr3 type scx_attrname value 'attr3',
        attr4 type scx_attrname value 'attr4',
      end of cargo_to_low.

    constants:
      begin of instance_vorhanden,
        msgid type symsgid value 'Z04_FT_MSG_SFM',
        msgno type symsgno value '015',
        attr1 type scx_attrname value 'mv_producer',
        attr2 type scx_attrname value 'mv_model',
        attr3 type scx_attrname value 'mv_make',
        attr4 type scx_attrname value 'attr4',
      end of instance_vorhanden.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous OPTIONAL
        iv_model like mv_model OPTIONAL
        iv_make like mv_make OPTIONAL
        iv_producer like mv_model OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_d401_04_failed_sfm IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).

    me->mv_make = iv_make.
    me->mv_model = iv_model.
    me->mv_producer = iv_producer.

    CLEAR me->textid.

    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
