# HRTL Scoring 2022: Validation Protocol

## Purpose

This document provides step-by-step procedures for validating your implementation of the `hrtl_scoring_2022()` algorithm. Use this guide to verify that migration to a new data architecture produces correct results.

---

## Quick Validation Checklist

Before diving into detailed testing, run this high-level checklist:

- [ ] **Data transformation applied**: DailyAct_22 conditional recoding based on HCABILITY
- [ ] **Age filtering works**: Only children aged 3, 4, or 5 included
- [ ] **IFA recoding complete**: All 28 items converted to 0-indexed values
- [ ] **Reverse coding correct**: 17 items have reversed directionality (higher = better)
- [ ] **Thresholds joined**: Every (item × age) combination has on_track and emerging values
- [ ] **Domain aggregation**: Means computed, not sums
- [ ] **Domain cutoffs**: <2.0 = Needs Support, 2.0-2.49 = Emerging, ≥2.5 = On-Track
- [ ] **HRTL logic**: (n_on_track ≥ 4) AND (n_needs_support == 0)
- [ ] **Weights preserved**: FWC variable included in output
- [ ] **Prevalence in range**: Overall HRTL between 50-70%

---

## Step 1: Manual Trace Through Algorithm

### Create Test Case

**Single child with known values:**

```r
# R test data
test_child = data.frame(
  HHID = 999001,
  SC_AGE_YEARS = 4,
  HCABILITY = 1,
  FWC = 1000,

  # Early Learning Skills (9 items)
  RecogBegin_22 = 2,      # Most of the time
  SameSound_22 = 1,       # Always
  RhymeWordR_22 = 3,      # About half
  RecogLetter_22 = 2,     # Some letters
  WriteName_22 = 2,       # Most of the time
  ReadOneDigit_22 = 4,    # Sometimes
  COUNTTO_R = 3,          # To 20
  GroupOfObjects_22 = 2,  # Most of the time
  SimpleAddition_22 = 3,  # About half

  # Social-Emotional (6 items)
  ClearExp_22 = 2,        # Most of the time
  NameEmotions_22 = 2,    # Most of the time
  ShareToys_22 = 2,       # Most of the time
  PlayWell_22 = 1,        # Always
  HurtSad_22 = 2,         # Most of the time
  FocusOn_22 = 2,         # Most of the time

  # Self-Regulation (5 items)
  StartNewAct_22 = 3,     # About half difficulty
  CalmDownR_22 = 3,       # About half difficulty
  WaitForTurn_22 = 3,     # About half difficulty
  distracted_22 = 3,      # About half the time
  temperR_22 = 4,         # Sometimes loses temper

  # Motor Development (4 items)
  DrawCircle_22 = 2,      # Pretty well
  DrawFace_22 = 2,        # Pretty well
  DrawPerson_22 = 1,      # Not very well
  BounceBall_22 = 3,      # OK

  # Health (3 items)
  K2Q01 = 2,              # Very good health
  K2Q01_D = 2,            # Very good teeth
  DailyAct_22 = 2         # Should become 0 due to HCABILITY=1
)
```

---

### Expected Results: Step-by-Step

#### Step 1.1: DailyAct Transformation

**Before:**
```
DailyAct_22 = 2
HCABILITY = 1
```

**After:**
```
DailyAct_22 = 0  (forced due to HCABILITY == 1)
```

---

#### Step 1.2: IFA Recoding

**Early Learning Skills (all reverse-coded):**

| Item | Raw | Reverse? | IFA |
|------|-----|----------|-----|
| RecogBegin_22 | 2 | Yes | 3 (5-cat: 4,3,2,1,0) |
| SameSound_22 | 1 | Yes | 4 |
| RhymeWordR_22 | 3 | Yes | 2 |
| RecogLetter_22 | 2 | No (numeric scale) | varies by scale |
| WriteName_22 | 2 | Yes | 3 |
| ReadOneDigit_22 | 4 | Yes | 1 |
| COUNTTO_R | 3 | No (special scale) | varies |
| GroupOfObjects_22 | 2 | Yes | 3 |
| SimpleAddition_22 | 3 | Yes | 2 |

**Note:** Exact IFA values depend on item-specific scales in `values_map`. Above assumes 5-category (0-4) scale with reversal.

---

#### Step 1.3: Apply Age-Specific Thresholds (Age 4)

Assume these thresholds for age 4 (hypothetical, use actual from Excel):

| Item (lex_ifa) | IFA Value | Emerging | On-Track | Classification |
|----------------|-----------|----------|----------|----------------|
| y22_1 (RecogBegin) | 3 | 2 | 3 | On-Track (3≥3) |
| y22_2 (SameSound) | 4 | 2 | 3 | On-Track (4≥3) |
| y22_3 (RhymeWord) | 2 | 2 | 3 | Emerging (2≥2, but 2<3) |
| ... | ... | ... | ... | ... |

**3-Point Scoring:**
- IFA < emerging → code_hrtl22 = 1 (Needs Support)
- emerging ≤ IFA < on_track → code_hrtl22 = 2 (Emerging)
- IFA ≥ on_track → code_hrtl22 = 3 (On-Track)

---

#### Step 1.4: Domain Aggregation

**Example: Early Learning Skills**

Assume item classifications:
- RecogBegin: 3 (On-Track)
- SameSound: 3 (On-Track)
- RhymeWord: 2 (Emerging)
- RecogLetter: 3 (On-Track)
- WriteName: 3 (On-Track)
- ReadOneDigit: 1 (Needs Support)
- CountTo: 2 (Emerging)
- GroupOfObjects: 3 (On-Track)
- SimpleAddition: 2 (Emerging)

**Mean:** (3+3+2+3+3+1+2+3+2) / 9 = 22/9 = 2.44

**Domain Classification:**
- 2.44 < 2.5 → **Emerging** (not On-Track)

---

**All Domains (Hypothetical):**

| Domain | Avg Score | Classification |
|--------|-----------|----------------|
| Early Learning Skills | 2.44 | Emerging |
| Social-Emotional Dev | 2.67 | On-Track |
| Self-Regulation | 2.20 | Emerging |
| Motor Development | 2.25 | Emerging |
| Health | 2.67 | On-Track (note: DailyAct = 0 helps) |

---

#### Step 1.5: Overall HRTL

**Counts:**
- n_on_track = 2 (SED, Health)
- n_needs_support = 0

**HRTL Calculation:**
```
hrtl = (2 >= 4) AND (0 == 0)
     = FALSE AND TRUE
     = FALSE
```

**Result:** Child is **NOT HRTL** (only 2/5 domains On-Track, need 4+)

---

### Validation Check

**Run your implementation on test_child and verify:**

```python
# Python example
result = hrtl_scoring_2022(test_data, itemdict, thresholds)

assert result['overall'].loc[0, 'HHID'] == 999001
assert result['overall'].loc[0, 'n_on_track'] == 2
assert result['overall'].loc[0, 'n_needs_support'] == 0
assert result['overall'].loc[0, 'hrtl'] == False

assert len(result['by_domain']) == 5  # Five domains
assert result['by_domain'].query("domain_2022 == 'Early Learning Skills'")['code'].values[0] == 'Emerging'
```

**If any assertion fails, debug that specific step in your implementation.**

---

## Step 2: Item-Level Validation

### Replicate Published Response Distributions

**Objective:** Verify item recoding matches Ghandour (2024) Supplementary Table 1

**Method:** Compare weighted means of IFA-coded items

### Test Function

**Original:** `functions/compare_SuppTable1_Ghandour24.R`

**Key Comparisons:**
- Weighted N per item
- Weighted mean (should match published values ± 0.05)
- Min/Max values (check recoding range)

### Implementation

```r
# R validation
library(gt)

# Load published values
published = readxl::read_excel("datasets/intermediate/Ghandour-2024-Supplementary-Data.xlsx")

# Your scoring output (before domain aggregation)
your_items = ifadat %>%
  tidyr::pivot_longer(starts_with("y22_"), names_to = "lex_ifa", values_to = "y") %>%
  dplyr::left_join(itemdict %>% dplyr::select(lex_ifa, var_cahmi), by = "lex_ifa") %>%
  dplyr::left_join(dat %>% dplyr::select(HHID, FWC), by = "HHID")

# Compute weighted statistics
your_stats = your_items %>%
  dplyr::group_by(var_cahmi) %>%
  dplyr::summarise(
    N_weighted = sum(FWC[!is.na(y)]),
    Mean = weighted.mean(y, FWC, na.rm = TRUE),
    Min = min(y, na.rm = TRUE),
    Max = max(y, na.rm = TRUE)
  )

# Compare
comparison = published %>%
  dplyr::inner_join(your_stats, by = "var_cahmi", suffix = c("_pub", "_yours")) %>%
  dplyr::mutate(
    Diff_Mean = abs(Mean_pub - Mean_yours),
    Pass = Diff_Mean < 0.05
  )

# Print failures
comparison %>% dplyr::filter(!Pass) %>% print()
```

---

### Acceptance Criteria

**Item Mean Differences:**
- **Pass:** |Difference| < 0.05
- **Acceptable:** |Difference| < 0.10 (may be due to rounding or sample differences)
- **Fail:** |Difference| ≥ 0.10 (indicates recoding error)

**Common Causes of Failures:**
- Reverse coding not applied (mean flipped)
- Wrong values_map (different scale used)
- Missing data not handled correctly
- DailyAct transformation forgotten

---

## Step 3: Domain-Level Validation

### Replicate Published Prevalence Estimates

**Objective:** Match Ghandour (2024) domain and overall HRTL prevalences

**Published Values (2022):**
```r
expected_prevalences = data.frame(
  Domain = c("Overall HRTL",
             "Early Learning Skills",
             "Social-Emotional Development",
             "Self-Regulation",
             "Motor Development",
             "Health"),
  Published_Pct = c(63.6, 68.8, 84.3, 73.2, 81.0, 86.5)
)
```

---

### Test Function

**Original:** `functions/compare_prevalences_Ghandour24.R`

```r
# Overall HRTL prevalence
overall_prev = results$overall %>%
  dplyr::summarise(
    HRTL_Pct = weighted.mean(hrtl, FWC, na.rm = TRUE) * 100
  )

# Domain-level prevalence (On-Track %)
domain_prev = results$by_domain %>%
  dplyr::group_by(domain_2022) %>%
  dplyr::summarise(
    OnTrack_Pct = weighted.mean(code == "On-Track", FWC, na.rm = TRUE) * 100
  )

# Compare
comparison = expected_prevalences %>%
  dplyr::left_join(
    domain_prev %>% dplyr::rename(Domain = domain_2022, Your_Pct = OnTrack_Pct),
    by = "Domain"
  ) %>%
  dplyr::mutate(
    Difference = Your_Pct - Published_Pct,
    Pass = abs(Difference) < 2.0
  )

print(comparison)
```

---

### Acceptance Criteria

**Prevalence Differences:**
- **Pass:** |Difference| < 2.0 percentage points
- **Acceptable:** 2.0 ≤ |Difference| < 5.0 (may be due to sample/version differences)
- **Fail:** |Difference| ≥ 5.0 (indicates algorithm error)

**Why Allow 2% Tolerance?**
- Survey data has sampling variability
- Different data vintages (DRC versions) may have slight differences
- Rounding in published tables
- Weighting adjustments

---

### Debugging Large Differences

**If Overall HRTL > 10% off:**

1. **Check HRTL logic:**
   ```python
   # Should be AND, not OR
   hrtl = (n_on_track >= 4) & (n_needs_support == 0)  # Correct
   hrtl = (n_on_track >= 4) | (n_needs_support == 0)  # Wrong!
   ```

2. **Check domain cutoffs:**
   ```python
   # Should be 2.5, not 2.0
   code[avg_score >= 2.5] = 'On-Track'  # Correct
   code[avg_score >= 2.0] = 'On-Track'  # Wrong!
   ```

3. **Check n_on_track counting:**
   ```python
   # Should count On-Track, not all non-missing
   n_on_track = (code == 'On-Track').sum()  # Correct
   n_on_track = code.notna().sum()  # Wrong!
   ```

---

**If Specific Domain > 10% off:**

1. **Check item assignments:**
   ```python
   # Is ClearExp in Social-Emotional (2022)?
   itemdict.query("var_cahmi == 'ClearExp_22'")['domain_2022']
   # Should return: "Social-Emotional Development"
   ```

2. **Check reverse coding:**
   ```python
   # RecogBegin should be reversed
   itemdict.query("var_cahmi == 'RecogBegin_22'")['reverse_coded']
   # Should return: True
   ```

3. **Check DailyAct transformation (if Health domain off):**
   ```python
   # DailyAct should be 0 when HCABILITY=1
   df.query("HCABILITY == 1")['DailyAct_22'].value_counts()
   # Should show: 0.0    <N>  (all zeros)
   ```

---

## Step 4: Weighted Analysis Validation

### Check Survey Weight Properties

**FWC should:**
- Be positive (> 0)
- Not have extreme outliers (max < 10,000 typically)
- Sum to approximately the U.S. population of 3-5 year olds (~12 million)

```python
# Python
print(df['FWC'].describe())
#       count    11121.0
#       mean     1020.3
#       std       485.7
#       min        12.5
#       25%       688.2
#       50%       921.0
#       75%      1265.8
#       max      6543.2

total_weighted = df['FWC'].sum()
print(f"Total weighted N: {total_weighted:,.0f}")
# Expected: ~11-13 million
```

---

### Compare Weighted vs. Unweighted Prevalence

**Expected Pattern:** Weighted and unweighted should differ, but not drastically

```python
# Python
weighted_hrtl = (
    (results['overall']['hrtl'] * results['overall']['FWC']).sum() /
    results['overall']['FWC'].sum()
) * 100

unweighted_hrtl = results['overall']['hrtl'].mean() * 100

print(f"Weighted HRTL: {weighted_hrtl:.1f}%")
print(f"Unweighted HRTL: {unweighted_hrtl:.1f}%")
print(f"Difference: {weighted_hrtl - unweighted_hrtl:.1f} pp")

# Typical difference: 1-5 percentage points
# Large difference (>10 pp) suggests weighting error
```

---

### Validate Weight Application

**Test:** Manually calculate prevalence for small subset

```python
# Create mini dataset
subset = results['overall'].head(10).copy()

# Manual weighted mean
numerator = (subset['hrtl'].astype(int) * subset['FWC']).sum()
denominator = subset['FWC'].sum()
manual_prev = (numerator / denominator) * 100

# Your function's result
subset_prev = weighted_prevalence(subset, 'hrtl', 'FWC') * 100

assert abs(manual_prev - subset_prev) < 0.001, "Weighting calculation error"
```

---

## Step 5: Edge Case Testing

### Test Case 1: All Items Missing for a Domain

```python
edge_case_1 = test_child.copy()

# Set all ELS items to missing
els_items = ['RecogBegin_22', 'SameSound_22', 'RhymeWordR_22',
             'RecogLetter_22', 'WriteName_22', 'ReadOneDigit_22',
             'COUNTTO_R', 'GroupOfObjects_22', 'SimpleAddition_22']

for item in els_items:
    edge_case_1[item] = None

result = hrtl_scoring_2022(edge_case_1, itemdict, thresholds)
```

**Expected:**
- ELS domain: `avg_score = NA`, `code = NA`
- Overall: Child should have only 4 domains scored
- HRTL: Can still be TRUE if 4 non-ELS domains are On-Track with 0 Needs Support

---

### Test Case 2: Exactly at Domain Cutoff

```python
edge_case_2 = test_child.copy()

# Manipulate items so ELS avg = exactly 2.5
# (requires careful selection of item values)

result = hrtl_scoring_2022(edge_case_2, itemdict, thresholds)
```

**Expected:**
- ELS domain: `avg_score = 2.5`, `code = "On-Track"`
- Verify inequality: `avg_score >= 2.5` includes equality

---

### Test Case 3: HRTL Boundary (Exactly 4 On-Track)

```python
edge_case_3 = test_child.copy()

# Manipulate to get exactly:
# 4 domains On-Track, 1 Emerging, 0 Needs Support

result = hrtl_scoring_2022(edge_case_3, itemdict, thresholds)
```

**Expected:**
- n_on_track = 4
- n_needs_support = 0
- HRTL = TRUE (boundary case included)

---

### Test Case 4: HRTL False Due to Needs Support

```python
edge_case_4 = test_child.copy()

# 4 domains On-Track, 1 Needs Support

result = hrtl_scoring_2022(edge_case_4, itemdict, thresholds)
```

**Expected:**
- n_on_track = 4
- n_needs_support = 1
- HRTL = FALSE (strict criterion violated)

---

### Test Case 5: Age Boundaries

```python
# Age exactly 3.0
edge_case_5a = test_child.copy()
edge_case_5a['SC_AGE_YEARS'] = 3

# Age exactly 6.0 (should be excluded)
edge_case_5b = test_child.copy()
edge_case_5b['SC_AGE_YEARS'] = 6

result_a = hrtl_scoring_2022(edge_case_5a, itemdict, thresholds)
result_b = hrtl_scoring_2022(edge_case_5b, itemdict, thresholds)
```

**Expected:**
- Age 3: Included, uses age-3 thresholds
- Age 6: Excluded (no row in output)

---

### Test Case 6: DailyAct with HCABILITY = 0

```python
edge_case_6 = test_child.copy()
edge_case_6['HCABILITY'] = 0
edge_case_6['DailyAct_22'] = 3  # High functional limitation

result = hrtl_scoring_2022(edge_case_6, itemdict, thresholds)
```

**Expected:**
- DailyAct_22 remains 3 (NOT transformed to 0)
- Health domain score affected (lower than test_child)

---

## Step 6: Regression Testing

### Create Reference Output

**After validating your implementation, save reference output:**

```python
# Python
reference_results = hrtl_scoring_2022(raw22, itemdict, thresholds)

reference_results['overall'].to_csv('reference_overall.csv', index=False)
reference_results['by_domain'].to_csv('reference_by_domain.csv', index=False)

# Save checksums
import hashlib

def hash_df(df):
    return hashlib.md5(df.to_string().encode()).hexdigest()

checksums = {
    'overall': hash_df(reference_results['overall']),
    'by_domain': hash_df(reference_results['by_domain'])
}

import json
with open('reference_checksums.json', 'w') as f:
    json.dump(checksums, f)
```

---

### Regression Test Suite

**Run after any code changes:**

```python
def test_regression():
    # Load reference
    ref_overall = pd.read_csv('reference_overall.csv')
    ref_by_domain = pd.read_csv('reference_by_domain.csv')

    # Run current implementation
    current = hrtl_scoring_2022(raw22, itemdict, thresholds)

    # Compare
    pd.testing.assert_frame_equal(current['overall'], ref_overall)
    pd.testing.assert_frame_equal(current['by_domain'], ref_by_domain)

    print("✓ Regression test passed")

test_regression()
```

---

## Step 7: Performance Benchmarking

### Timing

```python
import time

start = time.time()
result = hrtl_scoring_2022(raw22, itemdict, thresholds)
elapsed = time.time() - start

print(f"Scoring {len(raw22)} children took {elapsed:.2f} seconds")
print(f"Average: {elapsed/len(raw22)*1000:.2f} ms per child")

# Typical performance:
# R: 5-15 seconds for 11,121 children
# Python/pandas: 2-8 seconds
# SQL: 1-5 seconds (depends on indexing)
```

---

### Memory

```python
import sys

def get_size_mb(obj):
    return sys.getsizeof(obj) / 1024 / 1024

print(f"Input data: {get_size_mb(raw22):.1f} MB")
print(f"Output overall: {get_size_mb(result['overall']):.1f} MB")
print(f"Output by_domain: {get_size_mb(result['by_domain']):.1f} MB")

# Typical memory:
# Input: 5-20 MB (depends on data structure)
# Output: <1 MB (much smaller than input)
```

---

## Validation Report Template

### Suggested Report Structure

```markdown
# HRTL Scoring Validation Report

**Date:** YYYY-MM-DD
**Implementation:** [Python/SQL/SAS/etc.]
**Data Source:** [NSCH 2022, N = 11,121]

## 1. Item-Level Validation

| Item | Published Mean | Your Mean | Difference | Pass? |
|------|----------------|-----------|------------|-------|
| RecogBegin_22 | 1.85 | 1.83 | -0.02 | ✓ |
| ... | ... | ... | ... | ... |

**Summary:** XX/28 items passed (difference < 0.05)

## 2. Domain-Level Validation

| Domain | Published % | Your % | Difference | Pass? |
|--------|-------------|--------|------------|-------|
| Overall HRTL | 63.6% | 63.2% | -0.4 pp | ✓ |
| Early Learning | 68.8% | 69.1% | +0.3 pp | ✓ |
| ... | ... | ... | ... | ... |

**Summary:** X/6 prevalences passed (difference < 2.0 pp)

## 3. Edge Cases

- [ ] All missing domain: PASS
- [ ] Domain cutoff boundary: PASS
- [ ] HRTL boundary: PASS
- [ ] Needs Support violation: PASS
- [ ] Age filtering: PASS
- [ ] DailyAct transformation: PASS

## 4. Performance

- **Runtime:** X.XX seconds (X.XX ms/child)
- **Memory:** X.X MB peak usage

## 5. Conclusion

[PASS/FAIL] Implementation is [validated/requires fixes]

**Remaining Issues:**
- [List any validation failures or concerns]
```

---

## Common Validation Failures

### Failure: HRTL Prevalence Too High (>75%)

**Likely Causes:**
1. Using OR instead of AND in HRTL logic
2. Domain cutoff too low (2.0 instead of 2.5)
3. Not counting Needs Support correctly
4. DailyAct transformation making Health domain too easy

**Debug:**
```python
# Check distribution of domain classifications
results['by_domain']['code'].value_counts(normalize=True)
# Should see: On-Track ~70-85%, Emerging ~10-20%, Needs Support ~5-10%
```

---

### Failure: HRTL Prevalence Too Low (<50%)

**Likely Causes:**
1. Domain cutoff too high
2. Reverse coding not applied
3. Age thresholds too strict
4. Using sum instead of mean for domain aggregation

**Debug:**
```python
# Check domain means
results['by_domain'].groupby('domain_2022')['avg_score'].describe()
# Means should be 2.0-2.8 range, not 5-10 (would indicate sums)
```

---

### Failure: Specific Domain Prevalence Off

**Likely Causes:**
1. Wrong items assigned to domain
2. Reverse coding missing for that domain's items
3. Special transformation (DailyAct) not applied

**Debug:**
```python
# Trace one child through that domain
child_id = results['overall'].iloc[0]['HHID']
domain_name = 'Health'

longdat.query(f"HHID == {child_id} & domain_2022 == '{domain_name}'")
# Check: are lex_ifa correct? Are IFA values reasonable?
```

---

## Final Validation Sign-Off

**Before deploying your implementation in production, verify:**

- [ ] All 28 items validated (means match published)
- [ ] All 6 prevalences validated (within 2 pp of published)
- [ ] Edge cases handled correctly
- [ ] Regression tests pass
- [ ] Performance acceptable (<30 seconds for 10K children)
- [ ] Documentation complete
- [ ] Code reviewed by second person
- [ ] Published results replicated on test dataset

**Validation Completed By:** ___________________
**Date:** ___________________
**Approved By:** ___________________

---

## Resources

- **Published values:** `datasets/intermediate/Ghandour-2024-Supplementary-Data.xlsx`
- **Thresholds:** `datasets/intermediate/HRTL-2022-Scoring-Thresholds.xlsx`
- **Original code:** `functions/hrtl_scoring_2022.R`
- **Architecture doc:** `hrtl_scoring_2022_architecture.md`
- **Migration guide:** `HRTL_Scoring_2022_Migration_Guide.md`
