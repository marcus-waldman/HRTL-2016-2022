# Architecture Documentation: hrtl_scoring_2022 Function

## Overview

The `hrtl_scoring_2022()` function implements the CAHMI (Child and Adolescent Health Measurement Initiative) Health-Related Quality of Life (HRTL) scoring algorithm for 2022 NSCH (National Survey of Children's Health) data. It determines whether children aged 3-5 are "on track" for school readiness across five developmental domains.

**Purpose**: Transform raw survey responses into domain-level and overall school readiness classifications following Ghandour et al. (2024) methodology.

**Key Reference**: Title V National Outcome Measure for School Readiness definition: Children "on track" in 4-5 domains with no domain that "needs support" are considered HRTL.

## Function Signature

```r
hrtl_scoring_2022(rawdat, itemdict, coding_tholds)
```

## Input Data Architecture

### 1. rawdat (Raw CAHMI Dataset)

**Type**: data.frame (SPSS format from CAHMI)

**Required Variables**:
- `HHID` (character/numeric): Household ID - unique identifier for each child
- `SC_AGE_YEARS` (numeric): Child's age in years (function filters to 3, 4, or 5)
- `FWC` (numeric): Final survey weight for statistical weighting
- `[Item variables]`: 28 CAHMI survey item variables (see itemdict structure below)

**SPSS Label Metadata**: Variables contain SPSS value labels and attributes that need stripping via `zap_all()`

**Filter Behavior**: Function automatically filters to ages 3-5 only

---

### 2. itemdict (Item Dictionary)

**Type**: data.frame/tibble

**Purpose**: Maps raw CAHMI variable names to analysis variables and provides recoding instructions

**Required Columns**:

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `jid` | numeric | Item ID with decimal year suffix | 1.22, 2.22, ..., 28.22 |
| `year` | numeric | Survey year | 2022 |
| `domain_2022` | factor | Domain classification for 2022 framework | "Early Learning Skills", "Social-Emotional Development", "Self-Regulation", "Motor Development", "Health" |
| `var_cahmi` | character | Raw CAHMI variable name | "RecogBegin_22", "K2Q01", "DailyAct_22" |
| `lex_ifa` | character | IFA (Item Factor Analysis) variable name | "y22_1", "y22_2", ..., "y22_28" |
| `stem` | character | Full question text | "How often can this child..." |
| `reverse_coded` | logical | Whether item is reverse-coded | TRUE/FALSE |
| `reverse_only_in_mplus` | logical | Reverse only for Mplus (not IFA) | TRUE/FALSE |
| `values_map` | list-column | Recoding lookup table (see below) | list(data.frame) |

**values_map Structure** (nested data.frame for each item):

```r
data.frame(
  labels = character,        # Original SPSS value label (e.g., "Always", "Never")
  values_raw = numeric,      # Raw SPSS coded value (e.g., 1, 2, 3, 4, 5)
  values_ifa = numeric,      # Recoded IFA value (0-indexed, reversed if needed)
  values_mplus = numeric     # Mplus-specific recoding (if different from IFA)
)
```

**Special Cases**:
- Items with `domain_2022 == NA` are excluded from 2022 scoring (e.g., legacy item K6Q73_R)
- DailyAct_22 has `reverse_only_in_mplus = TRUE` (reversed for Mplus but not for IFA scoring)

**Five Domains (2022 Framework)**:
1. **Early Learning Skills** (9 items): RecogBegin, SameSound, RhymeWord, RecogLetter, WriteName, ReadOneDigit, CountTo, GroupOfObjects, SimpleAddition
2. **Social-Emotional Development** (6 items): ClearExp, NameEmotions, ShareToys, PlayWell, HurtSad, FocusOn
3. **Self-Regulation** (5 items): StartNewAct, CalmDown, WaitForTurn, Distracted, Temper
4. **Motor Development** (4 items): DrawCircle, DrawFace, DrawPerson, BounceBall
5. **Health** (3 items): K2Q01 (general health), K2Q01_D (teeth condition), DailyAct_22 (functional limitations)

---

### 3. coding_tholds (Coding Thresholds)

**Type**: data.frame

**Purpose**: Age-specific thresholds for classifying item responses as "on track", "emerging", or "needs support"

**Required Columns**:

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `lex_ifa` | character | IFA variable name (matches itemdict) | "y22_1", "y22_2" |
| `SC_AGE_YEARS` | numeric | Child age (3, 4, or 5) | 3, 4, 5 |
| `on_track` | numeric | Minimum IFA value for "on track" | 3, 4 |
| `emerging` | numeric | Minimum IFA value for "emerging" | 2 |

**Structure**: Long format with one row per item × age combination

**Example**:
```r
# For item y22_1 (RecogBegin):
lex_ifa    SC_AGE_YEARS  on_track  emerging
y22_1      3             2         1
y22_1      4             3         2
y22_1      5             4         3
```

**Derivation**: Thresholds are based on age-gradient norms from Ghandour et al. (2024), typically stored in Excel file `datasets/intermediate/HRTL-2022-Scoring-Thresholds.xlsx`

**Critical Notes**:
- Thresholds vary by age due to developmental expectations
- Each item has unique thresholds (not uniform across items)
- Missing thresholds for excluded items (those with `domain_2022 == NA`)

---

## Function Dependencies

### Direct Dependencies (Functions)

#### 1. recode_cahmi2ifa()

**File**: `functions/recode_cahmi2ifa.R`

**Purpose**: Convert raw CAHMI responses to IFA-coded values using itemdict mappings

**Signature**:
```r
recode_cahmi2ifa(inputdat, itemdict)
```

**Returns**: data.frame with columns named by `itemdict$lex_ifa`, values recoded per `itemdict$values_map`

**Process**:
1. Loop through each item in itemdict
2. Extract raw variable from inputdat
3. Strip SPSS labels with `zap_all()`
4. Remap values using `plyr::mapvalues()` from `values_raw` to `values_ifa`
5. Return data.frame with IFA-coded columns

**Dependency Chain**:
- Calls `zap_all()`
- Uses `itemdict$var_cahmi` and `itemdict$values_map`

---

#### 2. zap_all()

**File**: `functions/zap_all.R`

**Purpose**: Remove all SPSS metadata (labels, formats, widths) from haven-imported data

**Signature**:
```r
zap_all(x)
```

**Implementation**:
```r
x %>%
  haven::zap_label() %>%      # Remove variable labels
  haven::zap_labels() %>%     # Remove value labels
  haven::zap_formats() %>%    # Remove display formats
  haven::zap_widths()         # Remove column widths
```

**Why Needed**: SPSS imported data carries metadata that interferes with standard R operations; this function creates clean base R vectors

---

#### 3. get_itemdict22()

**File**: `functions/get_itemdict22.R`

**Purpose**: Generate the itemdict data structure for 2022 NSCH data

**Signature**:
```r
get_itemdict22(raw22, verbose = TRUE)
```

**Returns**: itemdict data.frame with all required columns including nested `values_map` list-column

**Process**:
1. Define 28 HRTL items with metadata (jid, domains, var_cahmi, stems)
2. Identify reverse-coded items (17 items in 2022)
3. For each item, call `get_cahmi_values_map()` to build `values_map`
4. Optionally print recoding verification if `verbose = TRUE`

**Key Data Embedded**:
- Domain assignments (2022 framework)
- Reverse-coding flags
- Item question stems

**Dependency Chain**:
- Calls `get_cahmi_values_map()` for each item
- Requires `raw22` to extract SPSS value labels

---

#### 4. get_cahmi_values_map()

**File**: `functions/get_cahmi_values_map.R`

**Purpose**: Extract SPSS value labels from raw data and create recoding lookup table

**Signature**:
```r
get_cahmi_values_map(rawdat, var, reverse, reverse_in_mplus = FALSE, force_value_missing = NULL)
```

**Parameters**:
- `rawdat`: Raw CAHMI dataset
- `var`: Variable name (string)
- `reverse`: Logical - reverse code for IFA?
- `reverse_in_mplus`: Logical - reverse only for Mplus (not IFA)?
- `force_value_missing`: Numeric vector of values to force to NA

**Returns**: data.frame with columns: `labels`, `values_raw`, `values_ifa`, `values_mplus`

**Algorithm**:
1. Extract SPSS value labels and codes using `sjlabelled::get_labels()` and `sjlabelled::get_values()`
2. Identify valid response codes (consecutive integers starting from 1 or higher)
3. Recode to 0-indexed: `values_ifa = values_raw - 1`
4. Apply reverse coding if `reverse = TRUE`: flip order
5. Shift to start at 0 if negative values produced
6. Create `values_mplus` (apply `reverse_in_mplus` if needed)
7. Force specified values to NA

**Special Cases**:
- `K2Q01_D` (teeth): Force value 6 ("don't know") to missing
- `DailyAct_22`: Reverse only for Mplus, not IFA

**Dependency**: Uses `sjlabelled`, `purrr`, `plyr` packages

---

### Package Dependencies

**Required R Packages**:
- `dplyr`: Data manipulation (filter, select, mutate, group_by, summarise, left_join)
- `tidyr`: Reshaping (pivot_longer)
- `haven`: SPSS data import (zap_* functions)
- `sjlabelled`: Extract SPSS labels (get_labels, get_values)
- `purrr`: List operations (pluck)
- `plyr`: Value remapping (mapvalues)
- `readxl`: Load threshold Excel files

---

## Algorithm Flow

### Step 1: Filter by Age
```r
dat = rawdat %>%
  dplyr::filter(SC_AGE_YEARS == 3 | SC_AGE_YEARS == 4 | SC_AGE_YEARS == 5)
```
- Subset to preschool-aged children (3-5 years)
- Expected N ≈ 11,121 for 2022 NSCH (per Ghandour 2024)

---

### Step 2: Recode CAHMI → IFA
```r
ifadat = dplyr::bind_cols(
  dat %>% dplyr::select(HHID, SC_AGE_YEARS),
  recode_cahmi2ifa(inputdat = dat, itemdict = itemdict)
)
```
- Retain HHID and age
- Convert 28 CAHMI items to IFA coding (0-indexed ordinal)
- Result: data.frame with columns `HHID`, `SC_AGE_YEARS`, `y22_1`, ..., `y22_28`

---

### Step 3: Apply Age-Specific Thresholds (Item-Level)
```r
longdat = ifadat %>%
  tidyr::pivot_longer(starts_with("y22_"), names_to = "lex_ifa", values_to = "y") %>%
  dplyr::left_join(itemdict %>% dplyr::select(lex_ifa, domain_2022), by = "lex_ifa") %>%
  dplyr::filter(!is.na(domain_2022)) %>%  # Exclude items not in 2022 framework
  dplyr::left_join(coding_tholds %>% dplyr::select(lex_ifa, SC_AGE_YEARS, on_track, emerging),
                   by = c("SC_AGE_YEARS", "lex_ifa"))
```

**Reshape to Long Format**: One row per child × item

**Join Domain and Thresholds**: Merge age-specific `on_track` and `emerging` cutoffs

**3-Point Scoring**:
```r
longdat = longdat %>%
  dplyr::mutate(code_hrtl22 = ifelse(is.na(y), NA, 1))  # Default: needs support
longdat$code_hrtl22[longdat$y >= longdat$emerging] = 2  # Upgrade to emerging
longdat$code_hrtl22[longdat$y >= longdat$on_track] = 3  # Upgrade to on-track
```

**Classification Logic**:
- `code_hrtl22 = 1` (Needs Support): `y < emerging`
- `code_hrtl22 = 2` (Emerging): `emerging <= y < on_track`
- `code_hrtl22 = 3` (On-Track): `y >= on_track`

---

### Step 4: Domain-Level Scoring
```r
summdat = longdat %>%
  dplyr::group_by(HHID, domain_2022) %>%
  dplyr::summarise(avg_score = mean(code_hrtl22, na.rm = TRUE))
```

**Average Item Scores Within Domain**: Each child has 5 avg_scores (one per domain)

**Handle NaN**: If all items missing for a domain, set `avg_score = NA`

**Domain-Level Classification**:
```r
summdat = summdat %>%
  dplyr::mutate(index_cat = NA)
summdat$index_cat[summdat$avg_score < 2] = 1       # Needs Support
summdat$index_cat[summdat$avg_score >= 2] = 2      # Emerging
summdat$index_cat[summdat$avg_score >= 2.5] = 3    # On-Track
```

**Key Thresholds** (Ghandour 2024):
- `avg_score < 2.0`: Needs Support
- `2.0 <= avg_score < 2.5`: Emerging
- `avg_score >= 2.5`: On-Track

**Convert to Ordered Factor**:
```r
summdat = summdat %>%
  dplyr::mutate(code = ordered(index_cat, levels = c(1, 2, 3),
                                labels = c("Needs Support", "Emerging", "On-Track")))
```

---

### Step 5: Overall HRTL Determination
```r
determine_hrtl = summdat %>%
  dplyr::group_by(HHID) %>%
  dplyr::summarise(
    n_on_track = sum(code == "On-Track"),
    n_needs_support = sum(code == "Needs Support")
  ) %>%
  dplyr::mutate(hrtl = (n_on_track >= 4 & n_needs_support == 0))
```

**HRTL Definition**:
- At least 4 of 5 domains "On-Track" AND
- Zero domains "Needs Support"

**Logical**: Children can have 1 "Emerging" domain and still qualify as HRTL if other 4 are "On-Track"

---

### Step 6: Return Results
```r
return(
  list(
    overall = determine_hrtl %>%
      dplyr::left_join(dat %>% dplyr::select(HHID, FWC), by = "HHID") %>%
      dplyr::mutate(across(everything(), zap_all)),

    by_domain = summdat %>%
      dplyr::left_join(dat %>% dplyr::select(HHID, FWC), by = "HHID") %>%
      dplyr::mutate(across(everything(), zap_all))
  )
)
```

**Output Structure**: List with two data.frames

---

## Output Structure

### overall (Overall HRTL Classification)

**Type**: data.frame

**Columns**:
- `HHID` (character/numeric): Household ID
- `n_on_track` (integer): Count of domains classified as "On-Track" (0-5)
- `n_needs_support` (integer): Count of domains classified as "Needs Support" (0-5)
- `hrtl` (logical): TRUE if child meets HRTL criteria, FALSE otherwise
- `FWC` (numeric): Survey weight

**Row Count**: One row per child (ages 3-5)

**Usage**: Calculate weighted prevalence of HRTL in population

---

### by_domain (Domain-Level Classifications)

**Type**: data.frame

**Columns**:
- `HHID` (character/numeric): Household ID
- `domain_2022` (factor): Domain name (5 levels)
- `code` (ordered factor): Domain classification ("Needs Support" < "Emerging" < "On-Track")
- `FWC` (numeric): Survey weight

**Row Count**: Up to 5 rows per child (one per domain; fewer if domains have all missing items)

**Usage**:
- Analyze specific domain performance
- Identify areas of strength/weakness
- Generate domain-level prevalence estimates

---

## Key Configuration Constants

### Cutscore (2022 Framework)
```r
cutscore_22 = 2.5  # Domain avg_score threshold for "On-Track" classification
```
**Not actively used in code** (hardcoded in if-statements instead), but documents the threshold

### HRTL Criteria
```r
n_on_track >= 4 & n_needs_support == 0
```

---

## Differences from 2016 Version

**For Migration Context**: If adapting for 2016 data, note these methodological changes:

| Aspect | 2016 (hrtl_scoring_2016) | 2022 (hrtl_scoring_2022) |
|--------|--------------------------|--------------------------|
| **Item-level scoring** | 3-point: 0 (at-risk), 1 (needs support), 2 (on-track) | 3-point: 1 (needs support), 2 (emerging), 3 (on-track) |
| **Domain aggregation** | Sum of item codes | Mean of item codes |
| **Domain cutoffs** | Fixed sum thresholds per domain | Average >= 2.0 (emerging), >= 2.5 (on-track) |
| **HRTL definition** | >= 4 domains on-track | >= 4 domains on-track AND 0 domains needs support |
| **Domains** | 4 domains (ELS, PHMD, Self-Reg, SED) | 5 domains (ELS, SED, Self-Reg, Motor Dev, Health) |
| **Item count** | 20 items | 28 items |

---

## Migration Checklist

When adapting `hrtl_scoring_2022()` to a new data architecture:

### 1. Data Input Layer
- [ ] Ensure raw dataset has `HHID`, `SC_AGE_YEARS`, and item variables
- [ ] Adapt SPSS label stripping if using different source format (CSV, SAS, etc.)
- [ ] Handle missing data encoding (SPSS system-missing vs. coded missing values)

### 2. Item Dictionary
- [ ] Build itemdict with all required columns (jid, domain_2022, var_cahmi, lex_ifa, values_map)
- [ ] Generate values_map for each item (may need custom logic if not SPSS format)
- [ ] Verify reverse-coding logic matches survey instrument
- [ ] Map raw variable names to new dataset's naming convention

### 3. Thresholds
- [ ] Obtain or derive age-specific thresholds (`on_track`, `emerging` by item and age)
- [ ] Format as long data.frame with columns: lex_ifa, SC_AGE_YEARS, on_track, emerging
- [ ] Validate thresholds match published norms (Ghandour 2024)

### 4. Dependencies
- [ ] Port or rewrite `recode_cahmi2ifa()` for new data format
- [ ] Port `zap_all()` (or replace with equivalent metadata removal)
- [ ] Port `get_cahmi_values_map()` (or build custom recoding lookup)
- [ ] Install required packages (dplyr, tidyr, haven, etc.)

### 5. Domain Definitions
- [ ] Verify domain assignments match 2022 framework (5 domains)
- [ ] Handle excluded items (those with `domain_2022 == NA`)
- [ ] Update domain names if using different taxonomy

### 6. Validation
- [ ] Test with known dataset and compare to published prevalence estimates
- [ ] Check domain classification distributions (% on-track, emerging, needs support)
- [ ] Verify overall HRTL prevalence matches expected range (50-70% typical)
- [ ] Confirm weighted analyses use `FWC` correctly

### 7. Special Cases
- [ ] Handle K2Q01_D (teeth) missing value logic (force value 6 to NA)
- [ ] Handle DailyAct_22 reverse coding (reversed for Mplus but not IFA)
- [ ] Address children with partial domain data (missing items)

---

## Example Usage

```r
# Load raw data
raw22 = haven::read_spss("datasets/raw/CAHMI-2022/2022 NSCH_Topical_DRC_CAHMI.sav")

# Generate item dictionary
itemdict = get_itemdict22(raw22, verbose = FALSE)

# Load thresholds
coding_tholds = readxl::read_xlsx("datasets/intermediate/HRTL-2022-Scoring-Thresholds.xlsx") %>%
  dplyr::mutate(lex_ifa = paste0("y22_", stringr::str_remove(as.character(jid), ".22")))

# Score HRTL
results = hrtl_scoring_2022(
  rawdat = raw22,
  itemdict = itemdict,
  coding_tholds = coding_tholds
)

# Overall HRTL prevalence (weighted)
results$overall %>%
  dplyr::summarise(
    hrtl_prev = weighted.mean(hrtl, FWC, na.rm = TRUE)
  )

# Domain-level prevalence
results$by_domain %>%
  dplyr::group_by(domain_2022, code) %>%
  dplyr::summarise(n = sum(FWC)) %>%
  dplyr::mutate(pct = n / sum(n))
```

---

## References

- Ghandour, R. M., et al. (2024). School Readiness Among U.S. Children Ages 3-5. *Title V National Outcome Measure*.
- Ghandour, R. M., et al. (2019). Healthy developmental, behavioral, and emotional milestones among young children. *Pediatrics*.

---

## Contact/Questions

For questions about this architecture or migration support, consult:
- Original CAHMI documentation
- Ghandour publications (2019, 2024)
- NSCH data user guides at https://www.childhealthdata.org/
