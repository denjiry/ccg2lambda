Require Export coqlib.
Parameter _アリス : Entity.
Parameter _以外 : Entity -> Prop.
Parameter _好き : Event -> Prop.
Parameter _嫌う : Event -> Prop.
Parameter _花 : Entity -> Prop.
Parameter _青い : Event -> Prop.
Theorem t1 :exists x,(exists z1,(_以外(z1) /\ exists e,(_青い(e) /\ (Nom(e) = z1)) /\ (x = z1)) /\ _花(x) /\ exists e,(_好き(e) /\ (Nom(e) = _アリス) /\ (Nom(e) = x))) /\ exists x,(_花(x) /\ exists e,(_青い(e) /\ (Nom(e) = x)) /\ exists e,(_嫌う(e) /\ (Nom(e) = x))).
Proof.
  Admitted.

  Theorem t2 :exists x,(_花(x) /\ exists z3,(exists z2,(_以外(z2) /\ exists e,(_青い(e) /\ (Nom(e) = z2)) /\ (z3 = z2)) /\ _花(z3) /\ exists e,(_好き(e) /\ (Nom(e) = _アリス) /\ (Nom(e) = z3))) /\ exists e,(_青い(e) /\ (Nom(e) = x)) /\ exists e,(_嫌う(e) /\ (Nom(e) = x))).

    Theorem t3 :exists x,(_花(x) /\ exists z5,(exists z4,(_以外(z4) /\ exists e,(_青い(e) /\ (Nom(e) = z4)) /\ (z5 = z4)) /\ _花(z5) /\ exists e,(_好き(e) /\ (Nom(e) = _アリス) /\ (Nom(e) = x) /\ (Nom(e) = z5))) /\ exists e,(_青い(e) /\ (Nom(e) = x)) /\ exists e,(_嫌う(e) /\ (Nom(e) = x))).

      Theorem t4 :(exists x,(exists z6,(_以外(z6) /\ exists e,(_青い(e) /\ (Nom(e) = z6)) /\ (x = z6)) /\ _花(x) /\ exists e,(_好き(e) /\ (Nom(e) = _アリス) /\ (Nom(e) = x))) /\ exists x,(_花(x) /\ exists e,(_青い(e) /\ (Nom(e) = x)) /\ exists e,(_嫌う(e) /\ (Nom(e) = x)))).
