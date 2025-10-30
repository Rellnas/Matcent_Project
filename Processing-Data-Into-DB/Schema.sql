-- Companies dimension
CREATE TABLE dim_companies (
    company_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_companies IS 'Master data for companies in the organization';

-- Areas/Locations dimension
CREATE TABLE dim_areas (
    area_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_areas IS 'Master data for areas/locations (HQ, Distribution, Plant, etc)';

-- Positions dimension
CREATE TABLE dim_positions (
    position_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_positions IS 'Master data for job positions/titles';

-- Departments dimension
CREATE TABLE dim_departments (
    department_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_departments IS 'Master data for departments';

-- Divisions dimension
CREATE TABLE dim_divisions (
    division_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_divisions IS 'Master data for divisions';

-- Directorates dimension
CREATE TABLE dim_directorates (
    directorate_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_directorates IS 'Master data for directorates (Commercial, HR & Corp Affairs, Technology)';

-- Grades dimension
CREATE TABLE dim_grades (
    grade_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_grades IS 'Master data for employee grade levels (III, IV, V)';

-- Education levels dimension
CREATE TABLE dim_education (
    education_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_education IS 'Master data for education levels (D3, S1, S2, S3)';

-- Majors/Fields of study dimension
CREATE TABLE dim_majors (
    major_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

COMMENT ON TABLE dim_majors IS 'Master data for educational majors/fields of study';

-- Competency pillars dimension
CREATE TABLE dim_competency_pillars (
    pillar_code VARCHAR(3) PRIMARY KEY,
    pillar_label TEXT NOT NULL
);

COMMENT ON TABLE dim_competency_pillars IS 
'Competency pillar codes and labels. Codes: GDR, CEX, IDS, QDD, STO, SEA, VCU, LIE, FTC, CSI';

-- Core employee master data
CREATE TABLE employees (
    employee_id TEXT PRIMARY KEY,
    fullname TEXT,
    nip TEXT,
    company_id INT REFERENCES dim_companies(company_id),
    area_id INT REFERENCES dim_areas(area_id),
    position_id INT REFERENCES dim_positions(position_id),
    department_id INT REFERENCES dim_departments(department_id),
    division_id INT REFERENCES dim_divisions(division_id),
    directorate_id INT REFERENCES dim_directorates(directorate_id),
    grade_id INT REFERENCES dim_grades(grade_id),
    education_id INT REFERENCES dim_education(education_id),
    major_id INT REFERENCES dim_majors(major_id),
    years_of_service_months INT
);

COMMENT ON TABLE employees IS 'Core employee master data with organizational assignments';
COMMENT ON COLUMN employees.nip IS 'Nomor Induk Pegawai (Employee ID Number)';
COMMENT ON COLUMN employees.years_of_service_months IS 'Total months of service';

-- Psychometric assessment profiles
CREATE TABLE profiles_psych (
    employee_id TEXT PRIMARY KEY REFERENCES employees(employee_id),
    pauli NUMERIC,
    faxtor NUMERIC,
    disc TEXT,
    disc_word TEXT,
    mbti TEXT,
    iq NUMERIC,
    gtq INT,
    tiki INT
);

COMMENT ON TABLE profiles_psych IS 'Psychometric assessment results for employees';
COMMENT ON COLUMN profiles_psych.pauli IS 'Pauli test score (mental speed/accuracy), range 20-100';
COMMENT ON COLUMN profiles_psych.faxtor IS 'Faxtor score (cognitive capacity), range 20-100';
COMMENT ON COLUMN profiles_psych.disc IS 'DISC behavioral type code (e.g., SI, DS, DC)';
COMMENT ON COLUMN profiles_psych.disc_word IS 'DISC type description';
COMMENT ON COLUMN profiles_psych.mbti IS 'Myers-Briggs Type Indicator (16 personality types)';
COMMENT ON COLUMN profiles_psych.iq IS 'IQ score, range 80-140';
COMMENT ON COLUMN profiles_psych.gtq IS 'General Aptitude Test score, range 9-46';
COMMENT ON COLUMN profiles_psych.tiki IS 'TIKI attention/concentration test, range 1-10';

-- PAPI work preferences scores
CREATE TABLE papi_scores (
    employee_id TEXT REFERENCES employees(employee_id),
    scale_code TEXT NOT NULL,
    score INT,
    CONSTRAINT papi_scores_unique UNIQUE (employee_id, scale_code)
);

CREATE INDEX idx_papi_employee ON papi_scores(employee_id);
CREATE INDEX idx_papi_scale ON papi_scores(scale_code);

COMMENT ON TABLE papi_scores IS 'PAPI (Personality and Preference Inventory) work preference scores';
COMMENT ON COLUMN papi_scores.scale_code IS '20 PAPI scales: Papi_N to Papi_Z';

-- CliftonStrengths assessment
CREATE TABLE strengths (
    employee_id TEXT REFERENCES employees(employee_id),
    rank INT NOT NULL,
    theme TEXT,
    CONSTRAINT strengths_unique UNIQUE (employee_id, rank)
);

CREATE INDEX idx_strengths_employee ON strengths(employee_id);
CREATE INDEX idx_strengths_rank ON strengths(rank);

COMMENT ON TABLE strengths IS 'CliftonStrengths themes ranked 1-14 per employee';
COMMENT ON COLUMN strengths.rank IS 'Strength ranking (1 = top strength, up to 14)';
COMMENT ON COLUMN strengths.theme IS 'CliftonStrengths theme name (34 possible themes)';

-- Yearly performance ratings
CREATE TABLE performance_yearly (
    employee_id TEXT REFERENCES employees(employee_id),
    year INT NOT NULL,
    rating INT,
    CONSTRAINT performance_yearly_unique UNIQUE (employee_id, year)
);

CREATE INDEX idx_performance_year ON performance_yearly(year);
CREATE INDEX idx_performance_employee ON performance_yearly(employee_id);

COMMENT ON TABLE performance_yearly IS 'Annual performance ratings for employees (2021-2025)';
COMMENT ON COLUMN performance_yearly.rating IS 'Performance rating 1-5 (5 = top performer)';
COMMENT ON COLUMN performance_yearly.year IS 'Performance year (2021-2025)';

-- Yearly competency assessments
CREATE TABLE competencies_yearly (
    employee_id TEXT REFERENCES employees(employee_id),
    pillar_code VARCHAR(3) REFERENCES dim_competency_pillars(pillar_code),
    year INT NOT NULL,
    score INT,
    CONSTRAINT competencies_yearly_unique UNIQUE (employee_id, pillar_code, year)
);

CREATE INDEX idx_competencies_pillar_year ON competencies_yearly(pillar_code, year);
CREATE INDEX idx_competencies_employee ON competencies_yearly(employee_id);

COMMENT ON TABLE competencies_yearly IS 'Annual competency pillar scores for employees';
COMMENT ON COLUMN competencies_yearly.score IS 'Competency score 1-5 for each pillar';
COMMENT ON COLUMN competencies_yearly.pillar_code IS 'Reference to competency pillar (GDR, CEX, etc)';

-- Employee lookup indexes
CREATE INDEX idx_employees_company ON employees(company_id);
CREATE INDEX idx_employees_directorate ON employees(directorate_id);
CREATE INDEX idx_employees_division ON employees(division_id);
CREATE INDEX idx_employees_department ON employees(department_id);
CREATE INDEX idx_employees_position ON employees(position_id);
CREATE INDEX idx_employees_grade ON employees(grade_id);

-- Performance analysis indexes
CREATE INDEX idx_performance_rating ON performance_yearly(rating);
CREATE INDEX idx_performance_year_rating ON performance_yearly(year, rating);

-- View: Employee with full organizational context
CREATE OR REPLACE VIEW vw_employee_full AS
SELECT 
    e.employee_id,
    e.fullname,
    e.nip,
    c.name AS company_name,
    a.name AS area_name,
    p.name AS position_name,
    dept.name AS department_name,
    div.name AS division_name,
    dir.name AS directorate_name,
    g.name AS grade_name,
    ed.name AS education_level,
    m.name AS major_name,
    e.years_of_service_months
FROM employees e
LEFT JOIN dim_companies c ON e.company_id = c.company_id
LEFT JOIN dim_areas a ON e.area_id = a.area_id
LEFT JOIN dim_positions p ON e.position_id = p.position_id
LEFT JOIN dim_departments dept ON e.department_id = dept.department_id
LEFT JOIN dim_divisions div ON e.division_id = div.division_id
LEFT JOIN dim_directorates dir ON e.directorate_id = dir.directorate_id
LEFT JOIN dim_grades g ON e.grade_id = g.grade_id
LEFT JOIN dim_education ed ON e.education_id = ed.education_id
LEFT JOIN dim_majors m ON e.major_id = m.major_id;

COMMENT ON VIEW vw_employee_full IS 'Employee data with all dimension labels (human-readable)';

-- View: Latest performance ratings
CREATE OR REPLACE VIEW vw_latest_performance AS
SELECT DISTINCT ON (employee_id)
    employee_id,
    year,
    rating
FROM performance_yearly
ORDER BY employee_id, year DESC;

COMMENT ON VIEW vw_latest_performance IS 'Most recent performance rating for each employee';

-- View: Top performers (Rating 5)
CREATE OR REPLACE VIEW vw_top_performers AS
SELECT DISTINCT
    py.employee_id,
    e.fullname,
    py.year,
    py.rating
FROM performance_yearly py
JOIN employees e ON py.employee_id = e.employee_id
WHERE py.rating = 5;

COMMENT ON VIEW vw_top_performers IS 'All employees who achieved rating 5 (top performer)';

-- TRUNCATE TABLE
--   competencies_yearly,
--   performance_yearly,
--   strengths,
--   papi_scores,
--   profiles_psych,
--   employees,
--   dim_competency_pillars,
--   dim_majors,
--   dim_education,
--   dim_grades,
--   dim_directorates,
--   dim_divisions,
--   dim_departments,
--   dim_positions,
--   dim_areas,
--   dim_companies
-- RESTART IDENTITY CASCADE;
