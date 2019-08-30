Require Export coqlib.
Parameter _なる : Event -> Prop.
Parameter _に : Event -> (Entity -> Prop).
Parameter _イタリア : Entity -> Prop.
Parameter _テノxmdashxル : Entity -> Prop.
Parameter _宇宙 : Entity -> Prop.
Parameter _人 : Entity -> Prop.
Parameter _最高 : Entity -> Prop.
Parameter _歌手 : Entity -> Prop.
Theorem t1:
  (exists x, (and (and (_人 x) (_イタリア x))
              (exists z2, (and
                         (and (and
                                 (exists z1, (and (and (_宇宙 z1) (_最高 z1)) (z2 = z1)))
                                 (_テノxmdashxル z2))
                              (_歌手 z2))
                         (exists e, (and
                                   (and (and (_なる e) (Past e)) ((Nom e) = x))
                                   ((Dat e) = z2)))))))
  ->
  (exists x, (and
            (and
               (and (_人 x) (_イタリア x))
               (exists e, (and
                         (and
                            (and (_なる e) (Past e))
                            (exists z2, (and
                                       (and
                                          (and
                                             (exists z1, (and (and (_宇宙 z1) (_最高 z1)) (z2 = z1)))
                                             (_テノxmdashxル z2))
                                          (_歌手 z2))
                                       ((Dat e) = z2))))
                         ((Nom e) = x))))
            True)).
  Set Firstorder Depth 1.
  (* Success *)
  (* nltac. *)
  (* Success *)
  (* nltac_prove. *)
  (* Ltac coqlib.nltac_prove := try (solve [ nltac_set; nltac_final | nltac_set_exch; nltac_final ]) *)
  (* Ltac coqlib.nltac_set := *)
  (* repeat *)
  (*  (nltac_init; try repeat substitution; try exchange_equality; *)
  (*    try repeat substitution; try eqlem_sub) *)
  (* Ltac coqlib.nltac_final := try (solve [ repeat nltac_base | clear_pred; repeat nltac_base ]) *)
  (* Success *)
  (* nltac_set. *)
  (* nltac_final. *)
  (* Success *)
  (* nltac_init. *)
  (* nltac_final. *)

  (* Success *)
  (* nltac_base. *)
  (* nltac_base. *)
  (* nltac_base. *)
  (* Ltac coqlib.nltac_base := *)
  (*  try nltac_init; try (eauto; eexists; firstorder); try (subst; eauto; firstorder; try congruence) *)
  (* Ltac coqlib.nltac_init := try (intuition; try solve_false; firstorder; repeat subst; firstorder) *)
  (* Success *)
  (* nltac_init. *)
  intuition. firstorder. subst.
  (* nltac_base. *)
  eexists. firstorder. eauto. firstorder.
  (* nltac_base. *)
  eexists. firstorder. eauto. firstorder.
  (* nltac_base. *)
  eexists. firstorder. eauto. firstorder. congruence.


(*DANGER nltac_set_exch.
   nltac_final. *)
Qed.
