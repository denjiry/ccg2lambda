Require Export coqlib.
Parameter _ソクラテス : Entity.
Parameter _人間 : Entity -> Prop.
Parameter _死ぬ : Event -> Prop.
Theorem t1:
  (exists x, (and
            (_人間 x)
            (exists e, (and ((Nom e) = x)
                        ((Nom e) = _ソクラテス)))))
  -> (exists x, (and
               (_人間 x)
               (exists e, (and (_死ぬ e)
                           ((Nom e) = x)))))
  -> (exists e, (and
               (_死ぬ e)
               ((Nom e) = _ソクラテス))).
Proof.
  (* Set Firstorder Depth 1. nltac. *)
  nltac_set. (* nltac_final. *)
  eexists.
  (* firstorder. *)
  (* assert (x2=x0). *)
  split.
  apply H1.
  Set Firstorder Depth 3.
  nltac_final.
Qed.
  (* (and True *)
  (*      (exists x, (and (_人間 x) *)
  (*                  (exists e, (and (and ((Nom e) = x) True) ((Nom e) = _ソクラテス)))))) *)
  (* -> (exists x, (and (_人間 x) (exists e, (and (_死ぬ e) ((Nom e) = x))))) *)
  (* -> (and True (exists e, (and (_死ぬ e) ((Nom e) = _ソクラテス)))). *)
