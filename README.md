# Talent Match Intelligence System

AI-powered talent matching platform. Analyze 2,010 employees, identify success patterns, rank candidates by fit.

**Live:** https://matcentproject-hg6qhetc6hcggjdoualtsz.streamlit.app

---

## Overview

```
Excel (2,010 employees) → Supabase DB → Step 1 (Pattern) → Step 2 (Algorithm) → Step 3 (Dashboard)
```

---

## Quick Start (5 minutes)

```bash
git clone https://github.com/Rellnas/Matcent_Project.git
cd Matcent_Project

python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Add API key: .streamlit/secrets.toml
# OPENROUTER_API_KEY = "sk-or-v1-your-key"

cd Step\ 3 && streamlit run app.py
# Open: http://localhost:8501
```

---

## 📁 File Structure

```
Matcent_Project/
├── README.md (this file)
├── app.py, requirements.txt
├── Processing-Data-Into-DB/
│   ├── Schema.sql → Create 16 database tables
│   ├── Import-Dataset.ipynb → Upload data to Supabase
│   └── SNLSupabaseEdit.sql → Enable security
├── Step 1/ → Analysis-Data.ipynb (analyze 2,010 employees)
├── Step 2/ → Matching.sql + Matching.ipynb (create algorithm)
└── Step 3/ → app.py (dashboard)
```

---

## HOW IT WORKS

### Data Setup

1. **Schema.sql** - Creates 16 tables in Supabase (employees, competencies, psychometric, performance, etc)
2. **Import-Dataset.ipynb** - Reads Excel file, uploads 200k+ records to database
3. **SNLSupabaseEdit.sql** - Enables Row Level Security (allows app to read data safely)

### Step 1: Success Pattern Discovery

**File:** Analysis-Data.ipynb

- Load 2,010 employees from Supabase
- Analyze 4 dimensions:
  - Competency (50%)
  - Cognitive ability (25%)
  - Behavioral traits (20%)
  - Contextual factors (5%)
- Compare high performers (rating 5) vs average
- Output: Success formula & baseline metrics

### Step 2: Matching Algorithm

**Files:** Matching.sql + Matching.ipynb

- Calculate baseline from benchmark employees
- Z-score normalize all 2,010 employees
- Aggregate 4 dimensions into single score
- Rank employees 0-100%
- Output: Ranked talent list

### Step 3: AI Dashboard

**File:** app.py

**User inputs:**

- Role name, level, purpose
- Select 2-5 benchmark employees

**Process:**

- OpenRouter API generates job profile
- Calculates match scores (vectorized)
- Displays top 20 + 5 visualizations

**Outputs:**

- Interactive ranking table
- Visualizations (histogram, radar, heatmap, etc)
- CSV export

---

## Key Metrics

| Metric      | Value     |
| ----------- | --------- |
| Employees   | 2,010     |
| Processing  | 15-30 sec |
| Match range | 0-100%    |
| Top match   | 92.5%     |
| Avg match   | 71.4%     |

---

## Tech Stack

- **Frontend:** Streamlit
- **Backend:** Python 3.13+
- **Database:** Supabase PostgreSQL
- **AI:** OpenRouter API (GPT-3.5)
- **Data:** Pandas, NumPy
- **Deploy:** Streamlit Cloud

---

## Security

Database uses Row Level Security:

- Read-only access for app
- No delete/update permissions
- Safe for public deployment

---

## Setup Steps (Detailed)

### 1. Database Setup

```bash
# Go to Supabase: https://supabase.com
# Create project → Get URL & API key

# SQL Editor → Run Schema.sql (creates 16 tables)
# Then run SNLSupabaseEdit.sql (enables security)
```

### 2. Import Data

```bash
# Run Import-Dataset.ipynb
jupyter notebook Processing-Data-Into-DB/Import-Dataset.ipynb

# Reads Study-Case-DA.xlsx (16 sheets)
# Uploads to Supabase (~200k records)
# Verify: Check table counts match
```

### 3. Run Analysis (Step 1)

```bash
jupyter notebook Step\ 1/Analysis-Data.ipynb
# Analyzes patterns, outputs success formula
```

### 4. Run Algorithm (Step 2)

```bash
jupyter notebook Step\ 2/Matching.ipynb
# Executes SQL, calculates rankings
```

### 5. Run Dashboard (Step 3)

```bash
cd Step\ 3
streamlit run app.py
```

---

## Features

✓ AI-generated job profiles
✓ 4-dimensional scoring
✓ Real-time matching
✓ 5 interactive visualizations
✓ CSV export
✓ Production deployed

---

## Documentation

**Full Report:** Case-Study-Report.md

- Executive summary
- Success patterns (4 dimensions)
- SQL algorithm explanation
- Dashboard features
- Challenges & solutions

---

## Important

- **API Key:** `OPENROUTER_API_KEY` in `.streamlit/secrets.toml` (DO NOT COMMIT)
- **Data:** Study-Case-DA.xlsx contains sensitive HR data
- **Database:** Requires Supabase account (free tier available)

---

## Performance

- 8x faster than naive approach
- Batch processing (2 queries vs 2000+)
- 92%+ accuracy for top candidates
- Scales to 10,000+ employees
