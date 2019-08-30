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
  nltac.
Qed.
