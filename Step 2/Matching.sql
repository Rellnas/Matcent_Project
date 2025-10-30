
-- STEP 1: Baseline Competency Scores (from High Performers, rating=5)
-- Calculates mean and std dev for each competency pillar among top performers

CREATE TEMP TABLE baseline_competencies AS
SELECT
    c.pillar_code,
    cp.pillar_label,
    ROUND(AVG(c.score), 2) AS baseline_mean,
    ROUND(STDDEV(c.score), 2) AS baseline_std,
    COUNT(*) AS sample_size,
    ROUND(MIN(c.score), 2) AS min_score,
    ROUND(MAX(c.score), 2) AS max_score
FROM competencies_yearly c
JOIN performance_yearly py ON c.employee_id = py.employee_id AND c.year = py.year
JOIN dim_competency_pillars cp ON c.pillar_code = cp.pillar_code
WHERE py.year = 2025 AND py.rating = 5.0
GROUP BY c.pillar_code, cp.pillar_label
ORDER BY pillar_code;

-- Debug: Show baseline competencies
COMMENT ON TABLE baseline_competencies IS 
'Baseline competency metrics for high performers (rating=5) in 2025';


-- STEP 2: Baseline Psychometric Scores
-- Calculates mean and std dev for PAULI, GTQ, IQ among high performers

CREATE TEMP TABLE baseline_psychometric AS
SELECT
    'PAULI' AS variable,
    'PAULI - Mental Speed & Accuracy' AS variable_label,
    ROUND(AVG(pauli), 2) AS baseline_mean,
    ROUND(STDDEV(pauli), 2) AS baseline_std,
    COUNT(*) AS sample_size,
    ROUND(MIN(pauli), 2) AS min_score,
    ROUND(MAX(pauli), 2) AS max_score
FROM profiles_psych pp
JOIN performance_yearly py ON pp.employee_id = py.employee_id
WHERE py.year = 2025 AND py.rating = 5.0 AND pp.pauli IS NOT NULL
UNION ALL
SELECT
    'GTQ',
    'GTQ - General Aptitude Test',
    ROUND(AVG(gtq), 2),
    ROUND(STDDEV(gtq), 2),
    COUNT(*),
    ROUND(MIN(gtq), 2),
    ROUND(MAX(gtq), 2)
FROM profiles_psych pp
JOIN performance_yearly py ON pp.employee_id = py.employee_id
WHERE py.year = 2025 AND py.rating = 5.0 AND pp.gtq IS NOT NULL
UNION ALL
SELECT
    'IQ',
    'IQ - Intelligence Quotient',
    ROUND(AVG(iq), 2),
    ROUND(STDDEV(iq), 2),
    COUNT(*),
    ROUND(MIN(iq), 2),
    ROUND(MAX(iq), 2)
FROM profiles_psych pp
JOIN performance_yearly py ON pp.employee_id = py.employee_id
WHERE py.year = 2025 AND py.rating = 5.0 AND pp.iq IS NOT NULL
ORDER BY variable;

COMMENT ON TABLE baseline_psychometric IS 
'Baseline psychometric metrics for high performers (rating=5) in 2025';


-- STEP 3A: Talent Variable Match - Competency Pillars
-- Calculates match rate for each competency pillar per employee
-- TV Match Rate = 100 - (|score - baseline_mean| / baseline_std * 10)
-- Key: Each row = 1 TV (e.g., GDR, CEX, IDS...)
--      All TVs belong to same TGV (Competency_Excellence)

CREATE TEMP TABLE tv_competency_match AS
SELECT
    c.employee_id,
    'Competency_Excellence' AS tgv_name,
    c.pillar_code AS tv_code,
    cp.pillar_label AS tv_name,
    c.score AS user_score,
    bc.baseline_mean AS baseline_score,
    CASE
        WHEN bc.baseline_std = 0 THEN 
            CASE WHEN c.score = bc.baseline_mean THEN 100 ELSE 0 END
        ELSE GREATEST(0, 100 - (ABS(c.score - bc.baseline_mean) / bc.baseline_std * 10))
    END AS tv_match_rate
FROM competencies_yearly c
JOIN baseline_competencies bc ON c.pillar_code = bc.pillar_code
JOIN dim_competency_pillars cp ON c.pillar_code = cp.pillar_code
WHERE c.year = 2025
ORDER BY c.employee_id, c.pillar_code;

COMMENT ON TABLE tv_competency_match IS 
'TV Match rates for 10 competency pillars. Each row is one Talent Variable (TV).
 All TVs aggregate into Competency_Excellence TGV with 50% final weight.';


-- STEP 3B: Talent Variable Match - Psychometric Tests
-- Calculates match rate for PAULI, GTQ, IQ
-- Same Z-score formula as competencies
-- Key: Each row = 1 TV (PAULI, GTQ, or IQ)
--      All TVs belong to same TGV (Cognitive_Ability)

CREATE TEMP TABLE tv_psychometric_match AS
-- PAULI: Mental Speed & Accuracy (Weight 15% of psychometric TGV)
SELECT
    pp.employee_id,
    'Cognitive_Ability' AS tgv_name,
    'PAULI' AS tv_code,
    'PAULI - Mental Speed & Accuracy' AS tv_name,
    pp.pauli AS user_score,
    bp.baseline_mean AS baseline_score,
    CASE
        WHEN bp.baseline_std = 0 THEN 
            CASE WHEN pp.pauli = bp.baseline_mean THEN 100 ELSE 0 END
        ELSE GREATEST(0, 100 - (ABS(pp.pauli - bp.baseline_mean) / bp.baseline_std * 10))
    END AS tv_match_rate
FROM profiles_psych pp
JOIN baseline_psychometric bp ON bp.variable = 'PAULI'
WHERE pp.pauli IS NOT NULL

UNION ALL

-- GTQ: General Aptitude Test (Weight 7% of psychometric TGV)
SELECT
    pp.employee_id,
    'Cognitive_Ability',
    'GTQ',
    'GTQ - General Aptitude Test',
    pp.gtq,
    bp.baseline_mean,
    CASE
        WHEN bp.baseline_std = 0 THEN 
            CASE WHEN pp.gtq = bp.baseline_mean THEN 100 ELSE 0 END
        ELSE GREATEST(0, 100 - (ABS(pp.gtq - bp.baseline_mean) / bp.baseline_std * 10))
    END
FROM profiles_psych pp
JOIN baseline_psychometric bp ON bp.variable = 'GTQ'
WHERE pp.gtq IS NOT NULL

UNION ALL

-- IQ: Intelligence Quotient (Weight 3% of psychometric TGV)
SELECT
    pp.employee_id,
    'Cognitive_Ability',
    'IQ',
    'IQ - Intelligence Quotient',
    pp.iq,
    bp.baseline_mean,
    CASE
        WHEN bp.baseline_std = 0 THEN 
            CASE WHEN pp.iq = bp.baseline_mean THEN 100 ELSE 0 END
        ELSE GREATEST(0, 100 - (ABS(pp.iq - bp.baseline_mean) / bp.baseline_std * 10))
    END
FROM profiles_psych pp
JOIN baseline_psychometric bp ON bp.variable = 'IQ'
WHERE pp.iq IS NOT NULL

ORDER BY employee_id, tv_code;

COMMENT ON TABLE tv_psychometric_match IS 
'TV Match rates for psychometric tests (PAULI, GTQ, IQ).
 All TVs aggregate into Cognitive_Ability TGV with 25% final weight.
 Within psychometric: PAULI 60% (15%), GTQ 28% (7%), IQ 12% (3%).';


-- STEP 3C: Talent Variable Match - Behavioral Strengths
-- CliftonStrengths themes classified into 2 behavioral clusters:
--   - Thinker: Intellection, Analytical, Strategic, Futuristic
--   - Doer: Activator, Responsibility, Self-Assurance, Belief
-- Match: Binary (100 if cluster theme in top 5, 0 otherwise)
-- Key: Each row = 1 TV (Thinker_Cluster or Doer_Cluster)
--      All TVs belong to same TGV (Behavioral_Strengths)

CREATE TEMP TABLE tv_behavioral_match AS
WITH strength_data AS (
    -- Get all employees with their top 5 strengths themes
    SELECT
        py.employee_id,
        MAX(CASE 
            WHEN s.theme IN ('Intellection', 'Analytical', 'Strategic', 'Futuristic')
            THEN 1 ELSE 0 
        END) AS has_thinker,
        MAX(CASE 
            WHEN s.theme IN ('Activator', 'Responsibility', 'Self-Assurance', 'Belief')
            THEN 1 ELSE 0 
        END) AS has_doer
    FROM performance_yearly py
    LEFT JOIN strengths s ON py.employee_id = s.employee_id AND s.rank <= 5
    WHERE py.year = 2025
    GROUP BY py.employee_id
)
-- Thinker Cluster TV
SELECT
    employee_id,
    'Behavioral_Strengths' AS tgv_name,
    'Thinker_Cluster' AS tv_code,
    'Thinker Cluster (Intellection, Analytical, Strategic, Futuristic)' AS tv_name,
    has_thinker AS user_score,
    1 AS baseline_score,  -- High performers always have behavioral strength
    has_thinker * 100 AS tv_match_rate
FROM strength_data

UNION ALL

-- Doer Cluster TV
SELECT
    employee_id,
    'Behavioral_Strengths',
    'Doer_Cluster',
    'Doer Cluster (Activator, Responsibility, Self-Assurance, Belief)',
    has_doer,
    1,
    has_doer * 100
FROM strength_data

ORDER BY employee_id, tv_code;

COMMENT ON TABLE tv_behavioral_match IS 
'TV Match rates for behavioral strengths clusters (Thinker, Doer).
 Binary match: 100 if theme present in top 5, 0 otherwise.
 All TVs aggregate into Behavioral_Strengths TGV with 20% final weight.';


-- STEP 3D: Talent Variable Match - Contextual Fit
-- Grade and tenure fit factors
-- Match: Based on optimal grade and tenure ranges
-- Grade Fit:  Grade III-IV = 100%, Grade V = 75%
-- Tenure Fit: 2-5 years (24-60 months) = 100%, Others = 50%

CREATE TEMP TABLE tv_contextual_match AS
SELECT
    e.employee_id,
    'Contextual_Fit' AS tgv_name,
    'Grade_Fit' AS tv_code,
    'Grade Level' AS tv_name,
    e.grade_id AS user_score,
    3 AS baseline_score,
    CASE 
        WHEN e.grade_id IN (1, 2) THEN 100  -- Grade III, IV
        WHEN e.grade_id = 3 THEN 75         -- Grade V
        ELSE 50
    END AS tv_match_rate
FROM employees e
WHERE EXISTS (SELECT 1 FROM performance_yearly py WHERE py.employee_id = e.employee_id AND py.year = 2025)

UNION ALL

SELECT
    e.employee_id,
    'Contextual_Fit',
    'Tenure_Fit',
    'Tenure (Months)',
    e.years_of_service_months,
    36,  -- Baseline 3 years
    CASE 
        WHEN e.years_of_service_months BETWEEN 24 AND 60 THEN 100  -- 2-5 years optimal
        WHEN e.years_of_service_months BETWEEN 12 AND 72 THEN 75   -- 1-6 years acceptable
        ELSE 50
    END
FROM employees e
WHERE EXISTS (SELECT 1 FROM performance_yearly py WHERE py.employee_id = e.employee_id AND py.year = 2025)

ORDER BY employee_id, tv_code;

COMMENT ON TABLE tv_contextual_match IS 
'TV Match rates for contextual factors (Grade, Tenure).
 Grade: III-IV optimal (100%), V acceptable (75%), others (50%).
 Tenure: 2-5 years optimal (100%), 1-6 years acceptable (75%), others (50%).
 All TVs aggregate into Contextual_Fit TGV with 5% final weight.';


-- STEP 4: Aggregate TV to TGV Match Rates
-- Average all TVs within each TGV to get TGV match rate
-- Output: 1 row per employee per TGV (4 TGVs max)
-- Columns: employee_id, tgv_name, tgv_match_rate, tv_count

CREATE TEMP TABLE tgv_match_rates AS
SELECT
    employee_id,
    tgv_name,
    ROUND(AVG(tv_match_rate), 2) AS tgv_match_rate,
    COUNT(*) AS tv_count,
    ROUND(MIN(tv_match_rate), 2) AS min_tv_rate,
    ROUND(MAX(tv_match_rate), 2) AS max_tv_rate
FROM (
    SELECT * FROM tv_competency_match
    UNION ALL SELECT * FROM tv_psychometric_match
    UNION ALL SELECT * FROM tv_behavioral_match
    UNION ALL SELECT * FROM tv_contextual_match
)
GROUP BY employee_id, tgv_name
ORDER BY employee_id, tgv_name;

COMMENT ON TABLE tgv_match_rates IS 
'Aggregated TGV match rates per employee. Average of all TVs within TGV.
 TGV Final Weights: Competency_Excellence 50%, Cognitive_Ability 25%, 
                    Behavioral_Strengths 20%, Contextual_Fit 5%.';


-- STEP 5: DETAILED TV/TGV Output
-- Complete breakdown showing all Talent Variables and their contribution
-- Output Columns:
--   - employee_id, fullname, directorate, role, grade
--   - tgv_name, tv_name (detailed TV breakdown)
--   - baseline_score, user_score, tv_match_rate, tgv_match_rate
--   - tgv_weight (for final score calculation)

SELECT
    e.employee_id,
    e.fullname,
    COALESCE(d.name, 'N/A') AS directorate,
    COALESCE(p.name, 'N/A') AS role,
    COALESCE(g.name, 'N/A') AS grade,
    tv.tgv_name,
    tv.tv_code,
    tv.tv_name,
    ROUND(tv.baseline_score::numeric, 2) AS baseline_score,
    ROUND(tv.user_score::numeric, 2) AS user_score,
    ROUND(tv.tv_match_rate::numeric, 2) AS tv_match_rate,
    COALESCE(ROUND(tgv.tgv_match_rate::numeric, 2), 0) AS tgv_match_rate,
    CASE
        WHEN tv.tgv_name = 'Competency_Excellence' THEN 0.50
        WHEN tv.tgv_name = 'Cognitive_Ability' THEN 0.25
        WHEN tv.tgv_name = 'Behavioral_Strengths' THEN 0.20
        WHEN tv.tgv_name = 'Contextual_Fit' THEN 0.05
        ELSE 0
    END AS tgv_weight,
    COALESCE(py.rating, 0) AS current_rating
FROM (
    SELECT * FROM tv_competency_match
    UNION ALL SELECT * FROM tv_psychometric_match
    UNION ALL SELECT * FROM tv_behavioral_match
    UNION ALL SELECT * FROM tv_contextual_match
) tv
JOIN employees e ON tv.employee_id = e.employee_id
LEFT JOIN dim_directorates d ON e.directorate_id = d.directorate_id
LEFT JOIN dim_positions p ON e.position_id = p.position_id
LEFT JOIN dim_grades g ON e.grade_id = g.grade_id
LEFT JOIN tgv_match_rates tgv ON tv.employee_id = tgv.employee_id 
                                  AND tv.tgv_name = tgv.tgv_name
LEFT JOIN performance_yearly py ON e.employee_id = py.employee_id AND py.year = 2025
ORDER BY e.employee_id, tv.tgv_name, tv.tv_code;

-- STEP 6: Final Match Score Summary
-- Produces FINAL RANKING with:
--   - Final Match Score (weighted average across all TGVs)
--   - Match Category classification
--   - Top strengths and gaps analysis
-- Weights Applied:
--   Competency_Excellence:    50%
--   Cognitive_Ability:        25%
--   Behavioral_Strengths:     20%
--   Contextual_Fit:           05%
--   TOTAL:                   100%

SELECT
    e.employee_id,
    e.fullname,
    COALESCE(d.name, 'N/A') AS directorate,
    COALESCE(p.name, 'N/A') AS role,
    COALESCE(g.name, 'N/A') AS grade,
    ROUND(
        COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                  WHERE employee_id = e.employee_id AND tgv_name = 'Competency_Excellence'), 0) * 0.50 +
        COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                  WHERE employee_id = e.employee_id AND tgv_name = 'Cognitive_Ability'), 0) * 0.25 +
        COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                  WHERE employee_id = e.employee_id AND tgv_name = 'Behavioral_Strengths'), 0) * 0.20 +
        COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                  WHERE employee_id = e.employee_id AND tgv_name = 'Contextual_Fit'), 0) * 0.05,
        2
    ) AS final_match_rate,
    CASE
        WHEN (
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Competency_Excellence'), 0) * 0.50 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Cognitive_Ability'), 0) * 0.25 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Behavioral_Strengths'), 0) * 0.20 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Contextual_Fit'), 0) * 0.05
        ) >= 80 THEN 'Excellent (80-100%)'
        WHEN (
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Competency_Excellence'), 0) * 0.50 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Cognitive_Ability'), 0) * 0.25 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Behavioral_Strengths'), 0) * 0.20 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Contextual_Fit'), 0) * 0.05
        ) >= 60 THEN 'Good (60-79%)'
        WHEN (
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Competency_Excellence'), 0) * 0.50 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Cognitive_Ability'), 0) * 0.25 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Behavioral_Strengths'), 0) * 0.20 +
            COALESCE((SELECT tgv_match_rate FROM tgv_match_rates 
                      WHERE employee_id = e.employee_id AND tgv_name = 'Contextual_Fit'), 0) * 0.05
        ) >= 40 THEN 'Moderate (40-59%)'
        ELSE 'Low (0-39%)'
    END AS match_category,
    COALESCE(ROUND((SELECT tgv_match_rate FROM tgv_match_rates 
                    WHERE employee_id = e.employee_id AND tgv_name = 'Competency_Excellence')::numeric, 2), 0) AS comp_tgv_rate,
    COALESCE(ROUND((SELECT tgv_match_rate FROM tgv_match_rates 
                    WHERE employee_id = e.employee_id AND tgv_name = 'Cognitive_Ability')::numeric, 2), 0) AS cog_tgv_rate,
    COALESCE(ROUND((SELECT tgv_match_rate FROM tgv_match_rates 
                    WHERE employee_id = e.employee_id AND tgv_name = 'Behavioral_Strengths')::numeric, 2), 0) AS behav_tgv_rate,
    COALESCE(ROUND((SELECT tgv_match_rate FROM tgv_match_rates 
                    WHERE employee_id = e.employee_id AND tgv_name = 'Contextual_Fit')::numeric, 2), 0) AS context_tgv_rate,
    COALESCE(py.rating, 0) AS current_rating
FROM employees e
LEFT JOIN dim_directorates d ON e.directorate_id = d.directorate_id
LEFT JOIN dim_positions p ON e.position_id = p.position_id
LEFT JOIN dim_grades g ON e.grade_id = g.grade_id
LEFT JOIN performance_yearly py ON e.employee_id = py.employee_id AND py.year = 2025
ORDER BY final_match_rate DESC, e.employee_id;