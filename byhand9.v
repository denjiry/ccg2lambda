Require Export coqlib.
Parameter _アリス : Entity.
Parameter _好き : Event -> Prop.
Parameter _嫌う : Event -> Prop.
Parameter _花 : Entity -> Prop.
Parameter _青い : Event -> Prop.

Theorem t1 :forall x, (_花(x) -> ((B(x) -> _嫌う(Alice, x)) \/ _好き(Alice, x))).
