(*
 * SPDX-License-Identifier: MIT
 * 
 *)
From Coq Require Import
     List.

From SPICY Require Import
     MyPrelude
     Maps
     ChMaps
     Messages
     Keys
     Automation
     Tactics
     Simulation
     SyntacticallySafe
     AdversaryUniverse

     ModelCheck.Commutation
     ModelCheck.InvariantSearch
     ModelCheck.ProtocolFunctions
     ModelCheck.ModelCheck
     ModelCheck.SilentStepElimination
     ModelCheck.SteppingTactics
     ModelCheck.UniverseInversionLemmas
.

From protocols Require Import
     NetAuth.

From SPICY Require IdealWorld RealWorld.

Import IdealWorld.IdealNotations
       RealWorld.RealWorldNotations
       SimulationAutomation.

From Frap Require Import Sets.

Module Foo <: Sets.EMPTY.
End Foo.
Module Import SN := Sets.SetNotations(Foo).

Set Implicit Arguments.

Open Scope protocol_scope.

Module NetAuthProtocolSecure <: AutomatedSafeProtocolSS.

  Import NetAuthProtocol.

  (* Some things may need to change here.  t__hon is where we place the 
   * type that the protocol computes.  It is set to Nat now, because we
   * return a natual number.
   *)
  Definition t__hon := Nat.
  Definition t__adv := Unit.
  Definition b    := tt.

  (* These two variables hook up the starting points for both specification and
   * implementation universes.  If you followed the template above, this shouldn't
   * need to be changed.
   *)
  Definition iu0  := ideal_univ_start.
  Definition ru0  := real_univ_start.

  Import Gen Tacs.

  (* These are here to help the proof automation.  Don't change. *)
  #[export] Hint Unfold t__hon t__adv b ru0 iu0 ideal_univ_start real_univ_start : core.
  #[export] Hint Unfold
       mkiU mkiUsr mkrU mkrUsr
       mkKeys
    : core.

  Lemma finitelyRuns : exists n, runningTimeMeasure ru0 n.
  Proof.
    autounfold; simpl.
    eexists.
    econstructor; simpl; find_runtime.

    Unshelve.
    all: exact 0.
  Qed.

  Require Import Coq.Program.Equality.

  Lemma typechecks : syntactically_safe_U ru0.
  Proof.
    unfold syntactically_safe_U; intros.
    autounfold
    ; subst
    ; simpl in *.

    unfold compute_ids; simpl.

    focus_user; simpl
    ; try solve [ do 2 eexists; split
                  ; [ unshelve (repeat typechecks1)
                      ; match goal with
                        | [ |- bool ] => exact true
                        | [ |- list safe_typ ] => exact []
                        end
                    | repeat verify_context_soundness ] ].


    Unshelve.
    all : exact TyDontCare.
  Qed.
    
  Lemma summarizable : exists summaries, summarize_univ ru0 summaries.
  Proof.
    autounfold; unfold summarize_univ; simpl; intros.
    unshelve (
        eexists; intros; focus_user; simpl
        ; (exists useless_summary; split; [ build_summary |]; eauto using useless_summary_summarizes)
      ) ; exact $0.
  Qed.
    
  Lemma lameness : @lameAdv t__adv b (RealWorld.adversary ru0).
  Proof.
    unfold lameAdv; autounfold; simpl; eauto.
  Qed.

  Set Ltac Profiling.

  Lemma safe_invariant :
    invariantFor
      {| Initial := {(ru0, iu0, true)}; Step := @stepSS t__hon t__adv  |}
      (@noresends_inv t__hon t__adv).
  Proof.
    unfold invariantFor
    ; unfold Initial, Step
    ; intros
    ; simpl in *
    ; split_ors
    ; try contradiction
    ; subst.

    autounfold in H0
    ; unfold fold_left, fst, snd in *.
    
    time (
        repeat transition_system_step
      ).

    Unshelve.
    all: exact 0  || auto.
  Qed.

  Show Ltac Profile.

  Lemma U_good : @universe_starts_sane _ Unit b ru0.
  Proof.
    autounfold;
      unfold universe_starts_sane; simpl.
    repeat (apply conj); intros; eauto.
    - focus_user; auto.
    - econstructor.
    - unfold AdversarySafety.keys_honest; rewrite Forall_natmap_forall; intros.
      unfold mkrUsr; simpl.
      rewrite !findUserKeys_add_reduce, findUserKeys_empty_is_empty; eauto.
    - unfold lameAdv; simpl; eauto.
  Qed.

  Lemma universe_starts_safe : universe_ok ru0.
  Proof.
    pose proof (adversary_is_lame_adv_univ_ok_clauses U_good).
    
    unfold universe_ok
    ; autounfold
    ; simpl
    ; intuition eauto
    .

    - econstructor; eauto.
    - unfold keys_and_permissions_good; solve_simple_maps; intuition eauto.
      solve_simple_maps; eauto.

      rewrite Forall_natmap_forall; intros.

      solve_simple_maps; simpl
      ; unfold permission_heap_good; intros;
        solve_simple_maps; solve_concrete_maps; eauto.

    - unfold user_cipher_queues_ok.
      rewrite Forall_natmap_forall; intros.
      focus_user
      ; simpl in *; econstructor; eauto.

    - unfold honest_nonces_ok, honest_user_nonces_ok, honest_nonces_ok
      ; repeat simple apply conj
      ; intros
      ; clean_map_lookups
      ; intros
      ; focus_user
      ; try contradiction; try discriminate; simpl;
        repeat (apply conj); intros; clean_map_lookups; eauto.

    - unfold honest_users_only_honest_keys; intros.
      focus_user;
        subst;
        simpl in *;
        clean_map_lookups;
        unfold mkrUsr; simpl; 
          rewrite !findUserKeys_add_reduce, findUserKeys_empty_is_empty;
          eauto;
          simpl in *;
          solve_concrete_perm_merges;
          solve_concrete_maps;
          solve_simple_maps;
          eauto.
  Qed.

End NetAuthProtocolSecure.
