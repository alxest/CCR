Require Import sflib.
Require Import Universe.
Require Import Sem.
From Paco Require Import paco.
Require Import RelationClasses List.
Require Import ClassicalChoice PropExtensionality FunctionalExtensionality.
(* Require Import Streams. *)

Set Implicit Arguments.

Definition single X (x: X): X -> Prop := fun x0 => x = x0.

Ltac et := eauto.

Module Tr.
  CoInductive t: Type :=
  | done (retv: Z)
  | spin
  | ub
  | nb
  | cons (hd: event) (tl: t)
  .
  Infix "##" := cons (at level 60, right associativity).
  (*** past -------------> future ***)
  (*** a ## b ## c ## spin / done ***)

  Fixpoint app (pre: list event) (bh: t): t :=
    match pre with
    | [] => bh
    | hd :: tl => cons hd (app tl bh)
    end
  .
  Lemma fold_app
        s pre tl
    :
      (Tr.cons s (Tr.app pre tl)) = Tr.app (s :: pre) tl
  .
  Proof. reflexivity. Qed.

  Definition prefix (pre: list event) (bh: t): Prop :=
    exists tl, <<APP: app pre tl = bh>>
  .

End Tr.











Module Beh.

Definition t: Type := Tr.t -> Prop.
Definition improves (src tgt: t): Prop := tgt <1= src.

Section BEHAVES.

Variable L: semantics.

Definition union (st0: L.(state)) (P: (option event) -> L.(state) -> Prop) :=
  exists ev st1, <<STEP: L.(step) st0 ev st1>> /\ <<UNION: P ev st1>>.
Definition inter (st0: L.(state)) (P: (option event) -> L.(state) -> Prop) :=
  forall ev st1 (STEP: L.(step) st0 ev st1), <<INTER: P ev st1>>.

Inductive _state_spin (state_spin: L.(state) -> Prop)
  (st0: L.(state)): Prop :=
| state_spin_angelic
    (SRT: L.(state_sort) st0 = angelic)
    (STEP: forall ev st1 (STEP: L.(step) st0 ev st1), <<TL: state_spin st1>>)
| state_spin_demonic
    (SRT: L.(state_sort) st0 = demonic)
    (STEP: exists ev st1 (STEP: L.(step) st0 ev st1), <<TL: state_spin st1>>)
.

Definition state_spin: _ -> Prop := paco1 _state_spin bot1.

Lemma state_spin_mon: monotone1 _state_spin.
Proof.
  ii. inv IN; try (by econs; eauto).
  - econs 1; et. ii. exploit STEP; et.
  - des. econs 2; et. esplits; et.
Qed.

Hint Constructors _state_spin.
Hint Unfold state_spin.
Hint Resolve state_spin_mon: paco.



Inductive _of_state (of_state: L.(state) -> Tr.t -> Prop): L.(state) -> Tr.t -> Prop :=
| sb_final
    st0 retv
    (FINAL: L.(state_sort) st0 = final (Vint retv))
  :
    _of_state of_state st0 (Tr.done retv)
| sb_spin
    st0
    (SPIN: state_spin st0)
  :
    _of_state of_state st0 (Tr.spin)
| sb_ub
    st0
    (ANG: L.(state_sort) st0 = angelic)
    (STUCK: ~exists ev st1, L.(step) st0 ev st1)
  :
    _of_state of_state st0 (Tr.ub)
| sb_nb
    st0
  :
    _of_state of_state st0 (Tr.nb)
| sb_vis
    st0 st1 ev evs
    (SRT: L.(state_sort) st0 = vis)
    (STEP: _.(step) st0 (Some ev) st1)
    (TL: of_state st1 evs)
  :
    _of_state of_state st0 (Tr.cons ev evs)
| sb_demonic
    st0
    evs
    (SRT: L.(state_sort) st0 = demonic)
    (STEP: union st0 (fun e st1 => (<<HD: e = None>>) /\ (<<TL: _of_state of_state st1 evs>>)))
  :
    _of_state of_state st0 evs
| sb_angelic
    st0
    evs
    (SRT: L.(state_sort) st0 = angelic)
    (STEP: inter st0 (fun e st1 => (<<HD: e = None>>) /\ (<<TL: _of_state of_state st1 evs>>)))
  :
    _of_state of_state st0 evs
.

Definition of_state: _ -> _ -> Prop := paco2 _of_state bot2.

Theorem of_state_ind :
forall (r P: _ -> _ -> Prop),
(forall st0 retv, state_sort L st0 = final (Vint retv) -> P st0 (Tr.done retv)) ->
(forall st0, state_spin st0 -> P st0 Tr.spin) ->
(forall st0, L.(state_sort) st0 = angelic -> ~(exists ev st1, L.(step) st0 ev st1) -> P st0 Tr.ub) ->
(forall st0, P st0 Tr.nb) ->

(forall st0 st1 ev evs
 (SRT: state_sort L st0 = vis)
 (STEP: _.(step) st0 (Some ev) st1)
 (TL: r st1 evs)
  ,
    P st0 (Tr.cons ev evs)) ->
(forall st0 evs
 (SRT: state_sort L st0 = demonic)
 (STEP: union st0
   (fun e st1 =>
    <<HD: e = None >> /\ <<TL: _of_state r st1 evs >> /\ <<IH: P st1 evs>>)), P st0 evs) ->
(forall st0 evs
        (* (IH: forall st1 (STEP: L.(step) st0 None st1), P st1 evs) *)
 (SRT: state_sort L st0 = angelic)
 (STEP: inter st0
   (fun e st1 => <<HD: e = None >> /\ <<TL: _of_state r st1 evs >> /\ <<IH: P st1 evs>>)),
 P st0 evs) ->
forall s t, _of_state r s t -> P s t.
Proof.
  (* fix IH 11. i. *)
  (* inv H5; eauto. *)
  (* - eapply H3; eauto. rr in STEP. des; clarify. *)
  (*   + esplits; eauto. rr. esplits; eauto. left. esplits; eauto. eapply IH; eauto. Guarded. *)
  (*   + esplits; eauto. rr. esplits; eauto. right. esplits; eauto. *)
  (* - eapply H4; eauto. ii. exploit STEP; eauto. i; des; clarify. *)
  (*   + esplits; eauto. left. esplits; eauto. eapply IH; eauto. *)
  (*   + esplits; eauto. right. esplits; eauto. *)
  fix IH 12. i.
  inv H6; eauto.
  - eapply H4; eauto. rr in STEP. des; clarify. esplits; eauto. rr. esplits; eauto. eapply IH; eauto.
  - eapply H5; eauto. ii. exploit STEP; eauto. i; des; clarify. esplits; eauto. eapply IH; eauto.
Qed.

Lemma of_state_mon: monotone2 _of_state.
Proof.
  ii. induction IN using of_state_ind; eauto.
  - econs 1; et.
  - econs 2; et.
  - econs 3; et.
  - econs 4; et.
  - econs 5; et.
  - econs 6; et. rr in STEP. des; clarify. rr. esplits; et.
  - econs 7; et. ii. exploit STEP; eauto. i; des; clarify.
Qed.

Hint Constructors _of_state.
Hint Unfold of_state.
Hint Resolve of_state_mon: paco.

Definition of_program: Tr.t -> Prop := of_state L.(initial_state).




(**********************************************************)
(*********************** properties ***********************)
(**********************************************************)

Lemma prefix_closed_state
      st0 pre bh
      (BEH: of_state st0 bh)
      (PRE: Tr.prefix pre bh)
  :
    <<NB: of_state st0 (Tr.app pre Tr.nb)>>
.
Proof.
  revert_until L. pcofix CIH. i. punfold BEH. rr in PRE. des; subst.
  destruct pre; ss; clarify.
  { pfold. econs; eauto. }

  remember (Tr.cons e (Tr.app pre tl)) as tmp. revert Heqtmp.
  induction BEH using of_state_ind; ii; ss; clarify.
  - pclearbot. pfold. econs; eauto. right. eapply CIH; et. rr; et.
  - pfold. econs 6; eauto. rr in STEP. des; clarify. rr. esplits; eauto.
    exploit IH; et. intro A. punfold A.
  - pfold. econs 7; eauto. ii. exploit STEP; eauto. clear STEP. i; des; clarify. esplits; eauto.
    exploit IH; et. intro A. punfold A.
Qed.

Theorem prefix_closed
      pre bh
      (BEH: of_program bh)
      (PRE: Tr.prefix pre bh)
  :
    <<NB: of_program (Tr.app pre Tr.nb)>>
.
Proof.
  eapply prefix_closed_state; eauto.
Qed.

Lemma nb_bottom
      st0
  :
    <<NB: of_state st0 Tr.nb>>
.
Proof. pfold. econs; et. Qed.

Lemma ub_top
      st0
      (UB: of_state st0 Tr.ub)
  :
    forall beh, of_state st0 beh
.
Proof.
  revert_until L. pfold. i. punfold UB.
  remember Tr.ub as tmp. revert Heqtmp.
  induction UB using of_state_ind; ii; ss; clarify.
  - econs 7; eauto. ii. exfalso. eauto.
  - rr in STEP. des. clarify. econs; eauto. rr. esplits; eauto.
  - econs 7; eauto. ii. exploit STEP; eauto. i; des; clarify. esplits; eauto.
Qed.

Lemma _beh_astep
      r tr st0 ev st1
      (SRT: L.(state_sort) st0 = angelic)
      (STEP: _.(step) st0 ev st1)
      (BEH: paco2 _of_state r st0 tr)
  :
    <<BEH: paco2 _of_state r st1 tr>>
.
Proof.
  exploit wf_angelic; et. i; clarify.
  revert_until L.
  pcofix CIH; i.
  punfold BEH.
  {
    generalize dependent st1.
    induction BEH using of_state_ind; et; try rewrite SRT in *; ii; ss.
    - punfold H. inv H; rewrite SRT in *; ss.
      exploit STEP0; et. i; des. pclearbot. et.
    - contradict H0; et.
    - rr in STEP. exploit STEP; et. i; des.
      pfold. eapply of_state_mon; et. ii; ss. eapply upaco2_mon; et.
  }
Qed.

Lemma beh_astep
      tr st0 ev st1
      (SRT: L.(state_sort) st0 = angelic)
      (STEP: _.(step) st0 ev st1)
      (BEH: of_state st0 tr)
  :
    <<BEH: of_state st1 tr>>
.
Proof.
  eapply _beh_astep; et.
Qed.

Lemma _beh_dstep
      r tr st0 ev st1
      (SRT: L.(state_sort) st0 = demonic)
      (STEP: _.(step) st0 ev st1)
      (BEH: paco2 _of_state r st1 tr)
  :
    <<BEH: paco2 _of_state r st0 tr>>
.
Proof.
  exploit wf_demonic; et. i; clarify.
  pfold. econs 6; et. rr. esplits; et. punfold BEH.
Qed.

Lemma beh_dstep
      tr st0 ev st1
      (SRT: L.(state_sort) st0 = demonic)
      (STEP: _.(step) st0 ev st1)
      (BEH: of_state st1 tr)
  :
    <<BEH: of_state st0 tr>>
.
Proof.
  eapply _beh_dstep; et.
Qed.

End BEHAVES.

End Beh.
Hint Unfold Beh.improves.
Hint Constructors Beh._state_spin.
Hint Unfold Beh.state_spin.
Hint Resolve Beh.state_spin_mon: paco.
Hint Constructors Beh._of_state.
Hint Unfold Beh.of_state.
Hint Resolve Beh.of_state_mon: paco.
