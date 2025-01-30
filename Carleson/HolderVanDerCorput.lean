import Carleson.TileStructure

/-! This should roughly contain the contents of chapter 8. -/

open scoped ShortVariables
variable {X : Type*} {a : ℕ} {q : ℝ} {K : X → X → ℂ} {σ₁ σ₂ : X → ℤ} {F G : Set X}
  [MetricSpace X] [ProofData a q K σ₁ σ₂ F G]

noncomputable section

open Set MeasureTheory Metric Function Complex Bornology TileStructure
open scoped NNReal ENNReal ComplexConjugate

/-- `cutoff R t x y` is `L(x, y)` in the proof of Lemma 8.0.1. -/
def cutoff (R t : ℝ) (x y : X) : ℝ :=
  max 0 (1 - dist x y / (t * R))

variable {R t : ℝ} {x y : X}

lemma cutoff_nonneg : 0 ≤ cutoff R t x y := by simp [cutoff]

lemma cutoff_comm : cutoff R t x y = cutoff R t y x := by
  unfold cutoff
  simp_rw [dist_comm x y]

lemma cutoff_Lipschitz (hR : 0 < R) (ht : 0 < t) :
    LipschitzWith ⟨(1 / (t * R)), by positivity⟩ (fun y ↦ cutoff R t x y) := by
  apply LipschitzWith.const_max
  apply LipschitzWith.of_le_add_mul
  intro a b
  simp only [one_div, NNReal.coe_mk, tsub_le_iff_right, div_eq_inv_mul, mul_one]
  have : (t * R) ⁻¹ * dist x b ≤ (t * R)⁻¹ * (dist x a + dist a b) := by
    gcongr
    exact dist_triangle _ _ _
  linarith

@[fun_prop]
lemma cutoff_continuous (hR : 0 < R) (ht : 0 < t) : Continuous (fun y ↦ cutoff R t x y) :=
  (cutoff_Lipschitz hR ht (X := X)).continuous

/-- `cutoff R t x` is measurable in `y`. -/
@[fun_prop]
lemma cutoff_measurable (hR : 0 < R) (ht : 0 < t) : Measurable (fun y ↦ cutoff R t x y) :=
  (cutoff_continuous hR ht).measurable

lemma hasCompactSupport_cutoff [ProperSpace X] (hR : 0 < R) (ht : 0 < t) {x : X} :
    HasCompactSupport (fun y ↦ cutoff R t x y) := by
  apply HasCompactSupport.intro (isCompact_closedBall x (t * R))
  intro y hy
  simp only [mem_closedBall, dist_comm, not_le] at hy
  simp only [cutoff, sup_eq_left, tsub_le_iff_right, zero_add]
  rw [one_le_div (by positivity)]
  exact hy.le

lemma integrable_cutoff (hR : 0 < R) (ht : 0 < t) {x : X} :
    Integrable (fun y ↦ cutoff R t x y) :=
  (cutoff_continuous hR ht).integrable_of_hasCompactSupport
    (hasCompactSupport_cutoff hR ht)

-- Is this useful for mathlib? neither exact? nor aesop can prove this. Same for the next lemma.
lemma leq_of_max_neq_left {a b : ℝ} (h : max a b ≠ a) : a < b := by
  by_contra! h'
  exact h (max_eq_left h')

lemma leq_of_max_neq_right {a b : ℝ} (h : max a b ≠ b) : b < a := by
  by_contra! h'
  exact h (max_eq_right h')

/-- Equation 8.0.4 from the blueprint -/
lemma aux_8_0_4 (hR : 0 < R) (ht : 0 < t) (h : cutoff R t x y ≠ 0) : y ∈ ball x (t * R) := by
  rw [mem_ball']
  have : 0 < 1 - dist x y / (t * R) := by
    apply leq_of_max_neq_left
    rwa [cutoff] at h
  exact (div_lt_one (by positivity)).mp (by linarith)

lemma aux_8_0_5 (hR : 0 < R) (ht : 0 < t) (h : y ∈ ball x (2⁻¹ * t * R)) :
    2⁻¹ ≤ cutoff R t x y := by
  rw [mem_ball', mul_assoc] at h
  have : dist x y / (t * R) < 2⁻¹ := (div_lt_iff₀ (by positivity)).mpr h
  calc 2 ⁻¹
    _ ≤ 1 - dist x y / (t * R) := by
      norm_num at *; linarith only [h, this]
    _ ≤ cutoff R t x y := le_max_right _ _

lemma aux_8_0_6 (hR : 0 < R) (ht : 0 < t) :
    2⁻¹ * volume.real (ball x (2⁻¹ * t * R)) ≤ ∫ y, cutoff R t x y := by
  calc 2 ⁻¹ * volume.real (ball x (2⁻¹ * t * R))
    _ = ∫ y in ball x (2⁻¹ * t * R), 2⁻¹ := by
      rw [setIntegral_const, mul_comm]
      rfl
    _ ≤ ∫ y in (ball x (2⁻¹ * t * R)), cutoff R t x y := by
      apply setIntegral_mono_on
      · apply integrableOn_const.2
        right
        exact measure_ball_lt_top
      · apply (integrable_cutoff hR ht).integrableOn
      · exact measurableSet_ball
      · intro y' hy'
        exact aux_8_0_5 hy' (hR := hR) (ht := ht)
    _ ≤ ∫ y, cutoff R t x y := by
      apply setIntegral_le_integral (integrable_cutoff hR ht)
      filter_upwards with x using (by simp [cutoff])

/-- The smallest integer `n` so that `2^n t ≥ 1`. -/
-- i.e., the real logarithm log₂ 1/t, rounded *up* to the nearest integer
private def n_8_0_7 (t : ℝ) : ℤ := Int.log 2 (1 / t) + 1

private lemma n_spec1 (ht : 0 < t) : 1 < 2 ^ (n_8_0_7 t) * t := calc
  1 = (1 / t) * t := by
    norm_num
    rw [mul_comm]
    exact (mul_inv_cancel₀ ht.ne').symm
  _ < 2 ^ (n_8_0_7 t) * t := by
    gcongr
    exact Int.lt_zpow_succ_log_self (by norm_num) (1 / t)

-- This lemma is probably not needed.
-- private lemma n_spec2 : ∀ n' < n_8_0_7 t, 2 ^ n' * t < 1 := sorry

/-- The constant occurring in Lemma 8.0.1. -/
def C8_0_1 (a : ℝ) (t : ℝ≥0) : ℝ≥0 := ⟨2 ^ (4 * a) * t ^ (- (a + 1)), by positivity⟩

/-- `ϕ ↦ \tilde{ϕ}` in the proof of Lemma 8.0.1. -/
def holderApprox (R t : ℝ) (ϕ : X → ℂ) (x : X) : ℂ :=
  (∫ y, cutoff R t x y * ϕ y) / (∫ y, cutoff R t x y)

-- This surely exists in mathlib; how is it named?
lemma foo {φ : X → ℂ} (hf : ∫ x, φ x ≠ 0) : ∃ z, φ z ≠ 0 := by
  by_contra! h
  exact hf (by simp [h])

/-- Part of Lemma 8.0.1. -/
lemma support_holderApprox_subset {z : X} {R t : ℝ} (hR : 0 < R)
    (ϕ : X → ℂ) (hϕ : ϕ.support ⊆ ball z R) (ht : t ∈ Ioc (0 : ℝ) 1) :
    support (holderApprox R t ϕ) ⊆ ball z (2 * R) := by
  intro x hx
  choose y hy using foo (left_ne_zero_of_mul hx)
  have : x ∈ ball y (t * R) := by
    apply aux_8_0_4 hR ht.1
    rw [cutoff_comm]
    simpa using left_ne_zero_of_mul hy
  have h : x ∈ ball y R := by
    refine Set.mem_of_mem_of_subset this ?_
    nth_rw 2 [← one_mul R]
    gcongr
    exact ht.2
  calc dist x z
    _ ≤ dist x y + dist y z := dist_triangle x y z
    _ < R + R := add_lt_add h (hϕ (right_ne_zero_of_mul hy))
    _ = 2 * R := by ring

-- XXX: inlining this does not work
lemma foobar (f : X → ℝ) : ∫ x, (f x : ℂ) = ((∫ x, f x : ℝ) : ℂ) := integral_ofReal

open Filter

/-- Part of Lemma 8.0.1. -/
lemma dist_holderApprox_le {z : X} {R t : ℝ} (hR : 0 < R) {C : ℝ≥0}
    (ϕ : X → ℂ) (hϕ : ϕ.support ⊆ ball z R)
    (h2ϕ : HolderWith C nnτ ϕ) (hτ : 0 < nnτ) (ht : t ∈ Ioc (0 : ℝ) 1) (x : X) :
    dist (ϕ x) (holderApprox R t ϕ x) ≤ (t * R) ^ τ * C := by
  have ht0 : 0 < t := ht.1
  have P : 0 < ∫ y, cutoff R t x y := by
    apply lt_of_lt_of_le _ (aux_8_0_6 hR ht.1)
    apply mul_pos (by positivity)
    apply measure_real_ball_pos
    positivity
  have : (∫ y, cutoff R t x y * ϕ x) / (∫ y, (cutoff R t x y : ℂ)) = ϕ x := by
    rw [integral_mul_right, mul_div_cancel_left₀]
    simpa only [ne_eq, ofReal_eq_zero, foobar] using P.ne'
  rw [dist_eq_norm, ← this, holderApprox, foobar, ← sub_div, ← integral_sub]; rotate_left
  · apply (integrable_cutoff hR ht0).ofReal.mul_const
  · apply Continuous.integrable_of_hasCompactSupport
    · apply Continuous.mul
      · have := cutoff_continuous hR ht0 (x := x)
        fun_prop
      · exact h2ϕ.continuous hτ
    · apply HasCompactSupport.mul_left
      apply HasCompactSupport.of_support_subset_isCompact (isCompact_closedBall z R)
      apply hϕ.trans ball_subset_closedBall
  rw [norm_div, norm_real, div_le_iff₀]; swap
  · exact P.trans_le (le_abs_self _)
  calc
    ‖∫ y, cutoff R t x y * ϕ x - cutoff R t x y * ϕ y‖
  _ = ‖∫ y, cutoff R t x y * (ϕ x - ϕ y)‖ := by simp only [mul_sub]
  _ ≤ ∫ y, ‖cutoff R t x y * (ϕ x - ϕ y)‖ := norm_integral_le_integral_norm _
  _ ≤ ∫ y, cutoff R t x y * (C * (t * R) ^ τ) := by
    apply integral_mono_of_nonneg
    · filter_upwards with y using (by positivity)
    · apply (integrable_cutoff hR ht0).mul_const
    filter_upwards with y
    rcases le_total (dist x y) (t * R) with hy | hy
    -- Case 1: |x - y| ≤ t * R, then cutoff is non-negative.
    · simp only [norm_mul, norm_real, Real.norm_eq_abs, norm_eq_abs, defaultτ, abs_ofReal,
        _root_.abs_of_nonneg cutoff_nonneg]
      gcongr
      · exact cutoff_nonneg
      rw [← Complex.norm_eq_abs, ← dist_eq_norm]
      exact h2ϕ.dist_le_of_le hy
    -- Case 2: |x - y| > t * R, and cutoff is zero.
    · have : cutoff R t x y = 0 := by
        simp only [cutoff, sup_eq_left, tsub_le_iff_right, zero_add]
        rwa [one_le_div₀ (by positivity)]
      simp [this]
  _ = (t * R) ^τ * C * ∫ y, cutoff R t x y := by
    rw [integral_mul_right]
    ring
  _ ≤ (t * R) ^ τ * C * ‖∫ (x_1 : X), cutoff R t x x_1‖ := by
    gcongr
    exact Real.le_norm_self _

lemma foobaz (f : X → ℝ) : ‖∫ x, (f x : ℂ)‖ = ‖∫ x, f x‖ := by
  rw [foobar, norm_real]

-- one direction always holds; the other needs non-negativity
lemma qux (f : X → ℝ) (hf : 0 ≤ f) : ‖∫ x, f x‖ = ∫ x, ‖f x‖ := by
  trans ∫ x, f x
  · rw [Real.norm_eq_abs, _root_.abs_of_nonneg]
    exact integral_nonneg hf
  · congr with x
    rw [Real.norm_eq_abs, _root_.abs_of_nonneg]
    exact hf x

-- need a linter: lemmas in the root namespace which exist at the same time in a sub-namespace
-- need protected, or namespacing: depends

-- general version: balls have positive measure (OpenPosMeasure should suffice)
lemma Continuous.integral_pos_of_pos {f : X → ℝ} {x : X}
    (hf : Continuous f) (hfpos : 0 ≤ f) (hfx : 0 < f x) : 0 < ∫ x, f x := by
  have : 0 ≤ ∫ x, f x := integral_nonneg hfpos
  by_contra! h
  have : ∫ x, f x = 0 := by linarith only [this, h]
  -- know: integral is nonneg
  -- is positive provides it's non-zero... if zero, function is a.e. zero
  -- but that's false as a ball has positive measure

--   x : X is given
-- integral cutoff R t x y over all y is 0 <=> cutoff is zero a.e. (since non-neg)

-- know: cutoff is supported inside a ball
-- know: cutoff is continuous: so if non-zero, it stays non-zero on a ball => do balls have positive measure?
--   yes, that is required in the definition!

  sorry

lemma integral_cutoff_positive {R t : ℝ} (hR : 0 < R) (ht : 0 < t) (x : X) :
    0 < ∫ (y : X), cutoff R t x y := by
  have : 0 < cutoff R t x x := by simp [cutoff]
  exact (cutoff_continuous hR ht).integral_pos_of_pos (fun y ↦ cutoff_nonneg (y := y)) this

-- equation 8.0.18 in the blueprint: two-fold case distinction on the branches in the max
lemma cutoff_norm_sub_left {x x' y : X} (hxx' : dist x x' < R) :
    ‖cutoff R t x y - cutoff R t x' y‖ ≤ dist x x' / (t * R) := by
  sorry

/-- Part of Lemma 8.0.1. -/
lemma lipschitzWith_holderApprox {z : X} {R t : ℝ} (hR : 0 < R) {C : ℝ≥0}
    (ϕ : X → ℂ) (hϕ : ϕ.support ⊆ ball z R)
    (h2ϕ : HolderWith C nnτ ϕ) (hτ : 0 < nnτ) (ht : t ∈ Ioc (0 : ℝ) 1) :
    LipschitzWith (C8_0_1 a ⟨t, ht.1.le⟩) (holderApprox R t ϕ) := by
  -- equation 8.0.14
  have (x : X) : ‖∫ y, cutoff R t x y‖ * ‖holderApprox R t ϕ x‖
      = ‖∫ y, cutoff R t x y * ϕ y‖ := by
    -- uniformise: left integral on LHS should be about complex numbers also
    rw [← foobaz]
    simp only [holderApprox, norm_div]
    nth_rw 1 [← foobar]
    set RRR : ℂ := (∫ (y : X), cutoff R t x y)
    set RRRR := ‖RRR‖
    have : ‖RRR‖ ≠ 0 := by
      simpa only [RRR, norm_eq_abs, map_eq_zero, foobar, abs_ofReal, abs_ne_zero]
        using (integral_cutoff_positive hR ht.1 _).ne'
    field_simp
  -- equation 8.0.15: some preliminary results
  have h₀ : HasCompactSupport ϕ := by
    apply (isCompact_closedBall z R).of_isClosed_subset isClosed_closure
    trans closure (Metric.ball z R)
    · gcongr
    · exact Metric.closure_ball_subset_closedBall
  have h' : HasCompactSupport (‖ϕ ·‖) := h₀.norm
  -- equation 8.0.15
  have eqn8015 (x : X) : ‖∫ y, cutoff R t x y‖ * ‖holderApprox R t ϕ x‖
      ≤ ‖∫ y, cutoff R t x y‖ * ⨆ x' : X, ‖ϕ x'‖ := by
    rw [this]
    calc ‖∫ (y : X), ↑(cutoff R t x y) * ϕ y‖
      _ ≤ ∫ (y : X), ‖↑(cutoff R t x y) * ϕ y‖ := norm_integral_le_integral_norm _
      _ = ∫ (y : X), ‖cutoff R t x y‖ * ‖ϕ y‖ := by
        simp_rw [norm_mul]
        congr with y
        rw [norm_real]
      _ ≤ ∫ (y : X), ‖↑(cutoff R t x y)‖ * ⨆ x' : X, ‖ϕ x'‖ := by
        gcongr
        · apply Integrable.bdd_mul
          · have : Continuous (‖ϕ ·‖) := (continuous_norm).comp (h2ϕ.continuous hτ)
            exact this.integrable_of_hasCompactSupport h'
          · exact (continuous_norm.comp (cutoff_continuous hR ht.1)).aestronglyMeasurable
          · simp_rw [norm_norm]
            apply (cutoff_continuous hR ht.1).bounded_above_of_compact_support
            exact hasCompactSupport_cutoff hR ht.1
        · apply Integrable.smul_const (f := fun a ↦ ‖cutoff R t x a‖) (c := ⨆ x', ‖ϕ x'‖)
          have : (‖cutoff R t x ·‖) = (cutoff R t x ·) := by
            ext a
            rw [Real.norm_eq_abs, _root_.abs_of_nonneg cutoff_nonneg]
          apply this ▸ integrable_cutoff hR ht.1
        intro a
        dsimp
        gcongr
        apply le_ciSup (f := Complex.abs ∘ ϕ)
        have almost : ∃ C, ∀ x, ‖ϕ x‖ ≤ C :=
          (h2ϕ.continuous hτ).bounded_above_of_compact_support h₀
        -- 'almost' is almost what I want
        sorry
      _ = (∫ (y : X), ‖↑(cutoff R t x y)‖) * ⨆ x' : X, ‖ϕ x'‖ := by rw [integral_mul_right]
      _ = ‖∫ (y : X), ↑(cutoff R t x y)‖ * ⨆ x' : X, ‖ϕ x'‖ := by
        congr
        symm
        apply qux
        apply cutoff_nonneg
    sorry
  -- part 1 of 8.0.16
  have (x : X) : ‖holderApprox R t ϕ x‖ ≤ ⨆ x' : ball z R, ‖ϕ x'‖ := by
    have : ⨆ x' : X, ‖ϕ x'‖ = ⨆ x' : ball z R, ‖ϕ x'‖ := by
      -- as ϕ is supported on B... should be a general lemma also
      sorry
    rw [← this]
    -- Divide equation 8.0.15 by L (which is positive).
    apply le_of_mul_le_mul_left (eqn8015 x)
    have aux {XXX : ℝ} (h: 0 < XXX) : 0 < ‖XXX‖ := sorry -- easy lemma, in mathlib
    apply aux (integral_cutoff_positive hR ht.1 x)
  -- part 2 of 8.0.16: TODO I don't think this works
  -- if ϕ is bounded, it could still oscillate wildly (making its Hölder norm arbitrarily large)
    -- in any case, abstract this result: if f is bounded by C, then C is at most the Holder norm
  have eqn8016_2 : ⨆ x' : ball z R, ‖ϕ x'‖ ≤ C := sorry

  have eqn8016 : ∀ x : ball z R, ‖holderApprox R t ϕ x‖ ≤ C := fun x ↦ (this x).trans eqn8016_2
  -- equation 8.0.17
  have {x x' : X} (hxx' : R ≤ dist x x') :
      R * (‖holderApprox R t ϕ x' - holderApprox R t ϕ x‖) / (dist x x')
      ≤ 2 * C := by
    calc R * (‖holderApprox R t ϕ x' - holderApprox R t ϕ x‖) / (dist x x')
      _ ≤ R * (‖holderApprox R t ϕ x' - holderApprox R t ϕ x‖) / R := by gcongr
      _ = ‖holderApprox R t ϕ x' - holderApprox R t ϕ x‖ := by field_simp
      _ ≤ ‖holderApprox R t ϕ x'‖ + ‖holderApprox R t ϕ x‖ := norm_sub_le _ _
      _ ≤ (⨆ x'', ‖holderApprox R t ϕ x''‖) + ⨆ x'', ‖holderApprox R t ϕ x''‖ := by
        gcongr
        · apply le_ciSup (f := (‖holderApprox R t ϕ ·‖)) (c := x')
          sorry -- proven above, TODO copy!
        · apply le_ciSup (f := (‖holderApprox R t ϕ ·‖)) (c := x)
          sorry -- proven above, likewise
      _ = (⨆ x'' : ball z R, ‖holderApprox R t ϕ x''‖) + ⨆ x'' : ball z R, ‖holderApprox R t ϕ x''‖ :=
        sorry -- also proven above, can copy (or rewrite the other steps accordingly)
      _ = 2 * ⨆ x'' : ball z R, ‖holderApprox R t ϕ x''‖ := by rw [two_mul]
      _ ≤ 2 * C := by
        gcongr
        exact Real.iSup_le eqn8016 NNReal.zero_le_coe

  have computation (x x' y : X) := calc
     (∫ y, cutoff R t x y) * ‖holderApprox R t ϕ x' - holderApprox R t ϕ x‖
    _ = ‖∫ y, (cutoff R t x y * (holderApprox R t ϕ x') - cutoff R t x y * (holderApprox R t ϕ x'))‖ := by
      rw [← Real.norm_of_nonneg (integral_cutoff_positive hR ht.1 x).le]
      -- convert integral to sth complex, then rw [norm_mul]
      -- finally, multiply into the integral (mul_right)
      sorry -- multiply into the integral
    _ = ‖∫ y, (cutoff R t x y * (holderApprox R t ϕ x') - cutoff R t x' y * (holderApprox R t ϕ x') + cutoff R t x' y * (holderApprox R t ϕ x') - cutoff R t x y * (holderApprox R t ϕ x'))‖ := by
      congr with y
      ring -- add and subtract the same term (8.0.20), then swap order of terms
    _ = ‖∫ y, (cutoff R t x y * (holderApprox R t ϕ x') - cutoff R t x' y * (holderApprox R t ϕ x')) + ∫ y, (cutoff R t x' y * (holderApprox R t ϕ x') - cutoff R t x y * (holderApprox R t ϕ x'))‖ := by
      -- set F := fun y ↦ cutoff R t x y * (holderApprox R t ϕ x') - cutoff R t x' y * (holderApprox R t ϕ x')
      -- congr with y
      -- field_simp
      -- ring
      sorry -- integral is linear... somehow
    _ ≤ ‖∫ y, (cutoff R t x y * (holderApprox R t ϕ x') - cutoff R t x' y * (holderApprox R t ϕ x'))‖
      + ‖∫ y, (cutoff R t x' y * (holderApprox R t ϕ x') - cutoff R t x y * (holderApprox R t ϕ x'))‖ := by

      set A := ∫ y, (cutoff R t x y * (holderApprox R t ϕ x') - cutoff R t x' y * (holderApprox R t ϕ x'))
      set B := ∫ y, (cutoff R t x' y * (holderApprox R t ϕ x') - cutoff R t x y * (holderApprox R t ϕ x'))
      convert norm_add_le (E := ℂ) A B
      have : ∫ (y : X), ↑(cutoff R t x y) * holderApprox R t ϕ x' - ↑(cutoff R t x' y) * holderApprox R t ϕ x' = A :=
        sorry
      --rw [this]
      --_ _
      sorry --apply? -- triange inequality
    -- next: pull out common factor on the left, and on the right






    _ = 1 := sorry
  sorry

#exit

/-- The constant occurring in Proposition 2.0.5. -/
def C2_0_5 (a : ℝ) : ℝ≥0 := 2 ^ (8 * a)

/-- Proposition 2.0.5. -/
theorem holder_van_der_corput {z : X} {R : ℝ≥0} (hR : 0 < R) {ϕ : X → ℂ}
    (hϕ : support ϕ ⊆ ball z R) (h2ϕ : hnorm (a := a) ϕ z R < ∞) {f g : Θ X} :
    ‖∫ x, exp (I * (f x - g x)) * ϕ x‖₊ ≤
    (C2_0_5 a : ℝ≥0∞) * volume (ball z R) * hnorm (a := a) ϕ z R *
    (1 + nndist_{z, R} f g) ^ (2 * a^2 + a^3 : ℝ)⁻¹ := sorry
