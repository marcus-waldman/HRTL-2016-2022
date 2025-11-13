# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Health-Related Quality of Life (HRTL) analysis project using National Survey of Children's Health (NSCH) data from 2016-2022. The project focuses on early learning skills (ELS) and social-emotional development (SED) domains for children aged 3-5 years.

## Data Architecture

### Data Pipeline Flow
1. **Raw SPSS Data** (`datasets/raw/CAHMI-YYYY/`) - Original NSCH datasets from CAHMI (Child and Adolescent Health Measurement Initiative)
2. **Item Dictionaries** - Define mapping between CAHMI variables and analysis variables across survey years
3. **Recoded Datasets** - Transform CAHMI data to Mplus-compatible format for item factor analysis (IFA)
4. **Analysis** - Bayesian Regression Multilevel Models (BRMS) for longitudinal analysis

### Key Data Transformations
- **CAHMI → Mplus**: Uses `recode_cahmi2mplus()` with year-specific item dictionaries (`get_itemdict16()`, `get_itemdict22()`)
- **Reverse Coding**: Many items are reverse-coded to align directionality (higher = better)
- **Value Mapping**: Raw SPSS values mapped to ordinal response categories via `get_cahmi_values_map()`
- **Missing Data Handling**: Specific values (e.g., 6 for K2Q01_D teeth condition) forced to missing

## Domain-Specific Functions

### Early Learning Skills (e1-e9)
- **e1**: RECOGBEGIN - Recognize beginning sounds
- **e2**: SAMESOUND - Identify same sounds
- **e3**: RHYMEWORD - Rhyme words
- **e4**: RECOGABC - Recognize alphabet letters
- **e5**: WRITENAME - Write first name
- **e6**: READONEDIGIT - Read single-digit numbers
- **e7**: COUNTTO - Count to a number
- **e8**: GROUPOFOBJECTS - Count objects in groups
- **e9**: SIMPLEADDITION - Simple addition

### Social-Emotional Development (o1-o6)
- **o1**: CLEAREXP - Explain experiences clearly
- **o2**: NAMEEMOTIONS - Recognize and name emotions
- **o3**: SHARETOYS - Share toys with others
- **o4**: PLAYWELL - Play well with others
- **o5**: HURTSAD - Show concern for others
- **o6**: FOCUSON - Focus on tasks

### Additional Domains
- **Health (h1-h3)**: General health, teeth condition, motor skills
- **Self-Regulation (r1-r5)**: Distraction, sitting still, task completion
- **Motor Development (m1-m5)**: Pencil use, physical abilities

Each function in `functions/` returns a list with:
- `data`: Year-specific recoded item responses joined by (year, hhid)
- `syntax`: Mplus MODEL syntax including factor loadings, thresholds, priors, constraints

## Main Analysis Scripts

### 0 - Construct Analytic Datasets - HRTL-2016-2020.R
- Loads raw SPSS files for 2016 and 2022
- Sources all functions from `functions/` directory
- Creates analytic datasets with proper variable recoding
- Validation checks against published Ghandour (2019, 2024) results

### 1 - Fit BRMS.R
- Fits Bayesian multilevel IRT models using brms/cmdstanr
- Models latent abilities (ELS, SED) as function of time, state, gender, age
- Uses cumulative logit link for ordinal responses
- Implements interrupted time series design (pre/post 2020)

## R Environment

### Required Packages
- **Data manipulation**: tidyverse, haven, sjlabelled, readxl
- **Bayesian modeling**: brms, cmdstanr
- **Performance**: OpenCL (for GPU acceleration)

### Working Directory Setup
Update `repo_wd` variable in main scripts to match local repository path:
```r
repo_wd = "C:/repos/HRTL-2016-2022"
setwd(repo_wd)
```

### Function Initialization
All helper functions must be sourced before running analyses:
```r
for(x in list.files("functions/", full.names = T)){
  cat(paste0("\n",x, " successfully sourced"))
  source(x)
}
```

## Data Validation

Validation checks ensure consistency with published CAHMI results:
- `compare_Table2_Ghandour19()`: Item-level response distributions (2016)
- `compare_Figure1_Ghandour19()`: Domain-level prevalence estimates (2016)
- `compare_SuppTable1_Ghandour24()`: Item-level response distributions (2022)
- `compare_prevalences_Ghandour24()`: Domain-level prevalence estimates (2022)

Reference data in `datasets/intermediate/`:
- Ghandour-2019-Tbl2.xlsx
- Ghandour-2019-Fig1.xlsx
- Ghandour-2024-Supplementary-Data.xlsx
- HRTL-2016-Scoring-Thresholds.xlsx
- HRTL-2022-Scoring-Thresholds.xlsx

## Key Technical Details

### Survey Design Variables
- **STRATUM**: Survey stratum
- **FIPSST**: State FIPS code
- **HHID**: Household ID (cluster)
- **FWC**: Final weight (survey weight)
- **SC_AGE_YEARS**: Child age in years (filtered to 3-5)

### Item Response Theory Structure
- **2PL Graded Response Models** for ordinal items
- **Factor loadings** constrained by item prefix (e.g., all e* items load on EL factor)
- **Thresholds** estimated separately for each response category
- **Priors** on threshold differences for measurement invariance across years

### Year-Specific Complications
- 2016 uses different response scales for some items (e.g., ClearExp: 4 vs 5 categories)
- Functions handle item harmonization across years using `transfer_never_always()`
- Some items only appear in specific year ranges (e.g., e1 starts in 2017)

## File Organization

- `functions/`: Modular item-specific recoding and syntax generation
- `datasets/raw/`: Original CAHMI SPSS files (not in git)
- `datasets/intermediate/`: Validation data, scoring thresholds, crosswalks
- `checks/`: Recoding verification output
- `saved-mplus-files/`: Historical Mplus input/output files
- `safe/`: Additional model output storage
