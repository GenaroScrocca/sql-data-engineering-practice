--DROP TABLE IF EXISTS Products

CREATE TABLE Products(
	ProductKey int primary key,
	ProductName varchar(100),
	StockLevel int,
	Price money
)

--TRUNCATE TABLE Products

INSERT INTO Products(ProductKey,ProductName,StockLevel,Price)
OUTPUT inserted.*
VALUES
(1,'adjustable race',1000,100.50),
(2,'bearing ball',800,90.85),
(3,' BB bearing ball',1250,120.45),
(4,' Headset ball bearing ',500,75.10),
(5,' Blade',1500,10.25),
(6,' LL Crankarm',200,2000.45),
(7,' ML Crankarm',200,1980.50),
(8,' HL Crankarm',200,1976.45),
(9,' Chainring Bolt',2000,10.25),
(10,' Chainring Nut',2000,3.45)


DROP TABLE IF EXISTS Products_Stage

CREATE TABLE Products_Stage(
	ProductKey int primary key,
	ProductName varchar(100),
	StockLevel int,
	Price money
)




INSERT INTO Products_Stage(ProductKey,ProductName,StockLevel,Price)
OUTPUT inserted.*
VALUES
(1,'adjustable race',1200,102.50),
(5,'crown race',400,100.25),
(6,'Chain stays',600,30.25)



--SCD1 Implementation

MERGE INTO Products T
	USING Products_Stage S
	ON T.ProductKey= S.ProductKey

WHEN NOT MATCHED THEN
	INSERT(ProductKey,ProductName,StockLevel,Price)
	VALUES(S.ProductKey,S.ProductName,S.StockLevel,S.Price)

WHEN MATCHED THEN
	UPDATE SET T.StockLevel= S.StockLevel,
			T.Price= S.Price;

SELECT * FROM Products
SELECT * FROM Products_Stage


--SCD2 Implementation

CREATE TABLE Products(
	ProductKey int,
	ProductName varchar(100),
	StockLevel int,
	Price money,
	StartDate datetime,
	EndDate datetime,
	IsActive bit
)


INSERT INTO Products(ProductKey,ProductName,StockLevel,Price,StartDate,EndDate,IsActive)
OUTPUT inserted.*
VALUES
(1,'adjustable race',1000,100.50,'2020-04-03',null,1),
(2,'bearing ball',800,90.85,'2021-01-02',null,1),
(3,' BB bearing ball',1250,120.45,'2002-07-02',null,1),
(4,' Headset ball bearing ',500,75.10,'2023-09-02',null,1)


-- 1) Tabla variable para guardar lo que hizo el MERGE (OUTPUT)
DECLARE @MergeOp TABLE(
    ProductKey   INT,
    ProductName  VARCHAR(100),
    StockLevel   INT,
    Price        MONEY,
    StartDate    DATE,
    EndDate      DATE,
    IsActive     BIT,
    Operation    VARCHAR(10)
);

-- 2) MERGE: sincroniza Products (destino) con Products_Stage (fuente)
MERGE INTO Products T
USING Products_Stage S
ON T.ProductKey = S.ProductKey
AND T.IsActive = 1

-- 3) Si el producto NO existe en destino (como activo) → INSERT (nuevo)
WHEN NOT MATCHED THEN
    INSERT(ProductKey, ProductName, StockLevel, Price, StartDate, EndDate, IsActive)
    VALUES(
        S.ProductKey,
        S.ProductName,
        S.StockLevel,
        S.Price,
        CAST(GETDATE() AS DATE),
        NULL,
        1
    )

-- 4) Si el producto existe (MATCHED) PERO CAMBIÓ algo → cerrar versión vieja (UPDATE)
WHEN MATCHED
AND (
       T.ProductName <> S.ProductName
    OR T.StockLevel  <> S.StockLevel
    OR T.Price       <> S.Price
)
THEN
    UPDATE SET
        T.EndDate  = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
        T.IsActive = 0

-- 5) OUTPUT: guardamos lo que vino del Stage + operación (INSERT/UPDATE)
OUTPUT
    S.ProductKey,
    S.ProductName,
    S.StockLevel,
    S.Price,
    CAST(GETDATE() AS DATE) AS StartDate,
    NULL AS EndDate,
    1 AS IsActive,
    $ACTION AS Operation
INTO @MergeOp;

-- 6) Insertar la "nueva versión" SOLO para los que fueron UPDATE (SCD2)
INSERT INTO Products(ProductKey, ProductName, StockLevel, Price, StartDate, EndDate, IsActive)
SELECT ProductKey, ProductName, StockLevel, Price, StartDate, EndDate, IsActive
FROM @MergeOp
WHERE Operation = 'UPDATE';



-- SCD3: Preserve history by adding column

--DROP TABLE IF EXISTS Products

CREATE TABLE Products(
	ProductKey int,
	ProductName varchar(100),
	StockLevel int,
	Price money,
	PreviousPrice_1 money,
	PreviousPrice_1_EndDate datetime,
	PreviousPrice_2 money,
	PreviousPrice_2_EndDate datetime
)


INSERT INTO Products(ProductKey,ProductName,StockLevel,Price)
OUTPUT inserted.*
VALUES
(1,'adjustable race',1000,100.50),
(2,'bearing ball',800,90.85),
(3,' BB bearing ball',1250,120.45),
(4,' Headset ball bearing ',500,75.10)




MERGE INTO Products T
USING Products_Stage S
ON T.ProductKey = S.ProductKey

WHEN NOT MATCHED THEN
	INSERT(ProductKey,ProductName,StockLevel,Price)
	VALUES(S.ProductKey,S.ProductName,S.StockLevel,S.Price)

WHEN MATCHED AND (T.StockLevel <> S.StockLevel OR T.Price <> S.Price) THEN
	UPDATE SET T.StockLevel= S.StockLevel,
			T.Price=S.Price,
			T.PreviousPrice_1= T.Price,
			T.PreviousPrice_1_EndDate= DATEADD(DD,-1,FORMAT(GETDATE(),'yyyy-MM-dd')),
			T.PreviousPrice_2= T.PreviousPrice_1,
			T.PreviousPrice_2_EndDate= PreviousPrice_1_EndDate; 

INSERT INTO Products_Stage(ProductKey,ProductName,StockLevel,Price)VALUES
(1,'Adjustable race',1200,105.50)


TRUNCATE TABLE Products_Stage