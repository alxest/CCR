Require Import Coqlib.
Require Import Universe.
Require Import STS.
Require Import Behavior.
Require Import ModSem.
Require Import Skeleton.
Require Import PCM.

Set Implicit Arguments.






Section BW.

  Context `{Σ: GRA.t}.

(***
local numFlip = 0

def get(): Int
  r = (numFlip &2 == 0) ? 0 : 1
  return r

def flip(): Unit
  numFlip := numFlip+1
  return ()
***)

  Definition getF: (option string * Any.t) -> itree Es Any.t :=
    fun _ =>
      n <- trigger (PGet);; `n: Z <- n↓?;;
      let r := (if (Z.even n) then Vint 0 else Vint (0xffffff)) in
      Ret (r↑)
    .

  Definition flipF: (option string * Any.t) -> itree Es Any.t :=
    fun _ =>
      n <- trigger (PGet);; `n: Z <- n↓?;;
      let n := (n+1)%Z in
      trigger (PPut n↑);;;
      Ret (Vundef↑)
    .

  Definition BWSem: ModSem.t := {|
    ModSem.fnsems := [("get", getF); ("flip", flipF)];
    ModSem.mn := "BW";
    ModSem.initial_st := 0%Z↑;
  |}
  .

  Definition BW: Mod.t := {|
    Mod.get_modsem := fun _ => BWSem;
    Mod.sk := Sk.unit;
  |}
  .
End BW.
