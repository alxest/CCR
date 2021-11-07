Require Import Coqlib.
Require Import ITreelib.
Require Import ImpPrelude.
Require Import STS.
Require Import Behavior.
Require Import ModSem.
Require Import Skeleton.
Require Import PCM.
Require Import Imp.
Require Import ImpNotations.

Set Implicit Arguments.



Section PROOF.
  Context `{Σ: GRA.t}.

  Import ImpNotations.
  Local Open Scope expr_scope.
  Local Open Scope stmt_scope.

  Definition mainF :=
    mk_function
      []
      ["arr"; "map"; "tmp"]
      ("tmp" =# malloc# 100%Z ;# "arr" =#& "gv0" ;# "arr" *=# "tmp" ;#
       "tmp" =@ "new" [] ;# "map" =#& "gv1" ;# "map" *=# "tmp" ;#
       @ "init" [] ;#
       @ "loop" []
      )
  .

  Definition MWprog: program :=
    mk_program
      "MW"
      []
      [("init", 0); ("loop", 0); ("new", 0); ("update", 0); ("access", 0)]
      [("gv0", 0%Z); ("gv1", 0%Z); ("gv2", 0%Z); ("gv3", 0%Z)]
      [("main", mainF); ("loop", mainF); ("put", mainF); ("get", mainF)]
  .

  Definition MWSem ge: ModSem.t := ImpMod.modsem MWprog ge.
  Definition MW: Mod.t := ImpMod.get_mod MWprog.

End PROOF.