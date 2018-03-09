
CREATE OR REPLACE FUNCTION employees_audit() RETURNS TRIGGER AS $employees_audit$
    DECLARE
		v_trig_enabled VARCHAR(1);
	BEGIN
		SELECT COALESCE(current_setting('session.trigs_enabled'),'Y')
        INTO v_trig_enabled;
		IF v_trig_enabled = 'Y' THEN
			IF (TG_OP = 'DELETE') THEN
				INSERT INTO employees_audit 
				SELECT 'D', now(), USER, OLD.*;
				RETURN OLD;
			ELSIF (TG_OP = 'UPDATE') THEN
				INSERT INTO employees_audit 
				SELECT 'U', now(), USER, NEW.*;
				RETURN NEW;
			ELSIF (TG_OP = 'INSERT') THEN
				INSERT INTO employees_audit 
				SELECT 'I', now(), USER, NEW.*;
				RETURN NEW;
			END IF;
		END IF;
        RETURN NULL; 
    END;
$employees_audit$ LANGUAGE plpgsql;

CREATE TRIGGER employees_audit
AFTER INSERT OR UPDATE OR DELETE ON employees
    FOR EACH ROW EXECUTE PROCEDURE employees_audit();

CREATE OR REPLACE FUNCTION employee_job_audit() RETURNS TRIGGER AS $employee_job_audit$
	DECLARE
		v_trig_enabled VARCHAR(1);
	BEGIN
    SELECT COALESCE(current_setting('session.trigs_enabled'),'Y')
        INTO v_trig_enabled;
		IF v_trig_enabled = 'Y' THEN
			IF (TG_OP = 'DELETE') THEN
				INSERT INTO employee_job_audit 
				SELECT 'D', now(), USER, OLD.*;
				RETURN OLD;
			ELSIF (TG_OP = 'UPDATE') THEN
				INSERT INTO employee_job_audit 
				SELECT 'U', now(), USER, NEW.*;
				RETURN NEW;
			ELSIF (TG_OP = 'INSERT') THEN
				INSERT INTO employee_job_audit 
				SELECT 'I', now(), USER, NEW.*;
				RETURN NEW;
			END IF;
        END IF;
        RETURN NULL; 
    END;
$employee_job_audit$ LANGUAGE plpgsql;

CREATE TRIGGER employee_job_audit
AFTER INSERT OR UPDATE OR DELETE ON employee_jobs
    FOR EACH ROW EXECUTE PROCEDURE employee_job_audit();
	
CREATE OR REPLACE FUNCTION employee_history_employees_audit() RETURNS TRIGGER AS $employee_history_employees_audit$
    DECLARE
		v_trig_enabled VARCHAR(1);
	BEGIN
    SELECT COALESCE(current_setting('session.trigs_enabled'),'Y')
        INTO v_trig_enabled;
		IF v_trig_enabled = 'Y' THEN
			IF (TG_OP = 'DELETE') THEN
				INSERT INTO employee_history 
				SELECT 
					OLD.employee_number,
					OLD.last_name,
					OLD.middle_name,
					OLD.first_name,
					OLD.gender,
					OLD.SSN,
					OLD.birth_date,
					-- get marital_status name
					(SELECT name 
						FROM marital_statuses m 
						WHERE 
						OLD.marital_status_id = m.id),
					-- get employment_status_type_name
					(SELECT name 
						FROM employment_status_types est 
						WHERE est.id = 
						OLD.employment_status_id),
					OLD.hire_date,
					OLD.reire_date,
					OLD.termination_date,
					-- get termation reason and type
					(SELECT name 
						FROM termination_reasons tr 
						WHERE 
						OLD.term_reason_id = tr.id ) 
						AS terminate_reason,
					(SELECT name 
						FROM termination_types tt 
						WHERE 
						OLD.term_type_id = tt.id ) 
						AS terminate_type,
					-- get job code and name
					(SELECT j.code 
						FROM jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id) 
						AS job_code,
					(SELECT j.name 
						FROM jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id) 
						AS job_name,
					-- get effective_date, expiry_date,pay_amount,standard_hours
					(SELECT ej.effective_date 
						FROM employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id) 
						AS employee_job_effective_date,
					(SELECT ej.expiry_date 
						FROM employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id) 
						AS employee_job_expiry_date,
					(SELECT ej.pay_amount 
						FROM employee_jobs ej  
						WHERE ej.employee_id = 
						OLD.id) 
						AS pay_amount,
					(SELECT ej.standard_hours 
						FROM employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id) 
						AS standard_hours,
					-- get employee type and employee status
					(SELECT et.name 
						FROM employee_types et, employee_jobs ej 
						WHERE ej.employee_type_id = et.id 
						AND ej.employee_id = 
						OLD.id) 
						AS employee_type,
					(SELECT es.name 
						FROM employee_statuses es, employee_jobs ej 
						WHERE ej.employee_status_id = es.id 
						AND ej.employee_id = 
						OLD.id) 
						AS employment_status,
					-- get department code and name
					(SELECT d.code 
						FROM departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id
						AND j.department_id = d.id) 
						AS department_code,
					(SELECT d.name 
						FROM departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_name,
					-- get location code and name
					(SELECT l.code 
						FROM locations l, departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_code,
					(SELECT l.name 
						FROM locations l, departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_name,
					-- get pay frequency and pay type
					(SELECT pf.name 
						FROM pay_frequencies pf, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id 
						AND j.pay_frequency_id = pf.id) 
						AS pay_frequency,
					(SELECT pt.name 
						FROM pay_types pt, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id 
						AND j.pay_type_id = pt.id) 
						AS pay_type,
					-- get supersior job name
					(SELECT jj.name 
						FROM jobs jj, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						OLD.id 
						AND ej.job_id = j.id 
						AND j.supervisor_job_id = jj.id) 
						AS report_to_job,
					now(),
					'Delete'
					;
				OLD.last_updated = now();
				RETURN OLD;
			ELSIF (TG_OP = 'UPDATE') THEN		
				INSERT INTO employee_history 
				SELECT 
					NEW.employee_number,
					NEW.last_name,
					NEW.middle_name,
					NEW.first_name,
					NEW.gender,
					NEW.SSN,
					NEW.birth_date,
					-- get marital_status name
					(SELECT name 
						FROM marital_statuses m 
						WHERE 
						NEW.marital_status_id = m.id),
					-- get employment_status_type_name
					(SELECT name 
						FROM employment_status_types est 
						WHERE est.id = 
						NEW.employment_status_id),
					NEW.hire_date,
					NEW.rehire_date,
					NEW.termination_date,
					-- get termation reason and type
					(SELECT name 
						FROM termination_reasons tr 
						WHERE 
						NEW.term_reason_id = tr.id ) 
						AS terminate_reason,
					(SELECT name 
						FROM termination_types tt 
						WHERE 
						NEW.term_type_id = tt.id ) 
						AS terminate_type,
					-- get job code and name
					(SELECT j.code 
						FROM jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id) 
						AS job_code,
					(SELECT j.name 
						FROM jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id) 
						AS job_name,
					-- get effective_date, expiry_date,pay_amount,standard_hours
					(SELECT ej.effective_date 
						FROM employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id) 
						AS employee_job_effective_date,
					(SELECT ej.expiry_date 
						FROM employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id) 
						AS employee_job_expiry_date,
					(SELECT ej.pay_amount 
						FROM employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id) 
						AS pay_amount,
					(SELECT ej.standard_hours 
						FROM employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id) 
						AS standard_hours,
					-- get employee type and employee status
					(SELECT et.name 
						FROM employee_types et, employee_jobs ej 
						WHERE ej.employee_type_id = et.id 
						AND ej.employee_id = 
						NEW.id) 
						AS employee_type,
					(SELECT es.name 
						FROM employee_statuses es, employee_jobs ej 
						WHERE ej.employee_status_id = es.id 
						AND ej.employee_id = 
						NEW.id) 
						AS employment_status,
					-- get department code and name
					(SELECT d.code 
						FROM departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_code,
					(SELECT d.name 
						FROM departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_name,
					-- get location code and name
					(SELECT l.code 
						FROM locations l, departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_code,
					(SELECT l.name 
						FROM locations l, departments d, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_name,
					-- get pay frequency and pay type
					(SELECT pf.name 
						FROM pay_frequencies pf, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id 
						AND j.pay_frequency_id = pf.id) 
						AS pay_frequency,
					(SELECT pt.name 
						FROM pay_types pt, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id 
						AND j.pay_type_id = pt.id) 
						AS pay_type,
					-- get supersior job name
					(SELECT jj.name 
						FROM jobs jj, jobs j, employee_jobs ej 
						WHERE ej.employee_id = 
						NEW.id 
						AND ej.job_id = j.id 
						AND j.supervisor_job_id = jj.id) 
						AS report_to_job,
					now(),
					'Update'
					;
				RETURN NEW;
			END IF;
		END IF;
        RETURN NULL; 
    END;
$employee_history_employees_audit$ LANGUAGE plpgsql;

CREATE TRIGGER employee_history_employees_audit
AFTER INSERT OR UPDATE OR DELETE ON employees
    FOR EACH ROW EXECUTE PROCEDURE employee_history_employees_audit();

CREATE OR REPLACE FUNCTION employee_history_employees_job_audit() RETURNS TRIGGER AS $employee_history_employees_job_audit$
	DECLARE
		v_trig_enabled VARCHAR(1);
	BEGIN
    SELECT COALESCE(current_setting('session.trigs_enabled'),'Y')
        INTO v_trig_enabled;
		IF v_trig_enabled = 'Y' THEN
			IF (TG_OP = 'DELETE') THEN
				INSERT INTO employee_history 
				SELECT 
					-- get name info
					(SELECT employee_number 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS employee_number ,
					(SELECT last_name 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS last_name,
					(SELECT middle_name 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS middle_name,
					(SELECT first_name 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS first_name,
					-- get personal info
					(SELECT gender 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS gender,
					(SELECT ssn 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS SSN,
					(SELECT birth_date 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS birth_date,
					-- get marital_status name
					(SELECT ms.name 
						FROM marital_statuses ms, employees e 
						WHERE e.marital_status_id = ms.id 
						AND 
						OLD.employee_id = e.id) 
						AS marital_status,
					-- get employment_status_type_name
					(SELECT est.name 
						FROM employment_status_types est , employees e 
						WHERE est.id = e.employment_status_id 
						AND 
						OLD.employee_id = e.id) 
						AS employment_status,
					-- gte hire info
					(SELECT hire_date 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS hire_date,
					(SELECT rehire_date 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id)
						AS rehire_date,
					(SELECT termination_date 
						FROM employees e 
						WHERE 
						OLD.employee_id = e.id) 
						AS termination_date,
					-- get termation reason and type
					(SELECT tr.name 
						FROM termination_reasons tr, employees e 
						WHERE e.term_reason_id = tr.id 
						AND 
						OLD.employee_id = e.id) 
						AS terminate_reason,
					(SELECT tt.name 
						FROM termination_types tt, employees e 
						WHERE e.term_type_id = tt.id 
						AND 
						OLD.employee_id = e.id) 
						AS terminate_type,
					-- get job code and name
					(SELECT j.code 
						FROM jobs j, employees e 
						WHERE 
						OLD.employee_id = e.id 
						AND 
						OLD.job_id = j.id) 
						AS job_code,
					(SELECT j.name 
						FROM jobs j, employees e 
						WHERE 
						OLD.employee_id = e.id 
						AND 
						OLD.job_id = j.id) 
						AS job_name,		
					-- get effective_date, expiry_date,pay_amount,standard_hours
					OLD.effective_date,
					OLD.expiry_date,
					OLD.pay_amount,
					OLD.standard_hours,
					-- get employee type and employee status
					(SELECT et.name 
						FROM employee_types et 
						WHERE 
						OLD.employee_type_id = et.id) 
						AS employee_type,
					(SELECT es.name 
						FROM employee_statuses es 
						WHERE 
						OLD.employee_status_id = es.id) 
						AS employment_status,
					-- get department code and name
					(SELECT d.code 
						FROM departments d, jobs j 
						WHERE 
						OLD.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_code,
					(SELECT d.name 
						FROM departments d, jobs j 
						WHERE 
						OLD.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_name,
					-- get location code and name
					(SELECT l.code 
						FROM locations l, departments d, jobs j 
						WHERE 
						OLD.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_code,
					(SELECT l.name 
						FROM locations l, departments d, jobs j 
						WHERE 
						OLD.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_name,
					-- get pay frequency and pay type
					(SELECT pf.name 
						FROM pay_frequencies pf, jobs j 
						WHERE 
						OLD.job_id = j.id 
						AND j.pay_frequency_id = pf.id) 
						AS pay_frequency,
					(SELECT pt.name 
						FROM pay_types pt, jobs j 
						WHERE 
						OLD.job_id = j.id 
						AND j.pay_type_id = pt.id) 
						AS pay_type,
					-- get supersior job name
					(SELECT jj.name 
						FROM jobs j, jobs jj 
						WHERE 
						OLD.job_id = j.id 
						AND j.supervisor_job_id = jj.id) 
						AS report_to_job,
					now(),
					'Delete'
					;
				--OLD.last_updated = now();
				RETURN OLD;
			ELSIF (TG_OP = 'UPDATE') THEN			
				INSERT INTO employee_history 
				SELECT 
					(SELECT employee_number 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS employee_number ,
					-- get name info
					(SELECT last_name 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS last_name,
					(SELECT middle_name 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS middle_name,
					(SELECT first_name 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS first_name,
					-- get personal info
					(SELECT gender 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS gender,
					(SELECT ssn 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS SSN,
					(SELECT birth_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS birth_date,
					-- get marital_status name
					(SELECT ms.name 
						FROM marital_statuses ms, employees e 
						WHERE e.marital_status_id = ms.id 
						AND 
						NEW.employee_id = e.id) 
						AS marital_status,
					-- get employment_status_type_name
					(SELECT est.name 
						FROM employment_status_types est , employees e 
						WHERE est.id = e.employment_status_id 
						AND 
						NEW.employee_id = e.id) 
						AS employment_status,
					-- gte hire info
					(SELECT hire_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS hire_date,
					(SELECT rehire_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS rehire_date,
					(SELECT termination_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS termination_date,
					-- get termation reason and type
					(SELECT tr.name 
						FROM termination_reasons tr, employees e 
						WHERE e.term_reason_id = tr.id 
						AND 
						NEW.employee_id = e.id) 
						AS terminate_reason,
					(SELECT tt.name 
						FROM termination_types tt, employees e 
						WHERE e.term_type_id = tt.id 
						AND 
						NEW.employee_id = e.id) 
						AS terminate_type,
					-- get job code and name
					(SELECT j.code 
						FROM jobs j, employees e 
						WHERE 
						NEW.employee_id = e.id 
						AND 
						NEW.job_id = j.id) 
						AS job_code,
					(SELECT j.name 
						FROM jobs j, employees e 
						WHERE 
						NEW.employee_id = e.id 
						AND 
						NEW.job_id = j.id) 
						AS job_name,		
					-- get effective_date, expiry_date,pay_amount,standard_hours
					NEW.effective_date,
					NEW.expiry_date,
					NEW.pay_amount,
					NEW.standard_hours,
					-- get employee type and employee status
					(SELECT et.name 
						FROM employee_types et 
						WHERE 
						NEW.employee_type_id = et.id) 
						AS employee_type,
					(SELECT es.name 
						FROM employee_statuses es 
						WHERE 
						NEW.employee_status_id = es.id) 
						AS employment_status,
					-- get department code and name
					(SELECT d.code 
						FROM departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_code,
					(SELECT d.name 
						FROM departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_name,
					-- get location code and name
					(SELECT l.code 
						FROM locations l, departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_code,
					(SELECT l.name 
						FROM locations l, departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_name,
					-- get pay frequency and pay type
					(SELECT pf.name 
						FROM pay_frequencies pf, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.pay_frequency_id = pf.id) 
						AS pay_frequency,
					(SELECT pt.name 
						FROM pay_types pt, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.pay_type_id = pt.id) 
						AS pay_type,
					-- get supersior job name
					(SELECT jj.name 
						FROM jobs j, jobs jj 
						WHERE 
						NEW.job_id = j.id 
						AND j.supervisor_job_id = jj.id) 
						AS report_to_job,
					now(),
					'Update'
					;
				RETURN NEW;
			ELSIF (TG_OP = 'INSERT') THEN
				INSERT INTO employee_history 
				SELECT 
					(SELECT employee_number 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS employee_number ,
					-- get name info
					(SELECT last_name 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS last_name,
					(SELECT middle_name 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS middle_name,
					(SELECT first_name 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS first_name,
					-- get personal info
					(SELECT gender 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS gender,
					(SELECT ssn 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS SSN,
					(SELECT birth_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS birth_date,
					-- get marital_status name
					(SELECT ms.name 
						FROM marital_statuses ms, employees e 
						WHERE e.marital_status_id = ms.id 
						AND 
						NEW.employee_id = e.id) 
						AS marital_status,
					-- get employment_status_type_name
					(SELECT est.name 
						FROM employment_status_types est , employees e 
						WHERE est.id = e.employment_status_id 
						AND 
						NEW.employee_id = e.id) 
						AS employment_status,
					-- gte hire info
					(SELECT hire_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS hire_date,
					(SELECT rehire_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS rehire_date,
					-- get termation reason and type
					(SELECT termination_date 
						FROM employees e 
						WHERE 
						NEW.employee_id = e.id) 
						AS termination_date,
					(SELECT tr.name 
						FROM termination_reasons tr, employees e 
						WHERE e.term_reason_id = tr.id 
						AND 
						NEW.employee_id = e.id) 
						AS terminate_reason,
					(SELECT tt.name 
						FROM termination_types tt, employees e 
						WHERE e.term_type_id = tt.id 
						AND 
						NEW.employee_id = e.id) 
						AS terminate_type,
					-- get job code and name
					(SELECT j.code 
						FROM jobs j, employees e 
						WHERE 
						NEW.employee_id = e.id 
						AND 
						NEW.job_id = j.id) 
						AS job_code,
					(SELECT j.name 
						FROM jobs j, employees e 
						WHERE 
						NEW.employee_id = e.id 
						AND 
						NEW.job_id = j.id) 
						AS job_name,		
					-- get effective_date, expiry_date,pay_amount,standard_hours
					NEW.effective_date,
					NEW.expiry_date,
					NEW.pay_amount,
					NEW.standard_hours,
					-- get employee type and employee status
					(SELECT et.name 
						FROM employee_types et 
						WHERE 
						NEW.employee_type_id = et.id) 
						AS employee_type,
					(SELECT es.name 
						FROM employee_statuses es 
						WHERE 
						NEW.employee_status_id = es.id) 
						AS employment_status,
					-- get department code and name
					(SELECT d.code 
						FROM departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_code,
					(SELECT d.name 
						FROM departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id) 
						AS department_name,
					-- get location code and name
					(SELECT l.code 
						FROM locations l, departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_code,
					(SELECT l.name 
						FROM locations l, departments d, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.department_id = d.id 
						AND d.location_id = l.id) 
						AS location_name,
					-- get pay frequency and pay type
					(SELECT pf.name 
						FROM pay_frequencies pf, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.pay_frequency_id = pf.id) 
						AS pay_frequency,
					(SELECT pt.name 
						FROM pay_types pt, jobs j 
						WHERE 
						NEW.job_id = j.id 
						AND j.pay_type_id = pt.id) 
						AS pay_type,
					-- get supersior job name
					(SELECT jj.name 
						FROM jobs j, jobs jj 
						WHERE 
						NEW.job_id = j.id 
						AND j.supervisor_job_id = jj.id) 
						AS report_to_job,
					now(),
					'Insert'
					;
				RETURN NEW;
			END IF;
		END IF;
        RETURN NULL; 
    END;
$employee_history_employees_job_audit$ LANGUAGE plpgsql;

CREATE TRIGGER employee_history_employees_job_audit
AFTER INSERT OR UPDATE OR DELETE ON employee_jobs
    FOR EACH ROW EXECUTE PROCEDURE employee_history_employees_job_audit();
