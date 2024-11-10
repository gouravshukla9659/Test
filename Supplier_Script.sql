Create schema stage_supplier;
create schema work_supplier;
create schema target_supplier;

CREATE OR REPLACE TABLE stage_supplier.STG_SUPPLIER (
    Supplier_number      INT,
    SupplierName    VARCHAR(150),
    ContactName     VARCHAR(100),
    Phone           VARCHAR(20),
    Email           VARCHAR(150),
    Address         VARCHAR(255),
    City            VARCHAR(100),
    State           VARCHAR(100),
    PostalCode      VARCHAR(20),
    Country         VARCHAR(100)
);

DELETE from stage_supplier.stg_supplier;

CREATE TABLE work_supplier.workSupplier (
    SupplierID      INT  PRIMARY KEY,
	Supplier_number INT,
    SupplierName    VARCHAR(150),
    ContactName     VARCHAR(100),
    Phone           VARCHAR(20),
    Email           VARCHAR(150),
    Address         VARCHAR(255),
    City            VARCHAR(100),
    State           VARCHAR(100),
    PostalCode      VARCHAR(20),
    Country         VARCHAR(100),
	Start_Date     DATE,
	End_Date     DATE
);

CREATE TABLE target_supplier.targetSupplier (
    SupplierID      INT  PRIMARY KEY,
	Supplier_number INT,
    SupplierName    VARCHAR(150),
    ContactName     VARCHAR(100),
    Phone           VARCHAR(20),
    Email           VARCHAR(150),
    Address         VARCHAR(255),
    City            VARCHAR(100),
    State           VARCHAR(100),
    PostalCode      VARCHAR(20),
    Country         VARCHAR(100),
	Start_Date     DATE,
	End_Date     DATE
);

Create or replace view Supplier_view AS
with MaxID AS (
select coalesce (MAX(SupplierID),0) as MAX_supplierID
from target_supplier.targetSupplier
),
Newsupplier AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY STG.Supplier_number) + (SELECT MAX_SupplierID FROM MaxID) AS New_SupplierID,
STG.Supplier_number,
STG.SupplierName,
STG.ContactName,
STG.Phone,
STG.Email,
STG.Address,
STG.City,
STG.State,
STG.PostalCode,
STG.Country,
'2024-10-01' as Start_Date,
'9999-12-31' as End_Date
FROM stage_supplier.STG_SUPPLIER STG
Left join target_supplier.targetSupplier TGT
on STG.SUPPLIER_NUMBER = TGT.SUPPLIER_NUMBER
And END_DATE = '9999-12-31'
where TGT.supplierid is null
)
select
coalesce(TGT.SupplierID, N.New_SupplierID) as SupplierID,
stg.supplier_number,
stg.suppliername,
stg.contactname,
stg.phone,
stg.email,
stg.address,
stg.city,
stg.state,
stg.postalcode,
stg.country,
'2024-10-01' as Start_Date,
'9999-12-31' as End_Date
FROM stage_supplier.STG_SUPPLIER STG
Left join target_supplier.targetSupplier TGT
on STG.SUPPLIER_NUMBER = TGT.SUPPLIER_NUMBER
And END_DATE = '9999-12-31'
left join NEWSUPPLIER N
on STG.SUPPLIER_NUMBER = N.Supplier_number
order by supplier_number;

INSERT into work_supplier.workSupplier
select * from supplier_view;

delete from work_supplier.worksupplier;

update target_supplier.targetSupplier
set End_Date = WRK.Start_Date
from work_supplier.worksupplier WRK
where target_supplier.targetSupplier.SupplierID = WRK.SUPPLIERID
AND target_supplier.targetSupplier.End_Date = '9999-12-31'
AND (

WRK.SUPPLIERNAME <> target_supplier.targetSupplier.suppliername
OR target_supplier.targetSupplier.contactname <> WRK.contactname
OR target_supplier.targetSupplier.Email <> WRK.Email
OR target_supplier.targetSupplier.Phone <> WRK.Phone
OR target_supplier.targetSupplier.Address <> WRK.Address
OR target_supplier.targetSupplier.City <> WRK.City
OR target_supplier.targetSupplier.State <> WRK.State
OR target_supplier.targetSupplier.PostalCode <> WRK.PostalCode
OR target_supplier.targetSupplier.Country <> WRK.Country);

INSERT into target_supplier.targetsupplier
SELECT
WRK.SupplierID,
WRK.Supplier_number,
WRK.Suppliername,
WRK.Contactname,
WRK.Phone,
WRK.Email,
WRK.Address,
WRK.City,
WRK.State,
WRK.PostalCode,
WRK.Country,
WRK.Start_Date,
WRK.END_DATE
from work_supplier.worksupplier WRK
Left join target_supplier.targetsupplier TGT
on WRK.SUPPLIERID = TGT.SUPPLIERID
and TGT.End_Date = '9999-12-31'
where TGT.SUPPLIERID is null;

select * from target_supplier.targetsupplier;