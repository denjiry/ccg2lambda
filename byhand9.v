Require Export coqlib.
Parameter _アリス : Entity.
Parameter _好き : Event -> Prop.
Parameter _嫌う : Event -> Prop.
Parameter _花 : Entity -> Prop.
Parameter _青い : Event -> Prop.

Theorem t1 :forall x, (_花(x)
                   ->
                   ((exists e, ((_青い(e) /\ (Nom(e) = x))
                            ->
                            (_嫌う(e) /\ (Nom(e) = _アリス) /\ (Acc(e)=x))))
                    \/
                    exists e, (_嫌う(e) /\ (Nom(e) = _アリス) /\ (Acc(e)=x))
                  )).
Proof.
Admitted.

(* Theorem t2 :forall x, (_花(x) -> ((_青い(x) -> _嫌う(Alice, x)) \/ _好き(Alice, x))). *)
