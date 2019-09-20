Require Export coqlib.
Parameter _アリス : Entity.
Parameter _好き : Event -> Prop.
Parameter _嫌う : Event -> Prop.
Parameter _花 : Entity -> Prop.
Parameter _青い : Event -> Prop.

Theorem t1: exists x,(_花(x) /\ exists e,(_青い(e) /\ (Nom(e) = x)) /\ exists e,(_嫌う(e) /\ exists x,(_花(x) /\ exists e02,(_好き(e02) /\ (Nom(e02) = _アリス) /\ (e02 = e) /\ (Nom(e02) = x))) /\ (Nom(e) = x))).
Proof.
  Admitted.

(* Theorem t2: exists x,(_花(x) /\ exists e,(_青い(e) /\ (Nom(e) = x)) /\ exists e,(_嫌う(e) /\ exists x,(_花(x) /\ exists e04,(_好き(e04) /\ (Nom(e04) = _アリス) /\ (e04 = e) /\ (Nom(e04) = x))) /\ (Nom(e) = x))).
Proof.
 Admitted.*)

Theorem t3: exists x,(_花(x)
                  /\
                  exists e,(_青い(e) /\ (Nom(e) = x))
                  /\
                  exists e,(_嫌う(e)
                        /\
                        exists x,(_花(x)
                              /\
                              exists e06,(_好き(e06)
                                      /\
                                      (Nom(e06) = _アリス)
                                      /\
                                      (e06 = e)
                                      /\
                                      (Nom(e06) = x))
                             )
                             /\
                             (Acc(e) = x)
                       )
                 ).
Proof.
Admitted.

