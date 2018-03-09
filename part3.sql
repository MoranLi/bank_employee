-- Solution for 2017 Term 1 CMPT355 Assignment 3
-- Author: Lujie Duan

-- copy in psql to load data files



\copy load_locations FROM 'assgn3-locationFile.csv' CSV HEADER;

\copy load_departments FROM 'assgn3-departmentFile.csv' CSV HEADER;

-- This need to be the one that has been corrected 
\copy load_employee_data FROM 'assgn3-employeeFile.csv' CSV HEADER;

\copy load_new_employe_data FROM 'assgn4-employeeFile.csv' CSV HEADER;

\copy load_jobs FROM 'assgn3-jobFile.csv' CSV HEADER;


-- add in values for reference tables
CREATE OR REPLACE FUNCTION load_reference_tables()
RETURNS void AS $$
BEGIN
  INSERT INTO countries(id, code, name)
  VALUES ( 1, 'CA', 'Canada'),
         ( 2, 'US', 'United States of America');
          
          
  INSERT INTO provinces(id, code, name)
  VALUES(1, 'SK', 'Saskatchewan'),
   (2, 'AB', 'Alberta'),
   (3, 'MB', 'Manitoba'),
   (4, 'BC', 'British Columbia'),
   (5, 'ON', 'Ontario'),
   (6, 'QB', 'Quebec'),
   (7, 'NB', 'New Brunswick'),
   (8, 'PE', 'Prince Edward Island'),
   (9, 'NS', 'Nova Scotia'),
   (10, 'NL', 'Newfoundland'),
   (11, 'YK', 'Yukon'),
   (12, 'NT', 'Northwest Territories'),
   (13, 'NU', 'Nunavut');

  INSERT INTO pay_types(id, code, name, description)
  VALUES (1, 'H', 'Hourly', 'Employees paid by an hourly rate of pay'),
         (2, 'S', 'Salary', 'Employees paid by a salaried rate of pay');
         
  INSERT INTO pay_frequencies(id,code,name, description)
  VALUES (1, 'B', 'Biweekly', 'Paid every two weeks'),
         (2, 'W', 'Weekly', 'Paid every week'),
         (3, 'M', 'Monthly', 'Paid once a month');
         
  INSERT INTO marital_statuses(id, code, name, description)
  VALUES(1, 'D', 'Divorced', ''),
        (2, 'M', 'Married', ''),
        (3, 'SP', 'Separated', ''),
        (4, 'C', 'Common-Law', ''),
        (5, 'S', 'Single', '');
        
  INSERT INTO employee_types(id,code,name,description)
  VALUES(1, 'REG', 'Regular', ''),
        (2, 'TEMP', 'Temporary', '');
        
  INSERT INTO employment_status_types(id,code,name,description)
  VALUES(1, 'A' ,'Active', ''),
        (2, 'I', 'Inactive', ''),
        (3, 'P', 'Paid Leave', ''),
        (4, 'U', 'Unpaid Leave', ''),
        (5, 'S', 'Suspension', '');
        
  INSERT INTO employee_statuses(id,code,name,description)
  VALUES(1, 'F' ,'Full-time', ''),
        (2, 'P', 'Part-time', ''),
        (3, 'C', 'Casual', '');
    
  INSERT INTO address_types(id,code,name,description)
  VALUES(1, 'HOME', 'Home', ''),
        (2, 'BUS', 'Business', ''); 
        
  INSERT INTO review_ratings(id,review_text,description)
  VALUES(1, 'Does Not Meet', ''),
        (2, 'Needs Improvement', ''),
        (3, 'Meets Expectations', ''),
        (4, 'Exceeds Expectations', ''),
        (5, 'Exceptional', '');
  
  -- See below for alternative way to do this      
  INSERT INTO phone_types(id,code,name,description)
  VALUES(1, 'H', 'Home', ''),
        (2, 'B', 'Business', ''),
        (3, 'M', 'Mobile', '');

  INSERT INTO termination_types(id,code,name,description)
  VALUES(1, 'V', 'Voluntary', ''),
        (2, 'I', 'Involuntary', '');
  
  INSERT INTO termination_reasons(id,code,name,description)
  VALUES(1, 'DEA', 'Death', ''),
        (2, 'JAB', 'Job Abandonmet', ''),
        (3, 'DIS', 'Dismissal', ''),
        (4, 'EOT', 'End of Temporary Assignment', ''),
        (5, 'LAY', 'Layoff', ''),
        (6, 'RET', 'Retirement', ''),
        (7, 'RES', 'Resignation', '');
  
  
END; $$ LANGUAGE plpgsql;

-- An alternative way to do the above INSERT
CREATE OR REPLACE FUNCTION load_phone_types()
RETURNS void AS $$
BEGIN
 
  INSERT INTO phone_types(id,code,name,description)
  SELECT COALESCE((
                SELECT MAX(PT.id) 
                FROM phone_types PT),0) + row_number() OVER () AS id, 
    UPPER(SUBSTRING(LPT.phone_type, 1, 1)),
    LPT.phone_type,
    ''
  FROM (
    SELECT DISTINCT ph1_type AS phone_type
    FROM load_employee_data led
    UNION
    SELECT DISTINCT ph2_type AS phone_type
    FROM load_employee_data led
    UNION
    SELECT DISTINCT ph3_type AS phone_type
    FROM load_employee_data led
    UNION
    SELECT DISTINCT ph4_type AS phone_type
    FROM load_employee_data led) AS LPT
  WHERE LPT.phone_type IS NOT NULL
    AND LPT.phone_type NOT IN (
    SELECT name 
    FROM phone_types);

END; $$ LANGUAGE plpgsql;


-- Helper function to load phone numbers
CREATE OR REPLACE FUNCTION load_phone_numbers(p_emp_id INT, p_country_code VARCHAR(5), p_area_code VARCHAR(3),
                                              p_ph_number CHAR(7), p_extension VARCHAR(10), p_ph_type VARCHAR(10),p_number_id INT)
RETURNS void AS  $$
DECLARE
  v_phone_type_id INT;
BEGIN
  
  SELECT id
  INTO v_phone_type_id 
  FROM phone_types 
  WHERE UPPER(name) = UPPER(p_ph_type);
  
  IF v_phone_type_id IS NOT NULL AND p_area_code IS NOT NULL AND p_ph_number IS NOT NULL THEN 
    INSERT INTO phone_numbers(employee_id, country_code,area_code,ph_number,extension,type_id,employee_number_id)
    VALUES(p_emp_id,p_country_code,p_area_code,p_ph_number,p_extension,v_phone_type_id,p_number_id);
  ELSE 
    RAISE NOTICE 'Did not insert phone number for record: %', p_ph_number;
  END IF; 
                     
END; $$ language plpgsql;


-- Load all the locations
CREATE OR REPLACE FUNCTION load_locations()
RETURNS void AS $$
DECLARE 
  v_job_locs RECORD;
  v_locs RECORD;
  v_prov_id INT;
  v_country_id INT;
  v_location_id INT;
BEGIN
-- load the locations from the location file
  FOR v_locs IN (SELECT 
                  TRIM(loc_code) loc_code, 
                  TRIM(loc_name) loc_name, 
                  TRIM(street_addr) street_addr, 
                  TRIM(city) city,
                  TRIM(province) province, 
                  TRIM(country) country,
                  REGEXP_REPLACE(UPPER(TRIM(postal_code)), '[^A-Z0-9]', '', 'g') postal_code
                FROM load_locations ll) LOOP
                
    SELECT id 
    INTO v_prov_id
    FROM provinces 
    WHERE name = v_locs.province;
    
    IF v_prov_id IS NULL THEN 
      RAISE NOTICE 'Record skipped because of invalid province for record: %', v_locs;
      CONTINUE;
    END IF; 
    
    SELECT id 
    INTO v_country_id 
    FROM countries 
    WHERE name = v_locs.country;
    
    IF v_country_id IS NULL THEN 
      RAISE NOTICE 'Record skipped because of invalid country for record: %', v_locs;
      CONTINUE;
    END IF; 
    
    SELECT id 
    INTO v_location_id 
    FROM locations 
    WHERE code = v_locs.loc_code;
    
    IF v_location_id IS NULL THEN
      INSERT INTO locations(code,name,street,city,province_id,country_id,postal_code)
      VALUES (v_locs.loc_code, v_locs.loc_name, v_locs.street_addr, v_locs.city, v_prov_id, v_country_id, v_locs.postal_code);
    ELSE 
      UPDATE locations 
      SET 
        name = v_locs.loc_name, 
        street = v_locs.street_addr,
        city = v_locs.city,
        province_id = v_prov_id,
        country_id = v_country_id, 
        postal_code = v_locs.postal_code
      WHERE id = v_location_id;
    END IF;  
  END LOOP;
END;
$$ language plpgsql;


-- Load all departments
CREATE OR REPLACE FUNCTION load_departments()
RETURNS void AS $$
DECLARE 
  v_req_depts RECORD;
  v_depts RECORD;
  v_mgr RECORD; 
  
  v_location_id INT;
  v_department_id INT; 
  v_mgr_job_id INT;
BEGIN
  FOR v_depts IN (SELECT 
                        TRIM(ld.dept_code) dept_code, 
                        TRIM(ld.dept_name) dept_name,  
                        TRIM(ld.dept_mgr_job_code) dept_mgr_job_code,  
                        TRIM(ld.dept_mgr_job_title) dept_mgr_job_title,
                        TRIM(ld.effective_date) effective_date,
                        TRIM(ld.expiry_date) expiry_date,
                        TRIM(locs.location_code) location_code
                     FROM 
                       load_departments ld, 
                       (SELECT TRIM(led.department_code) department_code, 
                              TRIM(led.location_code) location_code
                        FROM load_employee_data led
                        GROUP BY TRIM(led.department_code), TRIM(led.location_code)) locs 
                     WHERE TRIM(locs.department_code) = TRIM(ld.dept_code)
                       AND EXISTS (SELECT 1
                                   FROM load_locations ll
                                   WHERE TRIM(locs.location_code) = TRIM(ll.loc_code)) ) LOOP
         
    SELECT id 
    INTO v_location_id
    FROM locations 
    WHERE code = v_depts.location_code;
    
    IF v_location_id IS NULL THEN 
      RAISE NOTICE 'Record skipped because of invalid location for record: %', vdepts;
      CONTINUE;
    END IF; 
    
    SELECT d.id 
    INTO v_department_id 
    FROM departments d,locations l
    WHERE d.code = v_depts.dept_code and l.code = v_depts.location_code and d.location_id = l.id;
    
    IF v_department_id IS NULL THEN
      INSERT INTO departments(code,name,manager_job_id,location_id)
      VALUES (v_depts.dept_code, v_depts.dept_name, NULL, v_location_id)
      RETURNING id INTO v_department_id; 
    ELSE 
      UPDATE departments 
      SET 
        name = v_depts.dept_name, 
        location_id = v_location_id
      WHERE id = v_department_id;
    END IF; 
    
    
    -- find the manager job id 
    FOR v_mgr IN (SELECT id
                FROM jobs
                WHERE code = v_depts.dept_mgr_job_code
                  AND department_id = v_department_id) LOOP
      v_mgr_job_id := mgr.id;    
    END LOOP;
    
    IF v_mgr_job_id IS NOT NULL THEN 
      UPDATE departments 
      SET manager_job_id = v_mgr_job_id 
      WHERE id = v_department_id;  
    END IF;
     
  END LOOP;
END;
$$ language plpgsql;

-- Load all jobs
CREATE OR REPLACE FUNCTION load_jobs() 
RETURNS void AS $$
DECLARE
  v_jobs RECORD;
  v_depts RECORD; 
  
  v_location_id INT;
  v_department_id INT; 
  v_regional_code VARCHAR(10);
  v_job_id INT;
  v_mgr_job_id INT;
  v_pay_type_id INT;
  v_pay_freq_id INT;
  
BEGIN
  -- loop through all the jobs and either insert or update them. 
  FOR v_jobs IN (SELECT 
                   TRIM(led.job_code) job_code, 
                   TRIM(led.job_title) job_title, 
                   TRIM(led.pay_freq) pay_freq, 
                   TRIM(led.pay_type) pay_type, 
                   TRIM(led.supervisor_job_code) supervisor_job_code,
                   TRIM(led.department_code) department_code, 
                   TRIM(led.location_code) location_code, 
                   TO_DATE(TRIM(jobs.effective_date), 'DD/MM/YYYY') effective_date, 
                   TO_DATE(TRIM(jobs.expiry_date), 'DD/MM/YYYY') expiry_date
                 FROM load_employee_data led,
                     (SELECT 
                        lj.effective_date,
                        lj.expiry_date
                      FROM load_jobs lj) jobs 
                 GROUP BY led.job_code, led.job_title, led.pay_freq, 
                          led.pay_type, led.supervisor_job_code, led.department_code, 
                          led.location_code, jobs.effective_date, jobs.expiry_date) LOOP
    
    SELECT id 
    INTO v_location_id 
    FROM locations 
    WHERE code = v_jobs.location_code; 
    
    IF v_location_id IS NULL THEN 
      RAISE NOTICE 'Record skipped because of invalid location for record: %', v_jobs;
      CONTINUE;
    END IF; 
    
    SELECT id
    INTO v_department_id
    FROM departments 
    WHERE code = v_jobs.department_code
      AND location_id = v_location_id; 
      
    IF v_department_id IS NULL THEN 
      RAISE NOTICE 'Record skipped because of invalid department for record: %', v_jobs;
      CONTINUE;
    END IF;   
         
    SELECT id 
    INTO v_job_id 
    FROM jobs
    WHERE code = v_jobs.job_code
      AND department_id = v_department_id; 
    
    
    SELECT id 
    INTO v_pay_freq_id 
    FROM pay_frequencies 
    WHERE UPPER(name) = UPPER(v_jobs.pay_freq);
    
    IF v_pay_freq_id IS NULL THEN 
      RAISE NOTICE 'Record skipped because of invalid pay frequency for record: %', v_jobs;
      CONTINUE;
    END IF; 
  
    SELECT id 
    INTO v_pay_type_id 
    FROM pay_types
    WHERE UPPER(name) = UPPER(v_jobs.pay_type);
    
    IF v_pay_type_id IS NULL THEN 
      RAISE NOTICE 'Record skipped because of invalid pay type for record: %', v_jobs;
      CONTINUE;
    END IF; 
  
    IF v_job_id IS NULL THEN              
      INSERT INTO jobs(code,name, effective_date, expiry_date,department_id,pay_frequency_id, pay_type_id, supervisor_job_id)
      VALUES(v_jobs.job_code, v_jobs.job_title,v_jobs.effective_date,v_jobs.expiry_date,v_department_id,v_pay_freq_id,v_pay_type_id,NULL)
      RETURNING id INTO v_job_id;
    ELSE 
      UPDATE jobs
      SET name = v_jobs.job_title,
          effective_date = v_jobs.effective_date,
          expiry_date = v_jobs.expiry_date,
          department_id = v_department_id,
          pay_frequency_id = v_pay_freq_id,
          pay_type_id = v_pay_type_id
      WHERE id = v_job_id; 
    END IF;
  END LOOP;
  
  --
  -- update supervisor id
  --       
  --  get all the supervisor job codes for each employee job id
  FOR v_jobs IN (SELECT 
                   sup_jobs.code supervisor_job_code, 
                   emp_jobs.id emp_job_id,
                   emp_jobs.code emp_code,
                   emp_dept.id emp_department_id, 
                   emp_locs.id emp_location_id,
                   emp_locs.code emp_location_code
                 FROM 
                   load_employee_data led,
                   jobs sup_jobs, 
                   jobs emp_jobs, 
                   departments emp_dept, 
                   locations emp_locs
                 WHERE TRIM(led.supervisor_job_code) = sup_jobs.code
                   AND TRIM(led.job_code) = emp_jobs.code
                   AND emp_jobs.department_id = emp_dept.id
                   AND emp_dept.location_id = emp_locs.id
                 GROUP BY sup_jobs.code, emp_jobs.id, emp_jobs.code, emp_dept.id, emp_locs.id, emp_locs.code) LOOP
    
    -- there's basically a three-level hierarchy:
    -- local reporting: 
    --    employees reporting to a supervisor at a local level (02-) will report to the supervisor job in the same department
    -- regional reporting:
    --    employees reporting to a supervisor at a regional level (03-) will report to the regional manager in their same region/province
    -- executive reporting:
    --    employees reporting to an executive position (10-) will report to the executive position at headquarters)
    -- 
    IF v_jobs.supervisor_job_code LIKE '02-%' THEN 
      -- get the supervisor job id at the employee's location (but it might be in a different department at that location)
      SELECT j.id
      INTO v_mgr_job_id
      FROM 
        jobs j 
      WHERE j.code = v_jobs.supervisor_job_code 
        AND j.department_id IN (SELECT d.id
                                FROM departments d
                                WHERE d.location_id = v_jobs.emp_location_id);
     
    ELSIF v_jobs.supervisor_job_code LIKE '03-%' THEN 
      v_regional_code := SPLIT_PART(v_jobs.emp_location_code, '-', 1);
      
      -- find the active regional manager job in the selected region
      SELECT j.*, l.code, d.code
      INTO v_mgr_job_id 
      FROM 
        jobs j,
        locations l, 
        departments d, 
        employee_jobs ej
      WHERE l.code LIKE v_regional_code || '%'
        AND j.code = v_jobs.supervisor_job_code
        AND ej.job_id = j.id 
        AND l.id = d.location_id 
        AND d.id = j.department_id
        AND ej.effective_date <= CURRENT_DATE 
        AND COALESCE(ej.expiry_date,CURRENT_DATE+1) > CURRENT_DATE 
      LIMIT 1; 

    ELSIF v_jobs.supervisor_job_code LIKE '10-%' THEN 
      -- this is an executive supervisor at headquarters - just return the job id
      SELECT j.id
      INTO v_mgr_job_id 
      FROM jobs j
      WHERE j.code = v_jobs.supervisor_job_code;
    END IF; 
    
    
    IF v_mgr_job_id IS NULL THEN 
      RAISE NOTICE 'Could not find a manager for this job: %. Supervisor job id was updated to null.', v_jobs;
    END IF; 
    
    
    UPDATE jobs 
    SET supervisor_job_id = v_mgr_job_id
    WHERE id = v_jobs.emp_job_id;
    
  END LOOP;
  -- update department mgr id 
  FOR v_depts IN (SELECT 
                    d.id department_id,
                    TRIM(ld.dept_code) department_code,
                    j.id job_id
                  FROM 
                    load_departments ld,
                    jobs j, 
                    departments d
                  WHERE TRIM(ld.dept_mgr_job_code) = j.code
                    AND j.department_id = d.id ) LOOP
    UPDATE departments 
    SET manager_job_id = v_depts.job_id
    WHERE id = v_depts.department_id;
  END LOOP;
  
  
END;
$$ language plpgsql;
 
-- Load all employees
CREATE OR REPLACE FUNCTION load_employees()
RETURNS void AS $$
DECLARE
  v_emp RECORD;
  v_empjobs RECORD; 
  v_ssn_rec record;
  
  
  v_emp_id INT;
  v_employment_status_id INT;
  v_term_reason_id INT;
  v_term_type_id INT;
  v_emp_job_id INT;
  v_perf_review_id INT;
  v_employee_type_id INT;
  v_employee_status_id INT;
  v_job_id INT;
  v_home_addr_id INT;
  v_home_prov_id INT;
  v_home_country_id INT;
  v_home_addr_type_id INT;
  v_bus_addr_id INT;
  v_bus_prov_id INT;
  v_bus_country_id INT;
  v_bus_addr_type_id INT;
  v_marital_status_id INT;
  v_location_id INT;
  v_department_id INT; 
BEGIN
  --- insert or update employee data
  FOR v_emp IN (SELECT 
                  TRIM(led.employee_number) employee_number, 
                  TRIM(led.title) title, 
                  TRIM(led.first_name) first_name,
                  TRIM(led.middle_name) middle_name,
                  TRIM(led.last_name) last_name,
                  CASE TRIM(UPPER(led.gender)) 
                    WHEN 'MALE' THEN 'M'
                    WHEN 'FEMALE' THEN 'F'
                    ELSE 'U'
                  END gender,
                  TO_DATE(TRIM(led.birthdate), 'yyyy-mm-dd') birthdate, 
                  TRIM(led.marital_status) marital_status, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ssn)), '[^A-Z0-9]', '', 'g') ssn, 
                  TRIM(led.home_email) home_email, 
                  TO_DATE(TRIM(led.orig_hire_date), 'yyyy-mm-dd') orig_hire_date,
                  TO_DATE(TRIM(led.rehire_date), 'yyyy-mm-dd') rehire_date,
                  TO_DATE(TRIM(led.term_date), 'yyyy-mm-dd') term_date,
                  TRIM(led.term_type) term_type, 
                  TRIM(led.term_reason) term_reason, 
                  TRIM(led.job_code) job_code, 
                  TO_DATE(TRIM(led.job_st_date), 'yyyy-mm-dd') job_st_date,
                  TO_DATE(TRIM(led.job_end_date), 'yyyy-mm-dd') job_end_date,
                  TRIM(led.department_code) department_code, 
                  TRIM(led.location_code) location_code, 
                  TRIM(led.pay_freq) pay_freq,
                  TRIM(led.pay_type) pay_type,
                  COALESCE( TO_NUMBER(TRIM(led.hourly_amount), 'FM99G999G999.00'),
                            TO_NUMBER(TRIM(led.salary_amount), 'FM99G999G999.00') ) pay_amount,
                  TRIM(led.supervisor_job_code) supervisor_job_code, 
                  TRIM(led.employee_status) employee_status, 
                  TRIM(led.standard_hours) standard_hours,
                  TRIM(led.employee_type) employee_type, 
                  TRIM(led.employment_status) employment_status, 
                  TRIM(led.last_perf_num) last_perf_number, 
                  TRIM(led.last_perf_text) last_perf_text, 
                  TO_DATE(TRIM(led.last_perf_date), 'yyyy-mm-dd') last_perf_date, 
                  TRIM(led.home_street_num) home_street_num, 
                  TRIM(led.home_street_addr) home_street_addr, 
                  TRIM(led.home_street_suffix) home_street_suffix,
                  TRIM(led.home_city) home_city,
                  TRIM(led.home_state) home_state,
                  TRIM(led.home_country) home_country,
                  TRIM(led.home_zip_code) home_zip_code,
                  TRIM(led.bus_street_num)bus_street_num,
                  TRIM(led.bus_street_addr) bus_street_addr,
                  TRIM(led.bus_street_suffix) bus_street_suffix,
                  TRIM(led.bus_city) bus_city,
                  TRIM(led.bus_state) bus_state,
                  TRIM(led.bus_country) bus_country,
                  TRIM(led.bus_zip_code) bus_zip_code,
                  REGEXP_REPLACE(UPPER(TRIM(led.ph1_cc)), '[^A-Z0-9]', '', 'g') ph1_cc,
                  REGEXP_REPLACE(UPPER(TRIM(led.ph1_area)), '[^A-Z0-9]', '', 'g') ph1_area,
                  REGEXP_REPLACE(UPPER(TRIM(led.ph1_number)), '[^A-Z0-9]', '', 'g') ph1_number,
                  TRIM(led.ph1_extension) ph1_extension,
                  TRIM(led.ph1_type) ph1_type,  
                  REGEXP_REPLACE(UPPER(TRIM(led.ph2_cc)), '[^A-Z0-9]', '', 'g') ph2_cc, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph2_area)), '[^A-Z0-9]', '', 'g') ph2_area, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph2_number)), '[^A-Z0-9]', '', 'g') ph2_number, 
                  TRIM(led.ph2_extension) ph2_extension, 
                  TRIM(led.ph2_type) ph2_type,  
                  REGEXP_REPLACE(UPPER(TRIM(led.ph3_cc)), '[^A-Z0-9]', '', 'g') ph3_cc, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph3_area)), '[^A-Z0-9]', '', 'g') ph3_area, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph3_number)), '[^A-Z0-9]', '', 'g') ph3_number, 
                  TRIM(led.ph3_extension) ph3_extension, 
                  TRIM(led.ph3_type) ph3_type, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph4_cc)), '[^A-Z0-9]', '', 'g') ph4_cc, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph4_area)), '[^A-Z0-9]', '', 'g') ph4_area, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph4_number)), '[^A-Z0-9]', '', 'g') ph4_number,
                  TRIM(led.ph4_extension) ph4_extension, 
                  TRIM(led.ph4_type) ph4_type
                FROM load_employee_data led
                ORDER BY led.employee_number) LOOP
    
    -- get the employee number
    SELECT id
    INTO v_emp_id
    FROM employees 
    WHERE employee_number = v_emp.employee_number;

    -- get the employment status 
    SELECT id
    INTO v_employment_status_id
    FROM employment_status_types
    WHERE UPPER(name) = UPPER(v_emp.employment_status);
    
    SELECT id 
    INTO v_term_type_id
    FROM termination_types 
    WHERE UPPER(name) = UPPER(v_emp.term_type);
    
    SELECT id
    INTO v_term_reason_id
    FROM termination_reasons
    WHERE UPPER(name) = UPPER(v_emp.term_reason);
    
    SELECT id
    INTO v_marital_status_id
    FROM marital_statuses 
    WHERE UPPER(name) = UPPER(v_emp.marital_status); 
    
    
    -- if the employee isn't in the database yet...
    IF v_emp_id IS NULL THEN 
    
      -- check to make sure the SSN isn't already in use or null
      FOR v_ssn_rec IN (SELECT id 
                        FROM employees 
                        WHERE ssn = v_emp.ssn) LOOP
        RAISE NOTICE 'ssn already in use. cannot insert record: %', v_emp;
        CONTINUE;                
      END LOOP;
     
      IF v_emp.ssn IS NOT NULL THEN 
        INSERT INTO employees(employee_number,title,first_name,middle_name,last_name,gender,ssn,birth_date,
                              marital_status_id,home_email,employment_status_id,hire_date,rehire_date,termination_date,
                              term_type_id, term_reason_id)
        VALUES (v_emp.employee_number,v_emp.title,v_emp.first_name,v_emp.middle_name,v_emp.last_name,v_emp.gender,
                v_emp.ssn, v_emp.birthdate,v_marital_status_id,v_emp.home_email,v_employment_status_id, 
                v_emp.orig_hire_date,v_emp.rehire_date,v_emp.term_date, v_term_type_id, v_term_reason_id)
        RETURNING id into v_emp_id;
      ELSE 
        RAISE NOTICE 'Skipping employee record. ssn null for employee: %', v_emp;
        CONTINUE;
      END IF;
    
    ELSE 
    -- if you found the employee number, check to make sure it's the employee number for the right person.
      -- Check to make sure this is the right person
      IF NOT v_emp.ssn = (SELECT ssn 
                          FROM employees
                          WHERE id = v_emp_id) THEN 
        RAISE NOTICE 'This employee number belongs to another employee: %', v_emp;
        CONTINUE;
      END IF;
      
      UPDATE employees 
      SET 
        title = v_emp.title, 
        first_name = v_emp.first_name, 
        middle_name = v_emp.middle_name,
        last_name = v_emp.last_name, 
        gender = v_emp.gender, 
        ssn = v_emp.ssn, 
        birth_date = v_emp.birthdate,
        marital_status_id = v_marital_status_id, 
        home_email = v_emp.home_email,
        employment_status_id = v_employment_status_id,
        hire_date = v_emp.orig_hire_date, 
        rehire_date = v_emp.rehire_date,
        termination_date = v_emp.term_date,
        term_type_id = v_term_type_id,
        term_reason_id = v_term_reason_id
      WHERE id = v_emp_id;
    END IF;
    
    
    -- 
    -- Performance 
    --
    --  look for an existing review for the employee with the date in the file
    SELECT id
    INTO v_perf_review_id
    FROM employee_reviews
    WHERE employee_id = v_emp_id 
      AND review_date = v_emp.last_perf_date;

    -- if it doesn't exist, insert it. Otherwise, update the rating 
    IF v_perf_review_id IS NULL AND v_emp.last_perf_number IS NOT NULL AND v_emp.last_perf_date IS NOT NULL THEN 
      INSERT INTO employee_reviews(employee_id, review_date, rating_id)
      VALUES (v_emp_id, v_emp.last_perf_date, v_emp.last_perf_number::INT);
    ELSIF v_emp.last_perf_number IS NOT NULL AND v_emp.last_perf_date IS NOT NULL THEN
      UPDATE employee_reviews
      SET rating_id = v_emp.last_perf_number::INT
      WHERE id = v_perf_review_id;
    END IF;
    
    
    --
    --  insert/update into employee jobs
    --
    
     -- get the employee type 
    SELECT id
    INTO v_employee_type_id
    FROM employee_types
    WHERE UPPER(name) = UPPER(v_emp.employee_type);
    
    
    -- get the employee status
    SELECT id
    INTO v_employee_status_id
    FROM employee_statuses
    WHERE UPPER(name) = UPPER(v_emp.employee_status);
    
    -- look for an employee_job for this employee
    v_emp_job_id := NULL;
    FOR v_empjobs IN (SELECT ej.id
                      FROM 
                        employee_jobs ej, 
                        employees e,
                        jobs j
                      WHERE ej.employee_id = e.id 
                        AND e.employee_number = v_emp.employee_number 
                        AND ej.job_id = j.id
                        AND j.code = v_emp.job_code
                        AND v_emp.job_st_date = ej.effective_date) LOOP
      v_emp_job_id := v_empjobs.id;
    END LOOP;
    
    -- check to see if there is a job with this job code in this department/location combination.
    SELECT j.id 
    INTO v_job_id
    FROM jobs j
    LEFT JOIN departments d ON j.department_id = d.id
    JOIN locations l ON l.id = d.location_id
    WHERE l.code = v_emp.location_code
      AND UPPER(j.code) = UPPER(v_emp.job_code);

    IF v_job_id IS NULL
    THEN
        RAISE NOTICE 'No job exists with this job code, department, location combination for employee %, "%"', v_emp_id, v_emp.job_code;
        CONTINUE;
    END IF;
    
    -- check if there's an existing open employee job for this employee and job combination 
    --   during this time period. 
    -- If there isn't, then check for an existing open employee job and close it, and then insert a new 
    --   employee job record.
    -- If there is, do an update. 
    IF v_emp_job_id IS NULL THEN 
    
      -- check for existing open employee job and expire it.
      FOR v_empjobs IN (SELECT ej.id
                   FROM employee_jobs ej
                   WHERE ej.expiry_date IS NULL 
                     AND ej.employee_id = v_emp_id) LOOP
        UPDATE employee_jobs
        SET expiry_date = v_emp.job_st_date
        WHERE id = v_empjobs.id;
      END LOOP;
      
      INSERT INTO employee_jobs(employee_id,job_id,effective_date,expiry_date,pay_amount,
                                standard_hours,employee_type_id,employee_status_id)
      VALUES(v_emp_id, v_job_id, v_emp.job_st_date, v_emp.job_end_date, v_emp.pay_amount, v_emp.standard_hours::INT, 
             v_employee_type_id, v_employee_status_id );
    ELSE 
      -- UPDATE employee_jobs 
      UPDATE employee_jobs 
      SET pay_amount = v_emp.pay_amount, 
          standard_hours = v_emp.standard_hours::INT, 
          employee_type_id = v_employee_type_id,
          employee_status_id = v_employee_status_id,
          effective_date = v_emp.job_st_date,
          expiry_date = v_emp.job_end_date
      WHERE id = v_emp_job_id;
    END IF;
    
    
    
    --
    -- load addresses
    --
    
    -- add/update home addresses
    SELECT a.id
    INTO v_home_addr_id 
    FROM 
      emp_addresses a,
      address_types atype
    WHERE a.type_id = atype.id
      AND atype.code = 'HOME'
      AND a.employee_id = v_emp_id;
      
    SELECT id 
    INTO v_home_prov_id
    FROM provinces 
    WHERE UPPER(name) = UPPER(v_emp.home_state);
    
    SELECT id 
    INTO v_home_country_id
    FROM countries 
    WHERE UPPER(name) = UPPER(v_emp.home_country);
                          
    SELECT id 
    INTO v_home_addr_type_id
    FROM address_types 
    WHERE code = 'HOME';
   
    IF v_home_prov_id IS NOT NULL AND v_home_country_id IS NOT NULL THEN 
      IF v_home_addr_id IS NULL THEN 
        INSERT INTO emp_addresses(employee_id, street_number, street, street_suffix, city, province_id, country_id, postal_code, type_id) 
        VALUES(v_emp_id, v_emp.home_street_num, v_emp.home_street_addr,v_emp.home_street_suffix, 
               v_emp.home_city, v_home_prov_id, v_home_country_id, v_emp.home_zip_code, v_home_addr_type_id);
      ELSE 
        UPDATE emp_addresses
        SET street_number = v_emp.home_street_num,
			street = v_emp.home_street_addr, 
			street_suffix = v_emp.home_street_suffix,
            city = v_emp.home_city,
            province_id = v_home_prov_id, 
            country_id = v_home_country_id, 
            postal_code = v_emp.home_zip_code
        WHERE id = v_home_addr_id;            
      END IF;
    ELSE 
      RAISE NOTICE 'home province or country not found. Province id: %, Country id: %', v_home_prov_id, v_home_country_id;
    END IF; 
    
    
     -- add/update business addresses
    SELECT a.id
    INTO v_bus_addr_id 
    FROM 
      emp_addresses a,
      address_types atype
    WHERE a.type_id = atype.id
      AND atype.code = 'BUS'
      AND a.employee_id = v_emp_id;
      
    SELECT id 
    INTO v_bus_prov_id
    FROM provinces 
    WHERE UPPER(name) = UPPER(v_emp.bus_state);
    
    SELECT id 
    INTO v_bus_country_id
    FROM countries 
    WHERE UPPER(name) = UPPER(v_emp.bus_country);
                          
    SELECT id 
    INTO v_bus_addr_type_id
    FROM address_types 
    WHERE code = 'BUS'; 
     
    IF v_bus_prov_id IS NOT NULL AND v_bus_country_id IS NOT NULL THEN 
      IF v_bus_addr_id IS NULL THEN 
        INSERT INTO emp_addresses(employee_id, street_number, street, street_suffix, city, province_id, country_id, postal_code, type_id) 
        VALUES(v_emp_id,  v_emp.bus_street_num, v_emp.bus_street_addr, v_emp.bus_street_suffix,
               v_emp.bus_city, v_bus_prov_id, v_bus_country_id, v_emp.bus_zip_code, v_bus_addr_type_id);
      ELSE 
        UPDATE emp_addresses
        SET street_number = v_emp.bus_street_num,
			street = v_emp.bus_street_addr, 
			street_suffix = v_emp.bus_street_suffix, 
            city = v_emp.bus_city,
            province_id = v_bus_prov_id, 
            country_id = v_bus_country_id, 
            postal_code = v_emp.bus_zip_code
        WHERE id = v_bus_addr_id;      
      END IF;      
    ELSE 
      RAISE NOTICE 'Bussiness province or country not found. Province id: %, Country id: %', v_bus_prov_id, v_bus_country_id;
    END IF;  



    -- 
    -- remove any existing phone numbers for this employee
    --
    DELETE FROM phone_numbers 
    WHERE employee_id = v_emp_id; 
    
    --
    --  load employee phone numbers
    --
    PERFORM load_phone_numbers(v_emp_id,v_emp.ph1_cc,v_emp.ph1_area,v_emp.ph1_number,v_emp.ph1_extension,v_emp.ph1_type,1);
    PERFORM load_phone_numbers(v_emp_id,v_emp.ph2_cc,v_emp.ph2_area,v_emp.ph2_number,v_emp.ph2_extension,v_emp.ph2_type,2);
    PERFORM load_phone_numbers(v_emp_id,v_emp.ph3_cc,v_emp.ph3_area,v_emp.ph3_number,v_emp.ph3_extension,v_emp.ph3_type,3);
    PERFORM load_phone_numbers(v_emp_id,v_emp.ph4_cc,v_emp.ph4_area,v_emp.ph4_number,v_emp.ph4_extension,v_emp.ph4_type,4);
             
   
                
  END LOOP;
  
END;
$$ LANGUAGE plpgsql;

-- change to assignment 4

-- firstly load assignment employee`s data to the employee hsitory table
CREATE OR REPLACE FUNCTION load_employee_history()
RETURNS void AS $$
BEGIN
	INSERT INTO employee_history
	(
	employee_number,
	last_name,
	mid_name,
	first_name,
	gender,
	SSN,
	birth_date,
	marital_status,
	employee_status,
	hire_date,
	re_hire_date,
	terminate_date,
	terminate_reason,
	terminate_type,
	job_code,
	job_name,
	employee_job_effective_date,
	employee_job_expirty_date,
	pay_amount,
	standard_hours,
	employee_type,
	employment_status,
	department_code,
	department_name,
	location_code,
	location_name,
	pay_frequency,
	pay_type,
	report_to_job,
	change_date,
	operation)
	SELECT
		employee_number,
		last_name,
		middle_name,
		first_name,
		gender,
		ssn,
		birth_date,
		-- get marital_status name
		(SELECT name 
			FROM marital_statuses m 
			WHERE e.marital_status_id = m.id) 
			AS marital_status ,
		-- get employment_status_type_name
		(SELECT name 
			FROM employment_status_types est 
			WHERE est.id = e.employment_status_id) 
			AS employee_status,
		hire_date,
		rehire_date,
		termination_date,
		-- get terminate reason and type
		(SELECT name 
			FROM termination_reasons tr 
			WHERE e.term_reason_id = tr.id ) 
			AS terminate_reason,
		(SELECT name 
			FROM termination_types tt 
			WHERE e.term_type_id = tt.id ) 
			AS terminate_type,
		-- get job_code and job_name
		(SELECT j.code 
			FROM jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id) 
			AS job_code,
		(SELECT j.name 
			FROM jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id)
			AS job_name,
		-- get effective date & exprity date
		(SELECT ej.effective_date 
			FROM employee_jobs ej 
			WHERE ej.employee_id = e.id) 
			AS employee_job_effective_date,
		(SELECT ej.expiry_date 
			FROM employee_jobs ej 
			WHERE ej.employee_id = e.id) 
			AS employee_job_expiry_date,
		-- get pay_amount & standard hours
		(SELECT ej.pay_amount 
			FROM employee_jobs ej  
			WHERE ej.employee_id = e.id) 
			AS pay_amount,
		(SELECT ej.standard_hours 
			FROM employee_jobs ej 
			WHERE ej.employee_id = e.id) 
			AS standard_hours,
		-- get employee_status & employee_type
		(SELECT et.name 
			FROM employee_types et, employee_jobs ej 
			WHERE ej.employee_type_id = et.id 
			AND ej.employee_id = e.id) 
			AS employee_type,
		(SELECT es.name 
			FROM employee_statuses es, employee_jobs ej 
			WHERE ej.employee_status_id = es.id 
			AND ej.employee_id = e.id) 
			AS employment_status,
		-- get department code and department name
		(SELECT d.code 
			FROM departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id) 
			AS department_code,
		(SELECT d.name 
			FROM departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id) 
			AS department_name,
		-- get location code and location name
		(SELECT l.code 
			FROM locations l, departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id 
			AND d.location_id = l.id) 
			AS location_code,
		(SELECT l.name 
			FROM locations l, departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id 
			AND d.location_id = l.id) 
			AS location_name,
		-- get pay frequency and pay type
		(SELECT pf.name 
			FROM pay_frequencies pf, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.pay_frequency_id = pf.id) 
		AS pay_frequency,
		(SELECT pt.name 
			FROM pay_types pt, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.pay_type_id = pt.id) 
			AS pay_type,
		-- get supersior job name
		(SELECT jj.name 
			FROM jobs jj, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.supervisor_job_id = jj.id) 
			AS report_to_job,
		now(),
		-- default operation is none, just load infomation
		'None'
	FROM employees e;
END;$$ LANGUAGE plpgsql;

-- load assignment 3 employee data to employee audit table
CREATE OR REPLACE FUNCTION load_employees_audit()
RETURNS void AS $$
BEGIN
	INSERT INTO employees_audit
	(operation,
	stamp,
	userid,
	id,
	employee_number,
	title,
	first_name,
	middle_name,
	last_name,
	gender,
	ssn,
	birth_date,
	hire_date,
	rehire_date,
	termination_date,
	marital_status_id,
	home_email,
	employment_status_id,
	term_type_id,
	term_reason_id
	)
	SELECT
	-- default load, set operation to N
	'N',
	now(),
	USER,
	e.id,
	-- copy data from employees table
	e.employee_number,
	e.title,
	e.first_name,
	e.middle_name,
	e.last_name,
	e.gender,
	e.ssn,
	e.birth_date,
	e.hire_date,
	e.rehire_date,
	e.termination_date,
	e.marital_status_id,
	e.home_email,
	e.employment_status_id,
	e.term_type_id,
	e.term_reason_id
	FROM employees e;
END;$$ LANGUAGE plpgsql;

-- load assignment 3 employee data to employee audit table
CREATE OR REPLACE FUNCTION load_employee_jobs_audit()
RETURNS void AS $$
BEGIN
	INSERT INTO employee_job_audit
	(operation,
	stamp,
	userid,
	id,
	employee_id,
	job_id,
	effective_date,
	expiry_date,
	pay_amount,
	standard_hours,
	employee_type_id,
	employee_status_id
	)
	SELECT
	-- default load, set operation to N
	'N',
	now(),
	USER,
	-- copy data from employee_jobs table
	ej.id,
	ej.employee_id,
	ej.job_id,
	ej.effective_date,
	ej.expiry_date,
	ej.pay_amount,
	ej.standard_hours,
	ej.employee_type_id,
	ej.employee_status_id
	FROM employee_jobs ej;
END;$$ LANGUAGE plpgsql;

-- close all trigger to make it do not worki during load
SELECT set_config('session.trigs_enabled','N',FALSE);	

-- Invoke all the functions in the right ORder
SELECT load_reference_tables();
SELECT load_phone_types();
SELECT load_locations();
SELECT load_departments();
SELECT load_jobs();
SELECT load_employees();
SELECT load_employee_history();
SELECT load_employees_audit();
SELECT load_employee_jobs_audit();

-- load assignment 4 file data to the database

-- Helper function to load phone numbers
CREATE OR REPLACE FUNCTION load_NEW_phone_numbers(p_emp_id INT, p_country_code VARCHAR(5), p_area_code VARCHAR(3),
                                              p_ph_number CHAR(10), p_extension VARCHAR(10), p_ph_type VARCHAR(10), p_number_id INT)
RETURNS void AS  $$
DECLARE
  v_phone_type_id INT;
BEGIN
  
  SELECT id
  INTO v_phone_type_id 
  FROM phone_types 
  WHERE UPPER(name) = UPPER(p_ph_type);
  
  IF v_phone_type_id IS NOT NULL AND p_area_code IS NOT NULL AND p_ph_number IS NOT NULL THEN 
    INSERT INTO phone_numbers(employee_id, country_code,area_code,ph_number,extension,type_id,employee_number_id)
    VALUES(p_emp_id,p_country_code,p_area_code,p_ph_number,p_extension,v_phone_type_id,p_number_id);
  ELSE 
    RAISE NOTICE 'Did not insert phone number fOR recORd: %', p_ph_number;
  END IF; 
                     
END; $$ language plpgsql;

-- Load all employees
CREATE OR REPLACE FUNCTION load_NEW_employees()
RETURNS void AS $$
DECLARE
  v_emp RECORD;
  v_empjobs RECORD; 
  v_ssn_rec recORd;
  
  
  v_emp_id INT;
  v_employment_status_id INT;
  v_term_reason_id INT;
  v_term_type_id INT;
  v_emp_job_id INT;
  v_perf_review_id INT;
  v_employee_type_id INT;
  v_employee_status_id INT;
  v_job_id INT;
  v_home_addr_id INT;
  v_home_prov_id INT;
  v_home_country_id INT;
  v_home_addr_type_id INT;
  v_bus_addr_id INT;
  v_bus_prov_id INT;
  v_bus_country_id INT;
  v_bus_addr_type_id INT;
  v_marital_status_id INT;
  v_location_id INT;
  v_department_id INT; 
BEGIN
  --- insert OR update employee data
  FOR v_emp IN (SELECT 
                  TRIM(led.employee_number) employee_number, 
                  TRIM(led.title) title, 
                  TRIM(led.first_name) first_name,
                  TRIM(led.middle_name) middle_name,
                  TRIM(led.last_name) last_name,
                  CASE TRIM(UPPER(led.gender)) 
                    WHEN 'MALE' THEN 'M'
                    WHEN 'FEMALE' THEN 'F'
                    ELSE 'U'
                  END gender,
                  TO_DATE(TRIM(led.birthdate), 'yyyy-mm-dd') birthdate, 
                  TRIM(led.marital_status) marital_status, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ssn)), '[^A-Z0-9]', '', 'g') ssn, 
                  TRIM(led.home_email) home_email, 
                  TO_DATE(TRIM(led.ORig_hire_date), 'yyyy-mm-dd') ORig_hire_date,
                  TO_DATE(TRIM(led.rehire_date), 'yyyy-mm-dd') rehire_date,
                  TO_DATE(TRIM(led.term_date), 'yyyy-mm-dd') term_date,
                  TRIM(led.term_type) term_type, 
                  TRIM(led.term_reason) term_reason, 
                  TRIM(led.job_code) job_code, 
                  TO_DATE(TRIM(led.job_st_date), 'yyyy-mm-dd') job_st_date,
                  TO_DATE(TRIM(led.job_end_date), 'yyyy-mm-dd') job_end_date,
                  TRIM(led.department_code) department_code, 
                  TRIM(led.location_code) location_code, 
                  TRIM(led.pay_freq) pay_freq,
                  TRIM(led.pay_type) pay_type,
                  COALESCE( TO_NUMBER(TRIM(led.hourly_amount), 'FM99G999G999.00'),
                            TO_NUMBER(TRIM(led.salary_amount), 'FM99G999G999.00') ) pay_amount,
                  TRIM(led.supervisor_job_code) supervisor_job_code, 
                  TRIM(led.employee_status) employee_status, 
                  TRIM(led.standard_hours) standard_hours,
                  TRIM(led.employee_type) employee_type, 
                  TRIM(led.employment_status) employment_status, 
                  TRIM(led.last_perf_num) last_perf_number, 
                  TRIM(led.last_perf_text) last_perf_text, 
                  TO_DATE(TRIM(led.last_perf_date), 'yyyy-mm-dd') last_perf_date, 
                  TRIM(led.home_street_num) home_street_num, 
                  TRIM(led.home_street_addr) home_street_addr, 
                  TRIM(led.home_street_suffix) home_street_suffix,
                  TRIM(led.home_city) home_city,
                  TRIM(led.home_state) home_state,
                  TRIM(led.home_country) home_country,
                  TRIM(led.home_zip_code) home_zip_code,
                  TRIM(led.bus_street_num) bus_street_num,
                  TRIM(led.bus_street_addr) bus_street_addr,
                  TRIM(led.bus_street_suffix) bus_street_suffix,
                  TRIM(led.bus_city) bus_city,
                  TRIM(led.bus_state) bus_state,
                  TRIM(led.bus_country) bus_country,
                  TRIM(led.bus_zip_code) bus_zip_code,
                  REGEXP_REPLACE(UPPER(TRIM(led.ph1_cc)), '[^A-Z0-9]', '', 'g') ph1_cc,
                  REGEXP_REPLACE(UPPER(TRIM(led.ph1_area)), '[^A-Z0-9]', '', 'g') ph1_area,
                  REGEXP_REPLACE(UPPER(TRIM(led.ph1_number)), '[^A-Z0-9]', '', 'g') ph1_number,
                  TRIM(led.ph1_extension) ph1_extension,
                  TRIM(led.ph1_type) ph1_type,  
                  REGEXP_REPLACE(UPPER(TRIM(led.ph2_cc)), '[^A-Z0-9]', '', 'g') ph2_cc, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph2_area)), '[^A-Z0-9]', '', 'g') ph2_area, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph2_number)), '[^A-Z0-9]', '', 'g') ph2_number, 
                  TRIM(led.ph2_extension) ph2_extension, 
                  TRIM(led.ph2_type) ph2_type,  
                  REGEXP_REPLACE(UPPER(TRIM(led.ph3_cc)), '[^A-Z0-9]', '', 'g') ph3_cc, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph3_area)), '[^A-Z0-9]', '', 'g') ph3_area, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph3_number)), '[^A-Z0-9]', '', 'g') ph3_number, 
                  TRIM(led.ph3_extension) ph3_extension, 
                  TRIM(led.ph3_type) ph3_type, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph4_cc)), '[^A-Z0-9]', '', 'g') ph4_cc, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph4_area)), '[^A-Z0-9]', '', 'g') ph4_area, 
                  REGEXP_REPLACE(UPPER(TRIM(led.ph4_number)), '[^A-Z0-9]', '', 'g') ph4_number,
                  TRIM(led.ph4_extension) ph4_extension, 
                  TRIM(led.ph4_type) ph4_type
                FROM load_NEW_employe_data led
                ORDER BY led.employee_number) LOOP
    
    -- get the employee number
    SELECT id
    INTO v_emp_id
    FROM employees 
    WHERE employee_number = v_emp.employee_number;

    -- get the employment status 
    SELECT id
    INTO v_employment_status_id
    FROM employment_status_types
    WHERE UPPER(name) = UPPER(v_emp.employment_status);
    
    SELECT id 
    INTO v_term_type_id
    FROM termination_types 
    WHERE UPPER(name) = UPPER(v_emp.term_type);
    
    SELECT id
    INTO v_term_reason_id
    FROM termination_reasons
    WHERE UPPER(name) = UPPER(v_emp.term_reason);
    
    SELECT id
    INTO v_marital_status_id
    FROM marital_statuses 
    WHERE UPPER(name) = UPPER(v_emp.marital_status); 
    
    
    -- if the employee isn't in the databASe yet...
    IF v_emp_id IS NULL THEN 
    
      -- check to make sure the SSN isn't already in use OR null
      FOR v_ssn_rec IN (SELECT id 
                        FROM employees 
                        WHERE ssn = v_emp.ssn) LOOP
        RAISE NOTICE 'ssn already in use. cannot insert recORd: %', v_emp;
        CONTINUE;                
      END LOOP;
     
      IF v_emp.ssn IS NOT NULL THEN 
        INSERT INTO employees(employee_number,title,first_name,middle_name,last_name,gender,ssn,birth_date,
                              marital_status_id,home_email,employment_status_id,hire_date,rehire_date,termination_date,
                              term_type_id, term_reason_id)
        VALUES (v_emp.employee_number,v_emp.title,v_emp.first_name,v_emp.middle_name,v_emp.last_name,v_emp.gender,
                v_emp.ssn, v_emp.birthdate,v_marital_status_id,v_emp.home_email,v_employment_status_id, 
                v_emp.ORig_hire_date,v_emp.rehire_date,v_emp.term_date, v_term_type_id, v_term_reason_id)
        RETURNING id into v_emp_id;
      ELSE 
        RAISE NOTICE 'Skipping employee recORd. ssn null fOR employee: %', v_emp;
        CONTINUE;
      END IF;
    
    ELSE 
    -- if you found the employee number, check to make sure it's the employee number fOR the right person.
      -- Check to make sure this is the right person
      IF NOT v_emp.ssn = (SELECT ssn 
                          FROM employees
                          WHERE id = v_emp_id) THEN 
        RAISE NOTICE 'This employee number belongs to another employee: %', v_emp;
        CONTINUE;
      END IF;
      
      UPDATE employees 
      SET 
        title = v_emp.title, 
        first_name = v_emp.first_name, 
        middle_name = v_emp.middle_name,
        last_name = v_emp.last_name, 
        gender = v_emp.gender, 
        ssn = v_emp.ssn, 
        birth_date = v_emp.birthdate,
        marital_status_id = v_marital_status_id, 
        home_email = v_emp.home_email,
        employment_status_id = v_employment_status_id,
        hire_date = v_emp.ORig_hire_date, 
        rehire_date = v_emp.rehire_date,
        termination_date = v_emp.term_date,
        term_type_id = v_term_type_id,
        term_reason_id = v_term_reason_id
      WHERE id = v_emp_id;
    END IF;
    
    
    -- 
    -- PerfORmance 
    --
    --  look fOR an existing review fOR the employee with the date in the file
    SELECT id
    INTO v_perf_review_id
    FROM employee_reviews
    WHERE employee_id = v_emp_id 
      AND review_date = v_emp.last_perf_date;

    -- if it doesn't exist, insert it. Otherwise, update the rating 
    IF v_perf_review_id IS NULL AND v_emp.last_perf_number IS NOT NULL AND v_emp.last_perf_date IS NOT NULL THEN 
      INSERT INTO employee_reviews(employee_id, review_date, rating_id)
      VALUES (v_emp_id, v_emp.last_perf_date, v_emp.last_perf_number::INT);
    ELSIF v_emp.last_perf_number IS NOT NULL AND v_emp.last_perf_date IS NOT NULL THEN
      UPDATE employee_reviews
      SET rating_id = v_emp.last_perf_number::INT
      WHERE id = v_perf_review_id;
    END IF;
    
    
    --
    --  insert/update into employee jobs
    --
    
     -- get the employee type 
    SELECT id
    INTO v_employee_type_id
    FROM employee_types
    WHERE UPPER(name) = UPPER(v_emp.employee_type);
    
    
    -- get the employee status
    SELECT id
    INTO v_employee_status_id
    FROM employee_statuses
    WHERE UPPER(name) = UPPER(v_emp.employee_status);
    
    -- look fOR an employee_job fOR this employee
    v_emp_job_id := NULL;
    FOR v_empjobs IN (SELECT ej.id
                      FROM 
                        employee_jobs ej, 
                        employees e,
                        jobs j
                      WHERE ej.employee_id = e.id 
                        AND e.employee_number = v_emp.employee_number 
                        AND ej.job_id = j.id
                        AND j.code = v_emp.job_code
                        AND v_emp.job_st_date = ej.effective_date) LOOP
      v_emp_job_id := v_empjobs.id;
    END LOOP;
    
    -- check to see if there is a job with this job code in this department/location combination.
    SELECT j.id 
    INTO v_job_id
    FROM jobs j
    LEFT JOIN departments d ON j.department_id = d.id
    JOIN locations l ON l.id = d.location_id
    WHERE l.code = v_emp.location_code
      AND UPPER(j.code) = UPPER(v_emp.job_code);

    IF v_job_id IS NULL
    THEN
        RAISE NOTICE 'No job exists with this job code, department, location combination fOR employee %, "%"', v_emp_id, v_emp.job_code;
        CONTINUE;
    END IF;
    
    -- check if there's an existing open employee job fOR this employee AND job combination 
    --   during this time period. 
    -- If there isn't, then check fOR an existing open employee job AND close it, AND then insert a NEW 
    --   employee job recORd.
    -- If there is, do an update. 
    IF v_emp_job_id IS NULL THEN 
    
      -- check fOR existing open employee job AND expire it.
      FOR v_empjobs IN (SELECT ej.id
                   FROM employee_jobs ej
                   WHERE ej.expiry_date IS NULL 
                     AND ej.employee_id = v_emp_id) LOOP
        UPDATE employee_jobs
        SET expiry_date = v_emp.job_st_date
        WHERE id = v_empjobs.id;
      END LOOP;
      
      INSERT INTO employee_jobs(employee_id,job_id,effective_date,expiry_date,pay_amount,
                                standard_hours,employee_type_id,employee_status_id)
      VALUES(v_emp_id, v_job_id, v_emp.job_st_date, v_emp.job_end_date, v_emp.pay_amount, v_emp.standard_hours::INT, 
             v_employee_type_id, v_employee_status_id );
    ELSE 
      -- UPDATE employee_jobs 
      UPDATE employee_jobs 
      SET pay_amount = v_emp.pay_amount, 
          standard_hours = v_emp.standard_hours::INT, 
          employee_type_id = v_employee_type_id,
          employee_status_id = v_employee_status_id,
          effective_date = v_emp.job_st_date,
          expiry_date = v_emp.job_end_date
      WHERE id = v_emp_job_id;
    END IF;
    
    
    
    --
    -- load addresses
    --
    
    -- add/update home addresses
    SELECT a.id
    INTO v_home_addr_id 
    FROM 
      emp_addresses a,
      address_types atype
    WHERE a.type_id = atype.id
      AND atype.code = 'HOME'
      AND a.employee_id = v_emp_id;
      
    SELECT id 
    INTO v_home_prov_id
    FROM provinces 
    WHERE UPPER(name) = UPPER(v_emp.home_state);
    
    SELECT id 
    INTO v_home_country_id
    FROM countries 
    WHERE UPPER(name) = UPPER(v_emp.home_country);
                          
    SELECT id 
    INTO v_home_addr_type_id
    FROM address_types 
    WHERE code = 'HOME';
   
    IF v_home_prov_id IS NOT NULL AND v_home_country_id IS NOT NULL THEN 
      IF v_home_addr_id IS NULL THEN 
        INSERT INTO emp_addresses(employee_id, street_number, street, street_suffix, city, province_id, country_id, postal_code, type_id) 
        VALUES(v_emp_id, v_emp.home_street_num, v_emp.home_street_addr,v_emp.home_street_suffix, 
               v_emp.home_city, v_home_prov_id, v_home_country_id, v_emp.home_zip_code, v_home_addr_type_id);
      ELSE 
        UPDATE emp_addresses
        SET street_number = v_emp.home_street_num,
			street = v_emp.home_street_addr, 
			street_suffix = v_emp.home_street_suffix,
            city = v_emp.home_city,
            province_id = v_home_prov_id, 
            country_id = v_home_country_id, 
            postal_code = v_emp.home_zip_code
        WHERE id = v_home_addr_id;            
      END IF;
    ELSE 
      RAISE NOTICE 'home province or country not found. Province id: %, Country id: %', v_home_prov_id, v_home_country_id;
    END IF; 
    
    
     -- add/update business addresses
    SELECT a.id
    INTO v_bus_addr_id 
    FROM 
      emp_addresses a,
      address_types atype
    WHERE a.type_id = atype.id
      AND atype.code = 'BUS'
      AND a.employee_id = v_emp_id;
      
    SELECT id 
    INTO v_bus_prov_id
    FROM provinces 
    WHERE UPPER(name) = UPPER(v_emp.bus_state);
    
    SELECT id 
    INTO v_bus_country_id
    FROM countries 
    WHERE UPPER(name) = UPPER(v_emp.bus_country);
                          
    SELECT id 
    INTO v_bus_addr_type_id
    FROM address_types 
    WHERE code = 'BUS'; 
     
    IF v_bus_prov_id IS NOT NULL AND v_bus_country_id IS NOT NULL THEN 
      IF v_bus_addr_id IS NULL THEN 
        INSERT INTO emp_addresses(employee_id, street_number, street, street_suffix, city, province_id, country_id, postal_code, type_id) 
        VALUES(v_emp_id,  v_emp.bus_street_num, v_emp.bus_street_addr, v_emp.bus_street_suffix,
               v_emp.bus_city, v_bus_prov_id, v_bus_country_id, v_emp.bus_zip_code, v_bus_addr_type_id);
      ELSE 
        UPDATE emp_addresses
        SET street_number = v_emp.bus_street_num,
			street = v_emp.bus_street_addr, 
			street_suffix = v_emp.bus_street_suffix, 
            city = v_emp.bus_city,
            province_id = v_bus_prov_id, 
            country_id = v_bus_country_id, 
            postal_code = v_emp.bus_zip_code
        WHERE id = v_bus_addr_id;      
      END IF;      
    ELSE 
      RAISE NOTICE 'Bussiness province or country not found. Province id: %, Country id: %', v_bus_prov_id, v_bus_country_id;
    END IF;  

    -- 
    -- remove any existing phone numbers fOR this employee
    --
    DELETE FROM phone_numbers 
    WHERE employee_id = v_emp_id; 
    
    --
    --  load employee phone numbers
    --
    PERFORM load_NEW_phone_numbers(v_emp_id,v_emp.ph1_cc,v_emp.ph1_area,v_emp.ph1_number,v_emp.ph1_extension,v_emp.ph1_type,1);
    PERFORM load_NEW_phone_numbers(v_emp_id,v_emp.ph2_cc,v_emp.ph2_area,v_emp.ph2_number,v_emp.ph2_extension,v_emp.ph2_type,2);
    PERFORM load_NEW_phone_numbers(v_emp_id,v_emp.ph3_cc,v_emp.ph3_area,v_emp.ph3_number,v_emp.ph3_extension,v_emp.ph3_type,3);
    PERFORM load_NEW_phone_numbers(v_emp_id,v_emp.ph4_cc,v_emp.ph4_area,v_emp.ph4_number,v_emp.ph4_extension,v_emp.ph4_type,4);
             
   
                
  END LOOP;
  
END;
$$ LANGUAGE plpgsql;


-- first load all new data to the data then remove all duplicates

CREATE OR REPLACE FUNCTION load_new_employee_history()
RETURNS void AS $$
BEGIN
	INSERT INTO employee_history
	(
	employee_number,
	last_name,
	mid_name,
	first_name,
	gender,
	SSN,
	birth_date,
	marital_status,
	employee_status,
	hire_date,
	re_hire_date,
	terminate_date,
	terminate_reason,
	terminate_type,
	job_code,
	job_name,
	employee_job_effective_date,
	employee_job_expirty_date,
	pay_amount,
	standard_hours,
	employee_type,
	employment_status,
	department_code,
	department_name,
	location_code,
	location_name,
	pay_frequency,
	pay_type,
	report_to_job,
	change_date,
	operation)
	SELECT
		employee_number,
		last_name,
		middle_name,
		first_name,
		gender,
		ssn,
		birth_date,
		-- get marital_status name
		(SELECT name 
			FROM marital_statuses m 
			WHERE e.marital_status_id = m.id) 
			AS marital_status ,
		-- get employment_status_type_name
		(SELECT name 
			FROM employment_status_types est 
			WHERE est.id = e.employment_status_id) 
			AS employee_status,
		hire_date,
		rehire_date,
		termination_date,
		-- get terminate reason and type
		(SELECT name 
			FROM termination_reasons tr 
			WHERE e.term_reason_id = tr.id ) 
			AS terminate_reason,
		(SELECT name 
			FROM termination_types tt 
			WHERE e.term_type_id = tt.id ) 
			AS terminate_type,
		-- get job_code and job_name
		(SELECT j.code 
			FROM jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id) 
			AS job_code,
		(SELECT j.name 
			FROM jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id)
			AS job_name,
		-- get effective date & exprity date
		(SELECT ej.effective_date 
			FROM employee_jobs ej 
			WHERE ej.employee_id = e.id) 
			AS employee_job_effective_date,
		(SELECT ej.expiry_date 
			FROM employee_jobs ej 
			WHERE ej.employee_id = e.id) 
			AS employee_job_expiry_date,
		-- get pay_amount & standard hours
		(SELECT ej.pay_amount 
			FROM employee_jobs ej  
			WHERE ej.employee_id = e.id) 
			AS pay_amount,
		(SELECT ej.standard_hours 
			FROM employee_jobs ej 
			WHERE ej.employee_id = e.id) 
			AS standard_hours,
		-- get employee_status & employee_type
		(SELECT et.name 
			FROM employee_types et, employee_jobs ej 
			WHERE ej.employee_type_id = et.id 
			AND ej.employee_id = e.id) 
			AS employee_type,
		(SELECT es.name 
			FROM employee_statuses es, employee_jobs ej 
			WHERE ej.employee_status_id = es.id 
			AND ej.employee_id = e.id) 
			AS employment_status,
		-- get department code and department name
		(SELECT d.code 
			FROM departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id) 
			AS department_code,
		(SELECT d.name 
			FROM departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id) 
			AS department_name,
		-- get location code and location name
		(SELECT l.code 
			FROM locations l, departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id 
			AND d.location_id = l.id) 
			AS location_code,
		(SELECT l.name 
			FROM locations l, departments d, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.department_id = d.id 
			AND d.location_id = l.id) 
			AS location_name,
		-- get pay frequency and pay type
		(SELECT pf.name 
			FROM pay_frequencies pf, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.pay_frequency_id = pf.id) 
		AS pay_frequency,
		(SELECT pt.name 
			FROM pay_types pt, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.pay_type_id = pt.id) 
			AS pay_type,
		-- get supersior job name
		(SELECT jj.name 
			FROM jobs jj, jobs j, employee_jobs ej 
			WHERE ej.employee_id = e.id 
			AND ej.job_id = j.id 
			AND j.supervisor_job_id = jj.id) 
			AS report_to_job,
		now(),
		-- default operation is none, just load infomation
		'None'
	FROM employees e;
END;$$ LANGUAGE plpgsql;


-- remove duplicate datas
CREATE OR REPLACE FUNCTION update_employee_history_first()
RETURNS void AS $$
BEGIN 
	DELETE
		FROM
			employee_history eh1
			USING employee_history eh2
			WHERE
			-- first compare make sure not compare same row
			eh1.ctid < eh2.ctid
			-- additional condition to check if all field is equal/ both null
			AND
			(
				(eh1.employee_number = eh2.employee_number)	
				OR(
					(eh1.employee_number IS NULL)
					AND
					(eh2.employee_number IS NULL)
				)
			)
			
			AND
			(
				(eh1.last_name = eh2.last_name)
				OR(
					(eh1.last_name IS NULL)
					AND
					(eh2.last_name IS NULL)
				)
			)
			AND 
			(
				(eh1.mid_name = eh2.mid_name)
				OR(
					(eh1.mid_name IS NULL)
					AND
					(eh2.mid_name IS NULL)
				)
			)
			AND 
			(
				(eh1.first_name = eh2.first_name)
				OR(
					(eh1.first_name IS NULL)
					AND
					(eh2.first_name IS NULL)
				)
			)
			AND 
			(
				(eh1.gender = eh2.gender)
				OR(
					(eh1.gender IS NULL)
					AND
					(eh2.gender IS NULL)
				)
			)
			AND 
			(
				(eh1.SSN = eh2.SSN)
				OR(
					(eh1.SSN IS NULL)
					AND
					(eh2.SSN IS NULL)
				)
			)
			AND 
			(
				(eh1.birth_date = eh2.birth_date)
				OR(
					(eh1.birth_date IS NULL)
					AND
					(eh2.birth_date IS NULL)
				)
			)
			AND 
			(
				(eh1.marital_status = eh2.marital_status)
				OR(
					(eh1.marital_status IS NULL)
					AND
					(eh2.marital_status IS NULL)
				)
			)
			AND 
			(
				(eh1.employee_status = eh2.employee_status)
				OR(
					(eh1.employee_status IS NULL)
					AND
					(eh2.employee_status IS NULL)
				)
			)
			AND 
			(
				(eh1.hire_date = eh2.hire_date)
				OR(
					(eh1.hire_date IS NULL)
					AND
					(eh2.hire_date IS NULL)
				)
			)
			AND 
			(
				(eh1.re_hire_date = eh2.re_hire_date)
				OR(
					(eh1.re_hire_date IS NULL)
					AND
					(eh2.re_hire_date IS NULL)
				)
			)
			AND 
			(
				(eh1.terminate_date = eh2.terminate_date)
				OR(
					(eh1.terminate_date IS NULL)
					AND
					(eh2.terminate_date IS NULL)
				)
			)
			AND 
			(
				(eh1.terminate_reason = eh2.terminate_reason)
				OR(
					(eh1.terminate_reason IS NULL)
					AND
					(eh2.terminate_reason IS NULL)
				)
			)
			AND 
			(
				(eh1.terminate_type = eh2.terminate_type)
				OR(
					(eh1.terminate_type IS NULL)
					AND
					(eh2.terminate_type IS NULL)
				)
			)
			AND 
			(
				(eh1.job_code = eh2.job_code)
				OR(
					(eh1.job_code IS NULL)
					AND
					(eh2.job_code IS NULL)
				)
			)
			AND 
			(
				(eh1.job_name = eh2.job_name)
				OR(
					(eh1.job_name IS NULL)
					AND
					(eh2.job_name IS NULL)
				)
			)
			AND 
			(
				(eh1.employee_job_effective_date = eh2.employee_job_effective_date)
				OR(
					(eh1.employee_job_effective_date IS NULL)
					AND
					(eh2.employee_job_effective_date IS NULL)
				)
			)
			AND 
			(
				(eh1.employee_job_expirty_date = eh2.employee_job_expirty_date)
				OR(
					(eh1.employee_job_expirty_date IS NULL)
					AND
					(eh2.employee_job_expirty_date IS NULL)
				)
			)
			AND 
			(
				(eh1.standard_hours = eh2.standard_hours)
				OR(
					(eh1.standard_hours IS NULL)
					AND
					(eh2.standard_hours IS NULL)
				)
			)
			AND
			(
				(eh1.employee_type = eh2.employee_type)
				OR(
					(eh1.employee_type IS NULL)
					AND
					(eh2.employee_type IS NULL)
				)
			)
			AND 
			(
				(eh1.employment_status = eh2.employment_status)
				OR(
					(eh1.employment_status IS NULL)
					AND
					(eh2.employment_status IS NULL)
				)
			)
			AND 
			(
				(eh1.department_code = eh2.department_code)
				OR(
					(eh1.department_code IS NULL)
					AND
					(eh2.department_code IS NULL)
				)
			)
			AND 
			(
				(eh1.department_name = eh2.department_name)
				OR(
					(eh1.department_name IS NULL)
					AND
					(eh2.department_name IS NULL)
				)
			)
			AND 
			(
				(eh1.location_code = eh2.location_code)
				OR(
					(eh1.location_code IS NULL)
					AND
					(eh2.location_code IS NULL)
				)
			)
			AND 
			(
				(eh1.location_name = eh2.location_name)
				OR(
					(eh1.location_name IS NULL)
					AND
					(eh2.location_name IS NULL)
				)
			)
			AND 
			(
				(eh1.pay_frequency = eh2.pay_frequency)
				OR(
					(eh1.pay_frequency IS NULL)
					AND
					(eh2.pay_frequency IS NULL)
				)
			)
			AND 
			(
				(eh1.pay_type = eh2.pay_type)
				OR(
					(eh1.pay_type IS NULL)
					AND
					(eh2.pay_type IS NULL)
				)
			)
			AND 
			(
				(eh1.report_to_job = eh2.report_to_job)
				OR(
					(eh1.report_to_job IS NULL)
					AND
					(eh2.report_to_job IS NULL)
				)
			)
	;
END;$$ LANGUAGE plpgsql;

-- load assignment 4 employee data to employee audit table
CREATE OR REPLACE FUNCTION load_new_employees_audit()
RETURNS void AS $$
BEGIN
	INSERT INTO employees_audit
	(operation,
	stamp,
	userid,
	id,
	employee_number,
	title,
	first_name,
	middle_name,
	last_name,
	gender,
	ssn,
	birth_date,
	hire_date,
	rehire_date,
	termination_date,
	marital_status_id,
	home_email,
	employment_status_id,
	term_type_id,
	term_reason_id
	)
	SELECT
	-- default load, set operation to N
	'N',
	now(),
	USER,
	e.id,
	-- copy data from employees table
	e.employee_number,
	e.title,
	e.first_name,
	e.middle_name,
	e.last_name,
	e.gender,
	e.ssn,
	e.birth_date,
	e.hire_date,
	e.rehire_date,
	e.termination_date,
	e.marital_status_id,
	e.home_email,
	e.employment_status_id,
	e.term_type_id,
	e.term_reason_id
	FROM employees e;
END;$$ LANGUAGE plpgsql;

-- remove duplicate datas
CREATE OR REPLACE FUNCTION update_employees_audit_first()
RETURNS void AS $$
BEGIN 
	DELETE
		FROM
			employees_audit eh1
			USING employees_audit eh2
			WHERE
			-- first compare make sure not compare same row
			eh1.ctid < eh2.ctid
			-- additional condition to check if all field is equal/ both null
			AND
			(
				(eh1.id = eh2.id)	
				OR(
					(eh1.id IS NULL)
					AND
					(eh2.id IS NULL)
				)
			)
			AND
			(
				(eh1.employee_number = eh2.employee_number)	
				OR(
					(eh1.employee_number IS NULL)
					AND
					(eh2.employee_number IS NULL)
				)
			)
			AND
			(
				(eh1.last_name = eh2.last_name)
				OR(
					(eh1.last_name IS NULL)
					AND
					(eh2.last_name IS NULL)
				)
			)
			AND 
			(
				(eh1.middle_name = eh2.middle_name)
				OR(
					(eh1.middle_name IS NULL)
					AND
					(eh2.middle_name IS NULL)
				)
			)
			AND 
			(
				(eh1.first_name = eh2.first_name)
				OR(
					(eh1.first_name IS NULL)
					AND
					(eh2.first_name IS NULL)
				)
			)
			AND 
			(
				(eh1.gender = eh2.gender)
				OR(
					(eh1.gender IS NULL)
					AND
					(eh2.gender IS NULL)
				)
			)
			AND 
			(
				(eh1.ssn = eh2.ssn)
				OR(
					(eh1.ssn IS NULL)
					AND
					(eh2.ssn IS NULL)
				)
			)
			AND 
			(
				(eh1.birth_date = eh2.birth_date)
				OR(
					(eh1.birth_date IS NULL)
					AND
					(eh2.birth_date IS NULL)
				)
			)
			AND 
			(
				(eh1.marital_status_id = eh2.marital_status_id)
				OR(
					(eh1.marital_status_id IS NULL)
					AND
					(eh2.marital_status_id IS NULL)
				)
			)
			AND 
			(
				(eh1.employment_status_id = eh2.employment_status_id)
				OR(
					(eh1.employment_status_id IS NULL)
					AND
					(eh2.employment_status_id IS NULL)
				)
			)
			AND 
			(
				(eh1.hire_date = eh2.hire_date)
				OR(
					(eh1.hire_date IS NULL)
					AND
					(eh2.hire_date IS NULL)
				)
			)
			AND 
			(
				(eh1.rehire_date = eh2.rehire_date)
				OR(
					(eh1.rehire_date IS NULL)
					AND
					(eh2.rehire_date IS NULL)
				)
			)
			AND 
			(
				(eh1.termination_date = eh2.termination_date)
				OR(
					(eh1.termination_date IS NULL)
					AND
					(eh2.termination_date IS NULL)
				)
			)
			AND 
			(
				(eh1.term_reason_id = eh2.term_reason_id)
				OR(
					(eh1.term_reason_id IS NULL)
					AND
					(eh2.term_reason_id IS NULL)
				)
			)
			AND 
			(
				(eh1.term_type_id = eh2.term_type_id)
				OR(
					(eh1.term_type_id IS NULL)
					AND
					(eh2.term_type_id IS NULL)
				)
			)
			AND 
			(
				(eh1.home_email = eh2.home_email)
				OR(
					(eh1.home_email IS NULL)
					AND
					(eh2.home_email IS NULL)
				)
			)
			AND 
			(
				(eh1.title = eh2.title)
				OR(
					(eh1.title IS NULL)
					AND
					(eh2.title IS NULL)
				)
			)
	;
END;$$ LANGUAGE plpgsql;

-- load assignment 3 employee data to employee audit table
CREATE OR REPLACE FUNCTION load_new_employee_job_audit()
RETURNS void AS $$
BEGIN
	INSERT INTO employee_job_audit
	(operation,
	stamp,
	userid,
	id,
	employee_id,
	job_id,
	effective_date,
	expiry_date,
	pay_amount,
	standard_hours,
	employee_type_id,
	employee_status_id
	)
	SELECT
	-- default load, set operation to N
	'N',
	now(),
	USER,
	-- copy data from employee_jobs table
	ej.id,
	ej.employee_id,
	ej.job_id,
	ej.effective_date,
	ej.expiry_date,
	ej.pay_amount,
	ej.standard_hours,
	ej.employee_type_id,
	ej.employee_status_id
	FROM employee_jobs ej;
END;$$ LANGUAGE plpgsql;

-- remove duplicate datas
CREATE OR REPLACE FUNCTION update_employee_job_audit_first()
RETURNS void AS $$
BEGIN 
	DELETE
		FROM
			employee_job_audit eh1
			USING employee_job_audit eh2
			WHERE
			-- first compare make sure not compare same row
			eh1.ctid < eh2.ctid
			-- additional condition to check if all field is equal/ both null
			AND
			(
				(eh1.id = eh2.id)	
				OR(
					(eh1.id IS NULL)
					AND
					(eh2.id IS NULL)
				)
			)
			AND
			(
				(eh1.employee_id = eh2.employee_id)	
				OR(
					(eh1.employee_id IS NULL)
					AND
					(eh2.employee_id IS NULL)
				)
			)
			
			AND
			(
				(eh1.job_id = eh2.job_id)
				OR(
					(eh1.job_id IS NULL)
					AND
					(eh2.job_id IS NULL)
				)
			)
			AND 
			(
				(eh1.effective_date = eh2.effective_date)
				OR(
					(eh1.effective_date IS NULL)
					AND
					(eh2.effective_date IS NULL)
				)
			)
			AND 
			(
				(eh1.expiry_date = eh2.expiry_date)
				OR(
					(eh1.expiry_date IS NULL)
					AND
					(eh2.expiry_date IS NULL)
				)
			)
			AND 
			(
				(eh1.pay_amount = eh2.pay_amount)
				OR(
					(eh1.pay_amount IS NULL)
					AND
					(eh2.pay_amount IS NULL)
				)
			)
			AND 
			(
				(eh1.standard_hours = eh2.standard_hours)
				OR(
					(eh1.standard_hours IS NULL)
					AND
					(eh2.standard_hours IS NULL)
				)
			)
			AND 
			(
				(eh1.employee_type_id = eh2.employee_type_id)
				OR(
					(eh1.employee_type_id IS NULL)
					AND
					(eh2.employee_type_id IS NULL)
				)
			)
	;
END;$$ LANGUAGE plpgsql;

-- call load functions and remove duplicate data functions

SELECT load_NEW_employees();
SELECT load_new_employee_history();
SELECT load_new_employees_audit();
SELECT load_new_employee_job_audit();
SELECT update_employee_history_first();
SELECT update_employees_audit_first();
SELECT update_employee_job_audit_first();


-- enable trigger
SELECT set_config('session.trigs_enabled','Y',FALSE);