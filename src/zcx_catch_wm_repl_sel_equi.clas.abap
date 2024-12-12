CLASS zcx_catch_wm_repl_sel_equi DEFINITION
  PUBLIC
  INHERITING FROM zcx_static_check
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS:
      msg_id TYPE symsgid VALUE 'ZCM_CATCH_WM_REPL_SE',
      BEGIN OF first_message,
        msgid TYPE symsgid VALUE msg_id,
        msgno TYPE symsgno VALUE '000',
        attr1 TYPE scx_attrname VALUE 'V1',
        attr2 TYPE scx_attrname VALUE 'V2',
        attr3 TYPE scx_attrname VALUE 'V3',
        attr4 TYPE scx_attrname VALUE 'V4',
      END OF first_message.



    CLASS-METHODS:
      raise IMPORTING textid    LIKE if_t100_message=>t100key OPTIONAL
                      previous  LIKE previous OPTIONAL
                      ty        TYPE symsgty DEFAULT zcl_error=>gcs_message_type-error
                      v1        TYPE any OPTIONAL
                      v2        TYPE any OPTIONAL
                      v3        TYPE any OPTIONAL
                      v4        TYPE any OPTIONAL
                      messages  TYPE BAPIRETTAB OPTIONAL
            RAISING   zcx_catch_wm_repl_sel_equi.

    METHODS constructor
      IMPORTING
        !textid    LIKE if_t100_message=>t100key OPTIONAL
        !previous  LIKE previous OPTIONAL
        !ty        TYPE symsgty DEFAULT zcl_error=>gcs_message_type-error
        !v1        TYPE any OPTIONAL
        !v2        TYPE any OPTIONAL
        !v3        TYPE any OPTIONAL
        !v4        TYPE any OPTIONAL
        !messages  TYPE BAPIRETTAB OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_catch_wm_repl_sel_equi IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor(
        textid    = textid
        previous  = previous
        ty        = ty
        v1        = v1
        v2        = v2
        v3        = v3
        v4        = v4
        messages  = messages ).
  ENDMETHOD.


  METHOD raise.
    RAISE EXCEPTION TYPE zcx_catch_wm_repl_sel_equi
      EXPORTING
        textid    = textid
        previous  = previous
        ty        = ty
        v1        = v1
        v2        = v2
        v3        = v3
        v4        = v4
        messages  = messages.
  ENDMETHOD.
ENDCLASS.
