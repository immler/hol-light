(* ========================================================================= *)
(* Basic notions of cardinal arithmetic.                                     *)
(* ========================================================================= *)

needs "Library/wo.ml";;

let TRANS_CHAIN_TAC th =
  MAP_EVERY (fun t -> TRANS_TAC th t THEN ASM_REWRITE_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* We need these a few times, so give them names.                            *)
(* ------------------------------------------------------------------------- *)

let sum_DISTINCT = distinctness "sum";;

let sum_INJECTIVE = injectivity "sum";;

let sum_CASES = prove_cases_thm sum_INDUCT;;

let FORALL_SUM_THM = prove
 (`(!z. P z) <=> (!x. P(INL x)) /\ (!x. P(INR x))`,
  MESON_TAC[sum_CASES]);;

let EXISTS_SUM_THM = prove
 (`(?z. P z) <=> (?x. P(INL x)) \/ (?x. P(INR x))`,
  MESON_TAC[sum_CASES]);;

(* ------------------------------------------------------------------------- *)
(* Special case of Zorn's Lemma for restriction of subset lattice.           *)
(* ------------------------------------------------------------------------- *)

let POSET_RESTRICTED_SUBSET = prove
 (`!P. poset(\(x,y). P(x) /\ P(y) /\ x SUBSET y)`,
  GEN_TAC THEN REWRITE_TAC[poset; fl] THEN
  CONV_TAC(ONCE_DEPTH_CONV GEN_BETA_CONV) THEN
  REWRITE_TAC[SUBSET; EXTENSION] THEN MESON_TAC[]);;

let FL_RESTRICTED_SUBSET = prove
 (`!P. fl(\(x,y). P(x) /\ P(y) /\ x SUBSET y) = P`,
  REWRITE_TAC[fl; FORALL_PAIR_THM; FUN_EQ_THM] THEN
  CONV_TAC(ONCE_DEPTH_CONV GEN_BETA_CONV) THEN MESON_TAC[SUBSET_REFL]);;

let ZL_SUBSETS = prove
 (`!P. (!c. (!x. x IN c ==> P x) /\
            (!x y. x IN c /\ y IN c ==> x SUBSET y \/ y SUBSET x)
            ==> ?z. P z /\ (!x. x IN c ==> x SUBSET z))
       ==> ?a:A->bool. P a /\ (!x. P x /\ a SUBSET x ==> (a = x))`,
  GEN_TAC THEN
  MP_TAC(ISPEC `\(x,y). P(x:A->bool) /\ P(y) /\ x SUBSET y` ZL) THEN
  REWRITE_TAC[POSET_RESTRICTED_SUBSET; FL_RESTRICTED_SUBSET] THEN
  REWRITE_TAC[chain] THEN
  CONV_TAC(ONCE_DEPTH_CONV GEN_BETA_CONV) THEN
  REWRITE_TAC[IN] THEN MATCH_MP_TAC MONO_IMP THEN CONJ_TAC THENL
   [MATCH_MP_TAC MONO_FORALL; ALL_TAC] THEN
  MESON_TAC[]);;

let ZL_SUBSETS_UNIONS = prove
 (`!P. (!c. (!x. x IN c ==> P x) /\
            (!x y. x IN c /\ y IN c ==> x SUBSET y \/ y SUBSET x)
            ==> P(UNIONS c))
       ==> ?a:A->bool. P a /\ (!x. P x /\ a SUBSET x ==> (a = x))`,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC ZL_SUBSETS THEN
  REPEAT STRIP_TAC THEN EXISTS_TAC `UNIONS(c:(A->bool)->bool)` THEN
  ASM_MESON_TAC[SUBSET; IN_UNIONS]);;

let ZL_SUBSETS_UNIONS_NONEMPTY = prove
 (`!P. (?x. P x) /\
       (!c. (?x. x IN c) /\
            (!x. x IN c ==> P x) /\
            (!x y. x IN c /\ y IN c ==> x SUBSET y \/ y SUBSET x)
            ==> P(UNIONS c))
       ==> ?a:A->bool. P a /\ (!x. P x /\ a SUBSET x ==> (a = x))`,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC ZL_SUBSETS THEN
  REPEAT STRIP_TAC THEN ASM_CASES_TAC `?x:A->bool. x IN c` THENL
   [EXISTS_TAC `UNIONS(c:(A->bool)->bool)` THEN
    ASM_SIMP_TAC[] THEN MESON_TAC[SUBSET; IN_UNIONS];
    ASM_MESON_TAC[]]);;

(* ------------------------------------------------------------------------- *)
(* Useful lemma to reduce some higher order stuff to first order.            *)
(* ------------------------------------------------------------------------- *)

let FLATTEN_LEMMA = prove
 (`(!x. x IN s ==> (g(f(x)) = x)) <=> !y x. x IN s /\ (y = f x) ==> (g y = x)`,
  MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Knaster-Tarski fixpoint theorem (used in Schroeder-Bernstein below).      *)
(* ------------------------------------------------------------------------- *)

let TARSKI_SET = prove
 (`!f. (!s t. s SUBSET t ==> f(s) SUBSET f(t)) ==> ?s:A->bool. f(s) = s`,
  REPEAT STRIP_TAC THEN MAP_EVERY ABBREV_TAC
   [`Y = {b:A->bool | f(b) SUBSET b}`; `a:A->bool = INTERS Y`] THEN
  SUBGOAL_THEN `!b:A->bool. b IN Y <=> f(b) SUBSET b` ASSUME_TAC THENL
   [EXPAND_TAC "Y" THEN REWRITE_TAC[IN_ELIM_THM]; ALL_TAC] THEN
  SUBGOAL_THEN `!b:A->bool. b IN Y ==> f(a:A->bool) SUBSET b` ASSUME_TAC THENL
   [ASM_MESON_TAC[SUBSET_TRANS; IN_INTERS; SUBSET]; ALL_TAC] THEN
  SUBGOAL_THEN `f(a:A->bool) SUBSET a`
   (fun th -> ASM_MESON_TAC[SUBSET_ANTISYM; IN_INTERS; th]) THEN
  ASM_MESON_TAC[IN_INTERS; SUBSET]);;

(* ------------------------------------------------------------------------- *)
(* We need a nonemptiness hypothesis for the nicest total function form.     *)
(* ------------------------------------------------------------------------- *)

let INJECTIVE_LEFT_INVERSE_NONEMPTY = prove
 (`(?x. x IN s)
   ==> ((!x y. x IN s /\ y IN s /\ (f(x) = f(y)) ==> (x = y)) <=>
        ?g. (!y. y IN t ==> g(y) IN s) /\
            (!x. x IN s ==> (g(f(x)) = x)))`,
  REWRITE_TAC[FLATTEN_LEMMA; GSYM SKOLEM_THM; AND_FORALL_THM] THEN
  MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Now bijectivity.                                                          *)
(* ------------------------------------------------------------------------- *)

let BIJECTIVE_INJECTIVE_SURJECTIVE = prove
 (`(!x. x IN s ==> f(x) IN t) /\
   (!y. y IN t ==> ?!x. x IN s /\ (f x = y)) <=>
   (!x. x IN s ==> f(x) IN t) /\
   (!x y. x IN s /\ y IN s /\ (f(x) = f(y)) ==> (x = y)) /\
   (!y. y IN t ==> ?x. x IN s /\ (f x = y))`,
  MESON_TAC[]);;

let BIJECTIVE_INVERSES = prove
 (`(!x. x IN s ==> f(x) IN t) /\
   (!y. y IN t ==> ?!x. x IN s /\ (f x = y)) <=>
   (!x. x IN s ==> f(x) IN t) /\
   ?g. (!y. y IN t ==> g(y) IN s) /\
       (!y. y IN t ==> (f(g(y)) = y)) /\
       (!x. x IN s ==> (g(f(x)) = x))`,
  REWRITE_TAC[BIJECTIVE_INJECTIVE_SURJECTIVE;
              INJECTIVE_ON_LEFT_INVERSE;
              SURJECTIVE_ON_RIGHT_INVERSE] THEN
  MATCH_MP_TAC(TAUT `(a ==> (b <=> c)) ==> (a /\ b <=> a /\ c)`) THEN
  DISCH_TAC THEN REWRITE_TAC[RIGHT_AND_EXISTS_THM] THEN
  AP_TERM_TAC THEN ABS_TAC THEN EQ_TAC THEN ASM_MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Other variants of cardinal equality.                                      *)
(* ------------------------------------------------------------------------- *)

let EQ_C_BIJECTIONS = prove
 (`!s:A->bool t:B->bool.
        s =_c t <=> ?f g. (!x. x IN s ==> f x IN t /\ g(f x) = x) /\
                          (!y. y IN t ==> g y IN s /\ f(g y) = y)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[eq_c] THEN
  AP_TERM_TAC THEN GEN_REWRITE_TAC I [FUN_EQ_THM] THEN
  X_GEN_TAC `f:A->B` THEN REWRITE_TAC[] THEN
  EQ_TAC THENL [STRIP_TAC; MESON_TAC[]] THEN
  EXISTS_TAC `(\y. @x. x IN s /\ f x = y):B->A` THEN
  ASM_MESON_TAC[]);;

let EQ_C = prove
 (`s =_c t <=>
   ?R:A#B->bool. (!x y. R(x,y) ==> x IN s /\ y IN t) /\
                 (!x. x IN s ==> ?!y. y IN t /\ R(x,y)) /\
                 (!y. y IN t ==> ?!x. x IN s /\ R(x,y))`,
  REWRITE_TAC[eq_c] THEN EQ_TAC THENL
   [DISCH_THEN(X_CHOOSE_THEN `f:A->B` STRIP_ASSUME_TAC) THEN
    EXISTS_TAC `\(x:A,y:B). x IN s /\ y IN t /\ (y = f x)` THEN
    CONV_TAC(ONCE_DEPTH_CONV GEN_BETA_CONV) THEN ASM_MESON_TAC[];
    DISCH_THEN(CHOOSE_THEN (CONJUNCTS_THEN2 ASSUME_TAC MP_TAC)) THEN
    DISCH_THEN(CONJUNCTS_THEN2 MP_TAC ASSUME_TAC) THEN
    GEN_REWRITE_TAC (LAND_CONV o TOP_DEPTH_CONV)
     [EXISTS_UNIQUE_ALT; RIGHT_IMP_EXISTS_THM; SKOLEM_THM] THEN
    MATCH_MP_TAC MONO_EXISTS THEN ASM_MESON_TAC[]]);;

(* ------------------------------------------------------------------------- *)
(* The "easy" ordering properties.                                           *)
(* ------------------------------------------------------------------------- *)

let CARD_LE_REFL = prove
 (`!s:A->bool. s <=_c s`,
  GEN_TAC THEN REWRITE_TAC[le_c] THEN EXISTS_TAC `\x:A. x` THEN SIMP_TAC[]);;

let CARD_EMPTY_LE = prove
 (`!s:B->bool. ({}:A->bool) <=_c s`,
  REWRITE_TAC[LE_C; NOT_IN_EMPTY]);;

let CARD_LE_TRANS = prove
 (`!s:A->bool t:B->bool u:C->bool.
       s <=_c t /\ t <=_c u ==> s <=_c u`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c] THEN
  DISCH_THEN(CONJUNCTS_THEN2
   (X_CHOOSE_TAC `f:A->B`) (X_CHOOSE_TAC `g:B->C`)) THEN
  EXISTS_TAC `(g:B->C) o (f:A->B)` THEN REWRITE_TAC[o_THM] THEN
  ASM_MESON_TAC[]);;

let CARD_LT_REFL = prove
 (`!s:A->bool. ~(s <_c s)`,
  MESON_TAC[lt_c; CARD_LE_REFL]);;

let CARD_LET_TRANS = prove
 (`!s:A->bool t:B->bool u:C->bool.
       s <=_c t /\ t <_c u ==> s <_c u`,
  REPEAT GEN_TAC THEN REWRITE_TAC[lt_c] THEN
  MATCH_MP_TAC(TAUT `(a /\ b ==> c) /\ (c' /\ a ==> b')
                     ==> a /\ b /\ ~b' ==> c /\ ~c'`) THEN
  REWRITE_TAC[CARD_LE_TRANS]);;

let CARD_LTE_TRANS = prove
 (`!s:A->bool t:B->bool u:C->bool.
       s <_c t /\ t <=_c u ==> s <_c u`,
  REPEAT GEN_TAC THEN REWRITE_TAC[lt_c] THEN
  MATCH_MP_TAC(TAUT `(a /\ b ==> c) /\ (b /\ c' ==> a')
                     ==> (a /\ ~a') /\ b ==> c /\ ~c'`) THEN
  REWRITE_TAC[CARD_LE_TRANS]);;

let CARD_LT_TRANS = prove
 (`!s:A->bool t:B->bool u:C->bool.
       s <_c t /\ t <_c u ==> s <_c u`,
  MESON_TAC[lt_c; CARD_LTE_TRANS]);;

let CARD_EQ_REFL = prove
 (`!s:A->bool. s =_c s`,
  GEN_TAC THEN REWRITE_TAC[eq_c] THEN EXISTS_TAC `\x:A. x` THEN
  SIMP_TAC[] THEN MESON_TAC[]);;

let CARD_EQ_REFL_IMP = prove
 (`!s t:A->bool. s = t ==> s =_c t`,
  SIMP_TAC[CARD_EQ_REFL]);;

let CARD_EQ_SYM = prove
 (`!s t. s =_c t <=> t =_c s`,
  REPEAT GEN_TAC THEN REWRITE_TAC[eq_c; BIJECTIVE_INVERSES] THEN
  REWRITE_TAC[RIGHT_AND_EXISTS_THM] THEN
  GEN_REWRITE_TAC RAND_CONV [SWAP_EXISTS_THM] THEN
  REPEAT(AP_TERM_TAC THEN ABS_TAC) THEN REWRITE_TAC[CONJ_ACI]);;

let CARD_EQ_IMP_LE = prove
 (`!s t. s =_c t ==> s <=_c t`,
  REWRITE_TAC[le_c; eq_c] THEN MESON_TAC[]);;

let CARD_LT_IMP_LE = prove
 (`!s t. s <_c t ==> s <=_c t`,
  SIMP_TAC[lt_c]);;

let CARD_LE_RELATIONAL = prove
 (`!R:A->B->bool.
        (!x y y'. x IN s /\ R x y /\ R x y' ==> y = y')
        ==> {y | ?x. x IN s /\ R x y} <=_c s`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[le_c] THEN
  EXISTS_TAC `\y:B. @x:A. x IN s /\ R x y` THEN
  REWRITE_TAC[IN_ELIM_THM] THEN ASM_MESON_TAC[]);;

let CARD_LE_RELATIONAL_FULL = prove
 (`!R:A->B->bool s t.
        (!y. y IN t ==> ?x. x IN s /\ R x y) /\
        (!x y y'. x IN s /\ y IN t /\ y' IN t /\ R x y /\ R x y' ==> y = y')
        ==> t <=_c s`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[le_c] THEN
  EXISTS_TAC `\y:B. @x:A. x IN s /\ R x y` THEN
  REWRITE_TAC[IN_ELIM_THM] THEN ASM_MESON_TAC[]);;

let CARD_LE_EMPTY = prove
 (`!s. s <=_c {} <=> s = {}`,
  REWRITE_TAC[le_c; EXTENSION; NOT_IN_EMPTY] THEN MESON_TAC[]);;

let CARD_EQ_EMPTY = prove
 (`!s. s =_c {} <=> s = {}`,
  REWRITE_TAC[eq_c; EXTENSION; NOT_IN_EMPTY] THEN MESON_TAC[]);;

let CARD_SING_LE = prove
 (`!a:A s:B->bool. {a} <=_c s <=> ~(s = {})`,
  REPEAT GEN_TAC THEN
  ASM_CASES_TAC `s:B->bool = {}` THEN
  ASM_REWRITE_TAC[CARD_LE_EMPTY; NOT_INSERT_EMPTY] THEN
  FIRST_X_ASSUM(X_CHOOSE_TAC `b:B` o
    GEN_REWRITE_RULE I [GSYM MEMBER_NOT_EMPTY]) THEN
  REWRITE_TAC[le_c] THEN EXISTS_TAC `(\x. b):A->B` THEN
  ASM_SIMP_TAC[IN_SING]);;

(* ------------------------------------------------------------------------- *)
(* Antisymmetry (the Schroeder-Bernstein theorem).                           *)
(* ------------------------------------------------------------------------- *)

let CARD_LE_ANTISYM = prove
 (`!s:A->bool t:B->bool. s <=_c t /\ t <=_c s <=> (s =_c t)`,
  REPEAT GEN_TAC THEN EQ_TAC THENL
   [ALL_TAC;
    SIMP_TAC[CARD_EQ_IMP_LE] THEN ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN
    SIMP_TAC[CARD_EQ_IMP_LE]] THEN
  ASM_CASES_TAC `s:A->bool = {}` THEN ASM_CASES_TAC `t:B->bool = {}` THEN
  ASM_SIMP_TAC[CARD_LE_EMPTY; CARD_EQ_EMPTY] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[EXTENSION; NOT_IN_EMPTY; NOT_FORALL_THM]) THEN
  ASM_SIMP_TAC[le_c; eq_c; INJECTIVE_LEFT_INVERSE_NONEMPTY] THEN
  DISCH_THEN(CONJUNCTS_THEN2
   (X_CHOOSE_THEN `i:A->B`
     (CONJUNCTS_THEN2 ASSUME_TAC (X_CHOOSE_THEN `i':B->A` STRIP_ASSUME_TAC)))
   (X_CHOOSE_THEN `j:B->A`
     (CONJUNCTS_THEN2 ASSUME_TAC
       (X_CHOOSE_THEN `j':A->B` STRIP_ASSUME_TAC)))) THEN
  MP_TAC(ISPEC
    `\a. s DIFF (IMAGE (j:B->A) (t DIFF (IMAGE (i:A->B) a)))`
    TARSKI_SET) THEN
  REWRITE_TAC[] THEN ANTS_TAC THENL
   [REWRITE_TAC[SUBSET; IN_DIFF; IN_IMAGE] THEN MESON_TAC[];
    ALL_TAC] THEN
  DISCH_THEN(X_CHOOSE_THEN `a:A->bool` ASSUME_TAC) THEN
  REWRITE_TAC[BIJECTIVE_INVERSES] THEN REWRITE_TAC[RIGHT_AND_EXISTS_THM] THEN
  EXISTS_TAC `\x. if x IN a then (i:A->B)(x) else j'(x)` THEN
  EXISTS_TAC `\y. if y IN (IMAGE (i:A->B) a) then i'(y) else (j:B->A)(y)` THEN
  REWRITE_TAC[FUN_EQ_THM; o_THM; I_DEF] THEN
  ONCE_REWRITE_TAC[TAUT `a /\ b /\ c /\ d <=> (a /\ d) /\ (b /\ c)`] THEN
  REWRITE_TAC[AND_FORALL_THM] THEN
  REWRITE_TAC[TAUT `(a ==> b) /\ (a ==> c) <=> a ==> b /\ c`] THEN
  CONJ_TAC THENL
   [X_GEN_TAC `x:A` THEN ASM_CASES_TAC `x:A IN a`;
    X_GEN_TAC `y:B` THEN ASM_CASES_TAC `y IN IMAGE (i:A->B) a`] THEN
  ASM_REWRITE_TAC[] THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN
  RULE_ASSUM_TAC(REWRITE_RULE[EXTENSION; IN_UNIV; IN_DIFF; IN_IMAGE]) THEN
  TRY(FIRST_X_ASSUM(X_CHOOSE_THEN `x:A` STRIP_ASSUME_TAC)) THEN
  TRY(FIRST_X_ASSUM(fun th -> MP_TAC(SPEC `x:A` th) THEN
      ASM_REWRITE_TAC[] THEN ASSUME_TAC th)) THEN
  ASM_MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Totality (cardinal comparability).                                        *)
(* ------------------------------------------------------------------------- *)

let CARD_LE_TOTAL = prove
 (`!s:A->bool t:B->bool. s <=_c t \/ t <=_c s`,
  REPEAT GEN_TAC THEN
  ABBREV_TAC
   `P = \R. (!x:A y:B. R(x,y) ==> x IN s /\ y IN t) /\
            (!x y y'. R(x,y) /\ R(x,y') ==> (y = y')) /\
            (!x x' y. R(x,y) /\ R(x',y) ==> (x = x'))` THEN
  MP_TAC(ISPEC `P:((A#B)->bool)->bool` ZL_SUBSETS_UNIONS) THEN ANTS_TAC THENL
   [GEN_TAC THEN EXPAND_TAC "P" THEN
    REWRITE_TAC[UNIONS; IN_ELIM_THM] THEN
    REWRITE_TAC[SUBSET; IN] THEN MESON_TAC[];
    ALL_TAC] THEN
  FIRST_X_ASSUM(SUBST1_TAC o SYM) THEN REWRITE_TAC[] THEN
  DISCH_THEN(X_CHOOSE_THEN `R:A#B->bool` STRIP_ASSUME_TAC) THEN
  ASM_CASES_TAC `(!x:A. x IN s ==> ?y:B. y IN t /\ R(x,y)) \/
                 (!y:B. y IN t ==> ?x:A. x IN s /\ R(x,y))`
  THENL
   [FIRST_X_ASSUM(K ALL_TAC o SPEC `\(x:A,y:B). T`) THEN
    FIRST_X_ASSUM(DISJ_CASES_THEN MP_TAC) THEN
    REWRITE_TAC[RIGHT_IMP_EXISTS_THM; SKOLEM_THM; le_c] THEN ASM_MESON_TAC[];
    FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE I [DE_MORGAN_THM]) THEN
    REWRITE_TAC[NOT_FORALL_THM; NOT_IMP] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (X_CHOOSE_TAC `a:A`) (X_CHOOSE_TAC `b:B`)) THEN
    FIRST_X_ASSUM(MP_TAC o SPEC
      `\(x:A,y:B). (x = a) /\ (y = b) \/ R(x,y)`) THEN
    REWRITE_TAC[SUBSET; FORALL_PAIR_THM; IN; EXTENSION] THEN
    CONV_TAC(ONCE_DEPTH_CONV GEN_BETA_CONV) THEN
    RULE_ASSUM_TAC(REWRITE_RULE[IN]) THEN ASM_MESON_TAC[]]);;

(* ------------------------------------------------------------------------- *)
(* Other variants like "trichotomy of cardinals" now follow easily.          *)
(* ------------------------------------------------------------------------- *)

let CARD_LET_TOTAL = prove
 (`!s:A->bool t:B->bool. s <=_c t \/ t <_c s`,
  REWRITE_TAC[lt_c] THEN MESON_TAC[CARD_LE_TOTAL]);;

let CARD_LTE_TOTAL = prove
 (`!s:A->bool t:B->bool. s <_c t \/ t <=_c s`,
  REWRITE_TAC[lt_c] THEN MESON_TAC[CARD_LE_TOTAL]);;

let CARD_LT_TOTAL = prove
 (`!s:A->bool t:B->bool. s =_c t \/ s <_c t \/ t <_c s`,
  REWRITE_TAC[lt_c; GSYM CARD_LE_ANTISYM] THEN MESON_TAC[CARD_LE_TOTAL]);;

let CARD_NOT_LE = prove
 (`!s:A->bool t:B->bool. ~(s <=_c t) <=> t <_c s`,
  REWRITE_TAC[lt_c] THEN MESON_TAC[CARD_LE_TOTAL]);;

let CARD_NOT_LT = prove
 (`!s:A->bool t:B->bool. ~(s <_c t) <=> t <=_c s`,
  REWRITE_TAC[lt_c] THEN MESON_TAC[CARD_LE_TOTAL]);;

let CARD_LT_LE = prove
 (`!s t. s <_c t <=> s <=_c t /\ ~(s =_c t)`,
  REWRITE_TAC[lt_c; GSYM CARD_LE_ANTISYM] THEN CONV_TAC TAUT);;

let CARD_LE_LT = prove
 (`!s t. s <=_c t <=> s <_c t \/ s =_c t`,
  REPEAT GEN_TAC THEN REWRITE_TAC[GSYM CARD_NOT_LT] THEN
  GEN_REWRITE_TAC (LAND_CONV o RAND_CONV) [CARD_LT_LE] THEN
  REWRITE_TAC[DE_MORGAN_THM; CARD_NOT_LE; CARD_EQ_SYM]);;

let CARD_LE_CONG = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s =_c s' /\ t =_c t' ==> (s <=_c t <=> s' <=_c t')`,
  REPEAT GEN_TAC THEN REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN
  MATCH_MP_TAC(TAUT
   `!x y. (b /\ e ==> x) /\ (x /\ c ==> f) /\ (a /\ f ==> y) /\ (y /\ d ==> e)
          ==> (a /\ b) /\ (c /\ d) ==> (e <=> f)`) THEN
  MAP_EVERY EXISTS_TAC
   [`(s':B->bool) <=_c (t:C->bool)`;
    `(s:A->bool) <=_c (t':D->bool)`] THEN
  REWRITE_TAC[CARD_LE_TRANS]);;

let CARD_LT_CONG = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s =_c s' /\ t =_c t' ==> (s <_c t <=> s' <_c t')`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[GSYM CARD_NOT_LE] THEN
  AP_TERM_TAC THEN MATCH_MP_TAC CARD_LE_CONG THEN
  ASM_REWRITE_TAC[]);;

let CARD_EQ_TRANS = prove
 (`!s:A->bool t:B->bool u:C->bool.
       s =_c t /\ t =_c u ==> s =_c u`,
  REPEAT GEN_TAC THEN REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN
  REPEAT STRIP_TAC THEN ASM_MESON_TAC[CARD_LE_TRANS]);;

let CARD_EQ_CONG = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s =_c s' /\ t =_c t' ==> (s =_c t <=> s' =_c t')`,
  REPEAT STRIP_TAC THEN EQ_TAC THEN DISCH_TAC THENL
   [TRANS_CHAIN_TAC CARD_EQ_TRANS [`t:C->bool`; `s:A->bool`];
    TRANS_CHAIN_TAC CARD_EQ_TRANS [`s':B->bool`; `t':D->bool`]] THEN
  ASM_MESON_TAC[CARD_EQ_SYM]);;

(* ------------------------------------------------------------------------- *)
(* Finiteness and infiniteness in terms of cardinality of N.                 *)
(* ------------------------------------------------------------------------- *)

let INFINITE_CARD_LE = prove
 (`!s:A->bool. INFINITE s <=> (UNIV:num->bool) <=_c s`,
  REPEAT STRIP_TAC THEN EQ_TAC THENL
   [ALL_TAC;
    ONCE_REWRITE_TAC[GSYM CONTRAPOS_THM] THEN
    REWRITE_TAC[INFINITE; le_c; IN_UNIV] THEN REPEAT STRIP_TAC THEN
    FIRST_ASSUM(MP_TAC o MATCH_MP INFINITE_IMAGE_INJ) THEN
    DISCH_THEN(MP_TAC o C MATCH_MP num_INFINITE) THEN
    REWRITE_TAC[INFINITE] THEN
    MATCH_MP_TAC FINITE_SUBSET THEN EXISTS_TAC `s:A->bool` THEN
    ASM_SIMP_TAC[SUBSET; IN_IMAGE; IN_UNIV; LEFT_IMP_EXISTS_THM]] THEN
  DISCH_TAC THEN
  SUBGOAL_THEN `?f:num->A. !n. f(n) = @x. x IN (s DIFF IMAGE f {m | m < n})`
  MP_TAC THENL
   [MATCH_MP_TAC(MATCH_MP WF_REC WF_num) THEN
    REWRITE_TAC[IN_IMAGE; IN_ELIM_THM; IN_DIFF] THEN REPEAT STRIP_TAC THEN
    AP_TERM_TAC THEN ABS_TAC THEN ASM_MESON_TAC[];
    ALL_TAC] THEN
  REWRITE_TAC[le_c] THEN MATCH_MP_TAC MONO_EXISTS THEN
  X_GEN_TAC `f:num->A` THEN REWRITE_TAC[IN_UNIV] THEN DISCH_TAC THEN
  SUBGOAL_THEN `!n. (f:num->A)(n) IN (s DIFF IMAGE f {m | m < n})` MP_TAC THENL
   [GEN_TAC THEN ONCE_ASM_REWRITE_TAC[] THEN CONV_TAC SELECT_CONV THEN
    REWRITE_TAC[MEMBER_NOT_EMPTY] THEN
    MATCH_MP_TAC INFINITE_NONEMPTY THEN MATCH_MP_TAC INFINITE_DIFF_FINITE THEN
    ASM_SIMP_TAC[FINITE_IMAGE; FINITE_NUMSEG_LT];
    ALL_TAC] THEN
  REWRITE_TAC[IN_IMAGE; IN_ELIM_THM; IN_DIFF] THEN MESON_TAC[LT_CASES]);;

let FINITE_CARD_LT = prove
 (`!s:A->bool. FINITE s <=> s <_c (UNIV:num->bool)`,
  ONCE_REWRITE_TAC[TAUT `(a <=> b) <=> (~a <=> ~b)`] THEN
  REWRITE_TAC[GSYM INFINITE; CARD_NOT_LT; INFINITE_CARD_LE]);;

let CARD_LE_SUBSET = prove
 (`!s:A->bool t. s SUBSET t ==> s <=_c t`,
  REWRITE_TAC[SUBSET; le_c] THEN MESON_TAC[I_THM]);;

let CARD_LE_UNIV = prove
 (`!s:A->bool. s <=_c (:A)`,
  GEN_TAC THEN MATCH_MP_TAC CARD_LE_SUBSET THEN REWRITE_TAC[SUBSET_UNIV]);;

let CARD_LE_EQ_SUBSET = prove
 (`!s:A->bool t:B->bool. s <=_c t <=> ?u. u SUBSET t /\ (s =_c u)`,
  REPEAT GEN_TAC THEN EQ_TAC THENL
   [ALL_TAC;
    REPEAT STRIP_TAC THEN
    FIRST_ASSUM(MP_TAC o MATCH_MP CARD_LE_SUBSET) THEN
    MATCH_MP_TAC(TAUT `(a <=> b) ==> b ==> a`) THEN
    MATCH_MP_TAC CARD_LE_CONG THEN
    ASM_REWRITE_TAC[CARD_LE_CONG; CARD_EQ_REFL]] THEN
  REWRITE_TAC[le_c; eq_c] THEN
  DISCH_THEN(X_CHOOSE_THEN `f:A->B` STRIP_ASSUME_TAC) THEN
  REWRITE_TAC[RIGHT_AND_EXISTS_THM] THEN EXISTS_TAC `IMAGE (f:A->B) s` THEN
  EXISTS_TAC `f:A->B` THEN REWRITE_TAC[IN_IMAGE; SUBSET] THEN
  ASM_MESON_TAC[]);;

let CARD_INFINITE_CONG = prove
 (`!s:A->bool t:B->bool. s =_c t ==> (INFINITE s <=> INFINITE t)`,
  REWRITE_TAC[INFINITE_CARD_LE] THEN REPEAT STRIP_TAC THEN
  MATCH_MP_TAC CARD_LE_CONG THEN ASM_REWRITE_TAC[CARD_EQ_REFL]);;

let CARD_FINITE_CONG = prove
 (`!s:A->bool t:B->bool. s =_c t ==> (FINITE s <=> FINITE t)`,
  ONCE_REWRITE_TAC[TAUT `(a <=> b) <=> (~a <=> ~b)`] THEN
  REWRITE_TAC[GSYM INFINITE; CARD_INFINITE_CONG]);;

let CARD_LE_FINITE = prove
 (`!s:A->bool t:B->bool. FINITE t /\ s <=_c t ==> FINITE s`,
  ASM_MESON_TAC[CARD_LE_EQ_SUBSET; FINITE_SUBSET; CARD_FINITE_CONG]);;

let CARD_EQ_FINITE = prove
 (`!s t:A->bool. FINITE t /\ s =_c t ==> FINITE s`,
  REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN MESON_TAC[CARD_LE_FINITE]);;

let CARD_LE_INFINITE = prove
 (`!s:A->bool t:B->bool. INFINITE s /\ s <=_c t ==> INFINITE t`,
  MESON_TAC[CARD_LE_FINITE; INFINITE]);;

let CARD_LT_FINITE_INFINITE = prove
 (`!s:A->bool t:B->bool. FINITE s /\ INFINITE t ==> s <_c t`,
  REWRITE_TAC[GSYM CARD_NOT_LE; INFINITE] THEN MESON_TAC[CARD_LE_FINITE]);;

let CARD_LE_FINITE_INFINITE = prove
 (`!s:A->bool t:B->bool.
        FINITE s /\ INFINITE t ==> s <=_c t`,
  REPEAT STRIP_TAC THEN
  MATCH_MP_TAC CARD_LT_IMP_LE THEN
  ASM_SIMP_TAC[CARD_LT_FINITE_INFINITE]);;

let CARD_LE_CARD_IMP = prove
 (`!s:A->bool t:B->bool. FINITE t /\ s <=_c t ==> CARD s <= CARD t`,
  REPEAT STRIP_TAC THEN
  SUBGOAL_THEN `FINITE(s:A->bool)` ASSUME_TAC THENL
   [ASM_MESON_TAC[CARD_LE_FINITE]; ALL_TAC] THEN
  FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE I [le_c]) THEN
  DISCH_THEN(X_CHOOSE_THEN `f:A->B` STRIP_ASSUME_TAC) THEN
  MATCH_MP_TAC LE_TRANS THEN EXISTS_TAC `CARD(IMAGE (f:A->B) s)` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC(ARITH_RULE `(m = n:num) ==> n <= m`) THEN
    MATCH_MP_TAC CARD_IMAGE_INJ THEN ASM_REWRITE_TAC[];
    MATCH_MP_TAC CARD_SUBSET THEN ASM_REWRITE_TAC[] THEN
    ASM_MESON_TAC[SUBSET; IN_IMAGE]]);;

let CARD_EQ_CARD_IMP = prove
 (`!s:A->bool t:B->bool. FINITE t /\ s =_c t ==> (CARD s = CARD t)`,
  MESON_TAC[CARD_FINITE_CONG; LE_ANTISYM; CARD_LE_ANTISYM; CARD_LE_CARD_IMP]);;

let CARD_LE_CARD = prove
 (`!s:A->bool t:B->bool.
        FINITE s /\ FINITE t ==> (s <=_c t <=> CARD s <= CARD t)`,
  REPEAT STRIP_TAC THEN
  MATCH_MP_TAC(TAUT `(a ==> b) /\ (~a ==> ~b) ==> (a <=> b)`) THEN
  ASM_SIMP_TAC[CARD_LE_CARD_IMP] THEN
  REWRITE_TAC[CARD_NOT_LE; NOT_LE] THEN REWRITE_TAC[lt_c; LT_LE] THEN
  ASM_SIMP_TAC[CARD_LE_CARD_IMP] THEN
  MATCH_MP_TAC(TAUT `(c ==> a ==> b) ==> a /\ ~b ==> ~c`) THEN
  DISCH_TAC THEN GEN_REWRITE_TAC LAND_CONV [CARD_LE_EQ_SUBSET] THEN
  DISCH_THEN(X_CHOOSE_THEN `u:A->bool` STRIP_ASSUME_TAC) THEN
  MATCH_MP_TAC CARD_EQ_IMP_LE THEN
  SUBGOAL_THEN `u:A->bool = s` (fun th -> ASM_MESON_TAC[th; CARD_EQ_SYM]) THEN
  ASM_MESON_TAC[CARD_SUBSET_EQ; CARD_EQ_CARD_IMP; CARD_EQ_SYM]);;

let CARD_EQ_CARD = prove
 (`!s:A->bool t:B->bool.
        FINITE s /\ FINITE t ==> (s =_c t <=> (CARD s = CARD t))`,
  MESON_TAC[CARD_FINITE_CONG; LE_ANTISYM; CARD_LE_ANTISYM; CARD_LE_CARD]);;

let CARD_LT_CARD = prove
 (`!s:A->bool t:B->bool.
        FINITE s /\ FINITE t ==> (s <_c t <=> CARD s < CARD t)`,
  SIMP_TAC[CARD_LE_CARD; GSYM NOT_LE; GSYM CARD_NOT_LE]);;

let CARD_HAS_SIZE_CONG = prove
 (`!s:A->bool t:B->bool n. s HAS_SIZE n /\ s =_c t ==> t HAS_SIZE n`,
  REWRITE_TAC[HAS_SIZE] THEN
  MESON_TAC[CARD_EQ_CARD; CARD_FINITE_CONG]);;

let CARD_LE_IMAGE = prove
 (`!f s. IMAGE f s <=_c s`,
  REWRITE_TAC[LE_C; FORALL_IN_IMAGE] THEN MESON_TAC[]);;

let CARD_LE_IMAGE_GEN = prove
 (`!f:A->B s t. t SUBSET IMAGE f s ==> t <=_c s`,
  REPEAT STRIP_TAC THEN TRANS_TAC CARD_LE_TRANS `IMAGE (f:A->B) s` THEN
  ASM_SIMP_TAC[CARD_LE_IMAGE; CARD_LE_SUBSET]);;

let CARD_EQ_IMAGE = prove
 (`!f:A->B s.
        (!x y. x IN s /\ y IN s /\ f x = f y ==> x = y)
        ==> IMAGE f s =_c s`,
  REPEAT STRIP_TAC THEN ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN
  REWRITE_TAC[eq_c] THEN EXISTS_TAC `f:A->B` THEN ASM SET_TAC[]);;

let LE_C_IMAGE = prove
 (`!s:A->bool t:B->bool.
        s <=_c t <=> s = {} \/ ?f. IMAGE f t = s`,
  REPEAT GEN_TAC THEN
  ASM_CASES_TAC `s:A->bool = {}` THEN
  ASM_REWRITE_TAC[CARD_EMPTY_LE] THEN EQ_TAC THENL
   [FIRST_X_ASSUM(X_CHOOSE_TAC `a:A` o
      GEN_REWRITE_RULE I [GSYM MEMBER_NOT_EMPTY]) THEN
    REWRITE_TAC[LE_C] THEN DISCH_THEN(X_CHOOSE_TAC `f:B->A`) THEN
    EXISTS_TAC `\x. if (f:B->A) x IN s then f x else a` THEN
    ASM SET_TAC[];
    DISCH_THEN(CHOOSE_THEN(SUBST1_TAC o SYM)) THEN
    REWRITE_TAC[CARD_LE_IMAGE]]);;

(* ------------------------------------------------------------------------- *)
(* Cardinal arithmetic operations.                                           *)
(* ------------------------------------------------------------------------- *)

parse_as_infix("+_c",(16,"right"));;
parse_as_infix("*_c",(20,"right"));;

let add_c = new_definition
  `s +_c t = {INL x | x IN s} UNION {INR y | y IN t}`;;

let mul_c = new_definition
  `s *_c t = {(x,y) | x IN s /\ y IN t}`;;

(* ------------------------------------------------------------------------- *)
(* Congruence properties for the arithmetic operators.                       *)
(* ------------------------------------------------------------------------- *)

let CARD_LE_ADD = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s <=_c s' /\ t <=_c t' ==> s +_c t <=_c s' +_c t'`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c; add_c] THEN
  DISCH_THEN(CONJUNCTS_THEN2
   (X_CHOOSE_THEN `f:A->B` STRIP_ASSUME_TAC)
   (X_CHOOSE_THEN `g:C->D` STRIP_ASSUME_TAC)) THEN
  MP_TAC(prove_recursive_functions_exist sum_RECURSION
   `(!x. h(INL x) = INL((f:A->B) x)) /\ (!y. h(INR y) = INR((g:C->D) y))`) THEN
  MATCH_MP_TAC MONO_EXISTS THEN X_GEN_TAC `h:(A+C)->(B+D)` THEN STRIP_TAC THEN
  REWRITE_TAC[IN_UNION; IN_ELIM_THM] THEN
  CONJ_TAC THEN REPEAT GEN_TAC THEN
  REPEAT(DISCH_THEN(CONJUNCTS_THEN2 STRIP_ASSUME_TAC MP_TAC) THEN
         ASM_REWRITE_TAC[]) THEN
  ASM_REWRITE_TAC[sum_DISTINCT;
                  sum_INJECTIVE] THEN
  ASM_MESON_TAC[]);;

let CARD_LE_MUL = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s <=_c s' /\ t <=_c t' ==> s *_c t <=_c s' *_c t'`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c; mul_c] THEN
  DISCH_THEN(CONJUNCTS_THEN2
   (X_CHOOSE_THEN `f:A->B` STRIP_ASSUME_TAC)
   (X_CHOOSE_THEN `g:C->D` STRIP_ASSUME_TAC)) THEN
  EXISTS_TAC `\(x,y). (f:A->B) x,(g:C->D) y` THEN
  REWRITE_TAC[FORALL_PAIR_THM; IN_ELIM_THM] THEN
  CONV_TAC(ONCE_DEPTH_CONV GEN_BETA_CONV) THEN
  REWRITE_TAC[PAIR_EQ] THEN ASM_MESON_TAC[]);;

let CARD_FUNSPACE_LE = prove
 (`(:A) <=_c (:A') /\ (:B) <=_c (:B') ==> (:A->B) <=_c (:A'->B')`,
  REWRITE_TAC[le_c; IN_UNIV] THEN DISCH_THEN(CONJUNCTS_THEN2
   (X_CHOOSE_TAC `f:A->A'`) (X_CHOOSE_TAC `g:B->B'`)) THEN
  SUBGOAL_THEN `?f':A'->A. !x. f'(f x) = x` STRIP_ASSUME_TAC THENL
   [ASM_REWRITE_TAC[GSYM INJECTIVE_LEFT_INVERSE]; ALL_TAC] THEN
  EXISTS_TAC `\h. (g:B->B') o (h:A->B) o (f':A'->A)` THEN
  ASM_REWRITE_TAC[o_DEF; FUN_EQ_THM] THEN ASM_MESON_TAC[]);;

let CARD_ADD_CONG = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s =_c s' /\ t =_c t' ==> s +_c t =_c s' +_c t'`,
  SIMP_TAC[CARD_LE_ADD; GSYM CARD_LE_ANTISYM]);;

let CARD_MUL_CONG = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s =_c s' /\ t =_c t' ==> s *_c t =_c s' *_c t'`,
  SIMP_TAC[CARD_LE_MUL; GSYM CARD_LE_ANTISYM]);;

let CARD_FUNSPACE_CONG = prove
 (`(:A) =_c (:A') /\ (:B) =_c (:B') ==> (:A->B) =_c (:A'->B')`,
  SIMP_TAC[GSYM CARD_LE_ANTISYM; CARD_FUNSPACE_LE]);;

(* ------------------------------------------------------------------------- *)
(* Misc lemmas.                                                              *)
(* ------------------------------------------------------------------------- *)

let MUL_C_UNIV = prove
 (`(:A) *_c (:B) = (:A#B)`,
  REWRITE_TAC[EXTENSION; FORALL_PAIR_THM; mul_c; IN_ELIM_PAIR_THM; IN_UNIV]);;

let CARD_FUNSPACE_CURRY = prove
 (`(:A->B->C) =_c (:A#B->C)`,
  REWRITE_TAC[EQ_C_BIJECTIONS] THEN
  EXISTS_TAC `\(f:A->B->C) (x,y). f x y` THEN
  EXISTS_TAC `\(g:A#B->C) x y. g(x,y)` THEN
  REWRITE_TAC[IN_UNIV] THEN
  REWRITE_TAC[FUN_EQ_THM; FORALL_PAIR_THM]);;

let IN_CARD_ADD = prove
 (`(!x. INL(x) IN (s +_c t) <=> x IN s) /\
   (!y. INR(y) IN (s +_c t) <=> y IN t)`,
  REWRITE_TAC[add_c; IN_UNION; IN_ELIM_THM] THEN
  REWRITE_TAC[sum_DISTINCT; sum_INJECTIVE] THEN MESON_TAC[]);;

let IN_CARD_MUL = prove
 (`!s t x y. (x,y) IN (s *_c t) <=> x IN s /\ y IN t`,
  REWRITE_TAC[mul_c; IN_ELIM_THM; PAIR_EQ] THEN MESON_TAC[]);;

let CARD_LE_SQUARE = prove
 (`!s:A->bool. s <=_c s *_c s`,
  GEN_TAC THEN REWRITE_TAC[le_c] THEN EXISTS_TAC `\x:A. x,(@z:A. z IN s)` THEN
  SIMP_TAC[IN_CARD_MUL; PAIR_EQ] THEN
  CONV_TAC(ONCE_DEPTH_CONV SELECT_CONV) THEN MESON_TAC[]);;

let CARD_SQUARE_NUM = prove
 (`(UNIV:num->bool) *_c (UNIV:num->bool) =_c (UNIV:num->bool)`,
  REWRITE_TAC[GSYM CARD_LE_ANTISYM; CARD_LE_SQUARE] THEN
  REWRITE_TAC[le_c; IN_UNIV; mul_c; IN_ELIM_THM] THEN
  EXISTS_TAC `\(x,y). NUMPAIR x y` THEN
  REWRITE_TAC[FORALL_PAIR_THM] THEN
  CONV_TAC(ONCE_DEPTH_CONV GEN_BETA_CONV) THEN MESON_TAC[NUMPAIR_INJ]);;

let UNION_LE_ADD_C = prove
 (`!s t:A->bool. (s UNION t) <=_c s +_c t`,
  REPEAT GEN_TAC THEN MATCH_MP_TAC CARD_LE_IMAGE_GEN THEN
  EXISTS_TAC `function INL x -> (x:A) | INR x -> x` THEN
  REWRITE_TAC[add_c; IMAGE_UNION] THEN ONCE_REWRITE_TAC[SIMPLE_IMAGE] THEN
  REWRITE_TAC[GSYM IMAGE_o; o_DEF] THEN SET_TAC[]);;

let CARD_ADD_C = prove
 (`!s t. FINITE s /\ FINITE t ==> CARD(s +_c t) = CARD s + CARD t`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[add_c] THEN
  W(MP_TAC o PART_MATCH (lhs o rand) CARD_UNION o lhand o snd) THEN
  ASM_SIMP_TAC[SIMPLE_IMAGE; FINITE_IMAGE] THEN
  REWRITE_TAC[SET_RULE `IMAGE f s INTER IMAGE g t = {} <=>
                        !x y. x IN s /\ y IN t ==> ~(f x = g y)`] THEN
  REWRITE_TAC[sum_DISTINCT] THEN DISCH_THEN SUBST1_TAC THEN
  BINOP_TAC THEN MATCH_MP_TAC CARD_IMAGE_INJ THEN
  ASM_SIMP_TAC[sum_INJECTIVE]);;

let CARD_MUL_C = prove
 (`!s t. FINITE s /\ FINITE t ==> CARD(s *_c t) = CARD s * CARD t`,
  SIMP_TAC[mul_c; GSYM CROSS; CARD_CROSS]);;

(* ------------------------------------------------------------------------- *)
(* Various "arithmetical" lemmas.                                            *)
(* ------------------------------------------------------------------------- *)

let CARD_ADD_SYM = prove
 (`!s:A->bool t:B->bool. s +_c t =_c t +_c s`,
  REPEAT GEN_TAC THEN REWRITE_TAC[eq_c] THEN
  MP_TAC(prove_recursive_functions_exist sum_RECURSION
    `(!x. (h:A+B->B+A) (INL x) = INR x) /\ (!y. h(INR y) = INL y)`) THEN
  MATCH_MP_TAC MONO_EXISTS THEN
  SIMP_TAC[FORALL_SUM_THM; EXISTS_SUM_THM; EXISTS_UNIQUE_THM] THEN
  REWRITE_TAC[sum_DISTINCT; sum_INJECTIVE; IN_CARD_ADD] THEN MESON_TAC[]);;

let CARD_ADD_ASSOC = prove
 (`!s:A->bool t:B->bool u:C->bool. s +_c (t +_c u) =_c (s +_c t) +_c u`,
  REPEAT GEN_TAC THEN REWRITE_TAC[eq_c] THEN
  CHOOSE_TAC(prove_recursive_functions_exist sum_RECURSION
    `(!u. (i:B+C->(A+B)+C) (INL u) = INL(INR u)) /\
     (!v. i(INR v) = INR v)`) THEN
  MP_TAC(prove_recursive_functions_exist sum_RECURSION
    `(!x. (h:A+B+C->(A+B)+C) (INL x) = INL(INL x)) /\
     (!z. h(INR z) = i(z))`) THEN
  MATCH_MP_TAC MONO_EXISTS THEN GEN_TAC THEN STRIP_TAC THEN
  ASM_REWRITE_TAC[FORALL_SUM_THM; EXISTS_SUM_THM; EXISTS_UNIQUE_THM;
                  sum_DISTINCT; sum_INJECTIVE; IN_CARD_ADD] THEN
  MESON_TAC[]);;

let CARD_MUL_SYM = prove
 (`!s:A->bool t:B->bool. s *_c t =_c t *_c s`,
  REPEAT GEN_TAC THEN REWRITE_TAC[eq_c] THEN
  MP_TAC(prove_recursive_functions_exist pair_RECURSION
    `(!x:A y:B. h(x,y) = (y,x))`) THEN
  MATCH_MP_TAC MONO_EXISTS THEN GEN_TAC THEN STRIP_TAC THEN
  REWRITE_TAC[EXISTS_UNIQUE_THM; FORALL_PAIR_THM; EXISTS_PAIR_THM] THEN
  ASM_REWRITE_TAC[FORALL_PAIR_THM; IN_CARD_MUL; PAIR_EQ] THEN
  MESON_TAC[]);;

let CARD_MUL_ASSOC = prove
 (`!s:A->bool t:B->bool u:C->bool. s *_c (t *_c u) =_c (s *_c t) *_c u`,
  REPEAT GEN_TAC THEN REWRITE_TAC[eq_c] THEN
  CHOOSE_TAC(prove_recursive_functions_exist pair_RECURSION
    `(!x y z. (i:A->B#C->(A#B)#C) x (y,z) = (x,y),z)`) THEN
  MP_TAC(prove_recursive_functions_exist pair_RECURSION
    `(!x p. (h:A#B#C->(A#B)#C) (x,p) = i x p)`) THEN
  MATCH_MP_TAC MONO_EXISTS THEN GEN_TAC THEN STRIP_TAC THEN
  REWRITE_TAC[EXISTS_UNIQUE_THM; FORALL_PAIR_THM; EXISTS_PAIR_THM] THEN
  ASM_REWRITE_TAC[FORALL_PAIR_THM; IN_CARD_MUL; PAIR_EQ] THEN
  MESON_TAC[]);;

let CARD_LDISTRIB = prove
 (`!s:A->bool t:B->bool u:C->bool.
        s *_c (t +_c u) =_c (s *_c t) +_c (s *_c u)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[eq_c] THEN
  CHOOSE_TAC(prove_recursive_functions_exist sum_RECURSION
    `(!x y. (i:A->(B+C)->A#B+A#C) x (INL y) = INL(x,y)) /\
     (!x z. (i:A->(B+C)->A#B+A#C) x (INR z) = INR(x,z))`) THEN
  MP_TAC(prove_recursive_functions_exist pair_RECURSION
    `(!x s. (h:A#(B+C)->(A#B)+(A#C)) (x,s) = i x s)`) THEN
  MATCH_MP_TAC MONO_EXISTS THEN GEN_TAC THEN STRIP_TAC THEN
  ASM_REWRITE_TAC[EXISTS_UNIQUE_THM; FORALL_PAIR_THM; EXISTS_PAIR_THM;
                  FORALL_SUM_THM; EXISTS_SUM_THM; PAIR_EQ; IN_CARD_MUL;
                  sum_DISTINCT; sum_INJECTIVE; IN_CARD_ADD] THEN
  MESON_TAC[]);;

let CARD_RDISTRIB = prove
 (`!s:A->bool t:B->bool u:C->bool.
        (s +_c t) *_c u =_c (s *_c u) +_c (t *_c u)`,
  REPEAT GEN_TAC THEN
  TRANS_TAC CARD_EQ_TRANS
   `(u:C->bool) *_c ((s:A->bool) +_c (t:B->bool))` THEN
  REWRITE_TAC[CARD_MUL_SYM] THEN
  TRANS_TAC CARD_EQ_TRANS
   `(u:C->bool) *_c (s:A->bool) +_c (u:C->bool) *_c (t:B->bool)` THEN
  REWRITE_TAC[CARD_LDISTRIB] THEN
  MATCH_MP_TAC CARD_ADD_CONG THEN REWRITE_TAC[CARD_MUL_SYM]);;

let CARD_LE_ADDR = prove
 (`!s:A->bool t:B->bool. s <=_c s +_c t`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c] THEN
  EXISTS_TAC `INL:A->A+B` THEN SIMP_TAC[IN_CARD_ADD; sum_INJECTIVE]);;

let CARD_LE_ADDL = prove
 (`!s:A->bool t:B->bool. t <=_c s +_c t`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c] THEN
  EXISTS_TAC `INR:B->A+B` THEN SIMP_TAC[IN_CARD_ADD; sum_INJECTIVE]);;

(* ------------------------------------------------------------------------- *)
(* A rather special lemma but temporarily useful.                            *)
(* ------------------------------------------------------------------------- *)

let CARD_ADD_LE_MUL_INFINITE = prove
 (`!s:A->bool. INFINITE s ==> s +_c s <=_c s *_c s`,
  GEN_TAC THEN REWRITE_TAC[INFINITE_CARD_LE; le_c; IN_UNIV] THEN
  DISCH_THEN(X_CHOOSE_THEN `f:num->A` STRIP_ASSUME_TAC) THEN
  MP_TAC(prove_recursive_functions_exist sum_RECURSION
    `(!x. h(INL x) = (f(0),x):A#A) /\ (!x. h(INR x) = (f(1),x))`) THEN
  MATCH_MP_TAC MONO_EXISTS THEN X_GEN_TAC `h:A+A->A#A` THEN
  STRIP_TAC THEN
  REPEAT((MATCH_MP_TAC sum_INDUCT THEN
          ASM_REWRITE_TAC[IN_CARD_ADD; IN_CARD_MUL; PAIR_EQ])
         ORELSE STRIP_TAC) THEN
  ASM_REWRITE_TAC[] THEN ASM_MESON_TAC[NUM_REDUCE_CONV `1 = 0`]);;

(* ------------------------------------------------------------------------- *)
(* Relate cardinal addition to the simple union operation.                   *)
(* ------------------------------------------------------------------------- *)

let CARD_DISJOINT_UNION = prove
 (`!s:A->bool t. (s INTER t = {}) ==> (s UNION t =_c s +_c t)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[EXTENSION; IN_INTER; NOT_IN_EMPTY] THEN
  STRIP_TAC THEN REWRITE_TAC[eq_c; IN_UNION] THEN
  EXISTS_TAC `\x:A. if x IN s then INL x else INR x` THEN
  REWRITE_TAC[FORALL_SUM_THM; IN_CARD_ADD] THEN
  REWRITE_TAC[COND_RAND; COND_RATOR] THEN
  REWRITE_TAC[TAUT `(if b then x else y) <=> b /\ x \/ ~b /\ y`] THEN
  REWRITE_TAC[sum_DISTINCT; sum_INJECTIVE; IN_CARD_ADD] THEN
  ASM_MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* The key to arithmetic on infinite cardinals: k^2 = k.                     *)
(* ------------------------------------------------------------------------- *)

let CARD_SQUARE_INFINITE = prove
 (`!k:A->bool. INFINITE k ==> (k *_c k =_c k)`,
  let lemma = prove
   (`INFINITE(s:A->bool) /\ s SUBSET k /\
     (!x y. R(x,y) ==> x IN (s *_c s) /\ y IN s) /\
     (!x. x IN (s *_c s) ==> ?!y. y IN s /\ R(x,y)) /\
     (!y:A. y IN s ==> ?!x. x IN (s *_c s) /\ R(x,y))
     ==> (s = {z | ?p. R(p,z)})`,
    REWRITE_TAC[EXTENSION; IN_ELIM_THM] THEN MESON_TAC[]) in
  REPEAT STRIP_TAC THEN
  ABBREV_TAC
    `P = \R. ?s. INFINITE(s:A->bool) /\ s SUBSET k /\
                 (!x y. R(x,y) ==> x IN (s *_c s) /\ y IN s) /\
                 (!x. x IN (s *_c s) ==> ?!y. y IN s /\ R(x,y)) /\
                 (!y. y IN s ==> ?!x. x IN (s *_c s) /\ R(x,y))` THEN
  MP_TAC(ISPEC `P:((A#A)#A->bool)->bool` ZL_SUBSETS_UNIONS_NONEMPTY) THEN
  ANTS_TAC THENL
   [CONJ_TAC THENL
     [FIRST_X_ASSUM(SUBST1_TAC o SYM) THEN REWRITE_TAC[] THEN
      ONCE_REWRITE_TAC[SWAP_EXISTS_THM] THEN
      REWRITE_TAC[RIGHT_EXISTS_AND_THM; GSYM EQ_C] THEN
      FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE I [INFINITE_CARD_LE]) THEN
      REWRITE_TAC[CARD_LE_EQ_SUBSET] THEN
      MATCH_MP_TAC MONO_EXISTS THEN X_GEN_TAC `s:A->bool` THEN
      STRIP_TAC THEN ASM_REWRITE_TAC[] THEN CONJ_TAC THENL
       [ASM_MESON_TAC[num_INFINITE; CARD_INFINITE_CONG]; ALL_TAC] THEN
      FIRST_ASSUM(fun th ->
       MP_TAC(MATCH_MP CARD_MUL_CONG (CONJ th th))) THEN
      GEN_REWRITE_TAC LAND_CONV [CARD_EQ_SYM] THEN
      DISCH_THEN(MP_TAC o C CONJ CARD_SQUARE_NUM) THEN
      DISCH_THEN(MP_TAC o MATCH_MP CARD_EQ_TRANS) THEN
      FIRST_ASSUM(fun th ->
        DISCH_THEN(ACCEPT_TAC o MATCH_MP CARD_EQ_TRANS o C CONJ th));
      ALL_TAC] THEN
    SUBGOAL_THEN
     `P = \R. INFINITE {z | ?x y. R((x,y),z)} /\
              (!x:A y z. R((x,y),z) ==> x IN k /\ y IN k /\ z IN k) /\
              (!x y. (?u v. R((u,v),x)) /\ (?u v. R((u,v),y))
                     ==> ?z. R((x,y),z)) /\
              (!x y. (?z. R((x,y),z))
                     ==> (?u v. R((u,v),x)) /\ (?u v. R((u,v),y))) /\
              (!x y z1 z2. R((x,y),z1) /\ R((x,y),z2) ==> (z1 = z2)) /\
              (!x1 y1 x2 y2 z. R((x1,y1),z) /\ R((x2,y2),z)
                               ==> (x1 = x2) /\ (y1 = y2))`
    SUBST1_TAC THENL
     [FIRST_X_ASSUM(SUBST1_TAC o SYM) THEN REWRITE_TAC[] THEN
      ONCE_REWRITE_TAC[MATCH_MP(TAUT `(a ==> b) ==> (a <=> b /\ a)`) lemma] THEN
      REWRITE_TAC[UNWIND_THM2] THEN REWRITE_TAC[FUN_EQ_THM] THEN
      REWRITE_TAC[IN_CARD_MUL; EXISTS_PAIR_THM; SUBSET; FUN_EQ_THM;
                  IN_ELIM_THM; FORALL_PAIR_THM; EXISTS_UNIQUE_THM;
                  UNIONS; PAIR_EQ] THEN
      GEN_TAC THEN AP_TERM_TAC THEN MESON_TAC[];
      ALL_TAC] THEN
    FIRST_X_ASSUM(K ALL_TAC o SYM) THEN REWRITE_TAC[] THEN GEN_TAC THEN
    GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV)
     [TAUT `a ==> b /\ c <=> (a ==> b) /\ (a ==> c)`] THEN
    GEN_REWRITE_TAC (LAND_CONV o ONCE_DEPTH_CONV) [FORALL_AND_THM] THEN
    MATCH_MP_TAC(TAUT
     `(c /\ d ==> f) /\ (a /\ b ==> e)
      ==> (a /\ (b /\ c) /\ d ==> e /\ f)`) THEN
    CONJ_TAC THENL
     [REWRITE_TAC[UNIONS; IN_ELIM_THM] THEN
      REWRITE_TAC[SUBSET; IN] THEN MESON_TAC[];
      ALL_TAC] THEN
    DISCH_THEN(CONJUNCTS_THEN2 (X_CHOOSE_TAC `s:(A#A)#A->bool`) MP_TAC) THEN
    DISCH_THEN(MP_TAC o SPEC `s:(A#A)#A->bool`) THEN
    ASM_REWRITE_TAC[INFINITE; CONTRAPOS_THM] THEN
    MATCH_MP_TAC(ONCE_REWRITE_RULE[TAUT `a /\ b ==> c <=> b ==> a ==> c`]
                      FINITE_SUBSET) THEN
    REWRITE_TAC[SUBSET; IN_ELIM_THM; UNIONS] THEN ASM_MESON_TAC[IN];
    ALL_TAC] THEN
  FIRST_X_ASSUM(SUBST1_TAC o SYM) THEN REWRITE_TAC[] THEN
  DISCH_THEN(X_CHOOSE_THEN `R:(A#A)#A->bool`
   (CONJUNCTS_THEN2 (X_CHOOSE_TAC `s:A->bool`) ASSUME_TAC)) THEN
  SUBGOAL_THEN `(s:A->bool) *_c s =_c s` ASSUME_TAC THENL
   [REWRITE_TAC[EQ_C] THEN EXISTS_TAC `R:(A#A)#A->bool` THEN ASM_REWRITE_TAC[];
    ALL_TAC] THEN
  SUBGOAL_THEN `s +_c s <=_c (s:A->bool)` ASSUME_TAC THENL
   [TRANS_TAC CARD_LE_TRANS `(s:A->bool) *_c s` THEN
    ASM_SIMP_TAC[CARD_EQ_IMP_LE; CARD_ADD_LE_MUL_INFINITE];
    ALL_TAC] THEN
  SUBGOAL_THEN `(s:A->bool) INTER (k DIFF s) = {}` ASSUME_TAC THENL
   [REWRITE_TAC[EXTENSION; IN_INTER; IN_DIFF; NOT_IN_EMPTY] THEN MESON_TAC[];
    ALL_TAC] THEN
  DISJ_CASES_TAC(ISPECL [`k DIFF (s:A->bool)`; `s:A->bool`] CARD_LE_TOTAL)
  THENL
   [SUBGOAL_THEN `k = (s:A->bool) UNION (k DIFF s)` SUBST1_TAC THENL
     [FIRST_ASSUM(MP_TAC o CONJUNCT1 o CONJUNCT2) THEN
      REWRITE_TAC[SUBSET; EXTENSION; IN_INTER; NOT_IN_EMPTY;
                  IN_UNION; IN_DIFF] THEN
      MESON_TAC[];
      ALL_TAC] THEN
    REWRITE_TAC[GSYM CARD_LE_ANTISYM; CARD_LE_SQUARE] THEN
    TRANS_TAC CARD_LE_TRANS
     `((s:A->bool) +_c (k DIFF s:A->bool)) *_c (s +_c k DIFF s)` THEN
    ASM_SIMP_TAC[CARD_DISJOINT_UNION; CARD_EQ_IMP_LE; CARD_MUL_CONG] THEN
    TRANS_TAC CARD_LE_TRANS `((s:A->bool) +_c s) *_c (s +_c s)` THEN
    ASM_SIMP_TAC[CARD_LE_ADD; CARD_LE_MUL; CARD_LE_REFL] THEN
    TRANS_TAC CARD_LE_TRANS `(s:A->bool) *_c s` THEN
    ASM_SIMP_TAC[CARD_LE_MUL] THEN
    TRANS_TAC CARD_LE_TRANS `s:A->bool` THEN ASM_SIMP_TAC[CARD_EQ_IMP_LE] THEN
    REWRITE_TAC[CARD_LE_EQ_SUBSET] THEN EXISTS_TAC `s:A->bool` THEN
    SIMP_TAC[CARD_EQ_REFL; SUBSET; IN_UNION];
    ALL_TAC] THEN
  UNDISCH_TAC `s:A->bool <=_c k DIFF s` THEN
  REWRITE_TAC[CARD_LE_EQ_SUBSET] THEN
  DISCH_THEN(X_CHOOSE_THEN `d:A->bool` STRIP_ASSUME_TAC) THEN
  SUBGOAL_THEN `(s:A->bool *_c d) UNION (d *_c s) UNION (d *_c d) =_c d`
  MP_TAC THENL
   [TRANS_TAC CARD_EQ_TRANS
       `((s:A->bool) *_c (d:A->bool)) +_c ((d *_c s) +_c (d *_c d))` THEN
    CONJ_TAC THENL
     [TRANS_TAC CARD_EQ_TRANS
       `((s:A->bool) *_c d) +_c ((d *_c s) UNION (d *_c d))` THEN
      CONJ_TAC THENL
       [ALL_TAC;
        MATCH_MP_TAC CARD_ADD_CONG THEN REWRITE_TAC[CARD_EQ_REFL]] THEN
      MATCH_MP_TAC CARD_DISJOINT_UNION THEN
      UNDISCH_TAC `s INTER (k DIFF s:A->bool) = {}` THEN
      UNDISCH_TAC `d SUBSET (k DIFF s:A->bool)` THEN
      REWRITE_TAC[EXTENSION; SUBSET; FORALL_PAIR_THM; NOT_IN_EMPTY;
                  IN_INTER; IN_UNION; IN_CARD_MUL; IN_DIFF] THEN MESON_TAC[];
      ALL_TAC] THEN
    TRANS_TAC CARD_EQ_TRANS `s:A->bool` THEN ASM_REWRITE_TAC[] THEN
    TRANS_TAC CARD_EQ_TRANS
      `(s:A->bool *_c s) +_c (s *_c s) +_c (s *_c s)` THEN
    CONJ_TAC THENL
     [REPEAT(MATCH_MP_TAC CARD_ADD_CONG THEN CONJ_TAC) THEN
      MATCH_MP_TAC CARD_MUL_CONG THEN ASM_REWRITE_TAC[CARD_EQ_REFL] THEN
      ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN ASM_REWRITE_TAC[];
      ALL_TAC] THEN
    TRANS_TAC CARD_EQ_TRANS `(s:A->bool) +_c s +_c s` THEN CONJ_TAC THENL
     [REPEAT(MATCH_MP_TAC CARD_ADD_CONG THEN ASM_REWRITE_TAC[]);
      ALL_TAC] THEN
    REWRITE_TAC[GSYM CARD_LE_ANTISYM; CARD_LE_ADDR] THEN
    TRANS_TAC CARD_LE_TRANS `(s:A->bool) +_c s` THEN
    ASM_SIMP_TAC[CARD_LE_ADD; CARD_LE_REFL];
    ALL_TAC] THEN
  FIRST_X_ASSUM(CONJUNCTS_THEN ASSUME_TAC) THEN
  FIRST_X_ASSUM(CONJUNCTS_THEN ASSUME_TAC) THEN
  REWRITE_TAC[EQ_C; IN_UNION] THEN
  DISCH_THEN(X_CHOOSE_TAC `S:(A#A)#A->bool`) THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `\x:(A#A)#A. R(x) \/ S(x)`) THEN
  ONCE_REWRITE_TAC[GSYM CONTRAPOS_THM] THEN DISCH_THEN(K ALL_TAC) THEN
  REWRITE_TAC[NOT_IMP] THEN REPEAT CONJ_TAC THENL
   [EXISTS_TAC `(s:A->bool) UNION d`;
    SIMP_TAC[SUBSET; IN];
    SUBGOAL_THEN `~(d:A->bool = {})` MP_TAC THENL
     [DISCH_THEN(MP_TAC o AP_TERM `FINITE:(A->bool)->bool`) THEN
      REWRITE_TAC[FINITE_RULES; GSYM INFINITE] THEN
      ASM_MESON_TAC[CARD_INFINITE_CONG];
      ALL_TAC] THEN
    REWRITE_TAC[GSYM MEMBER_NOT_EMPTY] THEN DISCH_THEN(X_CHOOSE_TAC `a:A`) THEN
    FIRST_ASSUM(MP_TAC o C MATCH_MP
     (ASSUME `a:A IN d`) o last o CONJUNCTS) THEN
    DISCH_THEN(MP_TAC o EXISTENCE) THEN
    DISCH_THEN(X_CHOOSE_THEN `b:A#A` (CONJUNCTS_THEN ASSUME_TAC)) THEN
    REWRITE_TAC[EXTENSION; NOT_FORALL_THM] THEN
    EXISTS_TAC `(b:A#A,a:A)` THEN ASM_REWRITE_TAC[IN] THEN
    DISCH_THEN(fun th -> FIRST_ASSUM
     (MP_TAC o CONJUNCT2 o C MATCH_MP th o CONJUNCT1)) THEN
    MAP_EVERY UNDISCH_TAC
     [`a:A IN d`; `(d:A->bool) SUBSET (k DIFF s)`] THEN
    REWRITE_TAC[SUBSET; IN_DIFF] THEN MESON_TAC[]] THEN
  REWRITE_TAC[INFINITE; FINITE_UNION; DE_MORGAN_THM] THEN
  ASM_REWRITE_TAC[GSYM INFINITE] THEN CONJ_TAC THENL
   [MAP_EVERY UNDISCH_TAC
     [`(d:A->bool) SUBSET (k DIFF s)`; `(s:A->bool) SUBSET k`] THEN
    REWRITE_TAC[SUBSET; IN_UNION; IN_DIFF] THEN MESON_TAC[];
    ALL_TAC] THEN
  REPEAT(FIRST_ASSUM(UNDISCH_TAC o check is_conj o concl)) THEN
  REWRITE_TAC[FORALL_PAIR_THM; EXISTS_UNIQUE_THM; EXISTS_PAIR_THM;
              IN_CARD_MUL; IN_UNION; PAIR_EQ] THEN
  MAP_EVERY UNDISCH_TAC
   [`(s:A->bool) SUBSET k`;
    `(d:A->bool) SUBSET (k DIFF s)`] THEN
  REWRITE_TAC[SUBSET; EXTENSION; NOT_IN_EMPTY; IN_INTER; IN_DIFF] THEN
  POP_ASSUM_LIST(K ALL_TAC) THEN
  REPEAT DISCH_TAC THEN REPEAT CONJ_TAC THENL
   [ASM_MESON_TAC[]; ASM_MESON_TAC[]; ALL_TAC] THEN
  GEN_TAC THEN DISCH_THEN(DISJ_CASES_THEN MP_TAC) THENL
   [ASM_MESON_TAC[]; ALL_TAC] THEN
  DISCH_THEN(fun th -> CONJ_TAC THEN MP_TAC th) THENL
   [ALL_TAC; ASM_MESON_TAC[]] THEN
  DISCH_THEN(fun th ->
   FIRST_ASSUM(MP_TAC o C MATCH_MP th o last o CONJUNCTS)) THEN
  MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Preservation of finiteness.                                               *)
(* ------------------------------------------------------------------------- *)

let CARD_ADD_FINITE = prove
 (`!s t. FINITE s /\ FINITE t ==> FINITE(s +_c t)`,
  SIMP_TAC[add_c; FINITE_UNION; SIMPLE_IMAGE; FINITE_IMAGE]);;

let CARD_ADD_FINITE_EQ = prove
 (`!s:A->bool t:B->bool. FINITE(s +_c t) <=> FINITE s /\ FINITE t`,
  REPEAT GEN_TAC THEN EQ_TAC THEN REWRITE_TAC[CARD_ADD_FINITE] THEN
  DISCH_THEN(fun th -> CONJ_TAC THEN MP_TAC th) THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_FINITE) THEN
  REWRITE_TAC[CARD_LE_ADDL; CARD_LE_ADDR]);;

let CARD_MUL_FINITE = prove
 (`!s t. FINITE s /\ FINITE t ==> FINITE(s *_c t)`,
  SIMP_TAC[mul_c; FINITE_PRODUCT]);;

let CARD_MUL_FINITE_EQ = prove
 (`!s:A->bool t:B->bool.
        FINITE(s *_c t) <=> s = {} \/ t = {} \/ FINITE s /\ FINITE t`,
  REWRITE_TAC[mul_c; GSYM CROSS; FINITE_CROSS_EQ]);;

(* ------------------------------------------------------------------------- *)
(* Hence the "absorption laws" for arithmetic with an infinite cardinal.     *)
(* ------------------------------------------------------------------------- *)

let CARD_MUL_ABSORB_LE = prove
 (`!s:A->bool t:B->bool. INFINITE(t) /\ s <=_c t ==> s *_c t <=_c t`,
  REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `(t:B->bool) *_c t` THEN
  ASM_SIMP_TAC[CARD_LE_MUL; CARD_LE_REFL;
               CARD_SQUARE_INFINITE; CARD_EQ_IMP_LE]);;

let CARD_MUL2_ABSORB_LE = prove
 (`!s:A->bool t:B->bool u:C->bool.
     INFINITE(u) /\ s <=_c u /\ t <=_c u ==> s *_c t <=_c u`,
  REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `(s:A->bool) *_c (u:C->bool)` THEN
  ASM_SIMP_TAC[CARD_MUL_ABSORB_LE] THEN MATCH_MP_TAC CARD_LE_MUL THEN
  ASM_REWRITE_TAC[CARD_LE_REFL]);;

let CARD_ADD_ABSORB_LE = prove
 (`!s:A->bool t:B->bool. INFINITE(t) /\ s <=_c t ==> s +_c t <=_c t`,
  REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `(t:B->bool) *_c t` THEN
  ASM_SIMP_TAC[CARD_SQUARE_INFINITE; CARD_EQ_IMP_LE] THEN
  TRANS_TAC CARD_LE_TRANS `(t:B->bool) +_c t` THEN
  ASM_SIMP_TAC[CARD_ADD_LE_MUL_INFINITE; CARD_LE_ADD; CARD_LE_REFL]);;

let CARD_ADD2_ABSORB_LE = prove
 (`!s:A->bool t:B->bool u:C->bool.
     INFINITE(u) /\ s <=_c u /\ t <=_c u ==> s +_c t <=_c u`,
  REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `(s:A->bool) +_c (u:C->bool)` THEN
  ASM_SIMP_TAC[CARD_ADD_ABSORB_LE] THEN MATCH_MP_TAC CARD_LE_ADD THEN
  ASM_REWRITE_TAC[CARD_LE_REFL]);;

let CARD_MUL_ABSORB = prove
 (`!s:A->bool t:B->bool.
     INFINITE(t) /\ ~(s = {}) /\ s <=_c t ==> s *_c t =_c t`,
  SIMP_TAC[GSYM CARD_LE_ANTISYM; CARD_MUL_ABSORB_LE] THEN REPEAT STRIP_TAC THEN
  FIRST_X_ASSUM(X_CHOOSE_TAC `a:A` o
   GEN_REWRITE_RULE I [GSYM MEMBER_NOT_EMPTY]) THEN
  REWRITE_TAC[le_c] THEN EXISTS_TAC `\x:B. (a:A,x)` THEN
  ASM_SIMP_TAC[IN_CARD_MUL; PAIR_EQ]);;

let CARD_ADD_ABSORB = prove
 (`!s:A->bool t:B->bool. INFINITE(t) /\ s <=_c t ==> s +_c t =_c t`,
  SIMP_TAC[GSYM CARD_LE_ANTISYM; CARD_LE_ADDL; CARD_ADD_ABSORB_LE]);;

let CARD_ADD2_ABSORB_LT = prove
 (`!s:A->bool t:B->bool u:C->bool.
        INFINITE u /\ s <_c u /\ t <_c u ==> s +_c t <_c u`,
  REPEAT STRIP_TAC THEN
  ASM_CASES_TAC `FINITE((s:A->bool) +_c (t:B->bool))` THEN
  ASM_SIMP_TAC[CARD_LT_FINITE_INFINITE] THEN
  DISJ_CASES_TAC(ISPECL [`s:A->bool`; `t:B->bool`] CARD_LE_TOTAL) THENL
   [ASM_CASES_TAC `FINITE(t:B->bool)` THENL
     [ASM_MESON_TAC[CARD_LE_FINITE; CARD_ADD_FINITE];
      TRANS_TAC CARD_LET_TRANS `t:B->bool`];
    ASM_CASES_TAC `FINITE(s:A->bool)` THENL
     [ASM_MESON_TAC[CARD_LE_FINITE; CARD_ADD_FINITE];
      TRANS_TAC CARD_LET_TRANS `s:A->bool`]] THEN
  ASM_REWRITE_TAC[] THEN
  MATCH_MP_TAC CARD_ADD2_ABSORB_LE THEN
  ASM_REWRITE_TAC[INFINITE; CARD_LE_REFL]);;

let CARD_LT_ADD = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
        s <_c s' /\ t <_c t' ==> s +_c t <_c s' +_c t'`,
  REPEAT STRIP_TAC THEN
  ASM_CASES_TAC `FINITE((s':B->bool) +_c (t':D->bool))` THENL
   [FIRST_X_ASSUM(STRIP_ASSUME_TAC o GEN_REWRITE_RULE I
      [CARD_ADD_FINITE_EQ]) THEN
    SUBGOAL_THEN `FINITE(s:A->bool) /\ FINITE(t:C->bool)`
    STRIP_ASSUME_TAC THENL
     [CONJ_TAC THEN FIRST_X_ASSUM(MATCH_MP_TAC o MATCH_MP
        (REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_FINITE) o
        MATCH_MP CARD_LT_IMP_LE) THEN
      ASM_REWRITE_TAC[];
      MAP_EVERY UNDISCH_TAC
       [`(s:A->bool) <_c (s':B->bool)`;
        `(t:C->bool) <_c (t':D->bool)`] THEN
      ASM_SIMP_TAC[CARD_LT_CARD; CARD_ADD_FINITE; CARD_ADD_C] THEN
      ARITH_TAC];
    MATCH_MP_TAC CARD_ADD2_ABSORB_LT THEN ASM_REWRITE_TAC[INFINITE] THEN
    CONJ_TAC THENL
     [TRANS_TAC CARD_LTE_TRANS `s':B->bool` THEN
      ASM_REWRITE_TAC[CARD_LE_ADDR];
      TRANS_TAC CARD_LTE_TRANS `t':D->bool` THEN
      ASM_REWRITE_TAC[CARD_LE_ADDL]]]);;

(* ------------------------------------------------------------------------- *)
(* Some more ad-hoc but useful theorems.                                     *)
(* ------------------------------------------------------------------------- *)

let CARD_MUL_LT_LEMMA = prove
 (`!s t:B->bool u. s <=_c t /\ t <_c u /\ INFINITE u ==> s *_c t <_c u`,
  REPEAT GEN_TAC THEN ASM_CASES_TAC `FINITE(t:B->bool)` THENL
   [REPEAT(DISCH_THEN(CONJUNCTS_THEN2 ASSUME_TAC MP_TAC)) THEN
    ONCE_REWRITE_TAC[GSYM CONTRAPOS_THM] THEN
    REWRITE_TAC[CARD_NOT_LT; INFINITE] THEN
    ASM_MESON_TAC[CARD_LE_FINITE; CARD_MUL_FINITE];
    ASM_MESON_TAC[INFINITE; CARD_MUL_ABSORB_LE; CARD_LET_TRANS]]);;

let CARD_MUL_LT_INFINITE = prove
 (`!s:A->bool t:B->bool u. s <_c u /\ t <_c u /\ INFINITE u ==> s *_c t <_c u`,
  REPEAT GEN_TAC THEN
  DISJ_CASES_TAC(ISPECL [`s:A->bool`; `t:B->bool`] CARD_LE_TOTAL) THENL
   [ASM_MESON_TAC[CARD_MUL_SYM; CARD_MUL_LT_LEMMA];
    STRIP_TAC THEN TRANS_TAC CARD_LET_TRANS `t:B->bool *_c s:A->bool` THEN
    ASM_MESON_TAC[CARD_EQ_IMP_LE; CARD_MUL_SYM; CARD_MUL_LT_LEMMA]]);;

(* ------------------------------------------------------------------------- *)
(* Cantor's theorem.                                                         *)
(* ------------------------------------------------------------------------- *)

let CANTOR_THM = prove
 (`!s:A->bool. s <_c {t | t SUBSET s}`,
  GEN_TAC THEN REWRITE_TAC[lt_c] THEN CONJ_TAC THENL
   [REWRITE_TAC[le_c] THEN EXISTS_TAC `(=):A->A->bool` THEN
    REWRITE_TAC[FUN_EQ_THM; IN_ELIM_THM; SUBSET; IN] THEN MESON_TAC[];
    REWRITE_TAC[LE_C; IN_ELIM_THM; SURJECTIVE_RIGHT_INVERSE] THEN
    REWRITE_TAC[NOT_EXISTS_THM] THEN X_GEN_TAC `g:A->(A->bool)` THEN
    DISCH_THEN(MP_TAC o SPEC `\x:A. s(x) /\ ~(g x x)`) THEN
    REWRITE_TAC[SUBSET; IN; FUN_EQ_THM] THEN MESON_TAC[]]);;

let CANTOR_THM_UNIV = prove
 (`(UNIV:A->bool) <_c (UNIV:(A->bool)->bool)`,
  MP_TAC(ISPEC `UNIV:A->bool` CANTOR_THM) THEN
  MATCH_MP_TAC EQ_IMP THEN AP_TERM_TAC THEN
  REWRITE_TAC[EXTENSION; SUBSET; IN_UNIV; IN_ELIM_THM]);;

(* ------------------------------------------------------------------------- *)
(* Lemmas about countability.                                                *)
(* ------------------------------------------------------------------------- *)

let NUM_COUNTABLE = prove
 (`COUNTABLE(:num)`,
  REWRITE_TAC[COUNTABLE; ge_c; CARD_LE_REFL]);;

let COUNTABLE_ALT = prove
 (`!s. COUNTABLE s <=> s <=_c (:num)`,
  REWRITE_TAC[COUNTABLE; ge_c]);;

let COUNTABLE_CASES = prove
 (`!s. COUNTABLE s <=> FINITE s \/ s =_c (:num)`,
  REWRITE_TAC[COUNTABLE_ALT; FINITE_CARD_LT; CARD_LE_LT]);;

let CARD_LE_COUNTABLE = prove
 (`!s t:A->bool. COUNTABLE t /\ s <=_c t ==> COUNTABLE s`,
  REWRITE_TAC[COUNTABLE; ge_c] THEN REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `t:A->bool` THEN ASM_REWRITE_TAC[]);;

let CARD_EQ_COUNTABLE = prove
 (`!s t:A->bool. COUNTABLE t /\ s =_c t ==> COUNTABLE s`,
  REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN MESON_TAC[CARD_LE_COUNTABLE]);;

let CARD_COUNTABLE_CONG = prove
 (`!s t. s =_c t ==> (COUNTABLE s <=> COUNTABLE t)`,
  REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN MESON_TAC[CARD_LE_COUNTABLE]);;

let COUNTABLE_SUBSET = prove
 (`!s t:A->bool. COUNTABLE t /\ s SUBSET t ==> COUNTABLE s`,
  REWRITE_TAC[COUNTABLE; ge_c] THEN REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `t:A->bool` THEN
  ASM_SIMP_TAC[CARD_LE_SUBSET]);;

let COUNTABLE_RESTRICT = prove
 (`!s P. COUNTABLE s ==> COUNTABLE {x | x IN s /\ P x}`,
  REPEAT GEN_TAC THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] COUNTABLE_SUBSET) THEN
  SET_TAC[]);;

let COUNTABLE_SUBSET_NUM = prove
 (`!s:num->bool. COUNTABLE s`,
  MESON_TAC[NUM_COUNTABLE; COUNTABLE_SUBSET; SUBSET_UNIV]);;

let FINITE_IMP_COUNTABLE = prove
 (`!s. FINITE s ==> COUNTABLE s`,
  SIMP_TAC[FINITE_CARD_LT; lt_c; COUNTABLE; ge_c]);;

let COUNTABLE_IMAGE = prove
 (`!f:A->B s. COUNTABLE s ==> COUNTABLE (IMAGE f s)`,
  REWRITE_TAC[COUNTABLE; ge_c] THEN REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `s:A->bool` THEN
  ASM_SIMP_TAC[CARD_LE_IMAGE]);;

let COUNTABLE_IMAGE_INJ_GENERAL = prove
 (`!(f:A->B) A s.
        (!x y. x IN s /\ y IN s /\ f(x) = f(y) ==> x = y) /\
        COUNTABLE A
        ==> COUNTABLE {x | x IN s /\ f(x) IN A}`,
  REPEAT STRIP_TAC THEN
  FIRST_X_ASSUM(MP_TAC o GEN_REWRITE_RULE I [INJECTIVE_ON_LEFT_INVERSE]) THEN
  DISCH_THEN(X_CHOOSE_TAC `g:B->A`) THEN
  MATCH_MP_TAC COUNTABLE_SUBSET THEN EXISTS_TAC `IMAGE (g:B->A) A` THEN
  ASM_SIMP_TAC[COUNTABLE_IMAGE] THEN ASM SET_TAC[]);;

let COUNTABLE_IMAGE_INJ_EQ = prove
 (`!(f:A->B) s.
        (!x y. x IN s /\ y IN s /\ (f(x) = f(y)) ==> (x = y))
        ==> (COUNTABLE(IMAGE f s) <=> COUNTABLE s)`,
  REPEAT STRIP_TAC THEN EQ_TAC THEN ASM_SIMP_TAC[COUNTABLE_IMAGE] THEN
  POP_ASSUM MP_TAC THEN REWRITE_TAC[IMP_IMP] THEN
  DISCH_THEN(MP_TAC o MATCH_MP COUNTABLE_IMAGE_INJ_GENERAL) THEN
  MATCH_MP_TAC EQ_IMP THEN AP_TERM_TAC THEN SET_TAC[]);;

let COUNTABLE_IMAGE_INJ = prove
 (`!(f:A->B) A.
        (!x y. (f(x) = f(y)) ==> (x = y)) /\
         COUNTABLE A
         ==> COUNTABLE {x | f(x) IN A}`,
  REPEAT GEN_TAC THEN
  MP_TAC(SPECL [`f:A->B`; `A:B->bool`; `UNIV:A->bool`]
    COUNTABLE_IMAGE_INJ_GENERAL) THEN REWRITE_TAC[IN_UNIV]);;

let COUNTABLE_EMPTY = prove
 (`COUNTABLE {}`,
  SIMP_TAC[FINITE_IMP_COUNTABLE; FINITE_RULES]);;

let COUNTABLE_INTER = prove
 (`!s t. COUNTABLE s \/ COUNTABLE t ==> COUNTABLE (s INTER t)`,
  REWRITE_TAC[TAUT `(a \/ b ==> c) <=> (a ==> c) /\ (b ==> c)`] THEN
  REPEAT GEN_TAC THEN CONJ_TAC THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] COUNTABLE_SUBSET) THEN
  SET_TAC[]);;

let COUNTABLE_UNION_IMP = prove
 (`!s t:A->bool. COUNTABLE s /\ COUNTABLE t ==> COUNTABLE(s UNION t)`,
  REWRITE_TAC[COUNTABLE; ge_c] THEN REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `(s:A->bool) +_c (t:A->bool)` THEN
  ASM_SIMP_TAC[CARD_ADD2_ABSORB_LE; num_INFINITE; UNION_LE_ADD_C]);;

let COUNTABLE_UNION = prove
 (`!s t:A->bool. COUNTABLE(s UNION t) <=> COUNTABLE s /\ COUNTABLE t`,
  REPEAT GEN_TAC THEN EQ_TAC THEN REWRITE_TAC[COUNTABLE_UNION_IMP] THEN
  DISCH_THEN(fun th -> CONJ_TAC THEN MP_TAC th) THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] COUNTABLE_SUBSET) THEN
  SET_TAC[]);;

let COUNTABLE_SING = prove
 (`!x. COUNTABLE {x}`,
  SIMP_TAC[FINITE_IMP_COUNTABLE; FINITE_SING]);;

let COUNTABLE_INSERT = prove
 (`!x s. COUNTABLE(x INSERT s) <=> COUNTABLE s`,
  ONCE_REWRITE_TAC[SET_RULE `x INSERT s = {x} UNION s`] THEN
  REWRITE_TAC[COUNTABLE_UNION; COUNTABLE_SING]);;

let COUNTABLE_DELETE = prove
 (`!x:A s. COUNTABLE(s DELETE x) <=> COUNTABLE s`,
  REPEAT GEN_TAC THEN ASM_CASES_TAC `(x:A) IN s` THEN
  ASM_SIMP_TAC[SET_RULE `~(x IN s) ==> s DELETE x = s`] THEN
  MATCH_MP_TAC EQ_TRANS THEN
  EXISTS_TAC `COUNTABLE((x:A) INSERT (s DELETE x))` THEN CONJ_TAC THENL
   [REWRITE_TAC[COUNTABLE_INSERT]; AP_TERM_TAC THEN ASM SET_TAC[]]);;

let COUNTABLE_DIFF_FINITE = prove
 (`!s t. FINITE s ==> (COUNTABLE(t DIFF s) <=> COUNTABLE t)`,
  REWRITE_TAC[RIGHT_FORALL_IMP_THM] THEN
  MATCH_MP_TAC FINITE_INDUCT_STRONG THEN
  SIMP_TAC[DIFF_EMPTY; SET_RULE `s DIFF (x INSERT t) = (s DIFF t) DELETE x`;
           COUNTABLE_DELETE]);;

let COUNTABLE_CROSS = prove
 (`!s t. COUNTABLE s /\ COUNTABLE t ==> COUNTABLE(s CROSS t)`,
  REWRITE_TAC[COUNTABLE; ge_c; CROSS; GSYM mul_c] THEN
  SIMP_TAC[CARD_MUL2_ABSORB_LE; num_INFINITE]);;

let COUNTABLE_AS_IMAGE_SUBSET = prove
 (`!s. COUNTABLE s ==> ?f. s SUBSET (IMAGE f (:num))`,
  REWRITE_TAC[COUNTABLE; ge_c; LE_C; SUBSET; IN_IMAGE] THEN MESON_TAC[]);;

let COUNTABLE_AS_IMAGE_SUBSET_EQ = prove
 (`!s:A->bool. COUNTABLE s <=> ?f. s SUBSET (IMAGE f (:num))`,
  REWRITE_TAC[COUNTABLE; ge_c; LE_C; SUBSET; IN_IMAGE] THEN MESON_TAC[]);;

let COUNTABLE_AS_IMAGE = prove
 (`!s:A->bool. COUNTABLE s /\ ~(s = {}) ==> ?f. s = IMAGE f (:num)`,
  REPEAT STRIP_TAC THEN FIRST_X_ASSUM(X_CHOOSE_TAC `a:A` o
    GEN_REWRITE_RULE I [GSYM MEMBER_NOT_EMPTY]) THEN
  FIRST_X_ASSUM(MP_TAC o MATCH_MP COUNTABLE_AS_IMAGE_SUBSET) THEN
  DISCH_THEN(X_CHOOSE_TAC `f:num->A`) THEN
  EXISTS_TAC `\n. if (f:num->A) n IN s then f n else a` THEN
  ASM SET_TAC[]);;

let FORALL_COUNTABLE_AS_IMAGE = prove
 (`(!d. COUNTABLE d ==> P d) <=> P {} /\ (!f. P(IMAGE f (:num)))`,
  MESON_TAC[COUNTABLE_AS_IMAGE; COUNTABLE_IMAGE; NUM_COUNTABLE;
            COUNTABLE_EMPTY]);;

let COUNTABLE_AS_INJECTIVE_IMAGE = prove
 (`!s. COUNTABLE s /\ INFINITE s
       ==> ?f. s = IMAGE f (:num) /\ (!m n. f(m) = f(n) ==> m = n)`,
  GEN_TAC THEN ONCE_REWRITE_TAC[CONJ_SYM] THEN
  REWRITE_TAC[INFINITE_CARD_LE; COUNTABLE; ge_c] THEN
  REWRITE_TAC[CARD_LE_ANTISYM; eq_c] THEN
  MATCH_MP_TAC MONO_EXISTS THEN SET_TAC[]);;

let COUNTABLE_UNIONS = prove
 (`!A:(A->bool)->bool.
        COUNTABLE A /\ (!s. s IN A ==> COUNTABLE s)
        ==> COUNTABLE (UNIONS A)`,
  GEN_TAC THEN
  GEN_REWRITE_TAC (LAND_CONV o TOP_DEPTH_CONV)
   [COUNTABLE_AS_IMAGE_SUBSET_EQ] THEN
  DISCH_THEN(CONJUNCTS_THEN2 (X_CHOOSE_TAC `f:num->A->bool`) MP_TAC) THEN
  GEN_REWRITE_TAC (LAND_CONV o BINDER_CONV) [RIGHT_IMP_EXISTS_THM] THEN
  REWRITE_TAC[SKOLEM_THM] THEN
  DISCH_THEN(X_CHOOSE_TAC `g:(A->bool)->num->A`) THEN
  MATCH_MP_TAC COUNTABLE_SUBSET THEN
  EXISTS_TAC `IMAGE (\(m,n). (g:(A->bool)->num->A) ((f:num->A->bool) m) n)
                    ((:num) CROSS (:num))` THEN
  ASM_SIMP_TAC[COUNTABLE_IMAGE; COUNTABLE_CROSS; NUM_COUNTABLE] THEN
  REWRITE_TAC[SUBSET; FORALL_IN_UNIONS] THEN
  REWRITE_TAC[IN_IMAGE; EXISTS_PAIR_THM; IN_CROSS; IN_UNIV] THEN
  ASM SET_TAC[]);;

let COUNTABLE_PRODUCT_DEPENDENT = prove
 (`!f:A->B->C s t.
        COUNTABLE s /\ (!x. x IN s ==> COUNTABLE(t x))
        ==> COUNTABLE {f x y | x IN s /\ y IN (t x)}`,
  REPEAT GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN `{(f:A->B->C) x y | x IN s /\ y IN (t x)} =
                IMAGE (\(x,y). f x y) {(x,y) | x IN s /\ y IN (t x)}`
  SUBST1_TAC THENL
   [REWRITE_TAC[EXTENSION; IN_IMAGE; EXISTS_PAIR_THM; IN_ELIM_PAIR_THM] THEN
    SET_TAC[];
    MATCH_MP_TAC COUNTABLE_IMAGE THEN POP_ASSUM MP_TAC] THEN
  GEN_REWRITE_TAC (LAND_CONV o TOP_DEPTH_CONV)
   [COUNTABLE_AS_IMAGE_SUBSET_EQ] THEN
  DISCH_THEN(CONJUNCTS_THEN2 (X_CHOOSE_TAC `f:num->A`) MP_TAC) THEN
  GEN_REWRITE_TAC (LAND_CONV o BINDER_CONV) [RIGHT_IMP_EXISTS_THM] THEN
  REWRITE_TAC[SKOLEM_THM] THEN
  DISCH_THEN(X_CHOOSE_TAC `g:A->num->B`) THEN
  MATCH_MP_TAC COUNTABLE_SUBSET THEN
  EXISTS_TAC `IMAGE (\(m,n). (f:num->A) m,(g:A->num->B)(f m) n)
                    ((:num) CROSS (:num))` THEN
  ASM_SIMP_TAC[COUNTABLE_IMAGE; COUNTABLE_CROSS; NUM_COUNTABLE] THEN
  REWRITE_TAC[SUBSET; FORALL_IN_UNIONS] THEN
  REWRITE_TAC[IN_IMAGE; FORALL_PAIR_THM; IN_ELIM_PAIR_THM;
              EXISTS_PAIR_THM; IN_CROSS; IN_UNIV] THEN
  ASM SET_TAC[]);;

let COUNTABLE_CARD_MUL = prove
 (`!s:A->bool t:B->bool. COUNTABLE s /\ COUNTABLE t ==> COUNTABLE(s *_c t)`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[mul_c] THEN
  ASM_SIMP_TAC[COUNTABLE_PRODUCT_DEPENDENT]);;

let COUNTABLE_CARD_MUL_EQ = prove
 (`!s:A->bool t:B->bool.
        COUNTABLE(s *_c t) <=> s = {} \/ t = {} \/ COUNTABLE s /\ COUNTABLE t`,
  REPEAT GEN_TAC THEN REWRITE_TAC[mul_c] THEN
  MAP_EVERY ASM_CASES_TAC [`s:A->bool = {}`; `t:B->bool = {}`] THEN
  ASM_REWRITE_TAC[COUNTABLE_EMPTY; EMPTY_GSPEC; NOT_IN_EMPTY;
                  SET_RULE `{x,y | F} = {}`] THEN
  EQ_TAC THEN SIMP_TAC[REWRITE_RULE[mul_c] COUNTABLE_CARD_MUL] THEN
  REPEAT STRIP_TAC THEN MATCH_MP_TAC COUNTABLE_SUBSET THENL
   [EXISTS_TAC `IMAGE FST ((s:A->bool) *_c (t:B->bool))`;
    EXISTS_TAC `IMAGE SND ((s:A->bool) *_c (t:B->bool))`] THEN
  ASM_SIMP_TAC[COUNTABLE_IMAGE; mul_c; SUBSET; IN_IMAGE; EXISTS_PAIR_THM] THEN
  REWRITE_TAC[IN_ELIM_PAIR_THM] THEN ASM SET_TAC[]);;

let CARD_EQ_PCROSS = prove
 (`!s:A^M->bool t:A^N->bool. s PCROSS t =_c s *_c t`,
  REPEAT GEN_TAC THEN REWRITE_TAC[EQ_C_BIJECTIONS; mul_c] THEN
  EXISTS_TAC `\z:A^(M,N)finite_sum. fstcart z,sndcart z` THEN
  EXISTS_TAC `\(x:A^M,y:A^N). pastecart x y` THEN
  REWRITE_TAC[FORALL_IN_GSPEC; PASTECART_IN_PCROSS] THEN
  REWRITE_TAC[IN_ELIM_PAIR_THM; PASTECART_FST_SND] THEN
  REWRITE_TAC[FORALL_IN_PCROSS; FSTCART_PASTECART; SNDCART_PASTECART]);;

let COUNTABLE_PCROSS_EQ = prove
 (`!s:A^M->bool t:A^N->bool.
        COUNTABLE(s PCROSS t) <=>
        s = {} \/ t = {} \/ COUNTABLE s /\ COUNTABLE t`,
  REPEAT GEN_TAC THEN MATCH_MP_TAC EQ_TRANS THEN
  EXISTS_TAC `COUNTABLE((s:A^M->bool) *_c (t:A^N->bool))` THEN CONJ_TAC THENL
   [MATCH_MP_TAC CARD_COUNTABLE_CONG THEN REWRITE_TAC[CARD_EQ_PCROSS];
    REWRITE_TAC[COUNTABLE_CARD_MUL_EQ]]);;

let COUNTABLE_PCROSS = prove
 (`!s:A^M->bool t:A^N->bool.
        COUNTABLE s /\ COUNTABLE t ==> COUNTABLE(s PCROSS t)`,
  SIMP_TAC[COUNTABLE_PCROSS_EQ]);;

let COUNTABLE_CART = prove
 (`!P. (!i. 1 <= i /\ i <= dimindex(:N) ==> COUNTABLE {x | P i x})
       ==> COUNTABLE {v:A^N | !i. 1 <= i /\ i <= dimindex(:N) ==> P i (v$i)}`,
  GEN_TAC THEN DISCH_TAC THEN
  SUBGOAL_THEN
   `!n. n <= dimindex(:N)
        ==> COUNTABLE {v:A^N | (!i. 1 <= i /\ i <= dimindex(:N) /\ i <= n
                                 ==> P i (v$i)) /\
                            (!i. 1 <= i /\ i <= dimindex(:N) /\ n < i
                                 ==> v$i = @x. F)}`
   (MP_TAC o SPEC `dimindex(:N)`) THEN REWRITE_TAC[LE_REFL; LET_ANTISYM] THEN
  INDUCT_TAC THENL
   [REWRITE_TAC[ARITH_RULE `1 <= i /\ i <= n /\ i <= 0 <=> F`] THEN
    SIMP_TAC[ARITH_RULE `1 <= i /\ i <= n /\ 0 < i <=> 1 <= i /\ i <= n`] THEN
    SUBGOAL_THEN
     `{v | !i. 1 <= i /\ i <= dimindex (:N) ==> v$i = (@x. F)} =
      {(lambda i. @x. F):A^N}`
     (fun th -> SIMP_TAC[COUNTABLE_SING;th]) THEN
    SIMP_TAC[EXTENSION; IN_SING; IN_ELIM_THM; CART_EQ; LAMBDA_BETA];
    ALL_TAC] THEN
  DISCH_TAC THEN
  MATCH_MP_TAC COUNTABLE_SUBSET THEN EXISTS_TAC
   `IMAGE (\(x:A,v:A^N). (lambda i. if i = SUC n then x else v$i):A^N)
          {x,v | x IN {x:A | P (SUC n) x} /\
                 v IN {v:A^N | (!i. 1 <= i /\ i <= dimindex(:N) /\ i <= n
                                ==> P i (v$i)) /\
                           (!i. 1 <= i /\ i <= dimindex (:N) /\ n < i
                                ==> v$i = (@x. F))}}` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC COUNTABLE_IMAGE THEN
    ASM_SIMP_TAC[REWRITE_RULE[CROSS] COUNTABLE_CROSS; ARITH_RULE `1 <= SUC n`;
                 ARITH_RULE `SUC n <= m ==> n <= m`];
    ALL_TAC] THEN
  REWRITE_TAC[SUBSET; IN_IMAGE; IN_ELIM_PAIR_THM; EXISTS_PAIR_THM] THEN
  X_GEN_TAC `v:A^N` THEN REWRITE_TAC[IN_ELIM_THM] THEN
  STRIP_TAC THEN EXISTS_TAC `(v:A^N)$(SUC n)` THEN
  EXISTS_TAC `(lambda i. if i = SUC n then @x. F else (v:A^N)$i):A^N` THEN
  SIMP_TAC[CART_EQ; LAMBDA_BETA; ARITH_RULE `i <= n ==> ~(i = SUC n)`] THEN
  ASM_MESON_TAC[LE; ARITH_RULE `1 <= SUC n`;
                ARITH_RULE `n < i /\ ~(i = SUC n) ==> SUC n < i`]);;

let EXISTS_COUNTABLE_SUBSET_IMAGE_INJ = prove
 (`!P f s.
    (?t. COUNTABLE t /\ t SUBSET IMAGE f s /\ P t) <=>
    (?t. COUNTABLE t /\ t SUBSET s /\
         (!x y. x IN t /\ y IN t ==> (f x = f y <=> x = y)) /\
         P (IMAGE f t))`,
  ONCE_REWRITE_TAC[TAUT `p /\ q /\ r <=> q /\ p /\ r`] THEN
  REPEAT GEN_TAC THEN REWRITE_TAC[EXISTS_SUBSET_IMAGE_INJ] THEN
  AP_TERM_TAC THEN ABS_TAC THEN MESON_TAC[COUNTABLE_IMAGE_INJ_EQ]);;

let FORALL_COUNTABLE_SUBSET_IMAGE_INJ = prove
 (`!P f s. (!t. COUNTABLE t /\ t SUBSET IMAGE f s ==> P t) <=>
           (!t. COUNTABLE t /\ t SUBSET s /\
                (!x y. x IN t /\ y IN t ==> (f x = f y <=> x = y))
                 ==> P(IMAGE f t))`,
  REPEAT GEN_TAC THEN
  ONCE_REWRITE_TAC[MESON[] `(!t. p t) <=> ~(?t. ~p t)`] THEN
  REWRITE_TAC[NOT_IMP; EXISTS_COUNTABLE_SUBSET_IMAGE_INJ; GSYM CONJ_ASSOC]);;

let EXISTS_COUNTABLE_SUBSET_IMAGE = prove
 (`!P f s.
    (?t. COUNTABLE t /\ t SUBSET IMAGE f s /\ P t) <=>
    (?t. COUNTABLE t /\ t SUBSET s /\ P (IMAGE f t))`,
  REPEAT GEN_TAC THEN EQ_TAC THENL
   [REWRITE_TAC[EXISTS_COUNTABLE_SUBSET_IMAGE_INJ] THEN MESON_TAC[];
    MESON_TAC[COUNTABLE_IMAGE; IMAGE_SUBSET]]);;

let FORALL_COUNTABLE_SUBSET_IMAGE = prove
 (`!P f s. (!t. COUNTABLE t /\ t SUBSET IMAGE f s ==> P t) <=>
           (!t. COUNTABLE t /\ t SUBSET s ==> P(IMAGE f t))`,
  REPEAT GEN_TAC THEN
  ONCE_REWRITE_TAC[MESON[] `(!x. P x) <=> ~(?x. ~P x)`] THEN
  REWRITE_TAC[NOT_IMP; GSYM CONJ_ASSOC; EXISTS_COUNTABLE_SUBSET_IMAGE]);;

let COUNTABLE_SUBSET_IMAGE = prove
 (`!f:A->B s t.
        COUNTABLE(t) /\ t SUBSET (IMAGE f s) <=>
        ?s'. COUNTABLE s' /\ s' SUBSET s /\ (t = IMAGE f s')`,
  REPEAT GEN_TAC THEN EQ_TAC THENL
   [ALL_TAC; ASM_MESON_TAC[COUNTABLE_IMAGE; IMAGE_SUBSET]] THEN
  SPEC_TAC(`t:B->bool`,`t:B->bool`) THEN
  REWRITE_TAC[FORALL_COUNTABLE_SUBSET_IMAGE] THEN MESON_TAC[]);;

(* ------------------------------------------------------------------------- *)
(* Cardinality of infinite list and cartesian product types.                 *)
(* ------------------------------------------------------------------------- *)

let CARD_EQ_LIST_GEN = prove
 (`!s:A->bool. INFINITE(s) ==> {l | !x. MEM x l ==> x IN s} =_c s`,
  GEN_TAC THEN DISCH_TAC THEN
  REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN CONJ_TAC THENL
   [ALL_TAC;
    REWRITE_TAC[le_c; IN_UNIV] THEN
    EXISTS_TAC `\x:A. [x]` THEN SIMP_TAC[CONS_11; IN_ELIM_THM; MEM]] THEN
  TRANS_TAC CARD_LE_TRANS `(:num) *_c (s:A->bool)` THEN CONJ_TAC THENL
   [ALL_TAC;
    MATCH_MP_TAC CARD_MUL2_ABSORB_LE THEN
    ASM_REWRITE_TAC[GSYM INFINITE_CARD_LE; CARD_LE_REFL]] THEN
  SUBGOAL_THEN `s *_c s <=_c (s:A->bool)` MP_TAC THENL
   [MATCH_MP_TAC CARD_MUL2_ABSORB_LE THEN ASM_REWRITE_TAC[CARD_LE_REFL];
    ALL_TAC] THEN
  REWRITE_TAC[le_c; mul_c; FORALL_PAIR_THM; IN_ELIM_PAIR_THM; PAIR_EQ] THEN
  REWRITE_TAC[IN_UNIV; LEFT_IMP_EXISTS_THM] THEN
  GEN_REWRITE_TAC I [FORALL_CURRY] THEN
  X_GEN_TAC `pair:A->A->A` THEN REWRITE_TAC[IN_ELIM_THM] THEN STRIP_TAC THEN
  SUBGOAL_THEN `?b:A. b IN s` CHOOSE_TAC THENL
   [ASM_MESON_TAC[INFINITE; FINITE_EMPTY; MEMBER_NOT_EMPTY]; ALL_TAC] THEN
  EXISTS_TAC `\l. LENGTH l,ITLIST (pair:A->A->A) l b` THEN
  REWRITE_TAC[PAIR_EQ; RIGHT_EXISTS_AND_THM; GSYM EXISTS_REFL] THEN
  SUBGOAL_THEN
   `!l:A list. (!x. MEM x l ==> x IN s) ==> (ITLIST pair l b) IN s`
  ASSUME_TAC THENL
   [LIST_INDUCT_TAC THEN ASM_REWRITE_TAC[MEM; ITLIST] THEN ASM_MESON_TAC[];
    CONJ_TAC THENL [ASM_MESON_TAC[]; ALL_TAC]] THEN
  ONCE_REWRITE_TAC[SWAP_FORALL_THM] THEN
  LIST_INDUCT_TAC THEN SIMP_TAC[LENGTH_EQ_NIL; LENGTH] THEN
  LIST_INDUCT_TAC THEN REWRITE_TAC[LENGTH; NOT_SUC] THEN
  REWRITE_TAC[ITLIST; SUC_INJ; MEM; CONS_11] THEN
  REPEAT STRIP_TAC THENL [ALL_TAC; FIRST_X_ASSUM MATCH_MP_TAC] THEN
  ASM_MESON_TAC[]);;

let CARD_EQ_LIST = prove
 (`INFINITE(:A) ==> (:A list) =_c (:A)`,
  DISCH_THEN(MP_TAC o MATCH_MP CARD_EQ_LIST_GEN) THEN
  REWRITE_TAC[IN_UNIV; SET_RULE `{x | T} = UNIV`]);;

let CARD_EQ_CART = prove
 (`INFINITE(:A) ==> (:A^N) =_c (:A)`,
  DISCH_TAC THEN REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN CONJ_TAC THENL
   [ALL_TAC;
    REWRITE_TAC[le_c; IN_UNIV] THEN
    EXISTS_TAC `(\x. lambda i. x):A->A^N` THEN
    SIMP_TAC[CART_EQ; LAMBDA_BETA] THEN
    MESON_TAC[LE_REFL; DIMINDEX_GE_1]] THEN
  TRANS_TAC CARD_LE_TRANS `(:A list)` THEN
  ASM_SIMP_TAC[CARD_EQ_LIST; CARD_EQ_IMP_LE] THEN REWRITE_TAC[LE_C] THEN
  EXISTS_TAC `(\l. lambda i. EL i l):(A)list->A^N` THEN
  ASM_SIMP_TAC[CART_EQ; IN_UNIV; LAMBDA_BETA] THEN X_GEN_TAC `x:A^N` THEN
  SUBGOAL_THEN `!n f. ?l. !i. i < n ==> EL i l:A = f i` MP_TAC THENL
   [INDUCT_TAC THEN REWRITE_TAC[CONJUNCT1 LT] THEN X_GEN_TAC `f:num->A` THEN
    FIRST_X_ASSUM(MP_TAC o SPEC `\i. (f:num->A)(SUC i)`) THEN
    REWRITE_TAC[LEFT_IMP_EXISTS_THM] THEN X_GEN_TAC `l:A list` THEN
    DISCH_TAC THEN EXISTS_TAC `CONS ((f:num->A) 0) l` THEN
    INDUCT_TAC THEN ASM_SIMP_TAC[EL; HD; TL; LT_SUC];
    DISCH_THEN(MP_TAC o SPECL [`dimindex(:N)+1`; `\i. (x:A^N)$i`]) THEN
    REWRITE_TAC[LEFT_IMP_EXISTS_THM; ARITH_RULE `i < n + 1 <=> i <= n`] THEN
    MESON_TAC[]]);;

(* ------------------------------------------------------------------------- *)
(* Cardinality of the reals. This is done in a rather laborious way to avoid *)
(* any dependence on the theories of analysis.                               *)
(* ------------------------------------------------------------------------- *)

let CARD_EQ_REAL = prove
 (`(:real) =_c (:num->bool)`,
  let lemma = prove
   (`!s m n. sum (s INTER (m..n)) (\i. inv(&3 pow i)) < &3 / &2 / &3 pow m`,
    REPEAT GEN_TAC THEN MATCH_MP_TAC REAL_LET_TRANS THEN
    EXISTS_TAC `sum (m..n) (\i. inv(&3 pow i))` THEN CONJ_TAC THENL
     [MATCH_MP_TAC SUM_SUBSET_SIMPLE THEN
      SIMP_TAC[FINITE_NUMSEG; INTER_SUBSET; REAL_LE_INV_EQ;
               REAL_POW_LE; REAL_POS];
      WF_INDUCT_TAC `n - m:num` THEN
      ASM_CASES_TAC `m:num <= n` THENL
       [ASM_SIMP_TAC[SUM_CLAUSES_LEFT] THEN ASM_CASES_TAC `m + 1 <= n` THENL
         [FIRST_X_ASSUM(MP_TAC o SPECL [`n:num`; `SUC m`]) THEN
          ANTS_TAC THENL [ASM_ARITH_TAC; REWRITE_TAC[ADD1; REAL_POW_ADD]] THEN
          MATCH_MP_TAC(REAL_ARITH
           `a + j:real <= k ==> x < j ==> a + x < k`) THEN
          REWRITE_TAC[real_div; REAL_INV_MUL; REAL_POW_1] THEN REAL_ARITH_TAC;
          ALL_TAC];
        ALL_TAC] THEN
      RULE_ASSUM_TAC(REWRITE_RULE[NOT_LE; GSYM NUMSEG_EMPTY]) THEN
      ASM_REWRITE_TAC[SUM_CLAUSES; REAL_ADD_RID] THEN
      REWRITE_TAC[REAL_ARITH `inv x < &3 / &2 / x <=> &0 < inv x`] THEN
      SIMP_TAC[REAL_LT_INV_EQ; REAL_LT_DIV; REAL_POW_LT; REAL_OF_NUM_LT;
               ARITH]]) in
  REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN CONJ_TAC THENL
   [TRANS_TAC CARD_LE_TRANS `(:num) *_c (:num->bool)` THEN CONJ_TAC THENL
     [ALL_TAC;
      MATCH_MP_TAC CARD_MUL2_ABSORB_LE THEN REWRITE_TAC[INFINITE_CARD_LE] THEN
      SIMP_TAC[CANTOR_THM_UNIV; CARD_LT_IMP_LE; CARD_LE_REFL]] THEN
    TRANS_TAC CARD_LE_TRANS `(:num) *_c {x:real | &0 <= x}` THEN CONJ_TAC THENL
     [REWRITE_TAC[LE_C; mul_c; EXISTS_PAIR_THM; IN_ELIM_PAIR_THM; IN_UNIV] THEN
      EXISTS_TAC `\(n,x:real). --(&1) pow n * x` THEN X_GEN_TAC `x:real` THEN
      MATCH_MP_TAC(MESON[] `P 0 \/ P 1 ==> ?n. P n`) THEN
      REWRITE_TAC[OR_EXISTS_THM] THEN EXISTS_TAC `abs x` THEN
      REWRITE_TAC[IN_ELIM_THM] THEN REAL_ARITH_TAC;
      ALL_TAC] THEN
    MATCH_MP_TAC CARD_LE_MUL THEN REWRITE_TAC[CARD_LE_REFL] THEN
    MP_TAC(ISPECL [`(:num)`; `(:num)`] CARD_MUL_ABSORB_LE) THEN
    REWRITE_TAC[CARD_LE_REFL; num_INFINITE] THEN
    REWRITE_TAC[le_c; mul_c; IN_UNIV; FORALL_PAIR_THM; IN_ELIM_PAIR_THM] THEN
    REWRITE_TAC[GSYM FORALL_PAIR_THM; INJECTIVE_LEFT_INVERSE] THEN
    REWRITE_TAC[LEFT_IMP_EXISTS_THM] THEN
    MAP_EVERY X_GEN_TAC [`pair:num#num->num`; `unpair:num->num#num`] THEN
    DISCH_TAC THEN
    EXISTS_TAC `\x:real n:num. &(FST(unpair n)) * x <= &(SND(unpair n))` THEN
    MATCH_MP_TAC REAL_WLOG_LT THEN REWRITE_TAC[IN_ELIM_THM; FUN_EQ_THM] THEN
    CONJ_TAC THENL [REWRITE_TAC[EQ_SYM_EQ; CONJ_ACI]; ALL_TAC] THEN
    MAP_EVERY X_GEN_TAC [`x:real`; `y:real`] THEN REPEAT STRIP_TAC THEN
    FIRST_X_ASSUM(MP_TAC o GENL [`p:num`; `q:num`] o
      SPEC `(pair:num#num->num) (p,q)`) THEN
    ASM_REWRITE_TAC[] THEN MATCH_MP_TAC(TAUT `~p ==> p ==> q`) THEN
    MP_TAC(SPEC `y - x:real` REAL_ARCH) THEN
    ASM_REWRITE_TAC[REAL_SUB_LT; NOT_FORALL_THM] THEN
    DISCH_THEN(MP_TAC o SPEC `&2`) THEN MATCH_MP_TAC MONO_EXISTS THEN
    X_GEN_TAC `p:num` THEN DISCH_TAC THEN
    MP_TAC(ISPEC `&p * x:real` REAL_ARCH_LT) THEN
    GEN_REWRITE_TAC LAND_CONV [num_WOP] THEN MATCH_MP_TAC MONO_EXISTS THEN
    MATCH_MP_TAC num_INDUCTION THEN
    ASM_SIMP_TAC[REAL_LE_MUL; REAL_POS;
      REAL_ARITH `x:real < &0 <=> ~(&0 <= x)`] THEN
    X_GEN_TAC `q:num` THEN REWRITE_TAC[GSYM REAL_OF_NUM_SUC] THEN
    DISCH_THEN(K ALL_TAC) THEN STRIP_TAC THEN
    FIRST_X_ASSUM(MP_TAC o SPEC `q:num`) THEN
    REWRITE_TAC[LT] THEN ASM_REAL_ARITH_TAC;
    REWRITE_TAC[le_c; IN_UNIV] THEN
    EXISTS_TAC `\s:num->bool. sup { sum (s INTER (0..n)) (\i. inv(&3 pow i)) |
                                    n IN (:num) }` THEN
    MAP_EVERY X_GEN_TAC [`x:num->bool`; `y:num->bool`] THEN
    ONCE_REWRITE_TAC[GSYM CONTRAPOS_THM] THEN
    REWRITE_TAC[EXTENSION; NOT_FORALL_THM] THEN
    GEN_REWRITE_TAC LAND_CONV [num_WOP] THEN
    MAP_EVERY (fun w -> SPEC_TAC(w,w)) [`y:num->bool`; `x:num->bool`] THEN
    MATCH_MP_TAC(MESON[IN]
     `((!P Q n. R P Q n <=> R Q P n) /\ (!P Q. S P Q <=> S Q P)) /\
      (!P Q. (?n. n IN P /\ ~(n IN Q) /\ R P Q n) ==> S P Q)
      ==> !P Q. (?n:num. ~(n IN P <=> n IN Q) /\ R P Q n) ==> S P Q`) THEN
    CONJ_TAC THENL [REWRITE_TAC[EQ_SYM_EQ]; REWRITE_TAC[]] THEN
    MAP_EVERY X_GEN_TAC [`x:num->bool`; `y:num->bool`] THEN
    DISCH_THEN(X_CHOOSE_THEN `n:num` STRIP_ASSUME_TAC) THEN
    MATCH_MP_TAC(REAL_ARITH `!z:real. y < z /\ z <= x ==> ~(x = y)`) THEN
    EXISTS_TAC `sum (x INTER (0..n)) (\i. inv(&3 pow i))` THEN CONJ_TAC THENL
     [MATCH_MP_TAC REAL_LET_TRANS THEN EXISTS_TAC
       `sum (y INTER (0..n)) (\i. inv(&3 pow i)) +
        &3 / &2 / &3 pow (SUC n)` THEN
      CONJ_TAC THENL
       [MATCH_MP_TAC REAL_SUP_LE THEN
        CONJ_TAC THENL [SET_TAC[]; REWRITE_TAC[FORALL_IN_GSPEC; IN_UNIV]] THEN
        X_GEN_TAC `p:num` THEN ASM_CASES_TAC `n:num <= p` THENL
         [MATCH_MP_TAC(REAL_ARITH
           `!d. s:real = t + d /\ d <= e ==> s <= t + e`) THEN
          EXISTS_TAC `sum(y INTER (n+1..p)) (\i. inv (&3 pow i))` THEN
          CONJ_TAC THENL
           [ONCE_REWRITE_TAC[INTER_COMM] THEN
            REWRITE_TAC[INTER; SUM_RESTRICT_SET] THEN
            ASM_SIMP_TAC[SUM_COMBINE_R; LE_0];
            SIMP_TAC[ADD1; lemma; REAL_LT_IMP_LE]];
          MATCH_MP_TAC(REAL_ARITH `y:real <= x /\ &0 <= d ==> y <= x + d`) THEN
          SIMP_TAC[REAL_LE_DIV; REAL_POS; REAL_POW_LE] THEN
          MATCH_MP_TAC SUM_SUBSET_SIMPLE THEN
          SIMP_TAC[REAL_LE_INV_EQ; REAL_POW_LE; REAL_POS] THEN
          SIMP_TAC[FINITE_INTER; FINITE_NUMSEG] THEN MATCH_MP_TAC
           (SET_RULE `s SUBSET t ==> u INTER s SUBSET u INTER t`) THEN
          REWRITE_TAC[SUBSET_NUMSEG] THEN ASM_ARITH_TAC];
        ONCE_REWRITE_TAC[INTER_COMM] THEN
        REWRITE_TAC[INTER; SUM_RESTRICT_SET] THEN ASM_CASES_TAC `n = 0` THENL
         [FIRST_X_ASSUM SUBST_ALL_TAC THEN
          ASM_REWRITE_TAC[SUM_SING; NUMSEG_SING; real_pow] THEN REAL_ARITH_TAC;
          ASM_SIMP_TAC[SUM_CLAUSES_RIGHT; LE_1; LE_0; REAL_ADD_RID] THEN
          MATCH_MP_TAC(REAL_ARITH `s:real = t /\ d < e ==> s + d < t + e`) THEN
          CONJ_TAC THENL
           [MATCH_MP_TAC SUM_EQ_NUMSEG THEN
            ASM_SIMP_TAC[ARITH_RULE `~(n = 0) /\ m <= n - 1 ==> m < n`];
            REWRITE_TAC[real_pow; real_div; REAL_INV_MUL; REAL_MUL_ASSOC] THEN
            CONV_TAC REAL_RAT_REDUCE_CONV THEN
            REWRITE_TAC[REAL_ARITH `&1 / &2 * x < x <=> &0 < x`] THEN
            SIMP_TAC[REAL_LT_INV_EQ; REAL_POW_LT; REAL_OF_NUM_LT; ARITH]]]];
      MP_TAC(ISPEC `{ sum (x INTER (0..n)) (\i. inv(&3 pow i)) | n IN (:num) }`
          SUP) THEN REWRITE_TAC[FORALL_IN_GSPEC; IN_UNIV] THEN
      ANTS_TAC THENL [ALL_TAC; SIMP_TAC[]] THEN
      CONJ_TAC THENL [SET_TAC[]; ALL_TAC] THEN
      EXISTS_TAC `&3 / &2 / &3 pow 0` THEN
      SIMP_TAC[lemma; REAL_LT_IMP_LE]]]);;

let UNCOUNTABLE_REAL = prove
 (`~COUNTABLE(:real)`,
  REWRITE_TAC[COUNTABLE; CARD_NOT_LE; ge_c] THEN
  TRANS_TAC CARD_LTE_TRANS `(:num->bool)` THEN
  REWRITE_TAC[CANTOR_THM_UNIV] THEN MATCH_MP_TAC CARD_EQ_IMP_LE THEN
  ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN REWRITE_TAC[CARD_EQ_REAL]);;

let CARD_EQ_REAL_IMP_UNCOUNTABLE = prove
 (`!s. s =_c (:real) ==> ~COUNTABLE s`,
  GEN_TAC THEN STRIP_TAC THEN
  DISCH_THEN(MP_TAC o ISPEC `(:real)` o MATCH_MP
    (REWRITE_RULE[IMP_CONJ] CARD_EQ_COUNTABLE)) THEN
  REWRITE_TAC[UNCOUNTABLE_REAL] THEN ASM_MESON_TAC[CARD_EQ_SYM]);;

let COUNTABLE_IMP_CARD_LT_REAL = prove
 (`!s:A->bool. COUNTABLE s ==> s <_c (:real)`,
  REWRITE_TAC[GSYM CARD_NOT_LE] THEN
  ASM_MESON_TAC[CARD_LE_COUNTABLE; UNCOUNTABLE_REAL]);;

(* ------------------------------------------------------------------------- *)
(* Cardinal exponentiation.                                                  *)
(* ------------------------------------------------------------------------- *)

parse_as_infix("^_c",(24,"left"));;

let exp_c = new_definition
  `s ^_c t = {f:B->A | (!x. x IN t ==> f x IN s) /\
                       (!x. ~(x IN t) ==> f x = @y. F)}`;;

let CARD_EXP_UNIV = prove
 (`(:A) ^_c (:B) = (:B->A)`,
  REWRITE_TAC[exp_c; IN_UNIV] THEN SET_TAC[]);;

let CARD_EXP_GRAPH = prove
 (`!s:A->bool t:B->bool.
        (s ^_c t) =_c {R:B->A->bool | (!x y. R x y ==> x IN t /\ y IN s) /\
                                      (!x. x IN t ==> ?!y. R x y)}`,
  REPEAT GEN_TAC THEN REWRITE_TAC[EQ_C_BIJECTIONS; exp_c; FORALL_IN_GSPEC] THEN
  MAP_EVERY EXISTS_TAC
   [`\f:B->A x y. x IN t /\ f x = y`;
    `\(R:B->A->bool) x. if x IN t then @y. R x y else @y. F`] THEN
  SIMP_TAC[IN_ELIM_THM; FUN_EQ_THM] THEN MESON_TAC[]);;

let CARD_EXP_GRAPH_PAIRED = prove
 (`!s:A->bool t:B->bool.
        (s ^_c t) =_c {R:B#A->bool | (!x y. R(x,y) ==> x IN t /\ y IN s) /\
                                     (!x. x IN t ==> ?!y. R(x,y))}`,
  MP_TAC CARD_EXP_GRAPH THEN
  REPEAT(MATCH_MP_TAC MONO_FORALL THEN GEN_TAC) THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_EQ_TRANS) THEN
  REWRITE_TAC[EQ_C_BIJECTIONS; FORALL_IN_GSPEC] THEN
  MAP_EVERY EXISTS_TAC
   [`\(R:B->A->bool) (x,y). R x y`;
    `\(R:B#A->bool) x y. R(x,y)`] THEN
  REWRITE_TAC[IN_ELIM_THM; FORALL_PAIR_THM; FUN_EQ_THM]);;

let CARD_EXP_0 = prove
 (`!s c:C. (s:A->bool) ^_c ({}:B->bool) =_c {c}`,
  REPEAT GEN_TAC THEN REWRITE_TAC[exp_c; NOT_IN_EMPTY] THEN
  ONCE_REWRITE_TAC[GSYM FUN_EQ_THM] THEN
  REWRITE_TAC[SET_RULE `{x | x = a} = {a}`] THEN
  SIMP_TAC[CARD_EQ_CARD; FINITE_SING; CARD_SING]);;

let CARD_EXP_ZERO = prove
 (`!s:B->bool c:C. ({}:A->bool) ^_c s =_c if s = {} then {c} else {}`,
  REPEAT GEN_TAC THEN REWRITE_TAC[exp_c] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[NOT_IN_EMPTY] THEN
  ASM_SIMP_TAC[SET_RULE `~(s = {}) ==> ~(!x. ~(x IN s))`] THEN
  REWRITE_TAC[CARD_EQ_EMPTY; EMPTY_GSPEC] THEN
  ONCE_REWRITE_TAC[GSYM FUN_EQ_THM] THEN
  REWRITE_TAC[SET_RULE `{x | x = a} = {a}`] THEN
  SIMP_TAC[CARD_EQ_CARD; FINITE_SING; CARD_SING]);;

let CARD_EXP_ADD = prove
 (`!s:A->bool t:B->bool u:C->bool.
        s ^_c (t +_c u) =_c (s ^_c t) *_c (s ^_c u)`,
  REPEAT GEN_TAC THEN
  REWRITE_TAC[add_c; mul_c; exp_c; EQ_C_BIJECTIONS] THEN
  REWRITE_TAC[FORALL_IN_UNION; FORALL_IN_GSPEC] THEN
  MAP_EVERY EXISTS_TAC
   [`\f:B+C->A. (\x. if x IN t then f(INL x) else @x. F),
                (\x. if x IN u then f(INR x) else @x. F)`;
    `\(g:B->A,h:C->A) z. if ?x. x IN t /\ INL x = z
                         then g(@x. x IN t /\ INL x = z)
                         else if ?y. y IN u /\ INR y = z
                         then h(@y. y IN u /\ INR y = z)
                         else @y. F`] THEN
  REWRITE_TAC[IN_ELIM_THM; IN_UNION] THEN
  REWRITE_TAC[injectivity "sum"; distinctness "sum"; PAIR_EQ] THEN
  REWRITE_TAC[ONCE_REWRITE_RULE[CONJ_SYM] UNWIND_THM1; CONJ_ASSOC] THEN
  REWRITE_TAC[FUN_EQ_THM] THEN CONJ_TAC THENL [SIMP_TAC[]; MESON_TAC[]] THEN
  GEN_TAC THEN STRIP_TAC THEN MATCH_MP_TAC sum_INDUCT THEN
  REWRITE_TAC[injectivity "sum"; distinctness "sum"; PAIR_EQ] THEN
  REPEAT STRIP_TAC THEN COND_CASES_TAC THEN ASM_REWRITE_TAC[] THEN
  CONV_TAC SYM_CONV THEN TRY(FIRST_X_ASSUM MATCH_MP_TAC) THEN
  ASM_MESON_TAC[injectivity "sum"; distinctness "sum"]);;

let CARD_EXP_MUL = prove
 (`!s:A->bool t:B->bool u:C->bool.
        s ^_c (t *_c u) =_c (s ^_c t) ^_c u`,
  REPEAT GEN_TAC THEN REWRITE_TAC[mul_c; exp_c; EQ_C_BIJECTIONS] THEN
  MAP_EVERY EXISTS_TAC
   [`\f:B#C->A y. if y IN u then \x. f(x,y) else @x. F`;
    `\f:C->B->A (x,y). if x IN t /\ y IN u then f y x else @x. F`] THEN
  REWRITE_TAC[FORALL_IN_GSPEC; FORALL_PAIR_THM; IN_ELIM_PAIR_THM] THEN
  REWRITE_TAC[FUN_EQ_THM; IN_ELIM_THM; FORALL_PAIR_THM; DE_MORGAN_THM] THEN
  REPEAT STRIP_TAC THEN ASM_SIMP_TAC[] THEN ASM_MESON_TAC[]);;

let CARD_MUL_EXP = prove
 (`!s:A->bool t:B->bool u:C->bool.
        (s *_c t) ^_c u =_c (s ^_c u) *_c (t ^_c u)`,
  REPEAT GEN_TAC THEN REWRITE_TAC[mul_c; exp_c; EQ_C_BIJECTIONS] THEN
  MAP_EVERY EXISTS_TAC
   [`\f:C->A#B. (\x. if x IN u then FST(f x) else @x. F),
                (\x. if x IN u then SND(f x) else @x. F)`;
    `\(g:C->A,h:C->B) x. if x IN u then (g x,h x) else @x. F`] THEN
  REWRITE_TAC[FUN_EQ_THM; FORALL_IN_GSPEC] THEN
  REWRITE_TAC[IN_ELIM_THM; FORALL_PAIR_THM; PAIR_EQ] THEN
  REWRITE_TAC[ONCE_REWRITE_RULE[CONJ_SYM] UNWIND_THM1; CONJ_ASSOC] THEN
  REWRITE_TAC[FUN_EQ_THM] THEN MESON_TAC[PAIR; PAIR_EQ]);;

let CARD_EXP_SING = prove
 (`!s:A->bool b:B. (s ^_c {b}) =_c s`,
  REPEAT GEN_TAC THEN REWRITE_TAC[exp_c; EQ_C_BIJECTIONS] THEN
  REWRITE_TAC[FORALL_IN_INSERT; NOT_IN_EMPTY] THEN
  REWRITE_TAC[IN_ELIM_THM; IN_SING] THEN
  MAP_EVERY EXISTS_TAC
   [`\f:(B->A). f b`; `\x:A y:B. if y = b then x else @y. F`] THEN
  SIMP_TAC[FUN_EQ_THM] THEN MESON_TAC[]);;

let CARD_LE_EXP_LEFT = prove
 (`!s:A->bool s':B->bool t:C->bool. s <=_c s' ==> s ^_c t <=_c s' ^_c t`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c; exp_c] THEN
  DISCH_THEN(X_CHOOSE_TAC `f:A->B`) THEN
  EXISTS_TAC `\(g:C->A) z:C. if z IN t then f(g z):B else @x. F` THEN
  SIMP_TAC[IN_ELIM_THM; FUN_EQ_THM] THEN ASM_MESON_TAC[]);;

let CARD_LE_EXP_RIGHT = prove
 (`!s:A->bool t:B->bool t':C->bool.
      ~(s = {}) /\ t <=_c t' ==> s ^_c t <=_c s ^_c t'`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c; exp_c; GSYM MEMBER_NOT_EMPTY] THEN
  DISCH_THEN(CONJUNCTS_THEN2 (X_CHOOSE_TAC `a:A`)
   (X_CHOOSE_THEN `f:B->C` STRIP_ASSUME_TAC)) THEN
  FIRST_ASSUM(MP_TAC o GEN_REWRITE_RULE I [INJECTIVE_ON_LEFT_INVERSE]) THEN
  DISCH_THEN(X_CHOOSE_TAC `h:C->B`) THEN
  EXISTS_TAC `\g:(B->A) c:C. if c IN t' then if h c IN t then g(h c) else a
                             else @x:A. F` THEN
  SIMP_TAC[IN_ELIM_THM] THEN CONJ_TAC THENL [ASM_MESON_TAC[]; ALL_TAC] THEN
  MAP_EVERY X_GEN_TAC [`k:B->A`; `l:B->A`] THEN
  REWRITE_TAC[FUN_EQ_THM] THEN STRIP_TAC THEN X_GEN_TAC `b:B` THEN
  ASM_CASES_TAC `(b:B) IN t` THEN ASM_SIMP_TAC[] THEN
  FIRST_X_ASSUM(MP_TAC o SPEC `(f:B->C) b`) THEN ASM_MESON_TAC[]);;

let CARD_LE_EXP = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
        ~(s = {}) /\ s <=_c s' /\ t <=_c t' ==> s ^_c t <=_c s' ^_c t'`,
  REPEAT STRIP_TAC THEN
  TRANS_TAC CARD_LE_TRANS `(s:A->bool) ^_c (t':D->bool)` THEN
  ASM_SIMP_TAC[CARD_LE_EXP_RIGHT; CARD_LE_EXP_LEFT]);;

let CARD_EXP_CONG = prove
 (`!s:A->bool s':B->bool t:C->bool t':D->bool.
      s =_c s' /\ t =_c t' ==> s ^_c t =_c s' ^_c t'`,
  REPEAT GEN_TAC THEN ASM_CASES_TAC `t':D->bool = {}` THEN
  ASM_SIMP_TAC[CARD_EQ_EMPTY] THENL
   [REPEAT STRIP_TAC THEN TRANS_TAC CARD_EQ_TRANS `{0}` THEN
    REWRITE_TAC[CARD_EXP_0; ONCE_REWRITE_RULE[CARD_EQ_SYM] CARD_EXP_0];
    ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN
    ASM_CASES_TAC `t:C->bool = {}` THEN
    ASM_REWRITE_TAC[CARD_EQ_EMPTY]] THEN
  ASM_CASES_TAC `s:A->bool = {}` THEN ASM_SIMP_TAC[CARD_EQ_EMPTY] THENL
   [STRIP_TAC THEN MP_TAC(ISPECL [`t:C->bool`; `0`] CARD_EXP_ZERO) THEN
    ASM_REWRITE_TAC[] THEN GEN_REWRITE_TAC LAND_CONV [CARD_EQ_SYM] THEN
    MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ] CARD_EQ_TRANS) THEN
    MP_TAC(INST_TYPE [`:B`,`:A`]
       (ISPECL [`t':D->bool`; `0`] CARD_EXP_ZERO)) THEN
    ASM_REWRITE_TAC[];
    ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN
    ASM_CASES_TAC `s':B->bool = {}` THEN
    ASM_REWRITE_TAC[CARD_EQ_EMPTY] THEN
    ASM_SIMP_TAC[CARD_LE_EXP; GSYM CARD_LE_ANTISYM]]);;

let CARD_EXP_FINITE = prove
 (`!s:A->bool t:B->bool. FINITE s /\ FINITE t ==> FINITE(s ^_c t)`,
  REPEAT GEN_TAC THEN ONCE_REWRITE_TAC[CONJ_SYM] THEN
  DISCH_THEN(MP_TAC o MATCH_MP FINITE_POWERSET o MATCH_MP FINITE_CROSS) THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_FINITE) THEN
  MP_TAC(ISPECL [`s:A->bool`; `t:B->bool`] CARD_EXP_GRAPH_PAIRED) THEN
  DISCH_THEN(MP_TAC o MATCH_MP CARD_EQ_IMP_LE) THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_TRANS) THEN
  MATCH_MP_TAC CARD_LE_SUBSET THEN
  REWRITE_TAC[SUBSET; FORALL_PAIR_THM; IN_CROSS] THEN SET_TAC[]);;

let CARD_EXP_C = prove
 (`!s:A->bool t:B->bool.
        FINITE s /\ FINITE t ==> CARD(s ^_c t) = (CARD s) EXP (CARD t)`,
  REWRITE_TAC[IMP_CONJ; RIGHT_FORALL_IMP_THM] THEN GEN_TAC THEN DISCH_TAC THEN
  MATCH_MP_TAC FINITE_INDUCT_STRONG THEN
  ASM_SIMP_TAC[CARD_CLAUSES; EXP] THEN CONJ_TAC THENL
   [ONCE_REWRITE_TAC[GSYM(ISPEC `0` CARD_SING)] THEN
    MATCH_MP_TAC CARD_EQ_CARD_IMP THEN SIMP_TAC[CARD_EXP_0; FINITE_SING];
    MAP_EVERY X_GEN_TAC [`b:B`; `t:B->bool`] THEN STRIP_TAC] THEN
  TRANS_TAC EQ_TRANS `CARD((s:A->bool) ^_c ({b:B} +_c (t:B->bool)))` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC CARD_EQ_CARD_IMP THEN
    ASM_SIMP_TAC[CARD_EXP_FINITE; CARD_ADD_FINITE; FINITE_SING] THEN
    MATCH_MP_TAC CARD_EXP_CONG THEN REWRITE_TAC[CARD_EQ_REFL] THEN
    ASM_SIMP_TAC[CARD_EQ_CARD; FINITE_INSERT; CARD_ADD_FINITE; FINITE_EMPTY;
                 CARD_ADD_C; CARD_SING; CARD_CLAUSES] THEN
    ARITH_TAC;
    ALL_TAC] THEN
  TRANS_TAC EQ_TRANS
    `CARD(((s:A->bool) ^_c {b:B}) *_c (s ^_c (t:B->bool)))` THEN
  CONJ_TAC THENL
   [MATCH_MP_TAC CARD_EQ_CARD_IMP THEN REWRITE_TAC[CARD_EXP_ADD] THEN
    ASM_SIMP_TAC[CARD_EXP_FINITE; CARD_MUL_FINITE; FINITE_SING];
    ASM_SIMP_TAC[CARD_MUL_C; CARD_EXP_FINITE; FINITE_SING]] THEN
  AP_THM_TAC THEN AP_TERM_TAC THEN
  MATCH_MP_TAC CARD_EQ_CARD_IMP THEN
  ASM_SIMP_TAC[CARD_EXP_SING]);;

let CARD_EXP_POWERSET = prove
 (`!s:A->bool. (:bool) ^_c s =_c {t | t SUBSET s}`,
  GEN_TAC THEN REWRITE_TAC[exp_c; EQ_C_BIJECTIONS; IN_UNIV] THEN
  MAP_EVERY EXISTS_TAC
   [`\P:A->bool. {x | x IN s /\ P x}`;
    `\t x:A. if x IN s then x IN t else @b. F`] THEN
  SIMP_TAC[IN_ELIM_THM] THEN SET_TAC[]);;

let CARD_EXP_CANTOR = prove
 (`!s:A->bool. s <_c (:bool) ^_c s`,
  GEN_TAC THEN
  TRANS_TAC CARD_LTE_TRANS `{t:A->bool | t SUBSET s}` THEN
  REWRITE_TAC[CANTOR_THM] THEN
  MATCH_MP_TAC CARD_EQ_IMP_LE THEN
  ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN REWRITE_TAC[CARD_EXP_POWERSET]);;

let CARD_EXP_ABSORB = prove
 (`!s:A->bool t:B->bool.
        INFINITE t /\ (:bool) <=_c s /\ s <=_c (:bool) ^_c t
        ==> s ^_c t =_c (:bool) ^_c t`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN
  ASM_SIMP_TAC[CARD_LE_EXP_LEFT; CARD_LE_REFL] THEN
  TRANS_TAC CARD_LE_TRANS `((:bool) ^_c t) ^_c (t:B->bool)` THEN
  ASM_SIMP_TAC[CARD_LE_EXP_LEFT] THEN MATCH_MP_TAC CARD_EQ_IMP_LE THEN
  TRANS_TAC CARD_EQ_TRANS `(:bool) ^_c ((t:B->bool) *_c t)` THEN
  SIMP_TAC[ONCE_REWRITE_RULE[CARD_EQ_SYM] CARD_EXP_MUL] THEN
  MATCH_MP_TAC CARD_EXP_CONG THEN
  ASM_SIMP_TAC[CARD_SQUARE_INFINITE; CARD_EQ_REFL]);;

let CARD_EQ_RESTRICTED_POWERSET,CARD_EQ_LIMITED_POWERSET = (CONJ_PAIR o prove)
 (`(!s:A->bool t:B->bool.
        INFINITE s
        ==> { k | k SUBSET s /\ k =_c t} =_c
            (if t <=_c s then s ^_c t else {})) /\
   (!s:A->bool t:B->bool.
        INFINITE s
        ==> if t <=_c s then { k | k SUBSET s /\ k <=_c t} =_c s ^_c t
            else { k | k SUBSET s /\ k <=_c t} =_c (:bool) ^_c s)`,
  let lemma = prove
   (`!s:A->bool t:B->bool u:C->bool.
          s <=_c t /\ t <=_c u /\ u <=_c s
          ==> s =_c u /\ t =_c u`,
    SIMP_TAC[GSYM CARD_LE_ANTISYM] THEN REPEAT STRIP_TAC THENL
     [TRANS_TAC CARD_LE_TRANS `t:B->bool`;
      TRANS_TAC CARD_LE_TRANS `s:A->bool`] THEN
    ASM_SIMP_TAC[]) in
  REWRITE_TAC[AND_FORALL_THM] THEN REPEAT GEN_TAC THEN
  ASM_CASES_TAC `INFINITE(s:A->bool)` THEN ASM_REWRITE_TAC[] THEN
  COND_CASES_TAC THEN ASM_REWRITE_TAC[] THENL
   [ALL_TAC;
    CONJ_TAC THENL
     [REWRITE_TAC[CARD_EQ_EMPTY; EXTENSION; NOT_IN_EMPTY; IN_ELIM_THM] THEN
      X_GEN_TAC `k:A->bool` THEN
      FIRST_X_ASSUM(MP_TAC o check(is_neg o concl)) THEN
      REWRITE_TAC[CONTRAPOS_THM] THEN STRIP_TAC THEN
      TRANS_TAC CARD_LE_TRANS `k:A->bool` THEN
      ASM_SIMP_TAC[CARD_LE_SUBSET] THEN MATCH_MP_TAC CARD_EQ_IMP_LE THEN
      ONCE_REWRITE_TAC[CARD_EQ_SYM] THEN FIRST_ASSUM ACCEPT_TAC;
      TRANS_TAC CARD_EQ_TRANS `{k:A->bool | k SUBSET s}` THEN
      REWRITE_TAC[ONCE_REWRITE_RULE[CARD_EQ_SYM] CARD_EXP_POWERSET] THEN
      MATCH_MP_TAC CARD_EQ_REFL_IMP THEN
      REWRITE_TAC[SET_RULE
       `{x | P x /\ Q x} = {x | P x} <=> !x. P x ==> Q x`] THEN
      X_GEN_TAC `k:A->bool` THEN DISCH_TAC THEN
      TRANS_TAC CARD_LE_TRANS `s:A->bool` THEN
      ASM_SIMP_TAC[CARD_LE_SUBSET] THEN
      ASM_MESON_TAC[CARD_LE_TOTAL]]] THEN
  MATCH_MP_TAC lemma THEN REPEAT CONJ_TAC THENL
   [MATCH_MP_TAC CARD_LE_SUBSET THEN
    SIMP_TAC[SUBSET; IN_ELIM_THM; CARD_EQ_IMP_LE];
    ASM_CASES_TAC `t:B->bool = {}` THENL
     [ASM_REWRITE_TAC[CARD_LE_EMPTY; SING_GSPEC; SET_RULE
       `k SUBSET s /\ k = {} <=> k = {}`] THEN
      MATCH_MP_TAC(ONCE_REWRITE_RULE[CARD_EQ_SYM] CARD_EQ_IMP_LE) THEN
      REWRITE_TAC[CARD_EXP_0];
      ALL_TAC] THEN
    TRANS_TAC CARD_LE_TRANS
     `{k:A->bool | k SUBSET s /\ ~(k = {}) /\ k <=_c (t:B->bool)}` THEN
    CONJ_TAC THENL
     [ALL_TAC;
      GEN_REWRITE_TAC I [LE_C] THEN
      SIMP_TAC[FORALL_IN_GSPEC; IMP_CONJ; LE_C_IMAGE] THEN
      EXISTS_TAC `\f:B->A. IMAGE f t` THEN
      X_GEN_TAC `k:A->bool` THEN STRIP_TAC THEN STRIP_TAC THEN
      DISCH_THEN(X_CHOOSE_THEN `f:B->A` (SUBST_ALL_TAC o SYM)) THEN
      EXISTS_TAC `\y. if y IN t then (f:B->A) y else @y. F` THEN
      ASM_SIMP_TAC[exp_c; IN_ELIM_THM] THEN ASM SET_TAC[]] THEN
    TRANS_TAC CARD_LE_TRANS
     `{{}} UNION
      {k:A->bool | k SUBSET s /\ ~(k = {}) /\ k <=_c (t:B->bool)}` THEN
    CONJ_TAC THENL
     [MATCH_MP_TAC CARD_LE_SUBSET THEN GEN_REWRITE_TAC I [SUBSET] THEN
      REWRITE_TAC[IN_ELIM_THM; IN_UNION; IN_SING] THEN
      X_GEN_TAC `k:A->bool` THEN ASM_CASES_TAC `k:A->bool = {}` THEN
      ASM_REWRITE_TAC[CARD_EMPTY_LE];
      ALL_TAC] THEN
    W(MP_TAC o PART_MATCH lhand UNION_LE_ADD_C o lhand o snd) THEN
    MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_TRANS) THEN
    MATCH_MP_TAC CARD_EQ_IMP_LE THEN MATCH_MP_TAC CARD_ADD_ABSORB THEN
    MATCH_MP_TAC(TAUT `(p ==> q) /\ p ==> p /\ q`) THEN CONJ_TAC THENL
     [DISCH_TAC THEN MATCH_MP_TAC CARD_LE_FINITE_INFINITE THEN
      ASM_REWRITE_TAC[FINITE_SING];
      ALL_TAC] THEN
    UNDISCH_TAC `INFINITE(s:A->bool)` THEN
    MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_INFINITE) THEN
    ONCE_REWRITE_TAC[le_c] THEN EXISTS_TAC `\x:A. {x}` THEN
    SIMP_TAC[SET_RULE `{a} = {b} <=> a = b`; IN_ELIM_THM] THEN
    ASM_SIMP_TAC[SING_SUBSET; NOT_INSERT_EMPTY; CARD_SING_LE];
    TRANS_TAC CARD_LE_TRANS
     `{k | k SUBSET ((t:B->bool) *_c (s:A->bool)) /\ k =_c t}` THEN
    CONJ_TAC THENL
     [MP_TAC(ISPECL [`s:A->bool`; `t:B->bool`] CARD_EXP_GRAPH_PAIRED) THEN
      DISCH_THEN(MP_TAC o MATCH_MP CARD_EQ_IMP_LE) THEN
      MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_TRANS) THEN
      MATCH_MP_TAC CARD_LE_SUBSET THEN
      REWRITE_TAC[SUBSET; mul_c; IN_ELIM_THM] THEN
      X_GEN_TAC `R:B#A->bool` THEN REWRITE_TAC[FORALL_PAIR_THM] THEN
      REPEAT STRIP_TAC THENL [ASM_MESON_TAC[IN]; ALL_TAC] THEN
      REWRITE_TAC[eq_c] THEN EXISTS_TAC `FST:B#A->B` THEN
      REWRITE_TAC[EXISTS_UNIQUE_DEF; FORALL_PAIR_THM; EXISTS_PAIR_THM] THEN
      ASM_MESON_TAC[PAIR_EQ; IN];
      SUBGOAL_THEN `(t:B->bool) *_c (s:A->bool) <=_c s` MP_TAC THENL
       [ASM_SIMP_TAC[CARD_MUL_ABSORB_LE]; ALL_TAC] THEN
      REWRITE_TAC[le_c] THEN
      DISCH_THEN(X_CHOOSE_THEN `p:B#A->A` STRIP_ASSUME_TAC) THEN
      EXISTS_TAC `IMAGE (p:B#A->A)` THEN REWRITE_TAC[IN_ELIM_THM] THEN
      CONJ_TAC THENL [X_GEN_TAC `u:B#A->bool`; ASM SET_TAC[]] THEN
      REPEAT STRIP_TAC THENL [ASM SET_TAC[]; ALL_TAC] THEN
      TRANS_TAC CARD_EQ_TRANS `u:B#A->bool` THEN
      ASM_SIMP_TAC[] THEN MATCH_MP_TAC CARD_EQ_IMAGE THEN ASM SET_TAC[]]]);;

let CARD_EQ_FULLSIZE_POWERSET = prove
 (`!s:A->bool.
        INFINITE s ==> {t | t SUBSET s /\ t =_c s} =_c {t | t SUBSET s}`,
  REPEAT STRIP_TAC THEN
  FIRST_ASSUM(MP_TAC o ISPEC `s:A->bool` o MATCH_MP
    CARD_EQ_RESTRICTED_POWERSET) THEN
  REWRITE_TAC[CARD_LE_REFL] THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_EQ_TRANS) THEN
  TRANS_TAC CARD_EQ_TRANS `(:bool) ^_c (s:A->bool)` THEN
  ASM_REWRITE_TAC[CARD_EXP_POWERSET] THEN
  MATCH_MP_TAC CARD_EXP_ABSORB THEN
  ASM_SIMP_TAC[CARD_LT_IMP_LE; CARD_EXP_CANTOR] THEN
  MATCH_MP_TAC CARD_LE_FINITE_INFINITE THEN
  ASM_REWRITE_TAC[FINITE_BOOL]);;

(* ------------------------------------------------------------------------- *)
(* More about cardinality of lists and restricted powersets etc.             *)
(* ------------------------------------------------------------------------- *)

let CARD_EQ_FINITE_SUBSETS = prove
 (`!s:A->bool. INFINITE(s) ==> {t | t SUBSET s /\ FINITE t} =_c s`,
  GEN_TAC THEN DISCH_TAC THEN REWRITE_TAC[GSYM CARD_LE_ANTISYM] THEN
  CONJ_TAC THENL
   [TRANS_TAC CARD_LE_TRANS `{l:A list | !x. MEM x l ==> x IN s}` THEN
    CONJ_TAC THENL
     [REWRITE_TAC[LE_C; IN_ELIM_THM] THEN
      EXISTS_TAC `set_of_list:A list->(A->bool)` THEN
      X_GEN_TAC `t:A->bool` THEN STRIP_TAC THEN
      EXISTS_TAC `list_of_set(t:A->bool)` THEN
      ASM_SIMP_TAC[MEM_LIST_OF_SET; GSYM SUBSET; SET_OF_LIST_OF_SET];
      MATCH_MP_TAC CARD_EQ_IMP_LE THEN
      MATCH_MP_TAC CARD_EQ_LIST_GEN THEN ASM_REWRITE_TAC[]];
   REWRITE_TAC[le_c] THEN EXISTS_TAC `\x:A. {x}` THEN
   REWRITE_TAC[IN_ELIM_THM; FINITE_SING] THEN SET_TAC[]]);;

let CARD_LE_LIST = prove
 (`!s:A->bool t:B->bool.
        s <=_c t
        ==> {l | !x. MEM x l ==> x IN s} <=_c {l | !x. MEM x l ==> x IN t}`,
  GEN_TAC THEN GEN_TAC THEN REWRITE_TAC[le_c; IN_ELIM_THM] THEN
  DISCH_THEN(X_CHOOSE_THEN `f:A->B` STRIP_ASSUME_TAC) THEN
  EXISTS_TAC `MAP (f:A->B)` THEN
  MATCH_MP_TAC(TAUT `p /\ (p ==> q) ==> p /\ q`) THEN CONJ_TAC THENL
   [REWRITE_TAC[MEM_MAP] THEN ASM_MESON_TAC[]; DISCH_TAC] THEN
  ONCE_REWRITE_TAC[SWAP_FORALL_THM] THEN
  LIST_INDUCT_TAC THEN SIMP_TAC[MAP_EQ_NIL; MAP] THEN
  LIST_INDUCT_TAC THEN REWRITE_TAC[MAP; NOT_CONS_NIL; MEM; CONS_11] THEN
  ASM_MESON_TAC[]);;

let CARD_LE_SUBPOWERSET = prove
 (`!s:A->bool t:B->bool.
        s <=_c t /\ (!f s. P s ==> Q(IMAGE f s))
        ==> {u | u SUBSET s /\ P u} <=_c {v | v SUBSET t /\ Q v}`,
  REPEAT GEN_TAC THEN REWRITE_TAC[le_c; IN_ELIM_THM] THEN DISCH_THEN
   (CONJUNCTS_THEN2 (X_CHOOSE_THEN `f:A->B` STRIP_ASSUME_TAC) ASSUME_TAC) THEN
  EXISTS_TAC `IMAGE (f:A->B)` THEN ASM_SIMP_TAC[] THEN ASM SET_TAC[]);;

let CARD_LE_FINITE_SUBSETS = prove
 (`!s:A->bool t:B->bool.
    s <=_c t
    ==> {u | u SUBSET s /\ FINITE u} <=_c {v | v SUBSET t /\ FINITE v}`,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC CARD_LE_SUBPOWERSET THEN
  ASM_SIMP_TAC[FINITE_IMAGE]);;

let CARD_LE_COUNTABLE_SUBSETS = prove
 (`!s:A->bool t:B->bool.
    s <=_c t
    ==> {u | u SUBSET s /\ COUNTABLE u} <=_c {v | v SUBSET t /\ COUNTABLE v}`,
  REPEAT STRIP_TAC THEN MATCH_MP_TAC CARD_LE_SUBPOWERSET THEN
  ASM_SIMP_TAC[COUNTABLE_IMAGE]);;

let CARD_LE_POWERSET = prove
 (`!s:A->bool t:B->bool.
    s <=_c t ==> {u | u SUBSET s} <=_c {v | v SUBSET t}`,
  REPEAT STRIP_TAC THEN PURE_ONCE_REWRITE_TAC[SET_RULE
    `{x | x SUBSET y} = {x | x SUBSET y /\ T}`] THEN
  MATCH_MP_TAC CARD_LE_SUBPOWERSET THEN
  ASM_SIMP_TAC[]);;

let COUNTABLE_LIST_GEN = prove
 (`!s:A->bool. COUNTABLE s ==> COUNTABLE {l | !x. MEM x l ==> x IN s}`,
  GEN_TAC THEN REWRITE_TAC[COUNTABLE; ge_c] THEN
  DISCH_THEN(MP_TAC o MATCH_MP CARD_LE_LIST) THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_TRANS) THEN
  MATCH_MP_TAC CARD_EQ_IMP_LE THEN
  REWRITE_TAC[IN_UNIV; SET_RULE `{x | T} = UNIV`] THEN
  SIMP_TAC[CARD_EQ_LIST; num_INFINITE]);;

let COUNTABLE_LIST = prove
 (`COUNTABLE(:A) ==> COUNTABLE(:A list)`,
  MP_TAC(ISPEC `(:A)` COUNTABLE_LIST_GEN) THEN
  REWRITE_TAC[IN_UNIV; SET_RULE `{x | T} = UNIV`]);;

let COUNTABLE_FINITE_SUBSETS = prove
 (`!s:A->bool. COUNTABLE(s) ==> COUNTABLE {t | t SUBSET s /\ FINITE t}`,
  GEN_TAC THEN REWRITE_TAC[COUNTABLE; ge_c] THEN
  DISCH_THEN(MP_TAC o MATCH_MP CARD_LE_FINITE_SUBSETS) THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_LE_TRANS) THEN
  MATCH_MP_TAC CARD_EQ_IMP_LE THEN
  REWRITE_TAC[IN_UNIV; SET_RULE `{x | T} = UNIV`] THEN
  SIMP_TAC[CARD_EQ_FINITE_SUBSETS; num_INFINITE]);;

let CARD_EQ_REAL_SEQUENCES = prove
 (`(:num->real) =_c (:real)`,
  TRANS_TAC CARD_EQ_TRANS `(:num->num->bool)` THEN
  ASM_SIMP_TAC[CARD_FUNSPACE_CONG; CARD_EQ_REFL; CARD_EQ_REAL] THEN
  TRANS_TAC CARD_EQ_TRANS `(:num#num->bool)` THEN
  ASM_SIMP_TAC[CARD_FUNSPACE_CURRY] THEN
  TRANS_TAC CARD_EQ_TRANS `(:num->bool)` THEN
  ASM_SIMP_TAC[CARD_FUNSPACE_CONG; CARD_EQ_REFL;
               ONCE_REWRITE_RULE[CARD_EQ_SYM] CARD_EQ_REAL;
               REWRITE_RULE[MUL_C_UNIV] CARD_SQUARE_NUM]);;

let CARD_EQ_COUNTABLE_SUBSETS_SUBREAL = prove
 (`!s:A->bool. INFINITE s /\ s <=_c (:real)
               ==> {t | t SUBSET s /\ COUNTABLE t} =_c (:real)`,
  REPEAT STRIP_TAC THEN REWRITE_TAC[COUNTABLE; ge_c] THEN
  FIRST_ASSUM(MP_TAC o ISPEC `(:num)` o MATCH_MP
    CARD_EQ_LIMITED_POWERSET) THEN
  ASM_REWRITE_TAC[GSYM INFINITE_CARD_LE] THEN
  MATCH_MP_TAC(REWRITE_RULE[IMP_CONJ_ALT] CARD_EQ_TRANS) THEN
  TRANS_TAC CARD_EQ_TRANS `(:num->bool)` THEN
  REWRITE_TAC[ONCE_REWRITE_RULE[CARD_EQ_SYM] CARD_EQ_REAL] THEN
  REWRITE_TAC[GSYM CARD_EXP_UNIV] THEN MATCH_MP_TAC CARD_EXP_ABSORB THEN
  REWRITE_TAC[num_INFINITE] THEN CONJ_TAC THENL
   [MATCH_MP_TAC CARD_LE_FINITE_INFINITE THEN
    ASM_REWRITE_TAC[FINITE_BOOL];
    TRANS_TAC CARD_LE_TRANS `(:real)` THEN ASM_REWRITE_TAC[] THEN
    MATCH_MP_TAC CARD_EQ_IMP_LE THEN
    TRANS_TAC CARD_EQ_TRANS `(:num->bool)` THEN
    REWRITE_TAC[CARD_EQ_REAL; CARD_EXP_UNIV; CARD_EQ_REFL]]);;

let CARD_EQ_COUNTABLE_SUBSETS_REAL = prove
 (`{s:real->bool | COUNTABLE s} =_c (:real)`,
  MP_TAC(ISPEC `(:real)` CARD_EQ_COUNTABLE_SUBSETS_SUBREAL) THEN
  REWRITE_TAC[SUBSET_UNIV; CARD_LE_REFL; real_INFINITE]);;
