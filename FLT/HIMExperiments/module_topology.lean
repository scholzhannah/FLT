/-
Copyright (c) 2024 Kevin Buzzaed. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Buzzard, Hannah Scholz, Ludwig Monnerjahn
-/

import Mathlib.RingTheory.TensorProduct.Basic -- we need tensor products of rings at some point
import Mathlib.Topology.Algebra.Module.Basic -- and we need topological rings and modules
import Mathlib.Topology.Algebra.Module.FiniteDimension
/-

# The "module topology" for a module over a topological ring.

Let `A` denote a topological ring.

If `M` is an `A`-module, then `M` seems to inherit a topology from `A`, which we call the
"module topology" until someone tells me its proper name. It's the coarsest topology
making all the `A`-linear maps `M →ₗ[A] A` continuous.

This topology has the following cool properties:

1) Any `A`-linear map `φ : M →ₗ[A] N` is continuous for the module topologies on source
and target.

2)

-/

-- This was an early theorem I proved when I didn't know what was true or not, and
-- was just experimenting.

-- theorem LinearMap.continuous_on_prod {ι κ : Type*} {R : Type*} {M : Type*}
--     [Finite ι] [Finite κ] [CommSemiring R] [TopologicalSpace R] [TopologicalSemiring R]
--     [AddCommMonoid M] [Module R M]
--     [TopologicalSpace M] [ContinuousAdd M] [ContinuousSMul R M]
--     (f : (ι → R) →ₗ[R] (κ → R) →ₗ[R] M) :
--     Continuous (fun xy ↦ f xy.1 xy.2 : (ι → R) × (κ → R) → M) := by
--   cases nonempty_fintype (ι × κ)
--   cases nonempty_fintype κ
--   cases nonempty_fintype ι
--   classical
--   have foo : (fun xy ↦ f xy.1 xy.2 : (ι → R) × (κ → R) → M) =
--       fun xy ↦ ∑ ik : ι × κ, ((xy.1 ik.1) * (xy.2 ik.2)) •
--         f (fun i ↦ if i = ik.1 then 1 else 0) (fun k ↦ if k = ik.2 then 1 else 0) := by
--     ext ⟨x, y⟩
--     simp only [pi_apply_eq_sum_univ (f x) y]
--     -- `rw [Fintype.sum_prod_type_right]` doesn't work and I don't know why
--     -- `rw [@Fintype.sum_prod_type_right _ ι κ ‹_› ‹_› _ _]` also doesn't work and I don't know why
--     -- annoying workaround
--     symm
--     convert @Fintype.sum_prod_type_right _ ι κ ‹_› ‹_› _ _
--     simp only [pi_apply_eq_sum_univ f x, mul_comm (x _), mul_smul, ← Finset.smul_sum, Eq.comm]
--     congr
--     apply sum_apply
--   rw [foo]
--   refine continuous_finset_sum _ fun i _ => Continuous.smul ?_ continuous_const
--   refine Continuous.mul (Continuous.comp (continuous_apply _) (continuous_fst)) ?_
--   exact (Continuous.comp (continuous_apply _) (continuous_snd))

variable (A : Type*) [CommRing A] [iA: TopologicalSpace A] [TopologicalRing A]

-- let M be an A-module
variable {M : Type*} [AddCommGroup M] [Module A M]
-- Here is a conceptual way to put a topology on `M`. Let's define it to be
-- the coarsest topology such that all `A`-linear maps from `M` to `A` are continuous
-- (recall that `A` already has a topology). If M is free of finite rank then
-- we'll see that this is the same as just choosing an isomorphism M = A^n and giving
-- it the product topology

/-- The "canonical topology" on a module `M` over a topological ring `A`. It's defined as
the weakest topology on `M` which makes every `A`-linear map `M → A` continuous. -/
-- make it an abbreviation not a definition; this means that Lean "prints `Module.topology`
-- in the tactic state for the human reader" but interally is syntactically equal to
-- to the `iInf`, meaning that all the `iInf` rewrites still work.
abbrev Module.topology : TopologicalSpace M :=
-- Topology defined as greatest lower bound of pullback topologies. So it's the biggest
-- topology making all the `f`s continuous.
  ⨅ (f : M →ₗ[A] A), TopologicalSpace.induced f inferInstance

-- let `N` be another module
variable {N : Type*} [AddCommGroup N] [Module A N]

/-- Every `A`-linear map between two `A`-modules with the canonical topology is continuous. -/
lemma Module.continuous_linear (e : M →ₗ[A] N) :
    @Continuous M N (Module.topology A) (Module.topology A) e := by
  -- rewrite the goal (continuity of `e`) as in inequality:
  --(canonical topology) ≤ (pullback of induced topology)
  rw [continuous_iff_le_induced]
  -- There's an already-proven lemma in mathlib that says the pullback of an `iInf` of
  -- topologies is the `iInf` of the pullbacks
  rw [induced_iInf]
  -- composite of the induced topologies is just topology induced by the composition
  -- need `simp_rw` because it's under a binder.
  simp_rw [induced_compose]
  -- so now we've got to prove `iInf S` is `≤ iInf T` for `S` the set of all linear
  -- maps from `M` to `A` and `T` the subset of those which factor through `e`.
  -- It of course suffices to prove `T` ⊆ `S`.
  apply sInf_le_sInf
  -- and this is a trivial calculation.
  rintro τ ⟨φ, rfl⟩
  exact ⟨φ ∘ₗ e, rfl⟩

-- A formal corollary should be that
def Module.homeomorphism_equiv (e : M ≃ₗ[A] N) :
    -- lean needs to be told the topologies explicitly in the statement
    let τM : TopologicalSpace M := Module.topology A
    let τN : TopologicalSpace N := Module.topology A
    M ≃ₜ N :=
  -- And also at the point where lean puts the structure together, unfortunately
  let τM : TopologicalSpace M := Module.topology A
  let τN : TopologicalSpace N := Module.topology A
  -- all the sorries should be formal.
  { toFun := e
    invFun := e.symm
    left_inv := e.left_inv
    right_inv := e.right_inv
    continuous_toFun := Module.continuous_linear A e
    continuous_invFun := Module.continuous_linear A e.symm
  }

-- sanity check: the topology on A^n is the product topology
example (ι : Type*) [Finite ι] :
    (Pi.topologicalSpace : TopologicalSpace (ι → A)) = Module.topology A := by
  -- suffices to prove that each topology is ≤ the other one
  apply le_antisymm
  · -- you're ≤ `iInf S` iff you're ≤ all elements of `S`
    apply le_iInf
    -- so take an element of `S`, the topology induced by `b : (ι → A) → A`
    intro b
    -- and we've got to prove that the product topology is `≤` it, which is the
    -- same as saying that `b` is continuous with the product topology on `A^ι`
    rw [← continuous_iff_le_induced]
    -- and we've already proved that all linear maps are continuous.
    apply LinearMap.continuous_on_pi b
  · -- the set Inf application works better here for some reason
    -- We've got to prove the module topology is ≤ the product topology, which is defined here to
    -- be the coarsest topology making all the projection maps continuous
    -- So it suffices to prove that all projections are linear
    apply sInf_le_sInf
    -- so let's look at the i'th projection
    rintro _ ⟨i, rfl⟩
    -- it's linear, because Lean has the projections as linear maps.
    exact ⟨LinearMap.proj i, rfl⟩

--maybe I should conclude this from the example above but don't know how
--otherwise this should be very easy to do by hand
lemma Module.topology_self : (iA :TopologicalSpace A) = Module.topology A := by
  refine le_antisymm (le_iInf (fun i ↦ ?_)) <| sInf_le ⟨LinearMap.id, induced_id⟩
  rw [← continuous_iff_le_induced, show i = LinearMap.lsmul A A (i 1) by ext;simp]
  exact continuous_const.mul continuous_id

lemma LinearMap.continuous_on_prod (f : (M × N) →ₗ[A] A) :
  @Continuous _ _ (@instTopologicalSpaceProd M N (Module.topology A) (Module.topology A)) _ f := by
  have : ⇑f = fun ⟨m, n⟩ ↦ f (⟨m, 0⟩) + f (⟨0, n⟩) := by
    ext x
    simp only
    have : x = (x.1, 0) + (0, x.2) := by simp
    nth_rewrite 1 [this]
    apply LinearMap.map_add
  rw [this]
  simp only
  apply @Continuous.add _ _ (@instTopologicalSpaceProd M N (Module.topology A) (Module.topology A))
    _ _ _ (fun x ↦ (fun m ↦ f (m, 0)) x.1) (fun x ↦ (fun n ↦ f (0, n)) x.2)
  . apply @Continuous.fst' _ _ _ (Module.topology A) (Module.topology A) _ (fun m ↦ f (m, 0))
    nth_rewrite 2 [Module.topology_self A]
    exact Module.continuous_linear A ({toFun := fun m ↦ f (m, 0), map_add' := by
    {intro x y; rw [← LinearMap.map_add, Prod.mk_add_mk, zero_add]}, map_smul' := by
    {intro m x; rw [← LinearMap.map_smul, RingHom.id_apply, Prod.smul_mk, smul_zero]}})
  . apply @Continuous.snd' _ _ _ (Module.topology A) (Module.topology A) _ (fun n ↦ f (0, n))
    nth_rewrite 2 [Module.topology_self A]
    exact Module.continuous_linear A ({toFun := fun n ↦ f (0, n), map_add' := by
    {intro x y; rw [← LinearMap.map_add, Prod.mk_add_mk, add_zero]}, map_smul' := by
    {intro m x; rw [← LinearMap.map_smul, RingHom.id_apply, Prod.smul_mk, smul_zero]}})

-- We need that the module topology on a product is the product topology
lemma Module.prod_canonical :
    @instTopologicalSpaceProd M N (Module.topology A) (Module.topology A) =
    (Module.topology A : TopologicalSpace (M × N)) := by
  -- the goal is to prove that an iInf equals an inf (of two topologies).
  apply le_antisymm
  · apply le_iInf
    intro f
    rw [← continuous_iff_le_induced]
    apply LinearMap.continuous_on_prod A f
  · apply le_inf
    · rw [induced_iInf]
      apply le_iInf
      intro f
      rw [induced_compose]
      exact iInf_le _ (LinearMap.lcomp _ _ (LinearMap.fst _ _ _) _)
    · rw [induced_iInf]
      apply le_iInf
      intro f
      rw [induced_compose]
      exact iInf_le _ (LinearMap.lcomp _ _ (LinearMap.snd _ _ _) _)

-- Linear maps are automatically continuous, so let's make a couple of handy ones:
-- they're probably there already but I couldn't find them
/-- Negation on a module as a linear map. -/
noncomputable def LinearMap.neg (M : Type*) [AddCommGroup M] [Module A M] :
    M →ₗ[A] M where
  toFun := (- .)
  map_add' := neg_add
  map_smul' r m := (smul_neg r m).symm

/-- Scalar multiplication in the second variable as a linear map. -/
noncomputable def LinearMap.smul₂ (M : Type*) [AddCommGroup M] [Module A M] (a : A):
    M →ₗ[A] M where
  toFun m := (a • m)
  map_add' := by simp
  map_smul' r m := by
    simp
    rw [@smul_algebra_smul_comm]

/-- Scalar multiplication in the first variable as a linear map. -/
noncomputable def LinearMap.smul₁ (M : Type*) [AddCommGroup M] [Module A M] (m : M):
    A →ₗ[A] M where
  toFun a := a • m
  map_add' := by simp [add_smul]
  map_smul' r n := by simp [mul_smul]

/-- Addition on a module as a linear map from `M²` to `M`. -/
noncomputable def LinearMap.add (M : Type*) [AddCommGroup M] [Module A M] :
    M × M →ₗ[A] M where
  toFun mn := mn.1 + mn.2
  map_add' _ _ := add_add_add_comm _ _ _ _
  map_smul' _ _ := (DistribSMul.smul_add _ _ _).symm

/-- Basis.equivFun in the first variable as a linear map. -/
noncomputable def LinearMap.basis₁ (M : Type*) (ι : Type*) [Finite ι] [AddCommGroup M] [Module A M] (b : Basis ι A M) (i : ι):
    M →ₗ[A] A where
  toFun m := b.equivFun m i
  map_add' := by simp
  map_smul' r n := by simp

noncomputable def LinearMap.prodfst (M N : Type*) [AddCommGroup M] [Module A M] [AddCommGroup N] [Module A N] :
    M × N →ₗ[A] M where
  toFun := Prod.fst
  map_add' := by simp
  map_smul' r n := by simp

noncomputable def LinearMap.prodsnd (M N : Type*) [AddCommGroup M] [Module A M] [AddCommGroup N] [Module A N] :
    M × N →ₗ[A] N where
  toFun := Prod.snd
  map_add' := by simp
  map_smul' r n := by simp

--local instance : TopologicalSpace P := Module.topology A

instance Module.instCommAdd {P : Type*} [AddCommGroup P] [Module A P]:
@ContinuousAdd P (Module.topology A) _ := by
  apply @ContinuousAdd.mk _ (topology A)
  rw [Module.prod_canonical A]
  exact Module.continuous_linear A (LinearMap.add A P)

variable [Module.Finite A M] [Module.Free A M] [Module.Finite A N] [Module.Free A N]


-- I really shoouldn't start with iA instead of topology A here.
-- But I need it like this in the next proof and don't know how to rewrite it there
-- Sorry for leaving it like this...
instance Module.instContinuousSMul : @ContinuousSMul A M _ (topology A) (topology A) := by
  rw [← Module.topology_self]
  apply @ContinuousSMul.mk A M _ _ (topology A)
  let ι := Free.ChooseBasisIndex A M
  have b : Basis ι A M := by
    simp only [ι]
    exact Free.chooseBasis A M
  have : (fun (p : A × M) ↦ p.1 • p.2) = (fun p ↦ ∑ i : ι, p.1 • b.equivFun p.2 i • b i) := by
    ext x
    rw [← Finset.smul_sum, Basis.sum_equivFun]
  rw [this]
  apply @continuous_finset_sum _ _ _ (@instTopologicalSpaceProd _  _ _ (topology A)) (topology A) _ _ _ _
  intro i _
  have : (fun (a : A × M) ↦ a.1 • b.equivFun a.2 i • b i) = (fun a ↦ (a.1 * b.equivFun a.2 i) • b i) := by
    ext
    rw [← mul_smul]
  rw [this]
  have : (fun a ↦ (a.1 * b.equivFun a.2 i) • b i) = (fun (a : A) ↦ a • b i) ∘ (fun (m : A × A) ↦ m.1 * m.2) ∘ (fun (m : A × M) ↦ (m.1, b.equivFun m.2 i)) := by
    ext a
    simp
  rw [this]
  apply @Continuous.comp _ _ _ (@instTopologicalSpaceProd _ _ _ (topology A)) _ (topology A) _ _
  · have : (fun a ↦ a • b i) = (LinearMap.smul₁ A M (b i)) := by
      unfold LinearMap.smul₁
      simp
    rw [this]
    nth_rewrite 1 [Module.topology_self A]
    apply Module.continuous_linear A (LinearMap.smul₁ A M (b i))
  apply @Continuous.comp _ _ _ (@instTopologicalSpaceProd _ _ _ (topology A)) _ _ _ _
  exact continuous_mul
  apply @Continuous.prod_map _ _ _ _ _ _ _ (topology A) (fun m ↦ m) (fun m ↦ b.equivFun m i)
  exact continuous_id
  have : (fun m ↦ b.equivFun m i) = LinearMap.basis₁ A M ι b i := by
    unfold LinearMap.basis₁
    simp
  rw [this]
  nth_rewrite 2 [Module.topology_self A]
  apply Module.continuous_linear A (LinearMap.basis₁ A M ι b i)



-- I assume this is true! Lots of things like this seem to be true.
lemma Module.continuous_bilinear {P : Type*} [AddCommGroup P] [Module A P] [Module.Finite A P] [Module.Free A P]
    (f : M →ₗ[A] N →ₗ[A] P) :
    @Continuous (M × N) P (Module.topology A) (Module.topology A) (fun mn ↦ f mn.1 mn.2) := by
  let ι := Free.ChooseBasisIndex A M
  let κ := Free.ChooseBasisIndex A N
  have b : Basis ι A M := by --how can I name the index ι without doing all this?
    simp only [ι]
    exact Free.chooseBasis A M
  have d : Basis κ A N := by
    simp only [κ]
    exact Free.chooseBasis A N
  rw [← prod_canonical]
  have : (fun (mn : M × N) ↦ (f mn.1) mn.2) =
    (fun (mn : M × N) ↦  (∑ k : κ, (∑ i : ι, d.equivFun mn.2 k • b.equivFun mn.1 i • f (b i)) (d k))) := by
    ext ⟨x, y⟩
    simp only
    calc
      (f x) y = (f (∑ i : ι, b.equivFun x i • b i)) (∑ k : κ, d.equivFun y k • d k) := by
        rw [Basis.sum_equivFun, Basis.sum_equivFun]
      _ = ∑ k : κ, (∑ i : ι, d.equivFun y k • b.equivFun x i • f (b i)) (d k) := by simp [Finset.smul_sum]
  rw [this]
  apply @continuous_finset_sum _ _ _ (@instTopologicalSpaceProd _  _ (topology A) (topology A))
    (topology A) _ _ _ Finset.univ
  intro k _
  have : (fun (a : M × N) ↦ (∑ i : ι, d.equivFun a.2 k • b.equivFun a.1 i • f (b i)) (d k)) =
    fun (a : M × N) ↦ ∑ i : ι, ((d.equivFun a.2 k • b.equivFun a.1 i • f (b i)) (d k)) := by
    simp
  rw [this]
  apply @continuous_finset_sum _ _ _ (@instTopologicalSpaceProd _  _ (topology A) (topology A))
    (topology A) _ _ _ Finset.univ
  intro i _
  apply @Continuous.smul _ _ _ (topology A) (topology A) (@instTopologicalSpaceProd _ _ (topology A) (topology A)) _ (@Module.instContinuousSMul _ _ iA _ _ _ _ _ _ ) _ _
  · have : (fun (x : M × N) ↦ d.equivFun x.2 k) = (LinearMap.basis₁ A N κ d k) ∘ Prod.snd := by
      ext
      unfold LinearMap.basis₁
      simp
    rw [this, ← Module.topology_self]
    apply @Continuous.comp _ _ _ (@instTopologicalSpaceProd _ _ (topology A) (topology A)) (topology A) _ _ _
    · nth_rewrite 2 [Module.topology_self A]
      apply Module.continuous_linear A (LinearMap.basis₁ A N κ d k)
    rw [Module.prod_canonical]
    exact Module.continuous_linear A (LinearMap.prodsnd A M N)
  apply @Continuous.smul _ _ _ (topology A) (topology A) (@instTopologicalSpaceProd _ _ (topology A) (topology A)) _ (@Module.instContinuousSMul _ _ iA _ _ _ _ _ _ ) _ _
  · have : (fun (x : M × N) ↦ b.equivFun x.1 i) = (LinearMap.basis₁ A M ι b i) ∘ Prod.fst := by
      ext
      unfold LinearMap.basis₁
      simp
    rw [this, ← Module.topology_self]
    apply @Continuous.comp _ _ _ (@instTopologicalSpaceProd _ _ (topology A) (topology A)) (topology A) _ _ _
    · nth_rewrite 2 [Module.topology_self A]
      apply Module.continuous_linear A (LinearMap.basis₁ A M ι b i)
    rw [Module.prod_canonical]
    exact Module.continuous_linear A (LinearMap.prodfst A M N)
  · apply @continuous_const _ _ (@instTopologicalSpaceProd _ _ (topology A) (topology A)) (topology A) _

-- Note that we have multiplication as a bilinear map.

-- Now say we have a non-commutative `A`-algebra `D` which is free of finite type.

variable (D : Type*) [Ring D] [Algebra A D] [Module.Finite A D] [Module.Free A D]

-- Let's put the module topology on `D`
def D_topology : TopologicalSpace D := Module.topology A

instance moobar : @TopologicalRing D (Module.topology A) _ :=
  let _ : TopologicalSpace D := Module.topology A
  { -- first we prove that addition is continuous
    continuous_add := by
      -- the product topology is the module topology
      rw [Module.prod_canonical A]
      -- and addition is linear so it's continuous for the module topology
      exact Module.continuous_linear A (LinearMap.add A D)
    -- multiplication is continuous:
    continuous_mul := by
      -- the product topology is the module topology
      rw [Module.prod_canonical A]
      -- and multiplication is bilinear so it's continuous for the module topology (I hope)
      apply Module.continuous_bilinear A (LinearMap.mul A D)
    -- finally negation is continuous because it's linear.
    continuous_neg := Module.continuous_linear A (LinearMap.neg _ _) }
