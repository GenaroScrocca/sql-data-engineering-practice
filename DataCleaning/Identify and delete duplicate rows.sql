CREATE TABLE EMPLOYEES(
	EmployeeId int,
	EmployeeName varchar(100),
	DOJ datetime,
	Department varchar(20),
	Salary float
)

INSERT INTO EMPLOYEES(EmployeeId,EmployeeName,DOJ,Department,Salary)VALUES
(1,'RAKESH','2023-01-12','IT',40000),
(2,'AMAN','2024-01-12','SALES',40400),
(3,'YUSUF','2025-01-12','IT',44000)


select * from EMPLOYEES

SELECT *,
ROW_NUMBER() OVER(PARTITION BY EmployeeId,EmployeeName,DOJ,Department,Salary
ORDER BY EmployeeId) RowNum
FROM Employees

--Delete duplicate rows using CTE
WITH CteDuplicates
AS
(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY EmployeeId,EmployeeName,DOJ,Department,
	Salary ORDER BY EmployeeId) RowNum
	FROM EMPLOYEES
) DELETE FROM CteDuplicates
where RowNum>1

