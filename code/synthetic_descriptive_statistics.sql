WITH 
participant_summary AS (
    SELECT
        study_id,
        COUNT(*) AS total_participants,
        AVG(age) AS mean_age,
        STDDEV(age) AS stddev_age,
        COUNTIF(sex = 'Male') / COUNT(*) AS male_proportion,
        COUNTIF(disease_type = 'AML') / COUNT(*) AS aml_proportion,
        COUNTIF(treatment_status = 'On Treatment') / COUNT(*) AS on_treatment_proportion
    FROM `cdms.participants`
    GROUP BY study_id
),

adverse_events_summary AS (
    SELECT
        study_id,
        COUNT(*) AS total_aes,
        COUNTIF(treatment_emergent) AS teae_count,
        COUNTIF(is_related) AS trae_count,
        AVG(severity_grade) AS mean_severity,
        COUNTIF(is_serious) / COUNT(*) AS serious_ae_proportion,
        COUNTIF(action_taken = 'Drug Withdrawn') / COUNT(*) AS discontinuation_rate
    FROM `cdms.adverse_events`
    GROUP BY study_id
),

response_summary AS (
    SELECT
        study_id,
        COUNT(DISTINCT subject_id) AS assessed_participants,
        COUNTIF(response_category IN ('Complete Response', 'Partial Response')) / COUNT(DISTINCT subject_id) AS overall_response_rate,
        AVG(bone_marrow_blast_percentage) AS mean_bone_marrow_blast,
        AVG(neutrophil_count) AS mean_neutrophil_count,
        NULL AS mean_tumor_size,
        NULL AS mean_ldh_level,
        'AML' AS disease_type
    FROM `cdms.aml_response_assessments`
    GROUP BY study_id
    
    UNION ALL
    
    SELECT
        study_id,
        COUNT(DISTINCT subject_id) AS assessed_participants,
        COUNTIF(response_category IN ('Complete Response', 'Partial Response')) / COUNT(DISTINCT subject_id) AS overall_response_rate,
        NULL AS mean_bone_marrow_blast,
        NULL AS mean_neutrophil_count,
        AVG(sum_of_product_diameters) AS mean_tumor_size,
        AVG(ldh_level) AS mean_ldh_level,
        'B-cell' AS disease_type
    FROM `cdms.bcell_response_assessments`
    GROUP BY study_id
)

SELECT
    p.study_id,
    p.total_participants,
    p.mean_age,
    p.stddev_age,
    p.male_proportion,
    p.aml_proportion,
    p.on_treatment_proportion,
    ae.total_aes,
    ae.teae_count,
    ae.trae_count,
    ae.mean_severity,
    ae.serious_ae_proportion,
    ae.discontinuation_rate,
    r.assessed_participants,
    r.overall_response_rate,
    COALESCE(r.mean_bone_marrow_blast, r.mean_tumor_size) AS primary_disease_measure,
    COALESCE(r.mean_neutrophil_count, r.mean_ldh_level) AS secondary_disease_measure,
    r.disease_type
FROM participant_summary p
JOIN adverse_events_summary ae ON p.study_id = ae.study_id
JOIN response_summary r ON p.study_id = r.study_id;