# HRTL Scoring 2022: Psychometric Foundation

## Purpose

This document explains the theoretical and statistical foundations underlying the HRTL scoring algorithm. Understanding these concepts is critical for interpreting results, making design decisions, and troubleshooting issues during migration.

---

## Item Factor Analysis (IFA) Basics

### What is IFA?

**Item Factor Analysis** is a statistical framework for analyzing ordinal survey responses (e.g., "Never", "Sometimes", "Often", "Always"). It's the categorical data equivalent of traditional factor analysis.

**Key Concepts:**
- **Latent Trait**: An unobserved ability/construct (e.g., "Early Learning Skills") that causes item responses
- **Item Response Function**: Probability of responding in category k given the latent trait level
- **Ordinal Scaling**: Response categories have meaningful order but unknown intervals

**Why IFA Instead of Raw Scores?**
1. **Handles non-linear relationships**: "Never" to "Sometimes" may not equal "Sometimes" to "Often"
2. **Missing data**: IFA estimates latent traits even with partial responses
3. **Measurement error**: Explicitly models uncertainty in individual scores
4. **Differential item functioning**: Can detect if items work differently across groups

---

### IFA in This Project

**Model Type:** 2-Parameter Logistic (2PL) Graded Response Model

**Evidence:** `1 - Fit BRMS.R`, lines 246-256
```r
mirt_model <- brms::bf(
  y | thres(gr=item) ~ exp(loglambda)*eta,  # 2PL Graded Response
  eta ~ 0 + (0+domain | person) + ...
  loglambda ~ 0 + prefix,
  nl = TRUE,
  family = cumulative(link = "logit", link_disc = "log")
)
```

**Parameters:**
- `eta`: Latent ability (θ in IRT notation)
- `loglambda`: Item discrimination (how well item separates low vs. high ability)
- `thres`: Threshold parameters (boundaries between response categories)

**Workflow:**
1. **Recoding Phase** (this scoring function): Transform raw CAHMI → IFA-ready ordinal codes
2. **Modeling Phase** (BRMS): Estimate latent traits and item parameters
3. **Scoring Phase** (CAHMI method): Use age-specific thresholds on IFA-coded items

---

## 0-Indexing Rationale

### Why Start at 0?

**Original Code:** `get_cahmi_values_map.R`, line 30
```r
values_map$values_ifa[idx] = values_map$values_raw[idx] - 1
```

**SPSS Raw Values:**
```
1 = Always
2 = Most of the time
3 = About half the time
4 = Sometimes
5 = Never
```

**IFA Recoding (Before Reversal):**
```
0 = Always
1 = Most of the time
2 = About half the time
3 = Sometimes
4 = Never
```

**Psychometric Reasons:**

1. **IRT Software Conventions**
   - Mplus, Stan, JAGS expect 0-indexed ordinal data
   - Threshold estimation treats first category as reference (θ = 0)
   - Parameterization: P(Y ≥ k | θ) uses k = 1, 2, ..., K-1 thresholds for K categories

2. **Mathematical Convenience**
   - Category count = max(values_ifa) + 1
   - Array indexing in C/C++ backends starts at 0
   - Simplifies threshold algebra

3. **Missing Data Distinction**
   - Valid responses: 0, 1, 2, 3, 4
   - Missing: NA/NULL
   - Avoids confusion with 1-based systems where 0 might mean "missing"

**Implementation Note:**
- This is a data preparation step only
- Final HRTL scores don't depend on whether you use 0-4 or 1-5
- But **threshold values** in Excel files assume 0-indexed data!

---

## Reverse Coding and Age Gradients

### The Problem: Inconsistent Directionality

**Example Items:**

| Item | Raw Scale | High Values Mean |
|------|-----------|------------------|
| RecogBegin (sound recognition) | 1=Always, 5=Never | High = Poor |
| Distracted | 1=Always, 5=Never | High = Poor |
| K2Q01 (health) | 1=Excellent, 5=Poor | High = Poor |
| StartNewAct (difficulty transitioning) | 1=Always, 5=Never | High = Better (difficulty=bad, but "never difficult"=good) |

**Why This Matters:**
- Items measuring the **same latent construct must point the same direction**
- Without reversal, factor loadings would be negative for some items
- Age gradients would be inconsistent (older children worse on some items?)

---

### Positive Age Gradients

**Evidence:** `functions/e3.R`, line 21 comment:
```r
# need to reverse for positive age gradient
```

**What is an Age Gradient?**
- Correlation between age and item performance
- **Expected pattern**: Older preschoolers (age 5) outperform younger (age 3) on developmental skills
- **Positive gradient**: As age ↑, score ↑

**Without Reverse Coding:**
```
Age 3: RecogBegin raw = 5 (Never) → High score
Age 5: RecogBegin raw = 1 (Always) → Low score
Correlation: negative age gradient (WRONG!)
```

**With Reverse Coding:**
```
Age 3: RecogBegin raw = 5 → IFA = 0 (After reversal)
Age 5: RecogBegin raw = 1 → IFA = 4 (After reversal)
Correlation: positive age gradient (CORRECT!)
```

---

### Reverse Coding Algorithm

**Code:** `get_cahmi_values_map.R`, lines 34-36
```r
if(reverse){
  values_map$values_ifa = with(values_map,
    plyr::mapvalues(values_ifa,
                    from = values_ifa %>% na.omit(),
                    to = sort(values_ifa, decreasing = T)))
}
```

**Step-by-Step:**

1. **Before reversal** (5-category item):
   ```
   values_raw: 1, 2, 3, 4, 5
   values_ifa: 0, 1, 2, 3, 4
   ```

2. **Identify valid values**: 0, 1, 2, 3, 4 (excluding NA)

3. **Sort descending**: 4, 3, 2, 1, 0

4. **Map**:
   ```
   from: 0, 1, 2, 3, 4
   to:   4, 3, 2, 1, 0
   ```

5. **After reversal**:
   ```
   values_raw: 1, 2, 3, 4, 5
   values_ifa: 4, 3, 2, 1, 0
   ```

**Result:** Higher values_ifa = Better performance

---

### Items Requiring Reversal (2022)

**From `get_itemdict22.R`, lines 87-88:**
```r
items22_reverse = c(1.22, 2.22, 4.22, 5.22, 6.22, 8.22, 9.22, 10.22,
                    11.22, 12.22, 13.22, 14.22, 15.22, 25.22, 26.22, 27.22, 28.22)
```

**17 of 28 items (61%) are reversed**

**Not Reversed:**
- Items 3, 7, 16-24: StartNewAct, CalmDown, WaitForTurn, Distracted, Temper, Motor items
- These items already measure dysfunction/difficulty, so "Never" (raw=5) = good (ifa=4, no reversal needed)

---

## Threshold Derivation

### What Are Thresholds?

**Definition:** Age-specific cut-points that classify IFA-coded responses as "Needs Support", "Emerging", or "On-Track"

**Example:** RecogBegin_22 (y22_1) for 4-year-olds
```
IFA Value:  0    1    2    3    4
                        ↑         ↑
                    emerging  on_track
```
- If child scores 0-1: Needs Support
- If child scores 2: Emerging
- If child scores 3-4: On-Track

---

### Age-Specific Thresholds

**Why Different Thresholds by Age?**

Developmental expectations increase with age:

| Item | Age | Emerging | On-Track |
|------|-----|----------|----------|
| RecogBegin (hypothetical) | 3 | 1 | 2 |
| RecogBegin | 4 | 2 | 3 |
| RecogBegin | 5 | 3 | 4 |

- 3-year-old scoring 2 (About half the time) = On-Track
- 5-year-old scoring 2 = Only Emerging
- Reflects normative development: older children expected to perform better

---

### Likely Derivation Method (Ghandour 2024)

**The documentation doesn't specify the exact method, but common approaches:**

#### Method 1: Percentile Norms
```
Emerging threshold = 25th percentile of IFA values for that age
On-Track threshold = 50th or 60th percentile
```

**Pros:**
- Empirically derived from data
- Age-appropriate by design

**Cons:**
- Arbitrary percentile choices
- Sample-dependent

---

#### Method 2: IRT-Based Standards
```
1. Fit IRT model to estimate latent ability (θ)
2. Map θ to item expected scores
3. Set thresholds where E[X|θ] crosses meaningful values
```

**Example:**
- Emerging: θ = -0.5 SD (below average but not extreme)
- On-Track: θ = 0.0 SD (average or better)

**Pros:**
- Accounts for measurement error
- Theoretically grounded

**Cons:**
- Complex to explain
- Requires IRT software

---

#### Method 3: Expert Judgment
```
Panel of developmental experts rates:
"What level of performance is age-appropriate?"
```

**Pros:**
- Face validity
- Clinical relevance

**Cons:**
- Subjective
- May not reflect actual population distributions

---

### Threshold Stability

**Key Question:** How much data is needed for reliable thresholds?

**Rough Guidelines (from IRT literature):**
- Minimum 100 children per age group (3, 4, 5) per item
- Prefer 200+ for stability
- 2022 NSCH: ~11,121 children ages 3-5 → ~3,700 per age group (adequate)

**Validation:**
- Compare thresholds across independent samples
- Bootstrap confidence intervals
- Sensitivity analysis: how much do results change if thresholds shift ±0.5?

**Documentation Gap:**
- Threshold confidence intervals not provided in Excel file
- No guidance on regenerating thresholds for new data

---

## Domain Structure Theory

### Five Domains (2022 Framework)

**From `get_itemdict22.R`, lines 14-21:**

1. **Early Learning Skills (ELS)** - 9 items
   - Phonological awareness (sounds, rhyming)
   - Letter/number recognition
   - Counting, simple math

2. **Social-Emotional Development (SED)** - 6 items
   - Communication (explaining experiences)
   - Emotional recognition
   - Prosocial behavior (sharing, playing well, empathy)

3. **Self-Regulation** - 5 items
   - Task persistence/focus
   - Behavioral control (temper, distraction)
   - Transitions, waiting

4. **Motor Development** - 4 items
   - Fine motor (drawing shapes, faces, people)
   - Gross motor (bouncing ball)

5. **Health** - 3 items
   - General health status
   - Oral health (teeth condition)
   - Functional limitations

---

### Theoretical Framework

**Likely Based On:**

1. **National School Readiness Goals (NEGP, 1995)**
   - Physical health and motor development
   - Social-emotional development
   - Language and cognitive skills
   - General knowledge
   - Approaches to learning (self-regulation)

2. **Title V Maternal and Child Health Block Grant**
   - HRTL is a **National Performance Measure**
   - School readiness defined holistically, not just academics

3. **Bioecological Model (Bronfenbrenner)**
   - Multiple domains interact
   - No single domain fully captures "readiness"
   - Context-dependent development

---

### Why Did Domains Change? (2016 → 2022)

**2016 Framework:** 4 domains
- Early Learning Skills (7 items)
- Physical Health and Motor Development (3 items)
- Social-Emotional Development (4 items)
- Self-Regulation (4 items)

**2022 Framework:** 5 domains
- Early Learning Skills (9 items) - **Expanded**
- Social-Emotional Development (6 items) - **Expanded**
- Self-Regulation (5 items) - **Expanded**
- Motor Development (4 items) - **Separated from Health**
- Health (3 items) - **Separated from Motor**

**Rationale (Inferred):**
1. **Conceptual clarity**: Health and motor skills are distinct constructs
2. **Item growth**: More items available in 2022 survey
3. **Factor analysis**: Empirical evidence that 5-factor model fits better
4. **Policy alignment**: Better matches Title V reporting structure

---

### Item-Domain Assignment Shifts

**Example: ClearExp (Explaining Experiences)**
- **2016:** Early Learning Skills domain
- **2022:** Social-Emotional Development domain

**Possible Reasons:**
1. **Reconceptualization**: Originally seen as language/cognitive, now seen as social communication
2. **Factor loadings**: Empirical analysis showed stronger correlation with SED items
3. **Content validity**: Experts reclassified based on developmental theory

**Impact on Migration:**
- Must use year-specific domain assignments
- Cannot directly compare domain scores across years
- Individual item scores can be compared (with harmonization)

---

## Design Decisions Explained

### Why Mean Instead of Sum? (2016 → 2022 Change)

**2016 Approach:**
```r
sum_code = sum(code_hrtl16)  # Total points across items
```

**2022 Approach:**
```r
avg_score = mean(code_hrtl22, na.rm = TRUE)  # Average points per item
```

---

#### Advantages of Mean:

**1. Missing Data Handling**
- **Sum penalizes missingness**: Child with 5/9 items answered gets lower sum
- **Mean adjusts automatically**: 5 items averaged = same scale as 9 items averaged
- Allows children with partial responses to be scored fairly

**2. Domain Comparability**
- ELS: 9 items → sum range 9-27 (2016: 0-14)
- Health: 3 items → sum range 3-9 (2016: 0-4)
- Sums have different ranges, means don't (both 1.0-3.0)

**3. Interpretability**
- Mean of 2.5 = "Average item score is halfway between Emerging (2) and On-Track (3)"
- Sum of 23 = Less intuitive

**4. Threshold Consistency**
- Single set of cutoffs (2.0, 2.5) works for all domains
- Sum would need domain-specific cutoffs (e.g., ELS ≥ 22, Health ≥ 7)

---

#### Disadvantages of Mean:

**1. Unequal Weighting**
- Child with 1/9 ELS items has domain score based on single item
- No minimum N requirement → unstable estimates

**2. Reliability Issues**
- Fewer items = lower reliability
- Mean doesn't account for measurement error

**3. Missing Not at Random**
- If hardest items are skipped, mean overestimates ability
- MCAR (missing completely at random) assumption often violated

---

#### Why Make This Change?

**Speculation (not documented):**
1. **Item count expanded** (2016: 20 items → 2022: 28 items)
   - More flexibility in response patterns
   - Sum penalties would be harsher

2. **Survey administration**
   - Skip logic may leave some items unanswered by design
   - Mean approach more robust

3. **Analytic consistency**
   - IRT models use averages/scaling, not sums
   - Aligning scoring with modeling approach

---

### Why 2.5 Cutoff for "On-Track"?

**Code:** `hrtl_scoring_2022.R`, line 39
```r
summdat$index_cat[summdat$avg_score >= 2.5] = 3  # On-Track
```

**Scale:**
- 1 = Needs Support (item-level)
- 2 = Emerging (item-level)
- 3 = On-Track (item-level)

**Domain average of 2.5 means:**
- "On average, items are between Emerging and On-Track"
- If all items scored 2 (Emerging), avg = 2.0 → Emerging domain
- If all items scored 3 (On-Track), avg = 3.0 → On-Track domain
- **2.5 = majority of items must be On-Track**

---

#### Mathematical Interpretation:

For 9-item domain (ELS):
- Avg = 2.5 requires total points ≥ 22.5
- Possible combinations:
  - 5 items On-Track (3) + 4 Emerging (2) = 5×3 + 4×2 = 23 → On-Track domain
  - 4 items On-Track + 5 Emerging = 4×3 + 5×2 = 22 → Emerging domain

**Interpretation:** Need majority (>50%) of items to be On-Track for domain to be On-Track

---

#### Policy Implications:

**Strict Standard:**
- Not enough to have "most items emerging"
- Requires clear majority at highest level
- Reflects high bar for school readiness

**Sensitivity:**
- Lowering to 2.4 would increase On-Track prevalence
- Raising to 2.6 would decrease it
- Choice of 2.5 = midpoint compromise

**Documentation Gap:** No sensitivity analysis published showing impact of varying cutoff

---

### Why Strict HRTL Criteria?

**Definition:** `hrtl = (n_on_track >= 4 & n_needs_support == 0)`

**Why Both Conditions?**

#### Scenario Analysis:

| Domains | On-Track | Emerging | Needs Support | HRTL? |
|---------|----------|----------|---------------|-------|
| A | 5 | 0 | 0 | **YES** |
| B | 4 | 1 | 0 | **YES** |
| C | 4 | 0 | 1 | **NO** |
| D | 3 | 2 | 0 | **NO** |

**Case C is key:** 4/5 On-Track but 1 Needs Support = NOT HRTL

---

#### Rationale:

**1. Risk-Based Approach**
- Even one area of serious deficit may impede school success
- **Compensatory model rejected** (can't make up for major weakness with strengths)
- **Conjunctive model adopted** (must meet minimum in all areas)

**2. Policy/Intervention Targeting**
- Children with "Needs Support" in any domain require immediate intervention
- HRTL classification = "ready WITHOUT additional support"
- Not ready = eligible for services

**3. Developmental Interconnectedness**
- Domains aren't independent
- Health crisis affects learning
- Self-regulation problems affect social skills
- One major deficit cascades

---

#### Alternative Definitions (Not Used):

**Total Score Approach:**
```
HRTL = sum of all domain scores >= 12 (out of 15)
```
- Pro: Simpler
- Con: Allows major deficit in one area

**Average Score Approach:**
```
HRTL = mean domain score >= 2.5
```
- Pro: Continuous measure
- Con: Obscures specific deficits

**Weighted Approach:**
```
HRTL = weighted sum (ELS × 0.4 + SED × 0.3 + ...)
```
- Pro: Reflects differential importance
- Con: Requires justification for weights

---

## Measurement Properties

### Reliability

**Not explicitly documented in codebase**, but IFA provides:

1. **Item Reliability:** Discrimination parameters (λ) indicate how well items separate high/low ability
2. **Scale Reliability:** Analogous to Cronbach's α in CTT
3. **Person Reliability:** Standard error of measurement for each child

**Expected Values (from IRT literature):**
- Item discrimination > 1.0 = Good
- Scale reliability > 0.80 = Adequate
- SE(θ) < 0.50 = Precise individual estimates

---

### Validity Evidence

**From Validation Functions:**

1. **Content Validity**
   - Items selected by CAHMI experts
   - Align with developmental milestones
   - Cover breadth of school readiness domains

2. **Construct Validity**
   - Positive age gradients (older children score higher)
   - Domain structure confirmed by factor analysis (inferred)

3. **Concurrent Validity**
   - Comparisons to published Ghandour results
   - `compare_prevalences_Ghandour24()` checks if scoring replicates published values

4. **Predictive Validity**
   - Not assessed in this codebase
   - Would require linking to kindergarten outcomes

---

### Fairness and Bias

**Differential Item Functioning (DIF):**
- Are items easier/harder for some demographic groups controlling for ability?
- Not explicitly tested in this scoring code
- BRMS model (line 250-251, `1 - Fit BRMS.R`) includes state random effects
  - Accounts for geographic variation
  - Could be extended to test for demographic DIF

**Missing Data Bias:**
- Assumption: Missing at random (MAR)
- If low-performing children more likely to skip items, prevalence overestimated
- No sensitivity analysis for MNAR (missing not at random)

---

## Comparison to Classical Test Theory (CTT)

| Aspect | CTT | IFA/IRT |
|--------|-----|---------|
| **Scale** | Sum or mean of raw scores | Latent trait (θ) |
| **Assumptions** | Interval scale, linearity | Ordinal, non-linear |
| **Missing data** | Problematic (sum biased) | Handled via likelihood |
| **Item properties** | Sample-dependent | Item parameters invariant |
| **Person estimates** | Score-dependent | Ability scale |
| **Software** | Excel, SPSS | Mplus, Stan, brms |

**This Project:**
- Uses **IFA-coded data** (ordinal, 0-indexed)
- But applies **CTT-style aggregation** (means, cutoffs)
- Hybrid approach: Prepares data for IRT modeling, but scoring uses simpler methods

**Why Hybrid?**
- Full IRT scoring requires model fitting (slow, complex)
- Age-specific thresholds approximate IRT-based classifications
- Easier to implement and explain for policy audiences

---

## References and Further Reading

### Key Citations:
- Ghandour, R. M., et al. (2024). School readiness among U.S. children ages 3-5. *Pediatrics*.
- Ghandour, R. M., et al. (2019). Healthy developmental milestones among young children. *Pediatrics*.
- Embretson, S. E., & Reise, S. P. (2000). *Item response theory for psychologists*. Psychology Press.
- Samejima, F. (1969). Estimation of latent ability using a response pattern of graded scores. *Psychometrika*.

### Online Resources:
- CAHMI surveys: https://www.cahmi.org/
- NSCH data: https://www.childhealthdata.org/
- Title V MCH: https://mchb.tvisdata.hrsa.gov/

### IRT Software:
- R packages: `mirt`, `TAM`, `brms`, `lavaan`
- Standalone: Mplus, IRTPRO, flexMIRT
- Python: `mirt-py`, `girth`

---

## Summary for Migrators

**Essential Psychometric Knowledge:**

1. **0-indexing is standard for IRT data** - Don't change this
2. **Reverse coding ensures positive age gradients** - Critical for validity
3. **Thresholds are age-specific developmental norms** - Can't use same thresholds for all ages
4. **Domain means allow missing data** - Feature, not bug
5. **HRTL is a strict standard** - Intentionally excludes children with any major deficit

**When in Doubt:**
- Preserve the original algorithm's logic exactly
- Validate against published prevalence estimates
- Consult psychometric literature for IRT/IFA best practices
