
DELETE FROM category_stage.STG_CATEGORY;
delete FROM category_work.work_category ;
DELETE FROM category_target.Category ;


CREATE OR REPLACE VIEW category_view AS
WITH MaxID AS (
    SELECT COALESCE(MAX(CategoryID), 0) AS MAX_CATEGORYID
    FROM category_target.Category
),
NewCategories AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY STG.Category_number) + (SELECT MAX_CATEGORYID FROM MaxID) AS New_CategoryID,
        STG.Category_number,
        STG.CategoryName,
        STG.Description,
        STG.Business_date AS Start_Date,
        '9999-12-31' AS End_Date
    FROM category_stage.STG_CATEGORY STG
    LEFT JOIN category_target.Category TGT
        ON STG.Category_number = TGT.Category_number
        AND TGT.End_Date = '9999-12-31'
    WHERE TGT.CategoryID IS NULL
)
SELECT
    COALESCE(TGT.CategoryID, N.New_CategoryID) AS CategoryID,
    STG.Category_number,
    STG.CategoryName,
    STG.Description,
    STG.Business_date,
    '9999-12-31' AS End_Date
--FROM NewCategories N
FROM category_stage.STG_CATEGORY STG
    LEFT JOIN category_target.Category TGT
        ON STG.Category_number = TGT.Category_number
        AND TGT.End_Date = '9999-12-31'
        LEFT JOIN NewCategories N 
        on STG.Category_number = N.Category_number
ORDER BY N.Category_number;

DELETE FROM category_work.work_category;
Insert into category_work.work_category
SELECT * FROM category_view ;

SELECT * FROM category_work.work_category;

Update category_target.Category
set End_Date = WRK.Start_Date
from category_work.work_category WRK
WHERE category_target.Category.CategoryID = WRK.CATEGORYID
AND category_target.Category.End_Date = '9999-12-31'
AND
(
--category_target.Category.Category_number <> WRK.CATEGORY_NUMBER
--OR 
category_target.Category.CategoryName <> WRK.CATEGORYNAME
OR category_target.Category.Description <> WRK.DESCRIPTION
OR category_target.Category.Start_Date <> WRK.start_date);

insert into category_target.Category
select
WRK.CategoryID,
WRK.Category_number,
WRK.CategoryName,
WRK.Description,
WRK.START_DATE,
WRK.END_DATE
from category_work.work_category WRK
LEFT JOIN category_target.category TGT
on WRK.CATEGORYID = TGT.CATEGORYID
AND TGT.END_DATE ='9999-12-31' 
WHERE
TGT.CATEGORYID is null;



SELECT * FROM category_target.Category ;