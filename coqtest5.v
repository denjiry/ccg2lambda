Require Export coqlib.
Parameter _ソクラテス : Entity.
Parameter _人間 : Entity -> Prop.
Parameter _死ぬ : Event -> Prop.
Theorem t1:
  (exists x, (and (_人間 x) (exists e, (and  ((Nom e) = x) ((Nom e) = _ソクラテス)))))
  -> (forall x, ((exists z1, (and (_人間 z1) (x = z1))) -> (exists e, (and (_死ぬ e) ((Nom e) = x)))))
  -> (exists e, (and (_死ぬ e) ((Nom e) = _ソクラテス))).
Proof.
  Set Firstorder Depth 1.
  firstorder.
  rewrite <- H2 in *. subst.
  (* substitution. *)
  eqlem_sub.
  firstorder.
  firstorder.
  (* nltac_set; nltac_final. *)
  (* nltac_prove. *)
  (* nltac. *)
  (* nltac_set; nltac_final. Set Firstorder Depth 3. nltac_final. *)
Qed.
