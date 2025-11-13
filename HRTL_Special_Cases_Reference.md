# HRTL Scoring 2022: Special Cases Reference

## Purpose

This document catalogs all edge cases, exceptions, item-specific quirks, and special handling rules in the HRTL scoring algorithm. Use this as a quick reference when encountering unexpected data patterns or behaviors during migration.

---

## Item-Specific Handling

### DailyAct_22 (Functional Limitations)

**Variable:** `DailyAct_22` (Health domain)
**CAHMI Code:** y22_27 (lex_ifa)

#### Special Transformation

**Location:** `0 - Construct Analytic Datasets - HRTL-2016-2020.R`, line 35

```r
raw22$DailyAct_22[raw22$HCABILITY==1] = 0
```

**Rule:** If `HCABILITY == 1`, force `DailyAct_22 = 0` **before any scoring**

**HCABILITY Variable:**
- Not explicitly documented in codebase
- Appears to indicate "child has normal health/ability status"
- Value 1 = No chronic conditions or disabilities
- Value 0 = Has chronic conditions or disabilities

**Rationale:**
- Children without health conditions should have no functional limitations
- This is a logical constraint, not an empirical observation
- Prevents inconsistent responses (healthy child reported with high limitations)

**Impact:**
- Affects ~70-80% of children (estimate)
- Substantially increases Health domain scores for HCABILITY=1 group
- Missing this transformation will **underestimate** Health domain On-Track prevalence

#### Reverse Coding Exception

**From `get_itemdict22.R`, line 91:**
```r
reverse_only_in_mplus = (startsWith(var_cahmi, "DailyAct"))
```

**Rule:** DailyAct is reversed for **Mplus** analysis but NOT for IFA recoding used in HRTL scoring

**Values (After HCABILITY transformation):**
```
Raw CAHMI scale:
0 = No limitations (after HCABILITY transformation)
1 = Usually not affected / Little effect
2 = Sometimes affected / Some effect
3 = Usually affected / Moderate effect
4 = Always affected / Lot of effect
```

**IFA Recoding (no reversal for scoring):**
```
values_ifa: 0, 1, 2, 3, 4  (same as raw, just 0-indexed if raw started at 1)
```

**Why Exception?**
- DailyAct measures dysfunction (higher = worse), unlike most items
- For Mplus IRT modeling, need consistent directionality (reverse needed)
- For CAHMI scoring, thresholds are calibrated to unreversed scale
- **Different purposes, different transformations**

---

### K2Q01_D (Teeth Condition)

**Variable:** `K2Q01_D` (Health domain)
**CAHMI Code:** y22_26 (lex_ifa)

#### Missing Value Rule

**From `get_itemdict22.R`, lines 99-101:**
```r
if(var_j=="K2Q01_D"){
  force_missing = 6
}
```

**Rule:** Force value 6 ("Don't know") to missing

**SPSS Value Labels:**
```
1 = Excellent
2 = Very good
3 = Good
4 = Fair
5 = Poor
6 = Don't know  ← FORCED TO MISSING
```

**IFA Recoding (with reversal):**
```
Raw: 1  2  3  4  5  6
IFA: 4  3  2  1  0  NA
```

**Rationale:**
- "Don't know" is not an ordinal response on the health continuum
- Including it would artificially extend the scale (5→6 categories)
- Threshold estimation requires true ordinal scale
- Missing is more appropriate than arbitrary numeric code

**Impact:**
- Small percentage of children (estimate <5%) have K2Q01_D = NA
- Health domain calculated from remaining 2 items (K2Q01, DailyAct_22)
- Missing data handled by `na.rm = TRUE` in mean calculation

#### Cross-Year Label Harmonization

**From `0 - Construct Analytic Datasets - HRTL-2016-2020.R`, lines 30-32:**
```r
labels_teeth = sjlabelled::get_values(raw22$K2Q01_D)
names(labels_teeth) = sjlabelled::get_labels(raw22$K2Q01_D)
raw16$K2Q01_D = haven::labelled_spss(raw16$K2Q01_D %>% haven::zap_labels(),
                                      labels = labels_teeth)
```

**Issue:** 2016 K2Q01_D has incorrect or missing SPSS value labels in raw data

**Solution:** Borrow labels from 2022 data before processing 2016

**Migration Note:**
- If using non-SPSS format, manually define teeth labels
- Ensure consistent across all years
- Always force value 6 to NA

---

### COUNTTO_R (Counting Ability)

**Variable:** `COUNTTO_R` (Early Learning Skills domain)
**CAHMI Code:** y22_7 (lex_ifa)

#### Naming Inconsistency

**Pattern Violation:** No year suffix in 2022 data

**Standard Pattern:** `[ItemName]_[YY]`
- Examples: `RecogBegin_22`, `ClearExp_16`

**Exception:** `COUNTTO_R` (2022), `COUNTTO` (2016)
- No `_22` or `_16` suffix
- Both years use COUNTTO (with/without _R)

**Why?**
- Likely legacy variable name in CAHMI survey instrument
- Not renamed during data processing

**Migration Impact:**
- Cannot rely on programmatic name generation
- Must use itemdict lookups explicitly

```python
# Bad (fragile)
var_name = f"COUNTTO_22"  # This variable doesn't exist!

# Good (robust)
var_name = itemdict.loc[itemdict['lex_ifa'] == 'y22_7', 'var_cahmi'].values[0]
# Returns: "COUNTTO_R"
```

#### Special Response Scale

**Not a standard Likert scale** - measures counting ability numerically

**Likely Scale:**
```
1 = Cannot count
2 = Can count to 5
3 = Can count to 10
4 = Can count to 20
5 = Can count to 50+
(Exact scale may vary by year - check SPSS labels)
```

**Reverse Coding:** Not reversed (higher raw value = better counting)

---

### K2Q01 (General Health)

**Variable:** `K2Q01` (Health domain)
**CAHMI Code:** y22_25 (lex_ifa)

#### No Year Suffix

**Same as COUNTTO:** Variable name consistent across all years

- `K2Q01` in 2016
- `K2Q01` in 2022
- No `_16` or `_22` suffix

**Standard SPSS Labels:**
```
1 = Excellent
2 = Very good
3 = Good
4 = Fair
5 = Poor
```

**IFA Recoding (with reversal):**
```
Raw: 1  2  3  4  5
IFA: 4  3  2  1  0
```

**Reverse:** Yes (higher IFA = better health)

---

### temperR_22 vs temper_16

**2022 Variable:** `temperR_22` (Self-Regulation domain)
**2016 Variable:** `temper_16` (Self-Regulation domain)

#### "R" Suffix Inconsistency

**Naming Convention:**
- `temperR_22` - Has "R" suffix in 2022
- `temper_16` - No "R" in 2016

**What "R" Means:**
- Indicates item is reverse-coded in raw CAHMI data
- But this is already handled by `reverse_coded` flag in itemdict
- "R" in variable name is redundant metadata

**Migration Note:**
- Don't assume "R" means reverse-coded in your implementation
- Use `itemdict$reverse_coded` column as source of truth
- Variable name is just a label

**Both items measure:** "How often does this child lose their temper?"
- Scale: 1=Always, 5=Never (2022)
- Higher raw value = less frequent tantrums = better self-regulation

---

### RecogLetter_22 (Letter Recognition)

**Variable:** `RecogLetter_22` (Early Learning Skills domain)
**CAHMI Code:** y22_4 (lex_ifa)

#### Non-Standard Response Scale

**Not frequency-based** - measures quantity of letters recognized

**Likely Scale:**
```
1 = No letters
2 = 1-10 letters
3 = 11-20 letters
4 = All 26 letters
(Exact categories vary - check SPSS labels)
```

**Reverse:** Yes (more letters = higher IFA)

**Different from Other ELS Items:**
- Most ELS items: "How often can this child..."
- RecogLetter: "About how many letters..."

**Threshold Setting:**
- Age-specific expectations
- Age 3: Recognize few letters = On-Track
- Age 5: Recognize all letters = On-Track

---

## Missing Data Patterns

### Item-Level Missing

#### Systematic Missing by Design

**CAHMI Skip Logic:**
- Some items only asked if previous responses meet criteria
- Example: Advanced skill items (SimpleAddition) may be skipped for younger children

**Handling:**
```r
na.rm = TRUE  # Used throughout algorithm
```

**Impact:**
- Child with 5/9 ELS items answered → domain score based on 5 items
- No minimum N requirement (could be 1 item!)

---

#### Random Missing

**Respondent Refusal or Don't Know:**
- Item-specific missing (not whole domain)
- Typically <5% per item

**Detection:**
```python
# Check missing patterns
missing_by_item = (
    ifadat.isna()
    .sum()
    .sort_values(ascending=False)
)
print(missing_by_item)
```

**Handling:** Exclude from mean calculation via `na.rm = TRUE`

---

#### Forced Missing (Value Exclusion)

**K2Q01_D Value 6:** Forced to NA (see above)

**Other Potential Cases:**
- SPSS values 95, 96, 99 (missing data codes)
- Detected automatically by `get_cahmi_values_map()` gap detection
- Not included in `values_ifa` mapping

**Detection Algorithm:** `get_cahmi_values_map.R`, lines 20-29
```r
dv = c(1, diff(values_raw))  # Check consecutive differences

if(!identical(unique(dv), 1)) {
  # Non-consecutive values detected
  idx = seq(1, min(which(dv != 1)) - 1)  # Use only up to first gap
} else {
  idx = 1:nrow(values_map)  # Use all values
}
```

**Example:**
```
values_raw: 1, 2, 3, 4, 5, 95, 96
dv: 1, 1, 1, 1, 1, 90, 1
First gap at position 6 (90 != 1)
Use only: 1, 2, 3, 4, 5
Exclude: 95, 96 (treated as missing)
```

---

### Domain-Level Missing

#### All Items Missing in Domain

**Cause:**
- Skip logic excluded entire domain
- Respondent refused all questions in domain
- Data quality issue

**Handling:** `hrtl_scoring_2022.R`, lines 32-33
```r
avg_score = mean(code_hrtl22, na.rm = TRUE)
avg_score[is.nan(avg_score)] = NA
```

**R Behavior:**
```r
mean(c(NA, NA, NA), na.rm = TRUE)
# Returns: NaN (not NA!)
```

**Correction Required:**
- Convert NaN → NA for consistency
- SQL/pandas may handle differently (often returns NULL/NA automatically)

**Impact on HRTL:**
- Domain with avg_score = NA is excluded from counts
- n_on_track doesn't increase
- Child cannot achieve HRTL if missing 2+ domains (would have max 3 on-track)

---

#### Partial Domain Missing

**Example:** 4/9 ELS items missing

**Calculation:**
```
5 items answered: 3, 3, 2, 3, 2
Mean: (3+3+2+3+2)/5 = 2.6
Domain: On-Track
```

**Same 5 items if 9 answered:**
```
9 items: 3, 3, 2, 3, 2, 1, 1, 2, 2
Mean: (3+3+2+3+2+1+1+2+2)/9 = 2.11
Domain: Emerging
```

**Implication:**
- Missing data can bias domain scores upward (if harder items skipped)
- Or downward (if easier items skipped)
- No bias correction applied in algorithm

---

### Overall HRTL with Missing Domains

**Scenario:** Child has only 3 domains with valid scores

**Calculation:**
```
3 domains: On-Track, On-Track, On-Track
n_on_track = 3
HRTL = (3 >= 4) & (0 == 0) = FALSE
```

**Result:** Cannot achieve HRTL even if all valid domains are On-Track

**This is intentional:**
- HRTL requires comprehensive assessment
- Missing domains = insufficient evidence
- Conservative classification

---

## Survey Design Variables

### STRATUM

**Variable:** Survey stratum identifier
**Type:** Numeric (2016: character, requires coercion)

#### 2016 Data Quality Issue

**From `0 - Construct Analytic Datasets - HRTL-2016-2020.R`, line 27:**
```r
raw16$STRATUM = as.numeric(raw16$STRATUM %>% zap_all())
```

**Problem:** 2016 STRATUM is character type in raw CAHMI SPSS file

**Solution:** Convert to numeric after stripping SPSS labels

**Migration:**
```python
# Python
df_2016['STRATUM'] = pd.to_numeric(df_2016['STRATUM'], errors='coerce')

# SQL
ALTER TABLE raw_2016 ALTER COLUMN stratum TYPE INTEGER USING stratum::integer;
```

---

#### STRATUM Not Used in Scoring

**Important:** `hrtl_scoring_2022()` does NOT use STRATUM

**Where It IS Used:**
- Variance estimation (not in this scoring function)
- `1 - Fit BRMS.R`, line 95: `STRATIFICATION = "stratfip"`
- Combined variable: `stratfip = paste0(stratum, "000", fipsst)`

**Migration Note:**
- Include STRATUM in data pipeline for completeness
- Not required for basic HRTL scoring
- Needed for survey-adjusted standard errors

---

### HHID (Household ID)

**Variable:** Cluster identifier
**Type:** Numeric or character

**Purpose:**
- Unique identifier for each child
- Used for joining datasets
- Cluster variable for survey design

**Uniqueness:**
- Should be unique per child (not per household in this context)
- Despite name, treated as individual child ID in HRTL scoring

**Usage in Scoring:**
- Join key between raw data and recoded data
- Group by variable for domain aggregation

**Watch Out:**
```python
# Check for duplicates
assert df['HHID'].is_unique, "Duplicate HHID values found!"
```

---

### FWC (Final Weight)

**Variable:** Survey weight
**Type:** Numeric (float)

**Purpose:**
- Inverse probability of selection
- Post-stratification adjustments
- Makes sample representative of U.S. population

**Properties:**
- Always positive (> 0)
- Typically range: 10 - 5,000
- Sum to U.S. population of 3-5 year olds (~11-13 million)

**Usage:**
```r
weighted.mean(hrtl, FWC, na.rm = TRUE)
```

**NOT Used For:**
- Individual scoring (weights don't affect child's HRTL status)
- Recoding or thresholds
- Domain classification

**Missing FWC:**
- Should be extremely rare (<0.1%)
- Exclude child from weighted analyses if FWC = NA
- Include in unweighted analyses

---

### FIPSST (State FIPS Code)

**Variable:** State identifier
**Type:** Numeric (2-digit)

**Not Used in Scoring Function:**
- Used in BRMS models for state random effects
- Useful for stratified analyses
- Not required for basic HRTL scoring

---

### SC_AGE_YEARS (Age in Years)

**Variable:** Child's age
**Type:** Numeric (integer)

**Filter Rule:**
```r
dat = rawdat %>%
  dplyr::filter(SC_AGE_YEARS == 3 | SC_AGE_YEARS == 4 | SC_AGE_YEARS == 5)
```

**Valid Values:** 3, 4, 5 (inclusive)

**Threshold Matching:**
- Must match exactly for joining age-specific thresholds
- If SC_AGE_YEARS is float (3.5), may fail to join → missing thresholds

**Edge Cases:**
- Age 2.99 → Excluded
- Age 3.00 → Included (if coded as 3)
- Age 6.00 → Excluded
- Age = NA → Excluded

---

## Cross-Year Harmonization

### transfer_never_always() Function

**Location:** `functions/transfer_never_always.R`

**Purpose:** Harmonize items with different response scales across years

**Example Use:** `functions/o1.R`, lines 71-74
```r
df_o1 = df_o1 %>% safe_left_join(
  transfer_never_always(., var_from = "o1_16", var_to = "o1_1722",
                         values_from = c(0,3), values_to = c(0,4)),
  by = c("year","hhid")
)
```

#### The Problem

**ClearExp (o1) has different scales:**

**2016 (o1_16):**
```
0 = All of the time
1 = Most of the time
2 = Some of the time
3 = None of the time
(4 categories)
```

**2017-2022 (o1_1722):**
```
0 = Always
1 = Most of the time
2 = About half the time
3 = Sometimes
4 = Never
(5 categories)
```

**Challenge:**
- Cannot directly compare scores
- Need to map endpoints: "None" (2016) ↔ "Never" (2022)

---

#### The Solution

**Transfer endpoint values from shorter to longer scale:**

```r
transfer_never_always(data,
                      var_from = "o1_16",    # 4-category
                      var_to = "o1_1722",    # 5-category
                      values_from = c(0,3),  # Endpoints in 2016
                      values_to = c(0,4))    # Endpoints in 2022
```

**Mapping:**
```
2016 value → 2022 value
0          → 0  (All/Always)
3          → 4  (None/Never)
1,2        → Not mapped (middle categories differ)
```

**Result:**
- Children measured in 2016 have o1_16 values mapped to o1_1722 scale
- Only endpoints mapped (conservative)
- Middle categories remain distinct
- Allows longitudinal analysis with caution

---

#### Items Requiring Harmonization

**From code inspection:**
- **o1 (ClearExp):** 2016 4-cat → 2022 5-cat
- **o4 (PlayWell):** Scale alignment
- **o5 (HurtSad):** Scale alignment

**Not All Items Need This:**
- Items new in 2022 (no 2016 equivalent)
- Items with identical scales across years

---

### Variable Name Mapping

#### Consistent Naming (No Harmonization Needed)

**Examples:**
- `K2Q01` - Same in all years
- `K2Q01_D` - Same in all years
- `K6Q73_R` - Same in 2016, 2022 (but excluded from 2022 scoring)

---

#### Changed Names (Require Mapping)

**Examples:**

| 2016 | 2022 | Item |
|------|------|------|
| `ClearExp_16` | `ClearExp_22` | Explain experiences |
| `RecogBegin_16` | `RecogBegin_22` | Recognize sounds |
| `distracted_16` | `distracted_22` | Easily distracted |
| `temper_16` | `temperR_22` | Lose temper |

**Pattern:** Add year suffix

**Exception:** COUNTTO, K2Q01, K2Q01_D (no suffix)

---

#### New Items in 2022

**Not in 2016:**
- `SameSound_22` (Early Learning)
- `NameEmotions_22` (Social-Emotional)
- Multiple Motor items: `DrawCircle_22`, `DrawFace_22`, `DrawPerson_22`, `BounceBall_22`

**Impact:**
- Cannot compare these items longitudinally
- Contribute to domain differences between years

---

#### Removed Items from 2016

**Not in 2022 framework:**
- `K6Q73_R` - Resilience item (excluded via `domain_2022 = NA`)
- Some 2016 items reassigned to different domains

---

## Threshold Edge Cases

### Missing Thresholds

**Cause:** Threshold file missing rows for certain (item × age) combinations

**Symptom:** After left join, `on_track` and `emerging` are NA

**Impact:**
```r
longdat$code_hrtl22[longdat$y >= longdat$on_track] = 3
# If on_track is NA, condition is NA, assignment doesn't happen
```

**Result:** Item remains at default value (1 = Needs Support)

**Detection:**
```python
# Check for missing thresholds
missing_thresholds = longdat[longdat['on_track'].isna()]
print(f"Missing thresholds for {len(missing_thresholds)} item-age combos")
print(missing_thresholds[['lex_ifa', 'SC_AGE_YEARS']].drop_duplicates())
```

**Solution:** Ensure threshold file has all 28 items × 3 ages = 84 rows

---

### Threshold Boundary Values

**Question:** Is `on_track = 3` inclusive or exclusive?

**Code:** `hrtl_scoring_2022.R`, line 27
```r
longdat$code_hrtl22[longdat$y >= longdat$on_track] = 3
```

**Answer:** `>=` is **inclusive**

- IFA value exactly equal to threshold qualifies as On-Track
- Not `>` (strictly greater)

**Example:**
```
on_track = 3
y = 3
Result: On-Track ✓

y = 2.99 (hypothetical)
Result: Emerging
```

**Domain Cutoffs:**
```r
summdat$index_cat[summdat$avg_score >= 2.5] = 3  # Also inclusive
```

---

### Negative Thresholds

**Can thresholds be negative?** No.

**Reason:**
- IFA values are 0-indexed: 0, 1, 2, ..., K-1
- All non-negative by construction
- Thresholds must be within valid range [0, K-1]

**Invalid Threshold Example:**
```
emerging = -1  # INVALID
on_track = 3   # Valid

Result: All children would be >= -1, all classified as Emerging
```

**Validation Check:**
```python
assert (thresholds['emerging'] >= 0).all(), "Negative emerging threshold!"
assert (thresholds['on_track'] >= 0).all(), "Negative on_track threshold!"
```

---

### Emerging > On-Track (Impossible)

**Logical Constraint:**
```
emerging < on_track
```

**Why?**
- Emerging is lower performance than On-Track
- Threshold values must increase with performance level

**Invalid Example:**
```
emerging = 3
on_track = 2  # INVALID (less than emerging)

If y = 2:
  y >= emerging (2 >= 3) = FALSE → code = 1 (Needs Support)
  y >= on_track (2 >= 2) = TRUE → code = 3 (On-Track)
Contradictory!
```

**Validation Check:**
```python
assert (thresholds['emerging'] < thresholds['on_track']).all(), \
       "Emerging threshold >= On-Track threshold!"
```

---

## Domain Classification Edge Cases

### Exactly at Cutoff

**Domain avg_score = 2.5 exactly**

**Code:** `hrtl_scoring_2022.R`, line 39
```r
summdat$index_cat[summdat$avg_score >= 2.5] = 3
```

**Result:** On-Track (inclusive `>=`)

**Similarly:**
- avg_score = 2.0 exactly → Emerging (not Needs Support)

---

### All Items Needs Support

**Domain avg_score = 1.0 (all items code_hrtl22 = 1)**

**Result:** index_cat = 1 (Needs Support)

**HRTL Impact:** n_needs_support increments, HRTL = FALSE

---

### All Items On-Track

**Domain avg_score = 3.0 (all items code_hrtl22 = 3)**

**Result:** index_cat = 3 (On-Track)

**HRTL Impact:** n_on_track increments

---

### Mixed Needs Support and On-Track

**Example:** 5 items On-Track (3), 4 items Needs Support (1)

**Calculation:**
```
avg_score = (5*3 + 4*1) / 9 = 19/9 = 2.11
```

**Result:** Emerging domain (2.0 ≤ 2.11 < 2.5)

**Not Needs Support** even though 44% of items are Needs Support

**Critical Point:**
- Domain classification uses mean, not counts
- Majority of items at extremes can produce middle category

---

## HRTL Classification Edge Cases

### Exactly 4 On-Track

**Scenario:** n_on_track = 4, n_needs_support = 0

**Result:** HRTL = TRUE (boundary case included)

**Code:** `hrtl_scoring_2022.R`, line 46
```r
hrtl = (n_on_track >= 4 & n_needs_support == 0)
# (4 >= 4) & (0 == 0) = TRUE & TRUE = TRUE
```

---

### 5 On-Track, 1 Needs Support (Impossible)

**Why Impossible?** Only 5 domains total

**If 5 On-Track:** All domains On-Track → n_needs_support must be 0

**Math:**
```
n_on_track + n_emerging + n_needs_support <= 5
If n_on_track = 5 → others = 0
```

---

### 4 On-Track, 1 Needs Support, 0 Emerging

**Scenario:**
- ELS: On-Track
- SED: On-Track
- Self-Reg: Needs Support
- Motor: On-Track
- Health: On-Track

**Calculation:**
```
n_on_track = 4
n_needs_support = 1
hrtl = (4 >= 4) & (1 == 0) = TRUE & FALSE = FALSE
```

**Result:** NOT HRTL (strict criterion: zero tolerance for Needs Support)

---

### 3 On-Track, 2 Emerging, 0 Needs Support

**Scenario:**
- 3 domains On-Track
- 2 domains Emerging
- 0 Needs Support

**Calculation:**
```
n_on_track = 3
n_needs_support = 0
hrtl = (3 >= 4) & (0 == 0) = FALSE & TRUE = FALSE
```

**Result:** NOT HRTL (need 4+ On-Track)

---

### Missing Domains

**Scenario:** Child has only 3 domains scored (2 domains all-missing)

**Maximum possible n_on_track:** 3

**Result:** Cannot achieve HRTL (need 4+)

**This is intentional:**
- Comprehensive assessment required
- Missing domains = insufficient evidence

---

## Data Type Edge Cases

### Floating Point Precision

**Domain avg_score is float:**
```python
avg_score = 2.49999999999
```

**Is this >= 2.5?** Depends on precision!

**Safe Comparison:**
```python
# Python
np.isclose(avg_score, 2.5)  # True if within tolerance

# Or round to avoid precision issues
avg_score = round(mean(code_hrtl22), 2)
```

**R Behavior:**
```r
2.49999999999 >= 2.5
# Returns FALSE (exact comparison)
```

**Recommendation:**
- Use exact comparison as in original code
- Don't round prematurely
- Accept that edge cases exist

---

### Integer vs. Float Threshold Matching

**Problem:** SC_AGE_YEARS is float (3.0) but thresholds expect int (3)

**SQL Example:**
```sql
-- This join may fail!
LEFT JOIN thresholds ON items.age = thresholds.age
-- If items.age is DECIMAL(3,1) and thresholds.age is INTEGER
```

**Solution:**
```sql
-- Explicit cast
LEFT JOIN thresholds ON CAST(items.age AS INTEGER) = thresholds.age
```

**Python:**
```python
df['SC_AGE_YEARS'] = df['SC_AGE_YEARS'].astype(int)
```

---

### Character vs. Numeric HHID

**Some implementations:**
- HHID as character: "000123456"
- HHID as numeric: 123456

**Join Implications:**
```python
# May fail if types don't match
df.merge(other, on='HHID')

# Safe approach
df['HHID'] = df['HHID'].astype(str)
other['HHID'] = other['HHID'].astype(str)
df.merge(other, on='HHID')
```

---

## Summary Quick Reference

### Critical Special Cases (Must Handle)

1. **DailyAct_22**: Force to 0 if HCABILITY == 1
2. **K2Q01_D**: Force value 6 to NA
3. **STRATUM**: Convert to numeric in 2016
4. **Mean not Sum**: Domain aggregation uses mean
5. **Reverse Coding**: 17/28 items (check itemdict)
6. **Domain Cutoffs**: 2.0 and 2.5, not 2.0 and 3.0
7. **HRTL Logic**: AND not OR

### Item Name Exceptions

- `COUNTTO_R` - No year suffix
- `K2Q01` - No year suffix
- `K2Q01_D` - No year suffix
- `temperR_22` - Has "R" suffix (2022 only)

### Data Type Gotchas

- STRATUM: Character → Numeric (2016)
- HHID: Ensure consistent type across joins
- SC_AGE_YEARS: Integer for threshold matching
- Domain avg_score: Float (don't round prematurely)

### Missing Data Rules

- Item-level: Exclude via `na.rm = TRUE`
- Domain-level: NaN → NA conversion
- K2Q01_D value 6: Force to NA
- SPSS missing codes (95, 96, 99): Auto-detected, excluded

### Cross-Year Differences

- 2016 uses sums, 2022 uses means
- Different response scales (4 vs 5 categories)
- Domain structure changed (4 → 5 domains)
- Item assignments shifted (ClearExp domain)

---

## Troubleshooting Guide

**Symptom:** HRTL prevalence way off (>10% difference)
- Check DailyAct transformation
- Verify domain cutoffs (2.5 not 2.0)
- Confirm HRTL logic (AND not OR)

**Symptom:** Specific domain prevalence off
- Check item→domain assignments
- Verify reverse coding for that domain's items
- Inspect threshold values

**Symptom:** All domains same score
- Likely using sum instead of mean
- Check aggregation function

**Symptom:** Negative or >5 IFA values
- Reverse coding applied twice
- Or not applied when should be
- Check values_map

**Symptom:** Threshold join failures
- SC_AGE_YEARS type mismatch
- lex_ifa name mismatch
- Missing rows in threshold file

---

## Contact

For questions about special cases not covered here:
- Review original R code in `functions/` directory
- Check comparison functions (`compare_*.R`)
- Consult Ghandour publications (2019, 2024)
- Refer to CAHMI documentation at https://www.cahmi.org/
