Create schema training_stage;
create schema training_work;
create schema training_transf;
create schema training_target;

CREATE OR REPLACE TABLE training_stage.STG_CUSTOMER (
    Customer_number      INT,
    FirstName       VARCHAR(100),
    LastName        VARCHAR(100),
    Email           VARCHAR(150),
    Phone           VARCHAR(20),
    Address         VARCHAR(255),
    City            VARCHAR(100),
    State           VARCHAR(100),
    PostalCode      VARCHAR(20),
    Country         VARCHAR(100),
    DateOfBirth     VARCHAR(100),
    RegistrationDate VARCHAR(100),
	Business_Date VARCHAR(100)
);

DELETE FROM training_stage.STG_CUSTOMER;

CREATE TABLE TRAINING_WORK.WRK_CUSTOMER (
    CustomerID      INT  PRIMARY KEY,
	Customer_number INT,
    FirstName       VARCHAR(100),
    LastName        VARCHAR(100),
    Email           VARCHAR(150),
    Phone           VARCHAR(20),
    Address         VARCHAR(255),
    City            VARCHAR(100),
    State           VARCHAR(100),
    PostalCode      VARCHAR(20),
    Country         VARCHAR(100),
    DateOfBirth     DATE,
    RegistrationDate VARCHAR(100),
	Start_Date     DATE,
	End_Date     DATE
);

DROP TABLE TRAINING_WORK.WRK_CUSTOMER;

CREATE TABLE training_target.Customer (
    CustomerID      INT  PRIMARY KEY,
	Customer_number INT,
    FirstName       VARCHAR(100),
    LastName        VARCHAR(100),
    Email           VARCHAR(150),
    Phone           VARCHAR(20),
    Address         VARCHAR(255),
    City            VARCHAR(100),
    State           VARCHAR(100),
    PostalCode      VARCHAR(20),
    Country         VARCHAR(100),
    DateOfBirth     DATE,
    RegistrationDate VARCHAR(100),
	Start_Date     DATE,
	End_Date     DATE
);

drop table training_target.customer;
select * from training_target.Customer;

Create or replace view customer_view as
with MaxID AS (
select coalesce (MAX(CustomerID),0) as MAX_CustomerID
from training_target.customer
),
NewCustomer AS (
select row_number () OVER (ORDER BY STG.Customer_number) + (select MAX_CustomerID from MaxID) AS
NewCustomerID,
STG.Customer_number,
STG.FirstName,
STG.LastName,
STG.Email,
STG.Phone,
STG.Address,
STG.City,
STG.State,
STG.PostalCode,
STG.Country,
STG.DateOfBirth,
STG.RegistrationDate,
STG.Business_Date as START_DATE,
'9999-12-31' AS END_DATE
From training_stage.stg_customer STG
LEFT JOIN 
training_target.Customer TGT
on STG.Customer_number = TGT.Customer_number
AND TGT.END_DATE ='9999-12-31' 
where TGT.CUSTOMERID IS NULL
)
SELECT 
COALESCE(TGT.CustomerID, N.NewCustomerID) as CustomerID,
STG.Customer_number,
STG.FIRSTNAME,
STG.LASTNAME,
STG.EMAIL,
STG.PHONE,
STG.ADDRESS,
STG.CITY,
STG.STATE,
STG.POSTALCODE,
STG.COUNTRY,
STG.DATEOFBIRTH,
STG.REGISTRATIONDATE,
STG.BUSINESS_DATE AS START_DATE,
'9999-12-31' AS END_DATE
From training_stage.stg_customer STG
LEFT JOIN 
training_target.Customer TGT
on STG.Customer_number = TGT.Customer_number
AND TGT.END_DATE ='9999-12-31'
left join newcustomer N
on STG.CUSTOMER_NUMBER = N.CUSTOMER_NUMBER
order by customer_number;


insert into training_work.wrk_customer
select * from customer_view;

delete from training_work.wrk_customer;

UPDATE training_target.Customer
SET END_DATE = WRK.Start_Date
FROM training_work.WRK_Customer WRK
WHERE training_target.Customer.CustomerID = WRK.Customerid
AND training_target.Customer.END_DATE ='9999-12-31'
AND 
(WRK.FirstName <> training_target.Customer.FirstName
OR training_target.Customer.LastName <> WRK.LastName
OR training_target.Customer.Email <> WRK.Email
OR training_target.Customer.Phone <> WRK.Phone
OR  training_target.Customer.Address <> WRK.Address
OR training_target.Customer.City <> WRK.City
OR training_target.Customer.State <> WRK.State
OR training_target.Customer.PostalCode <> WRK.PostalCode
OR training_target.Customer.Country <> WRK.Country
OR training_target.Customer.DateOfBirth <> WRk.DateOfBirth
OR training_target.Customer.RegistrationDate <> WRK.RegistrationDate);

INSERT INTO TRAINING_TARGET.CUSTOMER
SELECT
WRK.CustomerID,
WRK.CUSTOMER_NUMBER,
WRK.FIRSTNAME,
WRK.LASTNAME,
WRK.EMAIL,
WRK.PHONE,
WRK.ADDRESS,
WRK.CITY,
WRK.STATE,
WRK.POSTALCODE,
WRK.COUNTRY,
WRK.DATEOFBIRTH,
WRK.REGISTRATIONDATE,
WRK.START_DATE,
WRK.END_DATE
from training_work.wrk_customer WRK
Left join training_target.customer TGT
on WRK.CUSTOMERID = TGT.CUSTOMERID
AND TGT.END_DATE = '9999-12-31'
WHERE TGT.CUSTOMERID IS NULL;

SELECT * FROM training_TARGET.CUSTOMER;
drop TABLE training_Target.CUSTOMER;

Select * from training_work.wrk_customer;