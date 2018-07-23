Require Import Kami.Syntax.
Require Import Kami.Properties Kami.PProperties.
Import ListNotations.
Require Import Coq.Sorting.Permutation.
Require Import Coq.Sorting.PermutEq.
Require Import RelationClasses Setoid Morphisms.


Section BaseModule.
  Variable m: BaseModule.
  Variable o: RegsT.

  Inductive PPlusSubsteps: RegsT -> list RuleOrMeth -> MethsT -> Prop :=
  | NilPPlusSubstep (HRegs: getKindAttr o [=] getKindAttr (getRegisters m)) : PPlusSubsteps nil nil nil
  | PPlusAddRule (HRegs: getKindAttr o [=] getKindAttr (getRegisters m))
            rn rb
            (HInRules: In (rn, rb) (getRules m))
            reads u cs
            (HPAction: PSemAction o (rb type) reads u cs WO)
            (HReadsGood: SubList (getKindAttr reads)
                                 (getKindAttr (getRegisters m)))
            (HUpdGood: SubList (getKindAttr u)
                               (getKindAttr (getRegisters m)))
            upds execs calls oldUpds oldExecs oldCalls
            (HUpds: upds [=] u ++ oldUpds)
            (HExecs: execs [=] Rle rn :: oldExecs)
            (HCalls: calls [=] cs ++ oldCalls)
            (HDisjRegs: DisjKey oldUpds u)
            (HNoRle: forall x, In x oldExecs -> match x with
                                                | Rle _ => False
                                                | _ => True
                                                end)
            (HNoCall: forall c, In c cs -> forall v, In (fst c, v) oldCalls -> False)
            (HPSubstep: PPlusSubsteps oldUpds oldExecs oldCalls):
      PPlusSubsteps upds execs calls
  | PPlusAddMeth (HRegs: getKindAttr o [=] getKindAttr (getRegisters m))
            fn fb
            (HInMeths: In (fn, fb) (getMethods m))
            reads u cs argV retV
            (HPAction: PSemAction o ((projT2 fb) type argV) reads u cs retV)
            (HReadsGood: SubList (getKindAttr reads)
                                 (getKindAttr (getRegisters m)))
            (HUpdGood: SubList (getKindAttr u)
                               (getKindAttr (getRegisters m)))
            upds execs calls oldUpds oldExecs oldCalls
            (HUpds: upds [=] u ++ oldUpds)
            (HExecs: execs [=] Meth (fn, existT _ _ (argV, retV)) :: oldExecs)
            (HCalls: calls [=] cs ++ oldCalls)
            (HDisjRegs: DisjKey oldUpds u)
            (HNoCall: forall c, In c cs -> forall v, In (fst c, v) oldCalls -> False)
            (HNoExec: In (Meth (fn, existT _ _ (argV, retV))) oldExecs -> False)
            (HNoCycle: ~In fn (map fst cs))
            (HPSubstep: PPlusSubsteps oldUpds oldExecs oldCalls):
      PPlusSubsteps upds execs calls.
  
  Definition getLabelUpds (ls: list FullLabel) :=
    concat (map (fun x => fst x) ls).
  
  Definition getLabelExecs (ls: list FullLabel) :=
    map (fun x => fst (snd x)) ls.
  
  Definition getLabelCalls (ls: list FullLabel) :=
    concat (map (fun x => (snd (snd x))) ls).
  
  Lemma PPlusSubsteps_PSubsteps:
    forall upds execs calls,
      PPlusSubsteps upds execs calls ->
      exists l,
        PSubsteps m o l /\
        upds [=] getLabelUpds l /\
        execs [=] getLabelExecs l /\
        calls [=] getLabelCalls l.
  Proof.
    unfold getLabelUpds, getLabelExecs, getLabelCalls.
    induction 1; dest.
    - exists nil.
      repeat split; auto; constructor; auto.
    - exists ((u, (Rle rn, cs)) :: x).
      repeat split; auto; try constructor; auto; simpl.
      + econstructor; eauto; intros.
        * clear - H1 H4 HUpds HExecs HCalls HDisjRegs.
          intro.
          destruct (HDisjRegs k); auto.
          left; intro.
          clear - H1 H4 H H0.
          rewrite H1 in H.
          rewrite <- flat_map_concat_map in H.
          rewrite in_map_iff in H.
          setoid_rewrite in_flat_map in H.
          rewrite in_map_iff in *; dest; subst.
          firstorder fail.
        * clear - H2 H4 HExecs HNoRle.
          apply HNoRle.
          rewrite H2.
          rewrite in_map_iff.
          firstorder fail.
        * clear - H3 H4 H5 HCalls HNoCall.
          eapply HNoCall with (c := f); auto.
          rewrite H3.
          rewrite <- flat_map_concat_map.
          setoid_rewrite in_flat_map.
          unfold InCall in *; dest.
          exists x0; split; auto.
          apply i0.
      + rewrite H1 in HUpds; auto.
      + rewrite HExecs.
        constructor; auto.
      + rewrite H3 in HCalls; auto.
    - exists ((u, (Meth (fn, existT SignT (projT1 fb) (argV, retV)), cs)) :: x).
      repeat split; auto; try constructor; auto; simpl.
      + econstructor 3; eauto; intros.
        * clear - H1 H4 HUpds HExecs HCalls HDisjRegs.
          intro.
          destruct (HDisjRegs k); auto.
          left; intro.
          clear - H1 H4 H H0.
          rewrite H1 in H.
          rewrite <- flat_map_concat_map in H.
          rewrite in_map_iff in H.
          setoid_rewrite in_flat_map in H.
          rewrite in_map_iff in *; dest; subst.
          firstorder fail.
        * clear - H3 H4 H5 HCalls HNoCall.
          eapply HNoCall with (c := f); auto.
          rewrite H3.
          rewrite <- flat_map_concat_map.
          setoid_rewrite in_flat_map.
          unfold InCall in *; dest.
          exists x0; split; auto.
          apply i0.
        * clear - H2 H4 HExecs HNoExec.
          apply HNoExec; unfold InExec in *.
          rewrite H2; assumption.
      + rewrite H1 in HUpds; auto.
      + rewrite HExecs.
        constructor; auto.
      + rewrite H3 in HCalls; auto.
  Qed.
End BaseModule.

Section PPlusSubsteps_rewrite.
  
  Lemma PPlusSubsteps_rewrite_regs m o1 o2 upds execs calls:
    (o1 [=] o2) ->
    PPlusSubsteps m o1 upds execs calls ->
    PPlusSubsteps m o2 upds execs calls.
  Proof.
    induction 2.
    - econstructor 1.
      rewrite <- H; assumption.
    - econstructor 2;(rewrite <- H || apply (PSemAction_rewrite_state H) in HPAction); eauto.
    - econstructor 3;(rewrite <- H || apply (PSemAction_rewrite_state H) in HPAction); eauto.
  Qed.

  Lemma PPlusSubsteps_rewrite_upds m o execs calls upds1 upds2:
    (upds1 [=] upds2) ->
    PPlusSubsteps m o upds1 execs calls ->
    PPlusSubsteps m o upds2 execs calls.
  Proof.
    induction 2.
    - apply Permutation_nil in H; rewrite H.
      econstructor 1; assumption.
    - econstructor 2; eauto.
      rewrite H in HUpds.
      assumption.
    - econstructor 3; eauto.
      rewrite H in HUpds.
      assumption.
  Qed.

  Lemma PPlusSubsteps_rewrite_execs m o upds calls execs1 execs2:
    (execs1 [=] execs2) ->
    PPlusSubsteps m o upds execs1 calls ->
    PPlusSubsteps m o upds execs2 calls.
  Proof.
    induction 2.
    - apply Permutation_nil in H; rewrite H.
      econstructor 1; assumption.
    - econstructor 2; eauto.
      rewrite H in HExecs.
      assumption.
    - econstructor 3; eauto.
      rewrite H in HExecs.
      assumption.
  Qed.

  Lemma PPlusSubsteps_rewrite_calls m o upds execs calls1 calls2:
    (calls1 [=] calls2) ->
    PPlusSubsteps m o upds execs calls1 ->
    PPlusSubsteps m o upds execs calls2.
  Proof.
    induction 2.
    - apply Permutation_nil in H; rewrite H.
      econstructor 1; assumption.
    - econstructor 2; eauto.
      rewrite H in HCalls.
      assumption.
    - econstructor 3; eauto.
      rewrite H in HCalls.
      assumption.
  Qed.

  Lemma PPlusSubsteps_rewrite_all m o1 o2 upds1 execs1 calls1 upds2 execs2 calls2 :
    o1 [=] o2 ->
    upds1 [=] upds2 ->
    execs1 [=] execs2 ->
    calls1 [=] calls2 ->
    PPlusSubsteps m o1 upds1 execs1 calls1 ->
    PPlusSubsteps m o2 upds2 execs2 calls2.
  Proof.
    intros.
    apply (PPlusSubsteps_rewrite_regs H) in H3;
      apply (PPlusSubsteps_rewrite_upds H0) in H3;
      apply (PPlusSubsteps_rewrite_execs H1) in H3;
      apply (PPlusSubsteps_rewrite_calls H2) in H3;
      assumption.
  Qed.
  
  Global Instance PPlusSubsteps_rewrite' :
    Proper (Logic.eq ==>
                     @Permutation (string * {x : FullKind & fullType type x}) ==>
                     @Permutation (string * {x : FullKind & fullType type x}) ==>
                     @Permutation RuleOrMeth ==>
                     @Permutation MethT ==>
                     iff) (@PPlusSubsteps)| 10.
  Proof.
    repeat red; intros; split; intros; subst; eauto using Permutation_sym, PPlusSubsteps_rewrite_all.
    symmetry in H0.
    symmetry in H1.
    symmetry in H2.
    symmetry in H3.
    eapply PPlusSubsteps_rewrite_all; eauto.
  Qed.
End PPlusSubsteps_rewrite.

Lemma Permutation_flat_map_rewrite (A B : Type) (l1 l2 : list A) (f : A -> list B) :
  l1 [=] l2 ->
  flat_map f l1 [=] flat_map f l2.
Proof.
  induction 1; simpl in *; auto.
  - apply Permutation_app_head; assumption.
  - repeat rewrite app_assoc; apply Permutation_app_tail.
    rewrite Permutation_app_comm; reflexivity.
  - rewrite IHPermutation1, IHPermutation2; reflexivity.
Qed.

Global Instance Permutation_flat_map_rewrite' (A B : Type)(f : A -> list B):
  Proper (@Permutation A ==> @Permutation B) (@flat_map A B f) | 10.
repeat red; intros; intros; eauto using Permutation_flat_map_rewrite.
Qed.

Lemma PSubsteps_PPlusSubsteps:
  forall m o l,
    PSubsteps m o l ->
    PPlusSubsteps m o (getLabelUpds l) (getLabelExecs l) (getLabelCalls l).
Proof.
  induction 1; unfold getLabelUpds, getLabelExecs, getLabelCalls in *; try setoid_rewrite <- flat_map_concat_map.
  - econstructor; eauto.
  - rewrite HLabel; simpl; setoid_rewrite <-flat_map_concat_map in IHPSubsteps.
    econstructor 2; intros; eauto.
    + clear - HDisjRegs.
      induction ls.
      * firstorder.
      * intro; simpl in *; rewrite map_app, in_app_iff, DeM1.
        assert (DisjKey (flat_map (fun x : FullLabel => fst x) ls) u);[eapply IHls; eauto|].
        specialize (HDisjRegs a (or_introl _ eq_refl) k); specialize (H k).
        firstorder fail.
    + rewrite in_map_iff in H0; dest; rewrite <- H0.
      eapply HNoRle; eauto.
    + eapply HNoCall; eauto.
      rewrite in_flat_map in H1; dest.
      unfold InCall; exists x; split; auto.
      apply H2.
  - rewrite HLabel; simpl; setoid_rewrite <- flat_map_concat_map in IHPSubsteps.
    econstructor 3; intros; eauto.
    + clear - HDisjRegs.
      induction ls.
      * firstorder.
      * intro; simpl in *; rewrite map_app, in_app_iff, DeM1.
        assert (DisjKey (flat_map (fun x : FullLabel => fst x) ls) u);[eapply IHls; eauto|].
        specialize (HDisjRegs a (or_introl _ eq_refl) k); specialize (H k).
        firstorder fail.
    + eapply HNoCall; eauto.
      rewrite in_flat_map in H1; dest.
      unfold InCall; exists x; split; auto.
      apply H2.
Qed.

Section PPlusStep.
  Variable m: BaseModule.
  Variable o: RegsT.
  
  Definition MatchingExecCalls_flat (calls : MethsT) (exec : list RuleOrMeth) (m : BaseModule) :=
    forall (f : MethT),
      In f calls ->
      In (fst f) (map fst (getMethods m)) ->
      In (Meth f) exec.
  
  Inductive PPlusStep :  RegsT -> list RuleOrMeth -> MethsT -> Prop :=
  | BasePPlusStep upds execs calls:
      PPlusSubsteps m o upds execs calls ->
      MatchingExecCalls_flat calls execs m -> PPlusStep upds execs calls.
  
  Lemma PPlusStep_PStep:
    forall upds execs calls,
      PPlusStep upds execs calls ->
      exists l,
        PStep (Base m) o l /\
        upds [=] getLabelUpds l /\
        execs [=] getLabelExecs l /\
        calls [=] getLabelCalls l.
  Proof.
    induction 1.
    apply PPlusSubsteps_PSubsteps in H; dest.
    exists x; repeat split; eauto.
    econstructor 1; eauto.
    repeat intro; specialize (H0 f) ; simpl; split; auto.
    unfold InCall, InExec, getLabelUpds, getLabelExecs, getLabelCalls in *; dest.
    rewrite <- flat_map_concat_map in *.
    rewrite H2 in H0; apply H0; eauto.
    rewrite H3, in_flat_map; firstorder.
  Qed.

  Lemma PStep_PPlusStep :
  forall l,
    PStep (Base m) o l ->
    PPlusStep (getLabelUpds l) (getLabelExecs l) (getLabelCalls l).
  Proof.
    intros; inv H; econstructor.
    - apply PSubsteps_PPlusSubsteps in HPSubsteps; assumption.
    - repeat intro; specialize (HMatching f).
      unfold InCall, InExec, getLabelUpds, getLabelExecs, getLabelCalls in *.
      rewrite <- flat_map_concat_map, in_flat_map in *; dest.
      eapply HMatching; eauto.
  Qed.
End PPlusStep.

Section PPlusTrace.
  Variable m: BaseModule.
  
  Definition PPlusUpdRegs (u o o' : RegsT) :=
    getKindAttr o [=] getKindAttr o' /\
    (forall s v, In (s, v) o' -> In (s, v) u \/ (~ In s (map fst u) /\ In (s, v) o)).
  
  Inductive PPlusTrace : RegsT -> list (RegsT * ((list RuleOrMeth) * MethsT)) -> Prop :=
  | PPlusInitTrace (o' o'' : RegsT) ls'
                   (HPerm : o' [=] o'')
                   (HUpdRegs : Forall2 regInit o'' (getRegisters m))
                   (HTrace : ls' = nil):
      PPlusTrace o' ls'
  | PPlusContinueTrace (o o' : RegsT)
                       (upds : RegsT)
                       (execs : list RuleOrMeth)
                       (calls : MethsT)
                       (ls ls' : list (RegsT * ((list RuleOrMeth) * MethsT)))
                       (PPlusOldTrace : PPlusTrace o ls)
                       (HPPlusStep : PPlusStep m o upds execs calls)
                       (HUpdRegs : PPlusUpdRegs upds o o')
                       (HPPlusTrace : ls' = ((upds, (execs, calls))::ls)):
      PPlusTrace o' ls'.

  Notation PPT_upds := (fun x => fst x).
  Notation PPT_execs := (fun x => fst (snd x)).
  Notation PPT_calls := (fun x => snd (snd x)).
  
  Lemma PPlusTrace_PTrace o ls :
    PPlusTrace o ls ->
    exists ls',
      PTrace (Base m) o ls' /\
      PermutationEquivLists (map PPT_upds ls) (map getLabelUpds ls') /\
      PermutationEquivLists (map PPT_execs ls) (map getLabelExecs ls') /\
      PermutationEquivLists (map PPT_calls ls) (map getLabelCalls ls').
  Proof.
    induction 1; subst; dest.
    - exists nil; repeat split; econstructor; eauto.
    - apply PPlusStep_PStep in HPPlusStep; dest.
      exists (x0::x); repeat split; eauto; simpl in *; econstructor 2; eauto.
      + unfold PPlusUpdRegs in HUpdRegs; dest.
        repeat split; eauto.
        intros; destruct (H9 _ _ H10).
        * rewrite H5 in H11; unfold getLabelUpds in H11.
          rewrite <- flat_map_concat_map, in_flat_map in *; dest.
          left; exists (fst x1); split; auto.
          apply (in_map fst) in H11; assumption.
        * destruct H11; right; split; auto.
          intro; apply H11; dest.
          unfold getLabelUpds in *.
          rewrite H5, <- flat_map_concat_map, in_map_iff.
          setoid_rewrite in_flat_map.
          rewrite in_map_iff in H13,H14; dest.
          exists x2; split; auto.
          exists x3; subst; auto.
  Qed.

  Definition extractTriple (lfl : list FullLabel) : (RegsT * ((list RuleOrMeth) * MethsT)) :=
    (getLabelUpds lfl, (getLabelExecs lfl, getLabelCalls lfl)).

  Fixpoint extractTriples (llfl : list (list FullLabel)) : list (RegsT * ((list RuleOrMeth) * MethsT)) :=
    match llfl with
    |lfl::llfl' => (extractTriple lfl)::(extractTriples llfl')
    |nil => nil
    end.

  Lemma extractTriples_nil l :
    extractTriples l = nil -> l = nil.
  Proof.
    destruct l; intros; auto.
    inv H.
  Qed.
  
  Lemma PTrace_PPlusTrace o ls:
    PTrace (Base m) o ls ->
      PPlusTrace o (extractTriples ls).
  Proof.
    induction 1; subst; intros.
    - econstructor; eauto.
    - simpl; econstructor 2; eauto.
      + apply PStep_PPlusStep; apply HPStep.
      + unfold PUpdRegs,PPlusUpdRegs in *; dest; repeat split; eauto.
        intros; destruct (H1 _ _ H2);[left|right]; unfold getLabelUpds; dest.
        * rewrite <- flat_map_concat_map, in_flat_map.
          rewrite (in_map_iff fst) in H3; dest; rewrite <- H3 in H4.
          firstorder.
        * split; auto; intro; apply H3.
          rewrite <- flat_map_concat_map, in_map_iff in H5; dest.
          rewrite in_flat_map in H6; dest.
          exists (fst x0); split.
          -- rewrite in_map_iff; exists x0; firstorder.
          -- rewrite <- H5, in_map_iff; exists x; firstorder.
      + unfold extractTriple; reflexivity.
  Qed.
End PPlusTrace.

Section PPlusTraceInclusion.
  Notation PPT_upds := (fun x => fst x).
  Notation PPT_execs := (fun x => fst (snd x)).
  Notation PPT_calls := (fun x => snd (snd x)).
  
  Definition WeakInclusion_flat (t1 t2 : (RegsT *((list RuleOrMeth) * MethsT))) :=
    (forall (f : MethT), In (Meth f) (PPT_execs t1) /\ ~In f (PPT_calls t1) <->
                         In (Meth f) (PPT_execs t2) /\ ~In f (PPT_calls t2)) /\
    (forall (f : MethT), ~In (Meth f) (PPT_execs t1) /\ In f (PPT_calls t1) <->
                         ~In (Meth f) (PPT_execs t2) /\ In f (PPT_calls t2)) /\
    (forall (f : MethT), ((In (Meth f) (PPT_execs t1) /\ In f (PPT_calls t1)) \/
                          ((forall v, ~In (Meth (fst f, v)) (PPT_execs t1)) /\ (forall v, ~In (fst f, v) (PPT_calls t1)))) <->
                         ((In (Meth f) (PPT_execs t2) /\ In f (PPT_calls t2)) \/
                          ((forall v, (~In (Meth (fst f, v)) (PPT_execs t2))) /\ (forall v, ~In (fst f, v) (PPT_calls t2))))) /\
    ((exists rle, In (Rle rle) (PPT_execs t2)) ->
     (exists rle, In (Rle rle) (PPT_execs t1))).

  Lemma  InExec_rewrite f l:
    In (Meth f) (getLabelExecs l) <-> InExec f l.
  Proof.
    split; unfold InExec; induction l; simpl in *; intros; auto.
  Qed.

  Lemma InCall_rewrite f l :
    In f (getLabelCalls l) <-> InCall f l.
  Proof.
    split; unfold InCall; induction l; simpl in *; intros; dest; try contradiction.
    - unfold getLabelCalls in H. rewrite <- flat_map_concat_map, in_flat_map in H.
      assumption.
    -  unfold getLabelCalls; rewrite <- flat_map_concat_map, in_flat_map.
       firstorder fail.
  Qed.

  Lemma WeakInclusion_flat_WeakInclusion (l1 l2 : list FullLabel) :
    WeakInclusion_flat (extractTriple l1) (extractTriple l2) ->
    WeakInclusion l1 l2.
  Proof.
    unfold WeakInclusion_flat, extractTriple; simpl.
    setoid_rewrite InExec_rewrite; setoid_rewrite InCall_rewrite.    
    intros; assumption.
  Qed.
  
  Inductive WeakInclusions_flat : list (RegsT * ((list RuleOrMeth) * MethsT)) -> list (RegsT *((list RuleOrMeth) * MethsT)) -> Prop :=
  |WIf_Nil : WeakInclusions_flat nil nil
  |WIf_Cons : forall (lt1 lt2 : list (RegsT *((list RuleOrMeth) * MethsT))) (t1 t2 : RegsT *((list RuleOrMeth) * MethsT)),
      WeakInclusions_flat lt1 lt2 -> WeakInclusion_flat t1 t2 -> WeakInclusions_flat (t1::lt1) (t2::lt2).

  
  Lemma WeakInclusions_flat_WeakInclusions (ls1 ls2 : list (list FullLabel)) :
    WeakInclusions_flat (extractTriples ls1) (extractTriples ls2) ->
    WeakInclusions ls1 ls2.
  Proof.
    revert ls2; induction ls1; intros; simpl in *; inv H.
    - symmetry in H0; apply extractTriples_nil in H0; subst; econstructor.
    - destruct ls2; inv H2.
      econstructor 2.
      + eapply IHls1; eauto.
      + apply WeakInclusion_flat_WeakInclusion; assumption.
  Qed.
  
  Definition PPlusTraceList (m : BaseModule)(lt : list (RegsT * ((list RuleOrMeth) * MethsT))) :=
    (exists (o : RegsT), PPlusTrace m o lt).

  Definition PPlusTraceInclusion (m m' : BaseModule) :=
    forall (o : RegsT)(tl : list (RegsT *((list RuleOrMeth) * MethsT))),
      PPlusTrace m o tl -> exists (tl' : list (RegsT * ((list RuleOrMeth) * MethsT))),  PPlusTraceList m' tl' /\ WeakInclusions_flat tl tl'.

  Lemma WeakInclusions_flat_PermutationEquivLists_r ls1:
    forall l ls2,
      WeakInclusions_flat (extractTriples ls1) l ->
      PermutationEquivLists (map PPT_upds l) (map getLabelUpds ls2) ->
      PermutationEquivLists (map PPT_execs l) (map getLabelExecs ls2) ->
      PermutationEquivLists (map PPT_calls l) (map getLabelCalls ls2) ->
      WeakInclusions_flat (extractTriples ls1) (extractTriples ls2).
  Proof.
    induction ls1; intros; inv H; simpl in *.
    - destruct ls2; simpl in *.
      + econstructor.
      + inv H2.
    - destruct ls2; inv H2; inv H1; inv H0; simpl in *.
      econstructor.
      + eapply IHls1; eauto.
      + unfold WeakInclusion_flat in *; dest; simpl in *.
        split;[|split;[|split]];setoid_rewrite <- H10;auto; setoid_rewrite <- H9; auto.
  Qed.
  
  Lemma PPlusTraceInclusion_PTraceInclusion (m m' : BaseModule) :
    PPlusTraceInclusion m m' ->
    PTraceInclusion (Base m) (Base m').
  Proof.
    repeat intro.
    apply (PTrace_PPlusTrace) in H0.
    specialize (H o _ H0); dest.
    destruct  H.
    apply (PPlusTrace_PTrace) in H; dest.
    exists x1; split.
    - exists x0; assumption.
    - apply WeakInclusions_flat_WeakInclusions.
      apply (WeakInclusions_flat_PermutationEquivLists_r _ _ H1 H2 H3 H4).
  Qed.

  Corollary PPlusTraceInclusion_TraceInclusion (m m' : BaseModule) (Wfm : WfMod (Base m)) (Wfm' : WfMod (Base m')):
    PPlusTraceInclusion m m' ->
    TraceInclusion (Base m) (Base m').
  Proof.
    intros; apply PTraceInclusion_TraceInclusion, PPlusTraceInclusion_PTraceInclusion; auto.
  Qed.
End PPlusTraceInclusion.

Lemma NoDup_app_iff (A : Type) (l1 l2 : list A) :
  NoDup (l1++l2) <->
  NoDup l1 /\
  NoDup l2 /\
  (forall a, In a l1 -> ~In a l2) /\
  (forall a, In a l2 -> ~In a l1).
Proof.
  repeat split; intros; dest.
  - induction l1; econstructor; inv H; firstorder.
  - induction l2; econstructor; apply NoDup_remove in H; dest; firstorder.
  - induction l1; auto.
    simpl in H; rewrite NoDup_cons_iff in H; dest; firstorder.
    subst; firstorder.
  - induction l2; auto.
    apply NoDup_remove in H; dest; firstorder.
    subst; firstorder.
  -  induction l1; simpl; eauto.
     constructor.
     + rewrite in_app_iff, DeM1; split; firstorder.
       inv H; assumption.
     + inv H; eapply IHl1; eauto; firstorder.
Qed.

Lemma PSemAction_NoDup_Key_Calls k  o (a : ActionT type k) readRegs newRegs calls (fret : type k) :
  PSemAction o a readRegs newRegs calls fret ->
  NoDup (map fst calls).
Proof.
  induction 1; eauto;
    [rewrite HAcalls; simpl; econstructor; eauto; intro;
     specialize (fst_produce_snd _ _ H0) as TMP; dest; specialize (HDisjCalls x);
     contradiction | | | | subst; econstructor];
    rewrite HUCalls; rewrite map_app,NoDup_app_iff; repeat split; eauto;
      repeat intro; specialize (HDisjCalls a0); firstorder.
Qed.

Corollary PSemAction_NoDup_Calls k o (a : ActionT type k) readRegs newRegs calls (fret : type k) :
  PSemAction o a readRegs newRegs calls fret ->
  NoDup calls.
Proof.
  intros; apply PSemAction_NoDup_Key_Calls in H; apply NoDup_map_inv in H; assumption.
Qed.

Lemma PSemAction_NoDup_Key_Writes k o (a : ActionT type k) readRegs newRegs calls (fret : type k) :
  PSemAction o a readRegs newRegs calls fret ->
  NoDup (map fst newRegs).
Proof.
  induction 1;
    eauto;[|
           rewrite HANewRegs; simpl; econstructor; eauto; intro;
           specialize (fst_produce_snd _ _ H0) as TMP; dest; specialize (HDisjRegs x);
           contradiction| | |subst; econstructor];
    rewrite HUNewRegs; rewrite map_app,NoDup_app_iff; repeat split; eauto;
        repeat intro; specialize (HDisjRegs a0); firstorder.
Qed.

Corollary PSemAction_NoDup_Writes k o (a : ActionT type k) readRegs newRegs calls (fret : type k) :
  PSemAction o a readRegs newRegs calls fret ->
  NoDup newRegs.
Proof.
  intros; apply PSemAction_NoDup_Key_Writes in H; apply NoDup_map_inv in H; assumption.
Qed.

Lemma PPlusSubsteps_NoDup_Key_Calls m o upds execs calls:
  PPlusSubsteps m o upds execs calls ->
  NoDup (map fst calls).
Proof.
  induction 1;[econstructor| |];
    rewrite HCalls; rewrite map_app, NoDup_app_iff; repeat split;
      auto; eauto using PSemAction_NoDup_Key_Calls; repeat intro;
        specialize (fst_produce_snd _ _ H0) as TMP; dest;
          specialize (fst_produce_snd _ _ H1) as TMP; dest;
            [apply (HNoCall _ H2 _ H3)| apply (HNoCall _ H3 _ H2)
             |apply (HNoCall _ H2 _ H3)| apply (HNoCall _ H3 _ H2)].
Qed.

Lemma PPlusSubsteps_NoDup_Key_Writes m o upds execs calls:
  PPlusSubsteps m o upds execs calls ->
  NoDup (map fst upds).
Proof.
  induction 1;[econstructor| |];
    rewrite HUpds; rewrite map_app,NoDup_app_iff; repeat split;
      auto; eauto using PSemAction_NoDup_Key_Writes; repeat intro;
        specialize (HDisjRegs a);firstorder.
Qed.

Corollary PPlusSubsteps_NoDup_Writes m o upds execs calls :
  PPlusSubsteps m o upds execs calls ->
  NoDup upds.
Proof.
  intros; apply PPlusSubsteps_NoDup_Key_Writes in H;
    apply NoDup_map_inv in H; assumption.
Qed.

Lemma NoDup_app_Disj (A : Type) (dec : forall (a1 a2 : A), {a1 = a2}+{a1 <> a2}) :
    forall (l1 l2 : list A),
      NoDup (l1++l2) ->
      (forall a, ~In a l1 \/ ~In a l2).
Proof.
  intros.
  rewrite NoDup_app_iff in H; dest.
  destruct (in_dec dec a l1); auto.
Qed.

Notation remove_calls := (fun x y => negb (getBool (string_dec (fst x) (fst y)))).
Notation keep_calls := (fun x y => (getBool (string_dec (fst x) (fst y)))).

Definition methcmp (m1 m2 : MethT) : bool := getBool (MethT_dec m1 m2).

Definition remove_execs (calls : MethsT) (exec : RuleOrMeth) : bool :=
  match exec with
  | Rle _ => false
  | Meth f => existsb (methcmp f) calls
  end.

Lemma key_not_In_filter (f : DefMethT) (calls : MethsT) :
  key_not_In (fst f) calls ->
  filter (remove_calls f) calls = calls.
Proof.
  induction calls; unfold key_not_In in *; simpl in *; intros; auto.
  destruct string_dec; pose proof (H (snd a)); simpl in *.
  - apply False_ind; apply H0; left.
    destruct a; simpl in *; rewrite e; reflexivity.
  - rewrite IHcalls; auto.
    repeat intro; specialize (H v); apply H; right; assumption.
Qed.

Lemma PSemAction_inline_notIn (f : DefMethT) o k (a : ActionT type k)
      readRegs newRegs calls (fret : type k) :
  PSemAction o a readRegs newRegs calls fret ->
  ~In (fst f) (map fst calls) ->
  PSemAction o (inlineSingle f a) readRegs newRegs calls fret.
Proof.
  induction 1; simpl; intros.
  - destruct string_dec; subst.
    + apply False_ind; apply H0; rewrite HAcalls; simpl; left; reflexivity.
    + econstructor 1; eauto.
      apply IHPSemAction; intro; apply H0; rewrite HAcalls; simpl; right; assumption.
  - econstructor 2; eauto.
  - econstructor 3; eauto;[eapply IHPSemAction1|eapply IHPSemAction2];
      intro; apply H1; rewrite HUCalls, map_app, in_app_iff;[left|right]; assumption.
  - econstructor 4; eauto.
  - econstructor 5; eauto.
  - econstructor 6; eauto.
  - econstructor 7; eauto; [eapply IHPSemAction1|eapply IHPSemAction2];
      intro; apply H1; rewrite HUCalls, map_app, in_app_iff;[left|right]; assumption.
  - econstructor 8; eauto; [eapply IHPSemAction1|eapply IHPSemAction2];
      intro; apply H1; rewrite HUCalls, map_app, in_app_iff;[left|right]; assumption.
  - econstructor 9; eauto.
  - econstructor 10; eauto.
  - econstructor 11; eauto.
Qed.

Lemma PSemAction_inline_In (f : DefMethT) o readRegs' newRegs' calls' argV retV1:
    PSemAction o (projT2 (snd f) type argV) readRegs' newRegs' calls' retV1 ->
    forall {retK2} a readRegs newRegs calls (retV2 : type retK2),
      DisjKey newRegs' newRegs ->
      DisjKey calls' calls ->
      In (fst f,  (existT _ (projT1 (snd f)) (argV, retV1))) calls ->
      PSemAction o a readRegs newRegs calls retV2 ->
      PSemAction o (inlineSingle f a) (readRegs' ++ readRegs) (newRegs' ++ newRegs)
                 (calls' ++ filter (remove_calls f) calls) retV2.
Proof.
  induction a.
  - intros; simpl; destruct string_dec;[destruct Signature_dec|]; subst.
    + assert (DisjKey calls' (filter (remove_calls f) calls));[
      intro; destruct (H2 k); auto; right;
      intro; apply H5; rewrite in_map_iff in H6; dest; rewrite filter_In in H7; dest;
      rewrite in_map_iff; exists x; firstorder|].
      clear H2.
      econstructor; eauto; inv H4; EqDep_subst; rewrite HAcalls in H3; destruct H3.
      * econstructor; eauto.
        -- inversion H2; EqDep_subst.
           apply H.
      * apply False_ind.
        specialize (HDisjCalls (existT SignT (projT1 (snd f)) (argV, retV1))); contradiction.
      * inversion H2; EqDep_subst.
        apply PSemAction_inline_notIn.
        -- assert (filter (fun y : string * {x : Kind * Kind & SignT x} =>
                             negb (getBool (string_dec (fst f) (fst y)))) calls [=]
                          calls0);
             [rewrite HAcalls; simpl; destruct string_dec;[|exfalso; apply n; reflexivity];
              simpl;rewrite key_not_In_filter; auto|].
           apply (PSemAction_rewrite_calls (Permutation_sym H3) HPSemAction).
        -- intro.
           rewrite in_map_iff in H3; dest; rewrite filter_In in H4; dest.
           rewrite H3 in H6; destruct string_dec; simpl in *;[discriminate|apply n; reflexivity].
      * apply False_ind.
        specialize (HDisjCalls (existT SignT (projT1 (snd f)) (argV, retV1))); contradiction.
    + apply False_ind.
      inv H4; EqDep_subst.
      rewrite HAcalls in H3; destruct H3.
      * inv H3; EqDep_subst; apply n; reflexivity.
      * specialize (HDisjCalls (existT SignT (projT1 (snd f)) (argV, retV1))); contradiction.
    + inv H4; EqDep_subst.
      assert (DisjKey calls' (filter (remove_calls f) calls));
        [intro; destruct (H2 k); auto; right;
         intro; apply H4; rewrite in_map_iff in H5; dest; rewrite filter_In in H6; dest;
         rewrite in_map_iff; exists x; firstorder|].
      assert (key_not_In meth (calls'++(filter (remove_calls f) calls0))).
      * repeat intro; rewrite in_app_iff in H5; destruct H5.
        -- rewrite HAcalls in H2; destruct (H2 meth).
           ++ apply H6; rewrite in_map_iff; exists (meth, v); firstorder fail.
           ++ apply H6; simpl; left; reflexivity.
        -- rewrite filter_In in H5; dest.
           specialize (HDisjCalls v); contradiction.
      * econstructor.
        -- apply H5.
        -- rewrite HAcalls.
           simpl; destruct string_dec;[contradiction|simpl].
           symmetry; apply Permutation_middle.
        -- eapply H0; eauto.
           ++ repeat intro; destruct (H2 k);[left|right; intro; apply H6; rewrite HAcalls; right]; assumption.
           ++ rewrite HAcalls in H3.
              destruct H3;[inv H3; EqDep_subst; apply False_ind; apply n; reflexivity| assumption].
  - intros; inv H4; EqDep_subst; simpl in *; econstructor 2.
    eapply H0; eauto.
  - intros; inv H4; EqDep_subst; simpl in *.
    rewrite HUCalls, in_app_iff in H3; destruct H3; econstructor 3.
    + rewrite HUNewRegs in H1.
      assert (DisjKey (newRegs'++newRegs0) newRegsCont).
      * intro; specialize (H1 k0); specialize (HDisjRegs k0); rewrite map_app, in_app_iff, DeM1 in *;
          destruct H1, HDisjRegs;[left| right| right|right]; dest; auto.
      * apply H4.
    + rewrite HUCalls in H2.
      assert (DisjKey (calls'++(filter (remove_calls f) calls0)) callsCont).
      * intro; specialize (H2 k0); specialize (HDisjCalls k0); rewrite map_app, in_app_iff, DeM1 in *.
        destruct H2, HDisjCalls;[left| right| right|right]; dest; auto.
        split;[assumption|].
        intro; apply H4; rewrite in_map_iff in H5; dest; rewrite filter_In in H6; dest.
        rewrite <- H5; rewrite in_map_iff; exists x; firstorder.
      * apply H4.
    + eapply IHa; eauto.
      * rewrite HUNewRegs in H1; intro; specialize (H1 k0); rewrite map_app, in_app_iff, DeM1 in H1.
        destruct H1;[left|right];dest;auto.
      * rewrite HUCalls in H2; intro; specialize (H2 k0); rewrite map_app, in_app_iff, DeM1 in H2.
        destruct H2;[left|right];dest;auto.
    + rewrite HUReadRegs; rewrite app_assoc; reflexivity.
    + rewrite HUNewRegs; rewrite app_assoc; reflexivity.
    + rewrite HUCalls.
      rewrite filter_app, app_assoc.
      apply Permutation_app_head.
      assert (key_not_In (fst f) callsCont);
        [repeat intro;apply (in_map fst) in H4; apply (in_map fst) in  H3; simpl in *;
         specialize (HDisjCalls (fst f)); firstorder|].
      rewrite (key_not_In_filter _ H4); reflexivity.
    + apply PSemAction_inline_notIn; auto.
      apply (in_map fst) in H3; simpl in *.
      destruct (HDisjCalls (fst f)); auto.
    + rewrite HUNewRegs in H1.
      assert (DisjKey newRegs0 (newRegs'++newRegsCont)).
      * intro; specialize (H1 k0); specialize (HDisjRegs k0); rewrite map_app, in_app_iff, DeM1 in *;
          destruct H1, HDisjRegs; dest; auto.
      * apply H4.
    + rewrite HUCalls in H2.
      assert (DisjKey calls0 (calls'++(filter (remove_calls f) callsCont))).
      * intro; specialize (H2 k0); specialize (HDisjCalls k0); rewrite map_app, in_app_iff, DeM1 in *.
        destruct H2, HDisjCalls; dest; auto.
        right; split;[assumption|].
        intro; apply H4; rewrite in_map_iff in H5; dest; rewrite filter_In in H6; dest.
        rewrite <- H5; rewrite in_map_iff; exists x; firstorder.
      * apply H4.
    + apply PSemAction_inline_notIn; eauto.
      intro; apply (in_map fst) in H3; destruct (HDisjCalls (fst f)); simpl;auto.
    + rewrite HUReadRegs,Permutation_app_comm, <- app_assoc.
      apply Permutation_app_head.
      rewrite Permutation_app_comm; reflexivity.
    + rewrite HUNewRegs; repeat rewrite app_assoc. apply Permutation_app_tail.
      rewrite Permutation_app_comm; reflexivity.
    + rewrite HUCalls, filter_app.
      assert (key_not_In (fst f) calls0);
        [repeat intro; apply (in_map fst) in H4; apply (in_map fst) in H3; simpl in *;
         specialize (HDisjCalls (fst f));firstorder|].
      rewrite (key_not_In_filter _ H4).
      repeat rewrite app_assoc; apply Permutation_app_tail.
      rewrite Permutation_app_comm; reflexivity.
    + eapply H0; eauto.
      * rewrite HUNewRegs in H1; intro; specialize (H1 k0); rewrite map_app, in_app_iff, DeM1 in H1.
        destruct H1;[left|right];dest;auto.
      * rewrite HUCalls in H2; intro; specialize (H2 k0); rewrite map_app, in_app_iff, DeM1 in H2.
        destruct H2;[left|right];dest;auto.
  - intros; simpl; inv H4; EqDep_subst; econstructor 4; eauto.
  - intros; simpl; inv H4; EqDep_subst; econstructor 5; eauto.
    rewrite HNewReads; symmetry; apply Permutation_middle.
  - intros; simpl; inv H3; EqDep_subst; econstructor 6; auto.
    + rewrite HANewRegs in H0; specialize (H0 r); destruct H0;
        [|apply False_ind; apply H0;left;reflexivity].
      assert (key_not_In r (newRegs'++newRegs0));
        [intro;specialize (HDisjRegs v);rewrite in_app_iff,DeM1;
         split;auto;intro;apply H0;apply (in_map fst) in H3; assumption|].
      apply H3.
    + rewrite HANewRegs.
      symmetry; apply Permutation_middle.
    + eapply IHa; eauto.
      rewrite HANewRegs in H0.
      intro; specialize (H0 k0); simpl in *; firstorder fail.
  - intros; inv H4; EqDep_subst; simpl in *.
    rewrite HUCalls, in_app_iff in H3; destruct H3; econstructor 7.
    + rewrite HUNewRegs in H1.
      assert (DisjKey (newRegs'++newRegs1) newRegs2).
      * intro; specialize (H1 k0); specialize (HDisjRegs k0); rewrite map_app, in_app_iff, DeM1 in *;
          destruct H1, HDisjRegs;[left| right| right|right]; dest; auto.
      * apply H4.
    + rewrite HUCalls in H2.
      assert (DisjKey (calls'++(filter (remove_calls f) calls1)) calls2).
      * intro; specialize (H2 k0); specialize (HDisjCalls k0); rewrite map_app, in_app_iff, DeM1 in *.
        destruct H2, HDisjCalls;[left| right| right|right]; dest; auto.
        split;[assumption|].
        intro; apply H4; rewrite in_map_iff in H5; dest; rewrite filter_In in H6; dest.
        rewrite <- H5; rewrite in_map_iff; exists x; firstorder.
      * apply H4.
    + assumption.
    + eapply IHa1; eauto.
      * rewrite HUNewRegs in H1; intro; specialize (H1 k0); rewrite map_app, in_app_iff, DeM1 in H1.
        destruct H1;[left|right];dest;auto.
      * rewrite HUCalls in H2; intro; specialize (H2 k0); rewrite map_app, in_app_iff, DeM1 in H2.
        destruct H2;[left|right];dest;auto.
    + apply PSemAction_inline_notIn.
      * apply HPSemAction.
      * apply (in_map fst) in H3; destruct (HDisjCalls (fst f));tauto.
    + rewrite HUReadRegs; rewrite app_assoc; reflexivity.
    + rewrite HUNewRegs; rewrite app_assoc; reflexivity.
    + rewrite HUCalls.
      rewrite filter_app, app_assoc.
      apply Permutation_app_head.
      assert (key_not_In (fst f) calls2);
        [repeat intro;apply (in_map fst) in H4; apply (in_map fst) in  H3; simpl in *;
         specialize (HDisjCalls (fst f)); firstorder|].
      rewrite (key_not_In_filter _ H4); reflexivity.

    + rewrite HUNewRegs in H1.
      assert (DisjKey newRegs1 (newRegs'++newRegs2)).
      * intro; specialize (H1 k0); specialize (HDisjRegs k0); rewrite map_app, in_app_iff, DeM1 in *;
          destruct H1, HDisjRegs; dest; auto.
      * apply H4.
    + rewrite HUCalls in H2.
      assert (DisjKey calls1 (calls'++(filter (remove_calls f) calls2))).
      * intro; specialize (H2 k0); specialize (HDisjCalls k0); rewrite map_app, in_app_iff, DeM1 in *.
        destruct H2, HDisjCalls; dest; auto.
        right;split;[assumption|].
        intro; apply H4; rewrite in_map_iff in H5; dest; rewrite filter_In in H6; dest.
        rewrite <- H5; rewrite in_map_iff; exists x; firstorder.
      * apply H4.
    + assumption.
    + apply PSemAction_inline_notIn.
      * apply HAction.
      * apply (in_map fst) in H3; destruct (HDisjCalls (fst f));tauto.
    + eapply H0; eauto.
      * rewrite HUNewRegs in H1; intro; specialize (H1 k0); rewrite map_app, in_app_iff, DeM1 in H1.
        destruct H1;[left|right];dest;auto.
      * rewrite HUCalls in H2; intro; specialize (H2 k0); rewrite map_app, in_app_iff, DeM1 in H2.
        destruct H2;[left|right];dest;auto.
    + rewrite HUReadRegs; repeat rewrite app_assoc; apply Permutation_app_tail;
        rewrite Permutation_app_comm; reflexivity.
    + rewrite HUNewRegs; repeat rewrite app_assoc; apply Permutation_app_tail;
        rewrite Permutation_app_comm; reflexivity.
    + rewrite HUCalls.
      rewrite filter_app; repeat rewrite app_assoc.
      apply Permutation_app_tail.
      assert (key_not_In (fst f) calls1);
        [repeat intro;apply (in_map fst) in H4; apply (in_map fst) in  H3; simpl in *;
         specialize (HDisjCalls (fst f)); firstorder|].
      rewrite (key_not_In_filter _ H4), Permutation_app_comm; reflexivity.
    + rewrite HUCalls, in_app_iff in H3; destruct H3; econstructor 8.
      * rewrite HUNewRegs in H1.
        assert (DisjKey (newRegs'++newRegs1) newRegs2).
        -- intro; specialize (H1 k0); specialize (HDisjRegs k0); rewrite map_app, in_app_iff, DeM1 in *;
             destruct H1, HDisjRegs;[left| right| right|right]; dest; auto.
        -- apply H4.
      * rewrite HUCalls in H2.
        assert (DisjKey (calls'++(filter (remove_calls f) calls1)) calls2).
        -- intro; specialize (H2 k0); specialize (HDisjCalls k0); rewrite map_app, in_app_iff, DeM1 in *.
           destruct H2, HDisjCalls;[left| right| right|right]; dest; auto.
           split;[assumption|].
           intro; apply H4; rewrite in_map_iff in H5; dest; rewrite filter_In in H6; dest.
           rewrite <- H5; rewrite in_map_iff; exists x; firstorder.
        -- apply H4.
      * assumption.
      * eapply IHa2; eauto.
        -- rewrite HUNewRegs in H1; intro; specialize (H1 k0); rewrite map_app, in_app_iff, DeM1 in H1.
           destruct H1;[left|right];dest;auto.
        -- rewrite HUCalls in H2; intro; specialize (H2 k0); rewrite map_app, in_app_iff, DeM1 in H2.
           destruct H2;[left|right];dest;auto.
      * apply PSemAction_inline_notIn.
        -- apply HPSemAction.
        -- apply (in_map fst) in H3; destruct (HDisjCalls (fst f));tauto.
      * rewrite HUReadRegs; rewrite app_assoc; reflexivity.
      * rewrite HUNewRegs; rewrite app_assoc; reflexivity.
      * rewrite HUCalls.
        rewrite filter_app, app_assoc.
        apply Permutation_app_head.
        assert (key_not_In (fst f) calls2);
          [repeat intro;apply (in_map fst) in H4; apply (in_map fst) in  H3; simpl in *;
           specialize (HDisjCalls (fst f)); firstorder|].
        rewrite (key_not_In_filter _ H4); reflexivity.

      * rewrite HUNewRegs in H1.
        assert (DisjKey newRegs1 (newRegs'++newRegs2)).
        -- intro; specialize (H1 k0); specialize (HDisjRegs k0); rewrite map_app, in_app_iff, DeM1 in *;
          destruct H1, HDisjRegs; dest; auto.
        -- apply H4.
      * rewrite HUCalls in H2.
        assert (DisjKey calls1 (calls'++(filter (remove_calls f) calls2))).
        -- intro; specialize (H2 k0); specialize (HDisjCalls k0); rewrite map_app, in_app_iff, DeM1 in *.
           destruct H2, HDisjCalls; dest; auto.
           right;split;[assumption|].
           intro; apply H4; rewrite in_map_iff in H5; dest; rewrite filter_In in H6; dest.
           rewrite <- H5; rewrite in_map_iff; exists x; firstorder.
        -- apply H4.
      * assumption.
      * apply PSemAction_inline_notIn.
        -- apply HAction.
        -- apply (in_map fst) in H3; destruct (HDisjCalls (fst f));tauto.
      * eapply H0; eauto.
        -- rewrite HUNewRegs in H1; intro; specialize (H1 k0); rewrite map_app, in_app_iff, DeM1 in H1.
           destruct H1;[left|right];dest;auto.
        -- rewrite HUCalls in H2; intro; specialize (H2 k0); rewrite map_app, in_app_iff, DeM1 in H2.
           destruct H2;[left|right];dest;auto.
      * rewrite HUReadRegs; repeat rewrite app_assoc; apply Permutation_app_tail;
          rewrite Permutation_app_comm; reflexivity.
      * rewrite HUNewRegs; repeat rewrite app_assoc; apply Permutation_app_tail;
          rewrite Permutation_app_comm; reflexivity.
      * rewrite HUCalls.
        rewrite filter_app; repeat rewrite app_assoc.
        apply Permutation_app_tail.
        assert (key_not_In (fst f) calls1);
          [repeat intro;apply (in_map fst) in H4; apply (in_map fst) in  H3; simpl in *;
           specialize (HDisjCalls (fst f)); firstorder|].
        rewrite (key_not_In_filter _ H4), Permutation_app_comm; reflexivity.
  - intros; simpl; inv H3; EqDep_subst; econstructor 9; eauto.
  - intros; simpl; inv H3; EqDep_subst; econstructor 10; eauto.
  - intros; simpl; inv H3; contradiction.
Qed.

Lemma PPlusSubsteps_inline_notIn f m o upds execs calls:
  PPlusSubsteps m o upds execs calls ->
  ~In (fst f) (map fst calls) ->
  PPlusSubsteps (inlinesingle_BaseModule m f) o upds execs calls.
Proof.
  induction 1; simpl; intros.
  - econstructor 1; eauto.
  - rewrite HUpds, HExecs, HCalls.
    apply (in_map (inlinesingle_Rule f)) in HInRules.
    econstructor 2 with (u := u) (reads := reads); eauto.
    + eapply PSemAction_inline_notIn; eauto.
      intro; apply H0; rewrite HCalls, map_app, in_app_iff; left; assumption.
    + eapply IHPPlusSubsteps.
      intro; apply H0; rewrite HCalls, map_app, in_app_iff; right; assumption.
  - rewrite HUpds, HExecs, HCalls.
    apply (in_map (inlinesingle_Meth f)) in HInMeths; destruct fb.
    econstructor 3 with (u := u) (reads := reads); simpl; eauto.
    + simpl; eapply PSemAction_inline_notIn; eauto.
      intro; apply H0; rewrite HCalls, map_app, in_app_iff; left; assumption.
    + eapply IHPPlusSubsteps.
      intro; apply H0; rewrite HCalls, map_app, in_app_iff; right; assumption.
Qed.

Lemma KeyMatching2 (l : list DefMethT) (a b : DefMethT):
  NoDup (map fst l) -> In a l -> In b l -> fst a = fst b -> a = b.
Proof.
  induction l; intros.
  - inv H0.
  - destruct H0, H1; subst; auto; simpl in *.
    + inv H.
      apply False_ind, H4.
      rewrite H2, in_map_iff.
      exists b; firstorder.
    + inv H.
      apply False_ind, H4.
      rewrite <- H2, in_map_iff.
      exists a; firstorder.
    + inv H.
      eapply IHl; eauto.
Qed.

Lemma Substeps_permutation_invariant m o l l' :
  l [=] l' ->
  Substeps m o l ->
  Substeps m o l'.
Proof.
  induction 1; intros; auto.
  - inv H0.
    + inv HLabel.
      econstructor 2; eauto; setoid_rewrite <- H; auto.
    + inv HLabel.
      econstructor 3; eauto; setoid_rewrite <- H; auto.
  - inv H.
    + inv HLabel.
      inv HSubstep; inv HLabel.
      * specialize (HNoRle _ (in_eq _ _)); simpl in *; contradiction.
      * econstructor 3; eauto; intros.
        -- destruct H; subst.
           ++ simpl.
              specialize (HDisjRegs _ (in_eq _ _)); simpl in *.
              apply DisjKey_Commutative; assumption.
           ++ eapply HDisjRegs0; auto.
        -- rewrite Permutation_cons_append, InCall_app_iff in H0.
           destruct H0.
           ++ apply (HNoCall0 _ H _ H0).
           ++ unfold InCall in H0; dest.
              destruct H0;[subst|contradiction].
              destruct f; simpl in *.
              apply (HNoCall _ H1 s0).
              unfold InCall;
                exists (u0, (Meth (fn, existT SignT (projT1 fb) (argV, retV)), cs0));simpl; auto.
        -- unfold InExec in *; simpl in *.
           destruct H;[discriminate|auto].
        -- econstructor 2; eauto; intros.
           ++ eapply HDisjRegs; right; assumption.
           ++ eapply HNoRle; right; assumption.
           ++ apply (HNoCall _ H v2).
              rewrite Permutation_cons_append, InCall_app_iff;left; assumption.
    + inv HLabel.
      inv HSubsteps; inv HLabel.
      * econstructor 2; eauto; intros.
        -- destruct H; subst.
           ++ simpl.
              specialize (HDisjRegs _ (in_eq _ _)); simpl in *.
              apply DisjKey_Commutative; assumption.
           ++ eapply HDisjRegs0; auto.
        -- destruct H; subst; simpl in *; auto.
           eapply HNoRle; eauto.
        -- destruct H0; dest; destruct H0; subst; simpl in *.
           ++ destruct f; apply (HNoCall _ H1 s0); simpl.
              exists (u0, (Rle rn, cs0)); simpl; auto.
           ++ apply (HNoCall0 _ H v2).
              exists x; auto.
        -- econstructor 3; eauto; intros.
           ++ eapply HDisjRegs; right; assumption.
           ++ apply (HNoCall _ H v2).
              rewrite Permutation_cons_append, InCall_app_iff; auto.
           ++ unfold InExec in *; simpl in *.
              eapply HNoExec; right; assumption.
      * econstructor 3; eauto; intros.
        -- destruct H; subst; simpl.
           ++ specialize (HDisjRegs _ (in_eq _ _)); simpl in *.
              apply DisjKey_Commutative; assumption.
           ++ eapply HDisjRegs0; eauto.
        -- destruct H0; dest; destruct H0; subst; simpl in *.
           ++ destruct f; apply (HNoCall _ H1 s0).
              exists (u0, (Meth (fn0, existT SignT (projT1 fb0) (argV0, retV0)), cs0));
                simpl; auto.
           ++ apply (HNoCall0 _ H v2).
              exists x; auto.
        -- unfold InExec in *; simpl in *.
           destruct H.
           ++ inv H; EqDep_subst.
              destruct fb, fb0; simpl in *; subst; EqDep_subst.
              apply HNoExec; left; reflexivity.
           ++ apply HNoExec0; auto.
        -- econstructor 3; auto; auto;[apply HAction | | | | ]; auto; intros.
           ++ eapply HDisjRegs; right; assumption.
           ++ apply (HNoCall _ H v2).
              rewrite Permutation_cons_append, InCall_app_iff; auto.
           ++ unfold InExec in *; simpl in *.
              apply HNoExec; right; assumption.
Qed.

Lemma InCall_getLabelCalls f l:
  InCall f l ->
  In f (getLabelCalls l).
Proof.
  induction l; unfold InCall,getLabelCalls in *; intros; simpl; dest; auto.
  destruct H; subst;apply in_app_iff; [left; assumption|right; apply IHl].
  exists x; auto.
Qed.

Lemma getLabelCalls_InCall f l:
  In f (getLabelCalls l) ->
  InCall f l.
Proof.
  induction l; unfold InCall, getLabelCalls in *; intros; simpl in *;[contradiction|].
  rewrite in_app_iff in H; destruct H;[exists a; auto|specialize (IHl H);dest].
  exists x; auto.
Qed.

Corollary InCall_getLabelCalls_iff f l:
  InCall f l <->
  In f (getLabelCalls l).
Proof.
  split; intro; eauto using InCall_getLabelCalls, getLabelCalls_InCall.
Qed.

Lemma extract_exec (f : DefMethT) m o l u cs fb:
  NoDup (map fst (getMethods m)) ->
  In f (getMethods m) ->
  Substeps m o ((u, (Meth ((fst f), fb), cs))::l) ->
  exists reads e mret,
    fb =  existT SignT (projT1 (snd f)) (e, mret) /\
    DisjKey u (getLabelUpds l) /\
    DisjKey cs (getLabelCalls l) /\
    SemAction o ((projT2 (snd f) type) e) reads u cs mret /\
    (~In (fst f) (map fst cs)) /\
    (SubList (getKindAttr reads) (getKindAttr (getRegisters m))) /\
    (SubList (getKindAttr u) (getKindAttr (getRegisters m))) /\
    Substeps m o l.
Proof.
  intros.
  inv H1.
  - inv HLabel.
  - inv HLabel.
    destruct f, s0, fb0; simpl in *; subst;EqDep_subst.
    specialize (KeyMatching2 _ _ _ H HInMeths H0 (eq_refl)) as TMP.
    inv TMP; EqDep_subst.
    exists reads, argV, retV; repeat split; auto.
    + apply DisjKey_Commutative.
      clear - HDisjRegs.
      induction ls.
      * intro; left; auto.
      * unfold getLabelUpds in *; simpl.
        intro; rewrite map_app, in_app_iff, DeM1.
        specialize (HDisjRegs a (in_eq _ _) k) as TMP; simpl in *.
        assert (forall x, In x ls -> DisjKey (fst x) u0);[intros; eapply HDisjRegs; eauto|].
        specialize (IHls H k) as TMP2; destruct TMP, TMP2; firstorder fail.
    + intro x0; destruct (in_dec string_dec x0 (map fst cs0)),
                (in_dec string_dec x0 (map fst (getLabelCalls ls))); auto.
      apply False_ind.
      destruct (fst_produce_snd _ _ i), (fst_produce_snd _ _ i0).
      rewrite <-InCall_getLabelCalls_iff in H2.
      apply (HNoCall _ H1 _ H2).
Qed.

Lemma List_FullLabel_perm_getLabelUpds_perm l1 l2:
  List_FullLabel_perm l1 l2 ->
  getLabelUpds l1 [=] getLabelUpds l2.
Proof.
  induction 1.
  - reflexivity.
  - unfold getLabelUpds in *; inv H; simpl in *.
    rewrite H1, IHList_FullLabel_perm; reflexivity.
  - unfold getLabelUpds in *; inv H; inv H0; simpl in *.
    rewrite H2, H, IHList_FullLabel_perm; repeat rewrite app_assoc.
    apply Permutation_app_tail.
    apply Permutation_app_comm.
  - rewrite IHList_FullLabel_perm1, IHList_FullLabel_perm2; reflexivity.
Qed.

Lemma List_FullLabel_perm_getLabelCalls_perm l1 l2:
  List_FullLabel_perm l1 l2 ->
  getLabelCalls l1 [=] getLabelCalls l2.
Proof.
  induction 1.
  - reflexivity.
  - unfold getLabelCalls in *; inv H; simpl in *.
    rewrite H3, IHList_FullLabel_perm; reflexivity.
  - unfold getLabelCalls in *; inv H; inv H0; simpl in *.
    rewrite H4, H5, IHList_FullLabel_perm; repeat rewrite app_assoc.
    apply Permutation_app_tail.
    apply Permutation_app_comm.
  - rewrite IHList_FullLabel_perm1, IHList_FullLabel_perm2; reflexivity.
Qed.

Lemma List_FullLabel_perm_getLabelExecs_perm l1 l2:
  List_FullLabel_perm l1 l2 ->
  getLabelExecs l1 [=] getLabelExecs l2.
Proof.
  induction 1.
  - reflexivity.
  - unfold getLabelExecs in *; inv H; simpl in *.
    rewrite IHList_FullLabel_perm; reflexivity.
  - unfold getLabelExecs in *; inv H; inv H0; simpl in *.
    rewrite IHList_FullLabel_perm.
    apply perm_swap.
  - rewrite IHList_FullLabel_perm1, IHList_FullLabel_perm2; reflexivity.
Qed.

Lemma extract_exec_P (f : DefMethT) m o l u cs fb:
  NoDup (map fst (getMethods m)) ->
  In f (getMethods m) ->
  PSubsteps m o ((u, (Meth ((fst f),fb), cs))::l) ->
  exists reads e mret,
    fb = existT SignT (projT1 (snd f)) (e, mret) /\
    DisjKey u (getLabelUpds l) /\
    DisjKey cs (getLabelCalls l) /\
    PSemAction o ((projT2 (snd f) type) e) reads u cs mret /\
    (~In (fst f) (map fst cs)) /\
    (SubList (getKindAttr reads) (getKindAttr (getRegisters m))) /\
    (SubList (getKindAttr u) (getKindAttr (getRegisters m))) /\
    PSubsteps m o l.
Proof.
  intros.
  apply (PSubsteps_Substeps) in H1; dest.
  specialize (List_FullLabel_perm_in H2 _ (in_eq _ _)) as TMP; dest.
  specialize (in_split _ _ H6) as TMP; dest.
  rewrite H7, <- Permutation_middle in H2.
  specialize (List_FullLabel_perm_cons_inv H5 H2) as P2.
  inv H5.
  apply (Substeps_permutation_invariant (Permutation_sym (Permutation_middle _ _ _))) in H4.
  apply (extract_exec f) in H4; auto; dest.
  exists x0, x1, x4; repeat split; auto.
  + rewrite H11.
    rewrite (List_FullLabel_perm_getLabelUpds_perm P2).
    assumption.
  + setoid_rewrite H14.
    setoid_rewrite (List_FullLabel_perm_getLabelCalls_perm P2).
    assumption.
  + symmetry in H1, H11, H14.
    apply (PSemAction_rewrite_state H1).
    apply (PSemAction_rewrite_newRegs H11).
    apply (PSemAction_rewrite_calls H14).
    apply SemAction_PSemAction; assumption.
  + rewrite H14; assumption.
  + rewrite H11; assumption.
  + rewrite P2, H1.
    apply Substeps_PSubsteps; assumption.
Qed.

Corollary extract_exec_PPlus (f : DefMethT) m o upds execs calls fb:
  NoDup (map fst (getMethods m)) ->
  In f (getMethods m) ->
  PPlusSubsteps m o upds ((Meth ((fst f),fb))::execs) calls ->
  exists reads upds1 upds2 calls1 calls2 e mret,
    fb = existT SignT (projT1 (snd f)) (e, mret) /\
    PSemAction o ((projT2 (snd f) type) e) reads upds1 calls1 mret /\
    upds [=] upds1++upds2 /\
    calls [=] calls1++calls2 /\
    DisjKey upds1 upds2 /\
    DisjKey calls1 calls2 /\
    (~In (fst f) (map fst calls1)) /\
    (SubList (getKindAttr reads) (getKindAttr (getRegisters m))) /\
    (SubList (getKindAttr upds1) (getKindAttr (getRegisters m))) /\
    PPlusSubsteps m o upds2 execs calls2.
Proof.
  intros.
  apply (PPlusSubsteps_PSubsteps) in H1; dest.
  unfold getLabelExecs, getLabelUpds, getLabelCalls in *.
  specialize (Permutation_in _ H3 (in_eq _ _)) as H3'.
  rewrite (in_map_iff) in H3'; dest; destruct x0, p.
  apply in_split in H6; dest; rewrite H6,map_app in H4, H3, H2;rewrite concat_app in *; simpl in *.
  rewrite H5 in *;rewrite H6, <-Permutation_middle in H1.
  rewrite <- Permutation_middle, <- map_app in H3.
  apply Permutation_cons_inv in H3.
  apply extract_exec_P in H1; eauto; dest.
  exists x2, r, (getLabelUpds (x0++x1)), m0, (getLabelCalls (x0++x1)), x3, x4; repeat split; auto;
    [rewrite H2; unfold getLabelUpds| rewrite H4; unfold getLabelCalls | rewrite H3; apply PSubsteps_PPlusSubsteps; assumption];
    rewrite map_app, concat_app; repeat rewrite app_assoc; apply Permutation_app_tail; rewrite Permutation_app_comm; reflexivity.
Qed.

Lemma filter_preserves_NoDup A (f : A -> bool) l :
  NoDup l ->
  NoDup (filter f l).
Proof.
  induction 1.
  - simpl; constructor.
  - unfold filter; destruct (f x); fold (filter f l); auto.
    + econstructor; eauto.
      intro; apply H.
      rewrite filter_In in H1; dest; assumption.
Qed.

Lemma SubList_app_l_iff:
  forall (A : Type) (l1 l2 ls : list A), SubList (l1 ++ l2) ls <-> SubList l1 ls /\ SubList l2 ls.
Proof.
  split; intro;[apply SubList_app_l; assumption|dest; repeat intro; auto; rewrite in_app_iff in *; firstorder fail].
Qed.

Lemma PPlusSubsteps_inline_MatchingIn f m o upds execs calls fb:
  NoDup (map fst (getMethods m)) ->
  In f (getMethods m) ->
  PPlusSubsteps m o upds ((Meth ((fst f), fb))::execs) (((fst f), fb)::calls) ->
  PPlusSubsteps (inlinesingle_BaseModule m f) o upds execs calls.
Proof.
  intros; apply extract_exec_PPlus in H1; auto; dest; subst; simpl in *.
  inv H10; subst; simpl in *.
  - rewrite app_nil_r in H4.
    specialize (in_map fst _ _ (Permutation_in _ H4 (in_eq _ _))) as contrad; contradiction.
  - rewrite HExecs.
    specialize (Permutation_in _ H4 (in_eq _ _)) as TMP.
    rewrite in_app_iff in TMP; simpl in *; destruct TMP as [H1 | H1] ;[apply (in_map fst) in H1; contradiction|].
    rewrite HCalls, in_app_iff in H1; destruct H1.
    + destruct (in_dec MethT_dec (fst f, existT _ (projT1 (snd f)) (x4, x5)) oldCalls);
        [specialize (HNoCall _ H1 _ i); contradiction|].
      assert (~In (fst f) (map fst oldCalls));[intro; rewrite in_map_iff in H10; dest; destruct x6;
                                               simpl in *; subst; specialize (HNoCall _ H1 _ H11); contradiction|].
      specialize (PPlusSubsteps_inline_notIn _ HPSubstep H10) as HNotIn_Substep.
      specialize (in_map (inlinesingle_Rule f) _ _ HInRules) as HInRules_inline; simpl in *.
      assert (DisjKey x0 u) as P1;
        [intro k; specialize (H5 k); rewrite HUpds,map_app,in_app_iff,DeM1 in H5; clear - H5; firstorder fail|].
      assert (DisjKey x2 cs) as P2;
        [intro k; specialize (H6 k); rewrite HCalls,map_app,in_app_iff,DeM1 in H6; clear - H6; firstorder fail|].
      specialize (PSemAction_inline_In _ _ H2 P1 P2 H1 HPAction) as HIn_PSemAction.
      admit.
    + admit.
  - admit.
Admitted.
      (* econstructor 2; simpl; auto. *)
      (* * apply HInRules_inline. *)
      (* * simpl; apply HIn_PSemAction. *)
      (* * rewrite map_app, SubList_app_l_iff; auto. *)
      (* * rewrite map_app, SubList_app_l_iff; auto. *)
      (* * rewrite H3, HUpds, app_assoc; reflexivity. *)
      (* *  *)
    
Lemma PPlusSubsteps_inline f m o upds execs calls:
  PPlusSubsteps m o upds execs calls ->
  PPlusSubsteps (inlinesingle_BaseModule m f) o upds
                (filter (remove_execs (filter (keep_calls f) calls)) execs)
                (filter (remove_calls f) calls).
Proof.
  induction 1; simpl in *.
  - econstructor 1; eauto.
  - econstructor 2; auto.
    + apply (in_map (inlinesingle_Rule f)) in HInRules; simpl in *.
      apply HInRules.
    + admit.
    + admit.
    + admit.
    + admit.
    + admit.
    + admit.
    + admit.
    + admit.
    + admit.
    + admit.
  - admit.
Admitted.