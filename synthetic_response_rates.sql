WITH longitudinal_response AS (
    SELECT 
        p.study_id,
        p.subject_id,
        p.cohort,
        ra.assessment_date,
        ra.response_category,
        ROW_NUMBER() OVER (PARTITION BY p.subject_id ORDER BY ra.assessment_date) as assessment_number
    FROM cdms.participants p
    JOIN cdms.bcell_response_assessments ra ON p.subject_id = ra.subject_id
)
SELECT 
    study_id,
    cohort,
    assessment_number,
    COUNT(*) as total_patients,
    SUM(CASE WHEN response_category IN ('Complete Response', 'Partial Response') THEN 1 ELSE 0 END) as responders,
    SUM(CASE WHEN response_category IN ('Complete Response', 'Partial Response') THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as response_rate
FROM longitudinal_response
GROUP BY study_id, cohort, assessment_number
ORDER BY study_id, cohort, assessment_number;