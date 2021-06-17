Require Import Coqlib.
Require Import Universe.
Require Import STS.
Require Import Behavior.
Require Import ModSem.
Require Import Skeleton.
Require Import PCM.
Require Import Mem1 MemOpen.
Require Import TODOYJ.
Require Import NewEchoHeader.
Require Import IPM HoareDef OpenDef.
Require Import NewStack3A.

Set Implicit Arguments.




Section PROOF.

  Context `{Σ: GRA.t}.
  Context `{@GRA.inG stkRA Σ}.

  Definition echo_body: list val -> itree (kCallE +' pE +' eventE) val :=
    fun args =>
      _ <- (pargs [] args)?;;
      `h: val    <- (ckcall pure "new" ([]: list val));;
      `_: val    <- (ckcall impure "input" ([h]: list val));;
      `_: val    <- (ckcall impure "output" ([h]: list val));;
      Ret Vundef
  .





  Definition input_spec: fspec :=
    mk_fspec (fun h _argh _argl o =>
                (∃ (argh: list val) (argl: list val),
                  ⌜_argh = argh↑ ∧ _argl = argl↑ ∧ argl = [Vptr h 0] ∧ o = ord_top⌝
                   ** OwnM (is_stack h argh))%I)
             (fun h _reth _ => (∃ (reth: list val), ⌜_reth = reth↑⌝ ** OwnM(is_stack h reth))%I)
  .

  Definition input_body: list val -> itree (kCallE +' pE +' eventE) (list val) :=
    fun stk =>
      n <- (ckcall unknown "getint" ([]: list val));;
      if (dec n (Vint INT_MIN))
      then Ret stk
      else
        (ckcall impure "input" (n :: stk))
  .





  Definition output_spec: fspec :=
    mk_fspec (fun h _argh _argl o =>
                (∃ (argh: list val) (argl: list val),
                  ⌜_argh = argh↑ ∧ _argl = argl↑ ∧ argl = [Vptr h 0] ∧ o = ord_top⌝
                   ** OwnM (is_stack h argh))%I)
             (fun h _reth _ => (∃ (reth: list val), ⌜_reth = reth↑⌝ ** OwnM(is_stack h reth))%I)
  .

  Definition output_body: list val -> itree (kCallE +' pE +' eventE) (list val) :=
    fun stk =>
      match stk with
      | [] => Ret []
      | n :: stk' => `_: val <- (ckcall unknown "putint" ([n]: list val));; (ckcall impure "output" (stk'))
      end
  .





  Definition EchoSbtb: list (gname * kspecbody) :=
    [("echo", ksb_trivial (cfun echo_body));
    ("input",  mk_kspecbody input_spec (cfun input_body) (fun _ => triggerUB));
    ("output", mk_kspecbody output_spec (cfun output_body) (fun _ => triggerUB))
    ]
  .

  Definition EchoStb: list (gname * fspec).
    eapply (Seal.sealing "stb").
    let x := constr:(List.map (map_snd (fun ksb => (KModSem.disclose_ksb ksb): fspec)) EchoSbtb) in
    let y := eval cbn in x in
    eapply y.
  Defined.

  Definition KEchoSem: KModSem.t := {|
    KModSem.fnsems := EchoSbtb;
    KModSem.mn := "Echo";
    KModSem.initial_mr := ε;
    KModSem.initial_st := (∅: gmap mblock (list Z))↑;
  |}
  .
  Definition SEchoSem: SModSem.t := KEchoSem.
  Definition EchoSem (stb: list (string * fspec)): ModSem.t :=
    (SModSem.to_tgt stb) SEchoSem.



  Definition KEcho: KMod.t := {|
    KMod.get_modsem := fun _ => KEchoSem;
    KMod.sk := Sk.unit;
  |}
  .
  Definition SEcho: SMod.t := KEcho.
  Definition Echo (stb: Sk.t -> list (string * fspec)): Mod.t :=
    SMod.to_tgt stb SEcho.

End PROOF.
Global Hint Unfold EchoStb: stb.
