CREATE VIEW employee_data AS
SELECT 
	eh.employee_number,
	(SELECT title 
	FROM employees e 
	WHERE e.employee_number = eh.employee_number)
	AS title,
	eh.first_name,
	eh.mid_name,
	eh.last_name,	
	eh.gender,
	eh.birth_date,
	eh.marital_status,
	eh.SSN,
	(SELECT home_email 
	FROM employees e 
	WHERE e.employee_number = eh.employee_number)
	AS home_email,
	eh.hire_date,
	eh.re_hire_date,
	eh.terminate_date,
	eh.terminate_type,
	eh.terminate_reason,
	eh.job_name,
	eh.job_code,
	eh.employee_job_effective_date,
	eh.employee_job_expirty_date,
	eh.department_code,
	eh.location_code,
	eh.pay_frequency,
	eh.pay_type,
	(CASE 
	WHEN eh.pay_amount::INTEGER < 10000
	THEN NULL
	ELSE eh.pay_amount
	END
	) AS hourlyAmount,
	(CASE 
	WHEN eh.pay_amount::INTEGER >= 10000
	THEN NULL
	ELSE eh.pay_amount
	END
	) AS salarlyAmount,
	(SELECT j.code 
	FROM jobs j,
	departments d,
	locations l
	WHERE j.name = eh.report_to_job
	AND d.id = j.department_id
	AND d.code = eh.department_code
	AND l.code = eh.location_code
	AND l.id = d.location_id
	) AS supervisorJobCode,
	eh.employment_status,
	eh.standard_hours,
	eh.employee_type,
	eh.employee_status,
	(SELECT rr.id
	FROM review_ratings rr,
	employee_reviews er,
	employees e
	WHERE rr.id = er.rating_id
	AND er.employee_id = e.id
	AND e.employee_number = eh.employee_number
	) AS lastPerformanceRating,
	(SELECT rr.review_text
	FROM review_ratings rr,
	employee_reviews er,
	employees e
	WHERE rr.id = er.rating_id
	AND er.employee_id = e.id
	AND e.employee_number = eh.employee_number
	) AS lastPerformanceRatingText,
	(SELECT er.review_date
	FROM employee_reviews er,
	employees e
	WHERE er.employee_id = e.id
	AND e.employee_number = eh.employee_number
	) AS lastPerformanceRatingDate,
	
	(SELECT ea.street_number
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 1
	) AS homeStreetNum,
	(SELECT ea.street
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 1
	) AS homeStreetName,
	(SELECT ea.street_suffix
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 1
	) AS homeStreetSuffix,
	(SELECT ea.city
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 1
	) AS homeCity,
	(SELECT p.name
	FROM provinces p,
	emp_addresses ea,
	employees e
	WHERE p.id = ea.province_id
	AND ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 1
	) AS homeState,
	(SELECT c.name
	FROM countries c,
	emp_addresses ea,
	employees e
	WHERE c.id = ea.country_id
	AND ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 1
	) AS homeCountry,
	(SELECT ea.postal_code
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 1
	) AS homeZipCode,
	
	(SELECT ea.street_number
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 2
	) AS busStreetNum,
	(SELECT ea.street
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 2
	) AS busStreetName,
	(SELECT ea.street_suffix
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 2
	) AS busStreetSuffix,
	(SELECT ea.city
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 2
	) AS busCity,
	(SELECT p.name
	FROM provinces p,
	emp_addresses ea,
	employees e
	WHERE p.id = ea.province_id
	AND ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 2
	) AS busState,
	(SELECT c.name
	FROM countries c,
	emp_addresses ea,
	employees e
	WHERE c.id = ea.country_id
	AND ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 2
	) AS busCountry,
	(SELECT ea.postal_code
	FROM emp_addresses ea,
	employees e
	WHERE ea.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND ea.type_id = 2
	) AS busZipCode,
	
	(SELECT pn.country_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 1
	) AS phone1CountryCode,
	(SELECT pn.area_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 1
	) AS phone1AreaCode,
	(SELECT pn.ph_number
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 1
	) AS phone1Number,
	(SELECT pn.extension
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 1
	) AS phone1Extension,
	(SELECT pt.name
	FROM phone_types pt, 
	phone_numbers pn,
	employees e
	WHERE pt.id = pn.type_id 
	AND pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 1
	) AS phone1Type,
	
	(SELECT pn.country_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 2
	) AS phone2CountryCode,
	(SELECT pn.area_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 2
	) AS phone2AreaCode,
	(SELECT pn.ph_number
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 2
	) AS phone2Number,
	(SELECT pn.extension
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 2
	) AS phone2Extension,
	(SELECT pt.name
	FROM phone_types pt, 
	phone_numbers pn,
	employees e
	WHERE pt.id = pn.type_id 
	AND pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 2
	) AS phone2Type,
	
	(SELECT pn.country_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 3
	) AS phone3CountryCode,
	(SELECT pn.area_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 3
	) AS phone3AreaCode,
	(SELECT pn.ph_number
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 3
	) AS phone3Number,
	(SELECT pn.extension
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 3
	) AS phone3Extension,
	(SELECT pt.name
	FROM phone_types pt, 
	phone_numbers pn,
	employees e
	WHERE pt.id = pn.type_id 
	AND pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 3
	) AS phone3Type,
	
	(SELECT pn.country_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 4
	) AS phone4CountryCode,
	(SELECT pn.area_code
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 4
	) AS phone4AreaCode,
	(SELECT pn.ph_number
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 4
	) AS phone4Number,
	(SELECT pn.extension
	FROM phone_numbers pn,
	employees e
	WHERE pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 4
	) AS phone4Extension,
	(SELECT pt.name
	FROM phone_types pt, 
	phone_numbers pn,
	employees e
	WHERE pt.id = pn.type_id 
	AND pn.employee_id = e.id
	AND e.employee_number = eh.employee_number
	AND pn.employee_number_id = 4
	) AS phone4Type
	
FROM
        (SELECT
                employee_number,
                MAX(change_date)
        FROM employee_history
        GROUP BY 
        employee_number) en,
        employee_history eh
WHERE 
eh.employee_number = en.employee_number 
AND
eh.change_date = en.max
AND
eh.operation != 'Delete'
;

\copy (SELECT * FROM employee_data) To './Part4_Report.csv' With CSV HEADER