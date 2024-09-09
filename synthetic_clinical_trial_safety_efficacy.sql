-- Create or replace participants table in CDMS dataset
CREATE OR REPLACE TABLE `cdms.participants` (
    study_id STRING,
    subject_id STRING,
    site_name STRING,
    site_number STRING,
    age INT64,
    sex STRING,
    ethnicity STRING,
    race STRING,
    disease_type STRING,
    disease_subtype STRING,
    ecog_ps INT64,
    disease_status STRING,
    prior_therapies INT64,
    arm STRING,
    cohort STRING,
    dose_level STRING,
    date_of_first_dose DATE,
    date_of_last_date DATE,
    best_overall_response STRING,
    treatment_status STRING,
    reason_for_discontinuation STRING
);

-- Insert 100 random participants (corrected for study-specific disease types)
INSERT INTO `cdms.participants`
WITH base_data AS (
    SELECT
        CASE WHEN RAND() < 0.6 THEN 'STUDY-21' ELSE 'STUDY-15' END AS study_id,
        CONCAT('SUBJ', LPAD(CAST(ROW_NUMBER() OVER() AS STRING), 3, '0')) AS subject_id,
        ARRAY['Memorial Sloan Kettering', 'Dana-Farber Cancer Institute', 'MD Anderson Cancer Center', 'Mayo Clinic', 'Stanford Cancer Institute'][SAFE_CAST(FLOOR(RAND()*5) AS INT64)] AS site_name,
        CONCAT('SITE', LPAD(CAST(FLOOR(RAND()*20)+1 AS STRING), 3, '0')) AS site_number,
        CAST(FLOOR(RAND()*(75-18+1))+18 AS INT64) AS age,
        CASE WHEN RAND() < 0.5 THEN 'Male' ELSE 'Female' END AS sex,
        CASE WHEN RAND() < 0.8 THEN 'Not Hispanic or Latino' ELSE 'Hispanic or Latino' END AS ethnicity,
        ARRAY['White', 'Black or African American', 'Asian', 'Other'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS race,
        CAST(FLOOR(RAND()*3) AS INT64) AS ecog_ps,
        CASE WHEN RAND() < 0.7 THEN 'Relapsed' ELSE 'Refractory' END AS disease_status,
        CAST(FLOOR(RAND()*5)+1 AS INT64) AS prior_therapies,
        CASE WHEN RAND() < 0.5 THEN 'Arm A' ELSE 'Arm B' END AS arm,
        CONCAT('Cohort ', CAST(FLOOR(RAND()*3)+1 AS STRING)) AS cohort,
        DATE_ADD('2023-01-01', INTERVAL CAST(FLOOR(RAND()*90) AS INT64) DAY) AS date_of_first_dose,
        RAND() AS random_value
    FROM UNNEST(GENERATE_ARRAY(1, 100))
),
disease_data AS (
    SELECT 
        *,
        CASE
            WHEN study_id = 'STUDY-21' THEN 'AML'
            ELSE ARRAY['DLBCL', 'FL', 'MCL'][SAFE_CAST(FLOOR(RAND()*3) AS INT64)]
        END AS disease_type
    FROM base_data
)
SELECT
    study_id,
    subject_id,
    site_name,
    site_number,
    age,
    sex,
    ethnicity,
    race,
    disease_type,
    CASE
        WHEN disease_type = 'AML' THEN IF(RAND() < 0.7, 'FLT3-ITD+', 'FLT3-ITD-')
        WHEN disease_type = 'FL' THEN CONCAT('Grade ', CAST(FLOOR(RAND()*3)+1 AS STRING))
        ELSE NULL
    END AS disease_subtype,
    ecog_ps,
    disease_status,
    prior_therapies,
    arm,
    cohort,
    CASE
        WHEN study_id = 'STUDY-21' THEN ARRAY['600 mg', '800 mg', '1000 mg'][SAFE_CAST(FLOOR(RAND()*3) AS INT64)]
        ELSE ARRAY['200 mg', '400 mg', '600 mg'][SAFE_CAST(FLOOR(RAND()*3) AS INT64)]
    END AS dose_level,
    date_of_first_dose,
    CASE
        WHEN random_value < 0.8 THEN DATE_ADD(date_of_first_dose, INTERVAL CAST(FLOOR(RAND()*180)+30 AS INT64) DAY)
        ELSE NULL
    END AS date_of_last_date,
    ARRAY['Complete Response', 'Partial Response', 'Stable Disease', 'Progressive Disease'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS best_overall_response,
    CASE WHEN random_value < 0.8 THEN 'Off Treatment' ELSE 'On Treatment' END AS treatment_status,
    CASE
        WHEN random_value < 0.8 THEN
            ARRAY['Completed', 'Disease Progression', 'Adverse Event', 'Withdrawal by Subject'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)]
        ELSE NULL
    END AS reason_for_discontinuation
FROM disease_data;

-- Create or replace adverse_events table
CREATE OR REPLACE TABLE `cdms.adverse_events` (
    study_id STRING,
    subject_id STRING,
    ae_term STRING,
    ae_category STRING,
    start_date DATE,
    end_date DATE,
    severity_grade INT64,
    is_serious BOOL,
    is_related BOOL,
    treatment_emergent BOOL,
    action_taken STRING,
    outcome STRING
);

-- Insert random adverse events
INSERT INTO `cdms.adverse_events`
WITH base_ae_data AS (
    SELECT
        p.study_id,
        p.subject_id,
        p.date_of_first_dose,
        ARRAY['Neutropenia', 'Fatigue', 'Nausea', 'Diarrhea', 'Rash', 'Thrombocytopenia', 'Anemia', 'Fever', 'Headache', 'Vomiting'][SAFE_CAST(FLOOR(RAND()*10) AS INT64)] AS ae_term,
        ARRAY['Blood and lymphatic system disorders', 'General disorders', 'Gastrointestinal disorders', 'Skin and subcutaneous tissue disorders', 'Nervous system disorders'][SAFE_CAST(FLOOR(RAND()*5) AS INT64)] AS ae_category,
        DATE_ADD(p.date_of_first_dose, INTERVAL CAST(FLOOR(RAND()*30) AS INT64) DAY) AS start_date,
        CAST(FLOOR(RAND()*4)+1 AS INT64) AS severity_grade,
        RAND() < 0.2 AS is_serious,
        RAND() < 0.7 AS is_related,
        RAND() < 0.6 AS treatment_emergent,
        ARRAY['Dose Not Changed', 'Dose Reduced', 'Dose Interrupted', 'Drug Withdrawn'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS action_taken,
        ARRAY['Resolved', 'Resolving', 'Not Resolved', 'Fatal'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS outcome,
        RAND() AS random_value
    FROM
        `cdms.participants` p
    CROSS JOIN
        UNNEST(GENERATE_ARRAY(1, CAST(2 + RAND()*5 AS INT64))) -- Generate 2-6 AEs per participant
    WHERE
        RAND() < 0.9 -- 90% chance of having an AE
)
SELECT
    study_id,
    subject_id,
    ae_term,
    ae_category,
    start_date,
    DATE_ADD(start_date, INTERVAL CAST(FLOOR(RAND()*30) AS INT64) DAY) AS end_date,
    severity_grade,
    is_serious,
    is_related,
    treatment_emergent,
    action_taken,
    outcome
FROM base_ae_data;

 -- Create or replace AML response assessments table
CREATE OR REPLACE TABLE `cdms.aml_response_assessments` (
    study_id STRING,
    subject_id STRING,
    assessment_date DATE,
    response_category STRING,
    bone_marrow_blast_percentage FLOAT64,
    peripheral_blast_percentage FLOAT64,
    platelet_count INT64,
    neutrophil_count FLOAT64,
    transfusion_independence BOOL,
    extramedullary_disease STRING
);

-- Insert random AML response assessments
INSERT INTO `cdms.aml_response_assessments`
SELECT
    p.study_id,
    p.subject_id,
    DATE_ADD(p.date_of_first_dose, INTERVAL CAST(FLOOR(RAND()*90) AS INT64) DAY) AS assessment_date,
    ARRAY['Complete Remission', 'Partial Remission', 'Stable Disease', 'Progressive Disease'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS response_category,
    ROUND(RAND()*50, 1) AS bone_marrow_blast_percentage,
    ROUND(RAND()*20, 1) AS peripheral_blast_percentage,
    CAST(FLOOR(RAND()*(400000-20000+1))+20000 AS INT64) AS platelet_count,
    ROUND(RAND()*5, 1) AS neutrophil_count,
    RAND() < 0.6 AS transfusion_independence,
    CASE WHEN RAND() < 0.1 THEN 'Present' ELSE 'None' END AS extramedullary_disease
FROM
    `cdms.participants` p
WHERE
    p.disease_type = 'AML'
UNION ALL
SELECT
    p.study_id,
    p.subject_id,
    DATE_ADD(p.date_of_first_dose, INTERVAL CAST(FLOOR(RAND()*180) AS INT64) DAY) AS assessment_date,
    ARRAY['Complete Remission', 'Partial Remission', 'Stable Disease', 'Progressive Disease'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS response_category,
    ROUND(RAND()*50, 1) AS bone_marrow_blast_percentage,
    ROUND(RAND()*20, 1) AS peripheral_blast_percentage,
    CAST(FLOOR(RAND()*(400000-20000+1))+20000 AS INT64) AS platelet_count,
    ROUND(RAND()*5, 1) AS neutrophil_count,
    RAND() < 0.6 AS transfusion_independence,
    CASE WHEN RAND() < 0.1 THEN 'Present' ELSE 'None' END AS extramedullary_disease
FROM
    `cdms.participants` p
WHERE
    p.disease_type = 'AML';

-- Create or replace B-cell malignancy response assessments table
CREATE OR REPLACE TABLE `cdms.bcell_response_assessments` (
    study_id STRING,
    subject_id STRING,
    assessment_date DATE,
    response_category STRING,
    sum_of_product_diameters FLOAT64,
    bone_marrow_involvement BOOL,
    ldh_level FLOAT64,
    b_symptoms BOOL,
    pet_result STRING
);

-- Insert random B-cell malignancy response assessments
INSERT INTO `cdms.bcell_response_assessments`
SELECT
    p.study_id,
    p.subject_id,
    DATE_ADD(p.date_of_first_dose, INTERVAL CAST(FLOOR(RAND()*90) AS INT64) DAY) AS assessment_date,
    ARRAY['Complete Response', 'Partial Response', 'Stable Disease', 'Progressive Disease'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS response_category,
    ROUND(RAND()*200, 1) AS sum_of_product_diameters,
    RAND() < 0.3 AS bone_marrow_involvement,
    ROUND(100 + RAND()*400, 1) AS ldh_level,
    RAND() < 0.4 AS b_symptoms,
    CASE WHEN RAND() < 0.6 THEN 'Negative' ELSE 'Positive' END AS pet_result
FROM
    `cdms.participants` p
WHERE
    p.disease_type != 'AML'
UNION ALL
SELECT
    p.study_id,
    p.subject_id,
    DATE_ADD(p.date_of_first_dose, INTERVAL CAST(FLOOR(RAND()*180) AS INT64) DAY) AS assessment_date,
    ARRAY['Complete Response', 'Partial Response', 'Stable Disease', 'Progressive Disease'][SAFE_CAST(FLOOR(RAND()*4) AS INT64)] AS response_category,
    ROUND(RAND()*200, 1) AS sum_of_product_diameters,
    RAND() < 0.3 AS bone_marrow_involvement,
    ROUND(100 + RAND()*400, 1) AS ldh_level,
    RAND() < 0.4 AS b_symptoms,
    CASE WHEN RAND() < 0.6 THEN 'Negative' ELSE 'Positive' END AS pet_result
FROM
    `cdms.participants` p
WHERE
    p.disease_type != 'AML';

