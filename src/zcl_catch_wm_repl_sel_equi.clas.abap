CLASS zcl_catch_wm_repl_sel_equi DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
        BEGIN OF types,
            advance_replacement_year TYPE n LENGTH 4,
            equipment_id TYPE c LENGTH 10,
        END OF types.

    CLASS-METHODS:
        get_equipment_from_id IMPORTING equipment_id TYPE types-equipment_id
                              RETURNING VALUE(result) TYPE REF TO zcl_catch_wm_repl_sel_equi.

    DATA:
        equipment_id TYPE types-equipment_id.

    METHODS:
        constructor IMPORTING equipment_id TYPE types-equipment_id,
        change_advance_replacement_yea IMPORTING advance_replacement_year TYPE types-advance_replacement_year
                                       RAISING zcx_catch_wm_repl_sel_equi.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_catch_wm_repl_sel_equi IMPLEMENTATION.
  METHOD change_advance_replacement_yea.
    ##TODO "BAPI_EQUI_CHANGE? - Raise exception if error

  ENDMETHOD.

  METHOD get_equipment_from_id.
    result = new zcl_catch_wm_repl_sel_equi( equipment_id ).
  ENDMETHOD.

  METHOD constructor.
    me->equipment_id = equipment_id.
  ENDMETHOD.
ENDCLASS.
