-- Solution for 2017 Term 1 CMPT355 Assignment 3
-- Author: Lujie Duan

SET client_encoding to 'latin1';

-- Clean the schema
DROP TABLE IF EXISTS pay_types CASCADE;
DROP TABLE IF EXISTS pay_frequencies CASCADE;
DROP TABLE IF EXISTS phone_types CASCADE;
DROP TABLE IF EXISTS address_types CASCADE;
DROP TABLE IF EXISTS provinces CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS phone_numbers CASCADE;
DROP TABLE IF EXISTS emp_addresses CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS employee_jobs CASCADE;

DROP TABLE IF EXISTS employees_audit CASCADE;
DROP TABLE IF EXISTS employee_job_audit CASCADE;
DROP TABLE IF EXISTS employee_history CASCADE;
DROP TABLE IF EXISTS load_employee_data CASCADE;
DROP TABLE IF EXISTS load_new_employe_data CASCADE;
DROP TABLE IF EXISTS load_jobs CASCADE;
DROP TABLE IF EXISTS load_departments CASCADE;
DROP TABLE IF EXISTS load_locations CASCADE;

DROP VIEW IF EXISTS employee_data;

DROP DOMAIN IF EXISTS GENDER;
DROP DOMAIN IF EXISTS SSNTYPE;


-- Create
CREATE DOMAIN GENDER AS VARCHAR(1) 
DEFAULT 'U' 
CHECK (VALUE IN ('M', 'F', 'U', 'N'));

CREATE DOMAIN SSNTYPE AS VARCHAR(11);

CREATE TABLE pay_types(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE pay_frequencies(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE phone_types(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,  
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE address_types(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE provinces(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE countries(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE employees(
  id SERIAL,
  employee_number VARCHAR(200), 
  title VARCHAR(20), 
  first_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender GENDER NOT NULL,
  ssn ssnType NOT NULL,
  birth_date DATE,
  hire_date DATE NOT NULL,
  rehire_date DATE,
  termination_date DATE, 
  PRIMARY KEY(id));

CREATE TABLE phone_numbers(
  id SERIAL,
  employee_id INT NOT NULL REFERENCES employees(id), 
  country_code VARCHAR(3),
  area_code VARCHAR(3),
  -- change length to 10 because longer phone number exist in data file
  -- ph_number VARCHAR(7),
  ph_number VARCHAR(10),
  extension VARCHAR(8),
  type_id INT NOT NULL REFERENCES phone_types(id), 
  employee_number_id INT,
  PRIMARY KEY(id));

CREATE TABLE emp_addresses(
  id SERIAL,
  employee_id INT NOT NULL REFERENCES employees(id), 
  street_number VARCHAR(20),
  street VARCHAR(200),
  street_suffix VARCHAR(200),
  city VARCHAR(200),
  province_id INT NOT NULL REFERENCES provinces(id),
  country_id INT NOT NULL REFERENCES countries(id),
  postal_code VARCHAR(7),
  type_id INT NOT NULL REFERENCES address_types(id), 
  PRIMARY KEY(id));

CREATE TABLE locations(
  id SERIAL,
  code VARCHAR(10) NOT NULL UNIQUE,
  name VARCHAR(100),
  street VARCHAR(200) NOT NULL,
  city VARCHAR(200),
  province_id INT NOT NULL REFERENCES Provinces(id),
  country_id INT NOT NULL REFERENCES Countries(id),
  postal_code VARCHAR(7),
  PRIMARY KEY (id));

CREATE TABLE departments(
  id SERIAL,
  code VARCHAR(10) NOT NULL ,
  name VARCHAR(100), 
  location_id INT NOT NULL REFERENCES Locations(id),
  PRIMARY KEY (id));

CREATE TABLE jobs(
  id SERIAL,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  effective_date DATE NOT NULL,
  expiry_date DATE,
  supervisor_job_id INT REFERENCES Jobs(id),
  department_id INT NOT NULL REFERENCES Departments(id), 
  pay_frequency_id INT NOT NULL REFERENCES pay_frequencies(id),
  pay_type_id INT NOT NULL REFERENCES pay_types(id), 
  PRIMARY KEY(id));

CREATE TABLE employee_jobs(
  id SERIAL,
  employee_id INT NOT NULL REFERENCES Employees(id),
  job_id INT NOT NULL REFERENCES Jobs,
  effective_date DATE NOT NULL,
  expiry_date DATE,
  pay_amount INT,
  standard_hours INT,
  PRIMARY KEY (id));

ALTER TABLE Departments 
ADD COLUMN manager_job_id INT REFERENCES Jobs(id);

-- Solution for 2017 Term 1 CMPT355 Assignment 3
-- Author: Lujie Duan

-- Clean the schema
DROP TABLE IF EXISTS marital_statuses CASCADE;
DROP TABLE IF EXISTS employee_types CASCADE;
DROP TABLE IF EXISTS employment_status_types CASCADE;
DROP TABLE IF EXISTS employee_statuses CASCADE;
DROP TABLE IF EXISTS termination_types CASCADE;
DROP TABLE IF EXISTS termination_reasons CASCADE;
DROP TABLE IF EXISTS review_ratings CASCADE;
DROP TABLE IF EXISTS employee_reviews CASCADE;

-- Create
CREATE TABLE marital_statuses(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));


CREATE TABLE employee_types(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));


CREATE TABLE employment_status_types(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));


CREATE TABLE employee_statuses(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));


CREATE TABLE termination_types(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));


CREATE TABLE termination_reasons(
  id INT,
  code VARCHAR(10) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE review_ratings(
  id INT,
  review_text VARCHAR(1000) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  PRIMARY KEY (id));

CREATE TABLE employee_reviews(
  id SERIAL,
  employee_id INT REFERENCES employees(id) NOT NULL,
  review_date DATE NOT NULL,
  rating_id INT REFERENCES review_ratings(id) NOT NULL,
  PRIMARY KEY (id));


ALTER TABLE employees 
	ADD COLUMN marital_status_id INT REFERENCES marital_statuses(id) NOT NULL,
	ADD COLUMN home_email VARCHAR(200),
  ADD COLUMN employment_status_id INT REFERENCES employment_status_types(id),
	ADD COLUMN term_type_id INT REFERENCES termination_types(id),
	ADD COLUMN term_reason_id INT REFERENCES termination_reasons(id);


ALTER TABLE employee_jobs
	ADD COLUMN employee_type_id INT REFERENCES employee_types(id),
  ADD COLUMN employee_status_id INT REFERENCES employee_statuses(id);

-- change to assignment 4

CREATE TABLE employees_audit(
  operation varchar(1) not null,
  stamp timestamp not null,
  userid text not null,
  id SERIAL,
  employee_number VARCHAR(200), 
  title VARCHAR(20), 
  first_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender GENDER NOT NULL,
  ssn ssnType NOT NULL,
  birth_date DATE,
  hire_date DATE NOT NULL,
  rehire_date DATE,
  termination_date DATE, 
  marital_status_id INT,
  home_email VARCHAR(200),
  employment_status_id INT,
  term_type_id INT,
  term_reason_id INT
);

create table employee_job_audit(
  operation varchar(1) not null,
  stamp timestamp not null,
  userid text not null,
  id SERIAL,
  employee_id INT NOT NULL,
  job_id INT NOT NULL,
  effective_date DATE NOT NULL,
  expiry_date DATE,
  pay_amount INT,
  standard_hours INT,
  employee_type_id INT,
  employee_status_id INT
);

create table employee_history(
  -- employee`s personal information
  employee_number VARCHAR(200),
  last_name VARCHAR(50),
  mid_name varchar(50),
  first_name VARCHAR(50),
  gender varchar(6),
  SSN VARCHAR(11),
  birth_date date,
  marital_status varchar(10), 
  -- other employee information
  employee_status varchar(20),
  hire_date DATE not null,
  re_hire_date DATE,
  terminate_date DATE,
  terminate_reason varchar(400),
  terminate_Type varchar(50),
  -- employee`s job information
  job_code varchar(100),
  job_name VARCHAR(100),
  employee_job_effective_date DATE,
  employee_job_expirty_date DATE,
  pay_amount varchar(50),
  standard_hours int,
  employee_type varchar(9),
  employment_status varchar(9),
  department_code varchar(10),
  department_name VARCHAR(100),   
  location_code varchar(10),
  location_name VARCHAR(100),
  pay_frequency varchar(8),
  pay_type varchar(6),
  report_to_job varchar(50),
  -- field shore change date and time
  change_date timestamp,
  operation varchar(20) check (operation = 'Insert' or operation = 'Delete' or operation = 'Update' or operation = 'None')
);

-- Solution for 2017 Term 1 CMPT355 Assignment 3
-- Author: Lujie Duan

-- Create loading tables for assignment 3
-- Can use either long VARCHAR() or TEXT for the loading tables 

CREATE TABLE load_employee_data (
    employee_number VARCHAR(1000),
    title VARCHAR(1000),
    first_name VARCHAR(1000),
    middle_name VARCHAR(1000),
    last_name VARCHAR(1000),
    gender VARCHAR(1000),
    birthdate VARCHAR(1000),
    marital_status VARCHAR(1000),
    ssn VARCHAR(1000) ,
    home_email VARCHAR(1000),
    orig_hire_date VARCHAR(1000),
    rehire_date VARCHAR(1000),
    term_date VARCHAR(1000),
    term_type VARCHAR(1000),
    term_reason VARCHAR(1000),
    job_title VARCHAR(1000),
    job_code VARCHAR(1000),
    job_st_date VARCHAR(1000),
    job_end_date VARCHAR(1000),
    department_code VARCHAR(1000),
    location_code VARCHAR(1000),
    pay_freq VARCHAR(1000),
    pay_type VARCHAR(1000),
    hourly_amount VARCHAR(1000),
    salary_amount VARCHAR(1000),
    supervisor_job_code VARCHAR(1000),
    employee_status VARCHAR(1000),
    standard_hours VARCHAR(1000),
    employee_type VARCHAR(1000),
    employment_status VARCHAR(1000),
    last_perf_num VARCHAR(1000),
    last_perf_text VARCHAR(1000) ,
    last_perf_date VARCHAR(1000),
    home_street_num VARCHAR(1000),
    home_street_addr VARCHAR(1000),
    home_street_suffix VARCHAR(1000),
    home_city VARCHAR(1000),
    home_state VARCHAR(1000),
    home_country VARCHAR(1000),
    home_zip_code VARCHAR(1000),
    bus_street_num VARCHAR(1000),
    bus_street_addr VARCHAR(1000),
    bus_street_suffix VARCHAR(1000),
    bus_zip_code VARCHAR(1000),
    bus_city VARCHAR(1000),
    bus_state VARCHAR(1000),
    bus_country VARCHAR(1000),
    ph1_cc VARCHAR(1000),
    ph1_area VARCHAR(1000),
    ph1_number VARCHAR(1000),
    ph1_extension VARCHAR(1000),
    ph1_type VARCHAR(1000),
    ph2_cc VARCHAR(1000),
    ph2_area VARCHAR(1000),
    ph2_number VARCHAR(1000),
    ph2_extension VARCHAR(1000),
    ph2_type VARCHAR(1000),
    ph3_cc VARCHAR(1000),
    ph3_area VARCHAR(1000),
    ph3_number VARCHAR(1000),
    ph3_extension VARCHAR(1000),
    ph3_type VARCHAR(1000),
    ph4_cc VARCHAR(1000),
    ph4_area VARCHAR(1000),
    ph4_number VARCHAR(1000),
    ph4_extension VARCHAR(1000),
    ph4_type VARCHAR(1000)
);

CREATE TABLE load_new_employe_data (
    employee_number VARCHAR(1000),
    title VARCHAR(1000),
    first_name VARCHAR(1000),
    middle_name VARCHAR(1000),
    last_name VARCHAR(1000),
    gender VARCHAR(1000),
    birthdate VARCHAR(1000),
    marital_status VARCHAR(1000),
    ssn VARCHAR(1000) ,
    home_email VARCHAR(1000),
    orig_hire_date VARCHAR(1000),
    rehire_date VARCHAR(1000),
    term_date VARCHAR(1000),
    term_type VARCHAR(1000),
    term_reason VARCHAR(1000),
    job_title VARCHAR(1000),
    job_code VARCHAR(1000),
    job_st_date VARCHAR(1000),
    job_end_date VARCHAR(1000),
    department_code VARCHAR(1000),
    location_code VARCHAR(1000),
    pay_freq VARCHAR(1000),
    pay_type VARCHAR(1000),
    hourly_amount VARCHAR(1000),
    salary_amount VARCHAR(1000),
    supervisor_job_code VARCHAR(1000),
    employee_status VARCHAR(1000),
    standard_hours VARCHAR(1000),
    employee_type VARCHAR(1000),
    employment_status VARCHAR(1000),
    last_perf_num VARCHAR(1000),
    last_perf_text VARCHAR(1000) ,
    last_perf_date VARCHAR(1000),
    home_street_num VARCHAR(1000),
    home_street_addr VARCHAR(1000),
    home_street_suffix VARCHAR(1000),
    home_city VARCHAR(1000),
    home_state VARCHAR(1000),
    home_country VARCHAR(1000),
    home_zip_code VARCHAR(1000),
    bus_street_num VARCHAR(1000),
    bus_street_addr VARCHAR(1000),
    bus_street_suffix VARCHAR(1000),
    bus_zip_code VARCHAR(1000),
    bus_city VARCHAR(1000),
    bus_state VARCHAR(1000),
    bus_country VARCHAR(1000),
    ph1_cc VARCHAR(1000),
    ph1_area VARCHAR(1000),
    ph1_number VARCHAR(1000),
    ph1_extension VARCHAR(1000),
    ph1_type VARCHAR(1000),
    ph2_cc VARCHAR(1000),
    ph2_area VARCHAR(1000),
    ph2_number VARCHAR(1000),
    ph2_extension VARCHAR(1000),
    ph2_type VARCHAR(1000),
    ph3_cc VARCHAR(1000),
    ph3_area VARCHAR(1000),
    ph3_number VARCHAR(1000),
    ph3_extension VARCHAR(1000),
    ph3_type VARCHAR(1000),
    ph4_cc VARCHAR(1000),
    ph4_area VARCHAR(1000),
    ph4_number VARCHAR(1000),
    ph4_extension VARCHAR(1000),
    ph4_type VARCHAR(1000)
);

CREATE TABLE load_jobs (
    job_code VARCHAR(1000),
    job_title VARCHAR(1000),
    effective_date VARCHAR(1000),
    expiry_date VARCHAR(1000)
);


CREATE TABLE load_departments (
    dept_code VARCHAR(1000),
    dept_name VARCHAR(1000),
    dept_mgr_job_code VARCHAR(1000),    
    dept_mgr_job_title VARCHAR(1000),
    effective_date VARCHAR(1000),
    expiry_date VARCHAR(1000)
);



CREATE TABLE load_locations (
    loc_code VARCHAR(1000),
    loc_name VARCHAR(1000),
    street_addr VARCHAR(1000),
    city VARCHAR(1000),
    province VARCHAR(1000),
    country VARCHAR(1000),
    postal_code VARCHAR(1000)
);








