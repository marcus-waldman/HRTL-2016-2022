# HRTL Scoring 2022: Migration Guide

## Purpose

This guide provides critical implementation details for migrating the `hrtl_scoring_2022()` function to a different data architecture (e.g., Python/pandas, SQL, SAS). It covers hidden transformations, platform-specific dependencies, and practical workarounds not captured in the main architecture documentation.

---

## Critical Hidden Transformations

### 1. DailyAct_22 Conditional Recoding (MOST CRITICAL)

**Location in Original Code:** `0 - Construct Analytic Datasets - HRTL-2016-2020.R`, line 35

```r
raw22$DailyAct_22[raw22$HCABILITY==1] = 0
```

**What This Does:**
- **Before** any scoring algorithms run, DailyAct_22 (functional limitations item) is conditionally set to 0
- **Condition:** Only applied when `HCABILITY == 1`
- **Effect:** Forces "no functional limitations" for children with a specific health ability status

**HCABILITY Variable:**
- Appears to be a filter/flag variable in CAHMI data
- Value of 1 likely indicates "no chronic health conditions" or "no disabilities"
- Children without health limitations should have DailyAct_22 = 0 (no impact on daily activities)

**Migration Implementation:**
```python
# Python/pandas
import pandas as pd
df.loc[df['HCABILITY'] == 1, 'DailyAct_22'] = 0

# SQL
UPDATE raw_data
SET DailyAct_22 = 0
WHERE HCABILITY = 1;
```

**Why This Matters:**
- This transformation affects the Health domain score for a subset of children
- Missing this step will produce **incorrect HRTL classifications** for children with HCABILITY=1
- Approximately 70-80% of children may have HCABILITY=1 (rough estimate based on chronic condition prevalence)

**Validation Check:**
```r
# Before transformation
table(raw22$DailyAct_22, useNA = "always")

# After transformation
table(raw22$DailyAct_22[raw22$HCABILITY==1], useNA = "always")  # Should show all 0s
```

---

### 2. K2Q01_D Value Label Harmonization

**Location:** `0 - Construct Analytic Datasets - HRTL-2016-2020.R`, lines 30-32

```r
labels_teeth = sjlabelled::get_values(raw22$K2Q01_D)
names(labels_teeth) = sjlabelled::get_labels(raw22$K2Q01_D)
raw16$K2Q01_D = haven::labelled_spss(raw16$K2Q01_D %>% haven::zap_labels(),
                                      labels = labels_teeth)
```

**Issue:**
- 2016 K2Q01_D (teeth condition) has incorrect or missing SPSS value labels
- Labels must be borrowed from 2022 data to maintain consistency

**Migration Workaround:**
- If not using SPSS format, ensure K2Q01_D uses consistent value meanings across years:
  ```
  1 = Excellent
  2 = Very good
  3 = Good
  4 = Fair
  5 = Poor
  6 = Don't know (force to missing)
  ```

**Implementation:**
```python
# Define standard labels
teeth_labels = {
    1: 'Excellent',
    2: 'Very good',
    3: 'Good',
    4: 'Fair',
    5: 'Poor',
    6: None  # Force to missing
}

# Apply to both years
df['K2Q01_D'] = df['K2Q01_D'].replace({6: None})
```

---

### 3. STRATUM Variable Type Coercion (2016 Only)

**Location:** `0 - Construct Analytic Datasets - HRTL-2016-2020.R`, line 27

```r
raw16$STRATUM = as.numeric(raw16$STRATUM %>% zap_all())
```

**Issue:**
- 2016 STRATUM is character type in raw CAHMI data
- 2017-2022 STRATUM is numeric
- Must convert 2016 to numeric for consistency

**Migration:**
```python
# Python
df_2016['STRATUM'] = pd.to_numeric(df_2016['STRATUM'], errors='coerce')

# SQL (PostgreSQL)
ALTER TABLE raw_2016
ALTER COLUMN stratum TYPE INTEGER USING stratum::integer;
```

---

## SPSS Format Dependencies

### Core Dependency: sjlabelled Value Labels

**Functions That Require SPSS Labels:**
1. `get_cahmi_values_map()` - Extracts labels/values using `sjlabelled::get_labels()` and `sjlabelled::get_values()`
2. `get_itemdict22()` - Calls `get_cahmi_values_map()` for all 28 items
3. `recode_cahmi2ifa()` - Uses `values_map` from itemdict

**The Problem:**
- These functions **will not work** with CSV, SQL, or non-SPSS formats
- SPSS metadata (value labels) contains the mapping from codes to meanings

**Solution 1: Pre-build Value Maps**

Create a static lookup table independent of SPSS format:

```python
# Python implementation
value_maps = {
    'RecogBegin_22': {
        'labels': ['Always', 'Most of the time', 'About half the time',
                   'Sometimes', 'Never'],
        'values_raw': [1, 2, 3, 4, 5],
        'values_ifa': [4, 3, 2, 1, 0],  # Reversed for positive gradient
        'values_mplus': [4, 3, 2, 1, 0]
    },
    'K2Q01': {
        'labels': ['Excellent', 'Very good', 'Good', 'Fair', 'Poor'],
        'values_raw': [1, 2, 3, 4, 5],
        'values_ifa': [4, 3, 2, 1, 0],  # Reversed
        'values_mplus': [4, 3, 2, 1, 0]
    },
    # ... continue for all 28 items
}
```

**Solution 2: Extract Once, Store as JSON**

```r
# R: One-time extraction from SPSS
library(jsonlite)

itemdict22 = get_itemdict22(raw22, verbose = FALSE)
value_maps_json = lapply(1:nrow(itemdict22), function(i) {
  list(
    var_cahmi = itemdict22$var_cahmi[i],
    lex_ifa = itemdict22$lex_ifa[i],
    values_map = itemdict22$values_map[[i]]
  )
})

write_json(value_maps_json, "value_maps_2022.json")
```

```python
# Python: Load and use
import json
with open('value_maps_2022.json', 'r') as f:
    value_maps = json.load(f)

def recode_item(raw_series, var_name):
    vm = next(v for v in value_maps if v['var_cahmi'] == var_name)
    mapping = dict(zip(vm['values_map']['values_raw'],
                       vm['values_map']['values_ifa']))
    return raw_series.map(mapping)
```

---

### Response Scale Detection Algorithm

**Original R Implementation** (`get_cahmi_values_map.R`, lines 20-29):

```r
values_map = data.frame(
  labels = sjlabelled::get_labels(rawdat %>% purrr::pluck(var)),
  values_raw = sjlabelled::get_values(rawdat %>% purrr::pluck(var))
) %>%
  dplyr::mutate(dv = c(1, diff(values_raw)),
                values_ifa = NA)

if(!identical(unique(values_map$dv), 1)) {
  idx = seq(1, min(which(values_map$dv != 1)) - 1)
  if(!is.null(force_value_missing)) {
    idx = setdiff(idx, which(values_map$values_raw %in% force_value_missing))
  }
} else {
  idx = 1:nrow(values_map)
}
values_map$values_ifa[idx] = values_map$values_raw[idx] - 1
```

**What This Algorithm Does:**
1. Calculates `dv = diff(values_raw)` - difference between consecutive raw values
2. If all differences are 1 (consecutive integers), use all values
3. If non-consecutive (e.g., 1,2,3,4,5,95,96 for missing codes), stop before first gap
4. Subtract 1 to create 0-indexed values
5. Exclude `force_value_missing` values (e.g., 6 for K2Q01_D)

**Migration Implementation:**

```python
def detect_valid_response_scale(raw_values, force_missing=None):
    """
    Identify valid ordinal responses vs. missing data codes

    Args:
        raw_values: array of unique raw values from SPSS
        force_missing: list of values to exclude (e.g., [6] for 'don't know')

    Returns:
        List of values to use for IFA recoding
    """
    raw_values = sorted(raw_values)
    diffs = [raw_values[i+1] - raw_values[i] for i in range(len(raw_values)-1)]

    # Check if all consecutive
    if all(d == 1 for d in diffs):
        valid_idx = list(range(len(raw_values)))
    else:
        # Find first non-consecutive gap
        first_gap = next((i for i, d in enumerate(diffs) if d != 1), len(diffs))
        valid_idx = list(range(first_gap + 1))

    # Exclude forced missing values
    if force_missing:
        valid_idx = [i for i in valid_idx
                     if raw_values[i] not in force_missing]

    return [raw_values[i] for i in valid_idx]

# Example usage
raw_values = [1, 2, 3, 4, 5, 95, 96]  # 95, 96 are missing codes
valid = detect_valid_response_scale(raw_values)  # Returns [1,2,3,4,5]

# K2Q01_D special case
valid_teeth = detect_valid_response_scale([1,2,3,4,5,6], force_missing=[6])
# Returns [1,2,3,4,5], excluding 6
```

**Why This Matters:**
- CAHMI datasets use high values (90+) for various missing data types
- Algorithm automatically excludes these from ordinal scale
- Without this, missing codes would be treated as extreme valid responses

---

## Cross-Year Harmonization

### transfer_never_always() Function

**Location:** `functions/transfer_never_always.R`

**Purpose:** Harmonize items that have different response scales across survey years

**Example Use Case:**
- 2016 ClearExp: 4 categories (All/Most/Some/None of the time)
- 2022 ClearExp: 5 categories (Always/Most/About half/Sometimes/Never)
- Need to map "Never" (5) in 2022 to "None" (4) in 2016 for comparability

**Function Signature:**
```r
transfer_never_always(data, var_from, var_to, values_from, values_to)
```

**Migration Concept:**
```python
def harmonize_response_scales(df, var_from, var_to, value_mapping):
    """
    Create harmonized variable when response scales differ across years

    Args:
        df: DataFrame with year indicator
        var_from: Source variable name (e.g., 'o1_16')
        var_to: Target variable name (e.g., 'o1_1722')
        value_mapping: dict of {from_value: to_value}

    Returns:
        DataFrame with new harmonized column
    """
    # Find years with var_from
    mask_from = df[var_from].notna()

    # Apply mapping where var_from exists
    df.loc[mask_from, f'{var_to}_harmonized'] = \
        df.loc[mask_from, var_from].map(value_mapping)

    # Copy var_to values where they exist
    df.loc[~mask_from, f'{var_to}_harmonized'] = df.loc[~mask_from, var_to]

    return df

# Example: ClearExp harmonization
df = harmonize_response_scales(
    df,
    var_from='o1_16',
    var_to='o1_1722',
    value_mapping={0: 0, 3: 4}  # Map 2016 endpoints to 2022 scale
)
```

**Items Requiring Harmonization (2016-2022):**
- ClearExp (o1): 4→5 categories
- PlayWell (o4): Scale alignment
- HurtSad (o5): Scale alignment

---

## Variable Naming Inconsistencies

### Pattern Exceptions to Watch For:

**Standard Pattern:** `[ItemName]_[YY]` (e.g., `RecogBegin_22`, `ClearExp_16`)

**Exceptions:**

1. **COUNTTO_R** (line 29, `get_itemdict22.R`)
   - No year suffix in 2022
   - 2016 uses: `COUNTTO` (also no suffix)
   - Both map to different IFA variables: `y22_7`, `y16_6`

2. **K2Q01** and **K2Q01_D**
   - No year suffix (same variable name across all years)
   - General health and teeth condition items
   - Consistent across 2016-2022

3. **temperR_22** vs **temper_16**
   - 2022 has "R" suffix (indicates "reversed" in raw data)
   - 2016 has no "R"
   - Both map to self-regulation domain

4. **distracted_22** vs **distracted_16**
   - Consistent naming but different response scales

**Migration Strategy:**
- Build explicit mapping tables, don't rely on programmatic name generation
- Use item dictionaries as source of truth for variable names

```python
# Bad approach (fragile)
var_2022 = f"{item_stem}_22"

# Good approach
var_2022 = itemdict.loc[itemdict['lex_ifa'] == 'y22_7', 'var_cahmi'].values[0]
```

---

## Missing Data Handling

### Rule 1: Item-Level Missing

**Original Code:** `recode_cahmi2ifa()` line 11
```r
plyr::mapvalues(from = map_v$values_raw, to = map_v$values_ifa, warn_missing = F)
```

- `warn_missing = FALSE` means unmapped values become NA silently
- Any raw value not in `values_map$values_raw` → NA
- This catches SPSS missing codes (95, 96, 99, etc.) automatically

**Migration:**
```python
def recode_with_na(series, value_map):
    """Remap values, converting unmapped to NA"""
    return series.map(value_map)  # pandas maps unmapped to NaN automatically

# Explicit handling
def recode_safe(series, value_map, missing_codes=[95, 96, 99]):
    series = series.copy()
    series[series.isin(missing_codes)] = None
    return series.map(value_map)
```

---

### Rule 2: Domain-Level Missing (Critical)

**Original Code:** `hrtl_scoring_2022.R`, lines 32-33
```r
summdat = longdat %>%
  dplyr::group_by(HHID, domain_2022) %>%
  dplyr::summarise(avg_score = mean(code_hrtl22, na.rm = TRUE))
summdat$avg_score[is.nan(summdat$avg_score)] = NA
```

**Rules:**
1. Use `na.rm = TRUE` when computing domain mean
2. If ALL items missing → mean() returns NaN → convert to NA
3. If SOME items missing → mean() uses available items (no minimum N requirement!)

**Key Implication:**
- A child with only 1/9 ELS items answered will get a domain score based on that single item
- No minimum threshold for valid domain score
- This is intentional design (confirmed by published validation)

**Migration:**
```python
def domain_score_with_missing(group):
    """Compute domain average, handling all-missing case"""
    mean_val = group['code_hrtl22'].mean()  # pandas skipna=True by default
    return None if pd.isna(mean_val) else mean_val

domain_scores = (
    longdat
    .groupby(['HHID', 'domain_2022'])
    .apply(domain_score_with_missing)
    .reset_index(name='avg_score')
)
```

---

### Rule 3: Overall HRTL with Missing Domains

**Original Code:** `hrtl_scoring_2022.R`, line 45
```r
determine_hrtl = summdat %>%
  dplyr::group_by(HHID) %>%
  dplyr::summarise(
    n_on_track = sum(code == "On-Track"),
    n_needs_support = sum(code == "Needs Support")
  )
```

**Missing Domain Handling:**
- `sum()` excludes NA by default in dplyr
- If child has only 3 domains with valid scores:
  - Could have 3 "On-Track", 0 "Needs Support" → does NOT meet HRTL (need 4+)
  - Missing domains don't count toward n_on_track

**Edge Case:**
```
Child has 4 scored domains: 3 On-Track, 1 Emerging, 0 Needs Support
→ n_on_track = 3 → HRTL = FALSE (need 4)

If 5th domain was missing, child cannot achieve HRTL
```

**Migration:**
```python
# Python with explicit missing handling
hrtl_summary = (
    domain_scores
    .groupby('HHID')
    .agg(
        n_on_track=('code', lambda x: (x == 'On-Track').sum()),
        n_needs_support=('code', lambda x: (x == 'Needs Support').sum()),
        n_domains=('code', 'count')  # Track how many domains scored
    )
    .assign(hrtl=lambda x: (x['n_on_track'] >= 4) & (x['n_needs_support'] == 0))
)
```

---

## Survey Weights and Complex Design

### When to Use FWC

**Always Use FWC for:**
- Population prevalence estimates
- Domain-level prevalence
- Overall HRTL prevalence
- Comparison to published Ghandour results

**Never Use FWC for:**
- Individual child scoring (weights don't affect individual HRTL status)
- Model fitting in BRMS/IRT (handled separately via survey design variables)

**Weighted Mean Calculation:**
```python
# Python
import numpy as np

def weighted_prevalence(df, outcome_var, weight_var='FWC'):
    """Calculate weighted prevalence"""
    mask = df[outcome_var].notna() & df[weight_var].notna()
    numerator = (df.loc[mask, outcome_var] * df.loc[mask, weight_var]).sum()
    denominator = df.loc[mask, weight_var].sum()
    return numerator / denominator

# Example
hrtl_prev = weighted_prevalence(results['overall'], 'hrtl', 'FWC')
```

### Survey Design Variables (Not Used in Scoring)

**These variables are in the data but NOT used by `hrtl_scoring_2022()`:**
- `STRATUM` - Survey stratum
- `HHID` - Cluster ID
- `FIPSST` - State code

**They ARE used for:**
- Variance estimation (standard errors)
- Survey design-adjusted analyses
- BRMS models (`1 - Fit BRMS.R`)

**Migration Note:**
- You can safely ignore STRATUM, clustering for basic scoring
- Include them if you need survey-adjusted standard errors

---

## Platform-Specific Tips

### Python/Pandas

**Reverse Coding:**
```python
def reverse_code(series, max_val):
    """Reverse code an ordinal series"""
    return max_val - series

# For 0-4 scale (5 categories)
df['item_reversed'] = reverse_code(df['item'], 4)
```

**Pivot to Long Format:**
```python
longdat = pd.melt(
    ifadat,
    id_vars=['HHID', 'SC_AGE_YEARS'],
    value_vars=[col for col in ifadat.columns if col.startswith('y22_')],
    var_name='lex_ifa',
    value_name='y'
)
```

**Ordered Categorical:**
```python
from pandas.api.types import CategoricalDtype

domain_cat = CategoricalDtype(
    categories=['Needs Support', 'Emerging', 'On-Track'],
    ordered=True
)
summdat['code'] = summdat['index_cat'].map({
    1: 'Needs Support',
    2: 'Emerging',
    3: 'On-Track'
}).astype(domain_cat)
```

---

### SQL

**Conditional Update (DailyAct):**
```sql
UPDATE staging_data
SET dailyact_22 = 0
WHERE hcability = 1;
```

**Threshold Application:**
```sql
SELECT
    lex_ifa,
    y,
    emerging,
    on_track,
    CASE
        WHEN y IS NULL THEN NULL
        WHEN y >= on_track THEN 3
        WHEN y >= emerging THEN 2
        ELSE 1
    END AS code_hrtl22
FROM long_data
JOIN thresholds USING (lex_ifa, sc_age_years);
```

**Domain Aggregation:**
```sql
SELECT
    hhid,
    domain_2022,
    AVG(code_hrtl22) AS avg_score,
    CASE
        WHEN AVG(code_hrtl22) IS NULL THEN NULL
        WHEN AVG(code_hrtl22) >= 2.5 THEN 3
        WHEN AVG(code_hrtl22) >= 2.0 THEN 2
        ELSE 1
    END AS index_cat
FROM scored_items
GROUP BY hhid, domain_2022;
```

---

### SAS

**Missing Value Handling:**
```sas
/* SAS automatically excludes missing from MEAN() */
proc sql;
    create table domain_scores as
    select
        hhid,
        domain_2022,
        mean(code_hrtl22) as avg_score
    from long_data
    group by hhid, domain_2022;
quit;

/* Convert to categories */
data domain_scores;
    set domain_scores;
    if missing(avg_score) then index_cat = .;
    else if avg_score >= 2.5 then index_cat = 3;
    else if avg_score >= 2.0 then index_cat = 2;
    else index_cat = 1;
run;
```

---

## Performance Optimization

### Bottlenecks in Original Code

1. **Item-by-item recoding loop** (`recode_cahmi2ifa()`, line 5-13)
   - Processes 28 items sequentially
   - Each calls `pluck()` and `mapvalues()`
   - Could vectorize with case_when or lookup tables

2. **Pivot to long format** (line 20-21, `hrtl_scoring_2022.R`)
   - Transforms ~11,000 rows × 28 items → 308,000 rows
   - Memory intensive
   - Consider chunking for very large datasets

3. **Multiple joins** (lines 22-24)
   - Three left_joins on long data
   - Optimize by combining into single join

**Optimized Approach:**
```python
# Pre-merge all reference data before pivoting
long_data = (
    ifadat
    .melt(id_vars=['HHID', 'SC_AGE_YEARS'],
          value_vars=[col for col in ifadat if col.startswith('y22_')],
          var_name='lex_ifa', value_name='y')
    .merge(
        itemdict[['lex_ifa', 'domain_2022']],
        on='lex_ifa', how='left'
    )
    .query('domain_2022.notna()')
    .merge(
        thresholds[['lex_ifa', 'SC_AGE_YEARS', 'on_track', 'emerging']],
        on=['lex_ifa', 'SC_AGE_YEARS'], how='left'
    )
)
```

---

## Testing Your Migration

### Minimal Test Case

Create small test dataset to validate logic:

```python
test_data = pd.DataFrame({
    'HHID': [1, 1, 1, 2, 2, 2],
    'SC_AGE_YEARS': [4, 4, 4, 5, 5, 5],
    'HCABILITY': [1, 1, 1, 0, 0, 0],
    'RecogBegin_22': [2, 2, 2, 4, 4, 4],
    'K2Q01': [1, 1, 1, 5, 5, 5],
    'DailyAct_22': [2, 2, 2, 1, 1, 1],  # Should become 0 for HHID=1
    'FWC': [1000, 1000, 1000, 1500, 1500, 1500]
})
```

**Expected Results:**
- HHID 1: DailyAct_22 should be 0 after transformation (HCABILITY=1)
- HHID 2: DailyAct_22 stays 1 (HCABILITY=0)

### Validation Checklist

- [ ] DailyAct_22 conditional recoding applied correctly
- [ ] All 28 items recoded to IFA scale (0-indexed)
- [ ] Reverse-coded items have correct directionality (higher = better)
- [ ] K2Q01_D value 6 forced to missing
- [ ] Age filtering to 3-5 years applied
- [ ] Domain scores calculated as means (not sums)
- [ ] Domain categories: <2.0 = Needs Support, 2.0-2.49 = Emerging, ≥2.5 = On-Track
- [ ] HRTL = (n_on_track ≥ 4) AND (n_needs_support == 0)
- [ ] FWC weights preserved in output
- [ ] Overall HRTL prevalence matches expected range (50-70%)

---

## Common Migration Errors

### Error 1: Forgetting DailyAct Transformation
**Symptom:** Health domain scores don't match validation
**Fix:** Apply conditional recoding BEFORE scoring

### Error 2: Using Sums Instead of Means
**Symptom:** All domain scores are integers (9, 12, etc.)
**Fix:** Use `mean(code_hrtl22)` not `sum(code_hrtl22)`

### Error 3: Missing SPSS Labels
**Symptom:** `get_cahmi_values_map()` returns empty data.frame
**Fix:** Pre-build value_maps dictionary (see Solution 1 above)

### Error 4: Wrong Reverse Coding
**Symptom:** Negative age gradients (younger kids score higher)
**Fix:** Verify `values_ifa` decreases as raw values increase for reverse-coded items

### Error 5: Threshold Join Failures
**Symptom:** `on_track` and `emerging` columns are all NA
**Fix:** Check that `lex_ifa` and `SC_AGE_YEARS` match exactly between data and thresholds

### Error 6: NaN vs NA Confusion
**Symptom:** Domain scores show NaN instead of NA
**Fix:** Apply `summdat$avg_score[is.nan(summdat$avg_score)] = NA` after grouping

---

## Contact and Support

For migration questions or bugs, refer to:
- Main architecture document: `hrtl_scoring_2022_architecture.md`
- Psychometric foundation: `HRTL_Psychometric_Foundation.md`
- Validation protocol: `HRTL_Validation_Protocol.md`
- Special cases: `HRTL_Special_Cases_Reference.md`

Key references:
- Ghandour et al. (2024) - 2022 methodology
- Ghandour et al. (2019) - 2016 methodology
- NSCH Data User Guides - https://www.childhealthdata.org/
