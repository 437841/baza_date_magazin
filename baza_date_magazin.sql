create database wholesale_managment

CREATE TABLE category (
  CategoryID int NOT NULL,
  CategoryName varchar(30) NOT NULL
) 

--
-- Dumping data for table `category`
--

INSERT INTO category (CategoryID, CategoryName) VALUES
(1, 'Washing Powder'),
(2, 'Cosmetics'),
(3, 'Stationary'),
(4, 'Garments');

-- --------------------------------------------------------

--
-- Table structure for table `customer_information`
--

CREATE TABLE customer_information (
  CustomerID varchar(30) NOT NULL,
  Name varchar(30) NOT NULL,
  Address varchar(50) NOT NULL,
  Phone varchar(15) NOT NULL,
  Password varchar(15) NOT NULL
) 

--
-- Dumping data for table `customer_information`
--

INSERT INTO customer_information (CustomerID, Name, Address, Phone, Password) VALUES
('C11', 'Avijit Verma', 'XYZ', '7901012908', 'abc123'),
('C12', 'Swargam Avinash', 'ABC', '7901012908', 'qwerty'),
('C13', 'Pranavendra', 'XWR', '7077102278', 'asdfgh');

-- --------------------------------------------------------

--
-- Table structure for table `depleted_product`
--

CREATE TABLE depleted_product (
  ProductID int NOT NULL,
  Quantity int NOT NULL
) 
-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

CREATE TABLE payment (
  TransactionID int NOT NULL,
  Amount_Paid int NOT NULL,
  Mode varchar(30) NOT NULL,
  Transaction_Date int NOT NULL
) 

--
-- Dumping data for table `payment`
--

INSERT INTO payment (TransactionID, Amount_Paid, Mode, Transaction_Date) VALUES
(22, 4400, 'debit card', 2016),
(25, 4100, 'cash', 2016),
(27, 4500, 'cash', 2016),
(28, 1500, 'debit card', 2016);

-- --------------------------------------------------------

--
-- Table structure for table `price_list`
--

CREATE TABLE price_list (
  ProductID int NOT NULL,
  USP int NOT NULL
) 

--
-- Dumping data for table `price_list`
--

INSERT INTO price_list (ProductID, USP) VALUES
(1, 70),
(2, 100),
(3, 55),
(4, 150),
(5, 300);

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

CREATE TABLE product (
  ProductID int NOT NULL,
  Pname varchar(30) NOT NULL,
  CategoryID int NOT NULL,
  SupplierID int NOT NULL,
  Quantity_in_stock int NOT NULL,
  UnitPrice int NOT NULL,
  ReorderLevel int NOT NULL
) 

--
-- Dumping data for table `product`
--

INSERT INTO product (ProductID, Pname, CategoryID, SupplierID, Quantity_in_stock, UnitPrice, ReorderLevel) VALUES
(1, 'Nirma', 1, 1, 20, 60, 10),
(2, 'Surf', 1, 1, 55, 70, 10),
(3, 'Pond Powder', 2, 2, 35, 40, 10),
(4, 'Garnier Cream', 2, 2, 55, 110, 8),
(5, 'Parker Pen', 3, 2, 100, 250, 10);


CREATE PROCEDURE discount_calc (@product INT, @quant INT, @disc INT OUTPUT)  AS Begin
declare @price int; 
declare @total int;
select USP into price from price_list where ProductID = @product;
set @total=@quant*@price; 
if (@total >= 20000 and @total < 40000) 
   set @disc=@total*0.05;
 if (@total >= 40000 and @total < 60000) 
   set @disc=@total*0.075;
 if (@total >= 100000) 
   set @disc=@total*0.1;
END


CREATE TRIGGER depleted_check_update  ON product
FOR UPDATE AS
Declare @finished int=0;
declare @flag int=0;
DECLARE @c1 CURSOR;
DECLARE @ProductID INT;
SET @c1 = CURSOR FOR
SELECT ProductID
FROM inserted;

IF (SELECT Quantity_in_stock FROM inserted) < (SELECT ReorderLevel FROM inserted) begin 
UPDATE depleted_product
SET  depleted_product.ProductID=inserted.ProductID,  depleted_product.Quantity=inserted.Quantity_in_stock
from inserted;end
else Begin
open @c1;
FETCH NEXT FROM @c1 INTO @ProductID;
while @@FETCH_STATUS =0
Begin 

    IF @ProductID IN (SELECT ProductID FROM product)
  begin Set @finished=1
        Set @flag=1
   end
fetch next from @c1 INTO @ProductID;
End
close c1;
deallocate c1

End

if @flag=1
Delete from depleted_product where ProductID=(select ProductID from inserted);




CREATE TABLE supplier_information (
  SupplierID int NOT NULL,
  SName varchar(30) NOT NULL,
  Address varchar(50) NOT NULL,
  Phone varchar(15) NOT NULL) 

--
-- Dumping data for table `supplier_information`
--

INSERT INTO supplier_information (SupplierID, SName, Address, Phone) VALUES
(1, 'Swargam', 'XYZ', '123456789'),
(2, 'Sena', 'QWE', '987654329 ');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_detail`
--

CREATE TABLE transaction_detail (
  TransactionID int NOT NULL,
  ProductID int NOT NULL,
  Quantity int NOT NULL,
  Discount int NOT NULL DEFAULT '0',
  Total_Amount int NOT NULL,
  Trans_Init_Date date NOT NULL) 

--
-- Dumping data for table `transaction_detail`
--

INSERT INTO transaction_detail (TransactionID, ProductID, Quantity, Discount, Total_Amount, Trans_Init_Date) VALUES
(22, 1, 20, 0, 1400, '2016-11-17'),
(22, 2, 30, 0, 3000, '2016-11-17'),
(25, 3, 20, 0, 1100, '2016-11-17'),
(25, 4, 20, 0, 3000, '2016-11-17'),
(27, 1, 20, 0, 1400, '2016-11-15'),
(27, 2, 20, 0, 2000, '2016-11-15'),
(27, 3, 20, 0, 1100, '2016-11-15'),
(28, 4, 10, 0, 1500, '2016-11-16');


CREATE TRIGGER max_min_quantity ON transaction_detail INSTEAD OF INSERT AS
declare @var1 int;
declare @var2 int;

select ReorderLevel into var1 from Product where ProductID in (Select ProductID from inserted);
select Quantity_in_stock into var2 from Product where ProductID in (Select ProductID from inserted);
 --sau select @var1= ReorderLevel, @var2=Quantity_in_stock from product where ProductID in (select ProductID from inserted)
if exists(Select * from inserted where Quantity<@var1) 
    BEGIN
        DECLARE @errorMessage varchar(100) = 'Less than min quantity';
        RAISERROR(@errorMessage, 16, 1);
        ROLLBACK;
        RETURN;
    END;
    

if exists(Select * from inserted where Quantity>@var2)
  begin
  declare @errorMessage2 varchar(100)='More then max quanitity';
  raiserror(@errorMessage2,16,1);
  rollback;
  return;
  end;

update product set Quantity_in_stock = Quantity_in_stock - inserted.Quantity from product inner join inserted on product.ProductID = inserted.ProductID;



CREATE TRIGGER max_min_quantity_update ON transaction_detail INSTEAD OF UPDATE  AS
declare @var1 int;
declare @var2 int;

select ReorderLevel into var1 from Product where ProductID in (select ProductID from inserted);
select Quantity_in_stock into var2 from Product where ProductID in (select ProductID from inserted);
if exists(select * from inserted where Quantity<@var1)
   BEGIN
        DECLARE @errorMessage varchar(100) = 'Less than min quantity';
        RAISERROR(@errorMessage, 16, 1);
        ROLLBACK;
        RETURN;
    END;

if exists(select * from inserted where Quantity>@var2) 
   BEGIN
        DECLARE @errorMessage2 varchar(100) = 'Less than min quantity';
        RAISERROR(@errorMessage2, 16, 1);
        ROLLBACK;
        RETURN;
    END;
update product set Quantity_in_stock = Quantity_in_stock - inserted.Quantity from product inner join inserted on product.ProductID=inserted.ProductID;



CREATE TABLE transaction_information (
  TransactionID int NOT NULL,
  CustomerID varchar(30) NOT NULL,
  Trans_Init_Date date NOT NULL)

--
-- Dumping data for table `transaction_information`
--

INSERT INTO transaction_information (TransactionID, CustomerID, Trans_Init_Date) VALUES
(22, 'C12', '2016-11-17'),
(25, 'C11', '2016-11-17'),
(27, 'C13', '2016-11-15'),
(28, 'C13', '2016-11-16');

--
-- Triggers `transaction_information`
--
CREATE TRIGGER customer_check ON transaction_information INSTEAD OF INSERT AS
Begin

declare @flag int= 0;

 DECLARE @CursorTable TABLE (
        cursor_customerID INT
    );
    
    INSERT INTO @CursorTable (cursor_customerID)
    SELECT customerID
    FROM customer_information;
    
    DECLARE @CurrentValue INT;

    SELECT TOP 1 @CurrentValue =cursor_customerID
    FROM @CursorTable;
    
    -- Start cursor-like loop
    WHILE @@ROWCOUNT > 0
    BEGIN
        if @CurrentValue in(select customerID from inserted) begin 
        set @flag=1;end
        
        -- Move to the next row
        DELETE FROM @CursorTable WHERE @CurrentValue in(select customerID from inserted) 
        SELECT TOP 1 @CurrentValue  FROM @CursorTable where @CurrentValue in(select customerID from inserted) 
       
    END;

	if @flag=0 begin
DECLARE @errorMessage varchar(100) = 'Customer does not exist';
        RAISERROR(@errorMessage, 16, 1);
end;
END



CREATE TRIGGER customer_check_update  ON transaction_information INSTEAD OF UPDATE AS BEGIN
declare @flag int= 0;

 DECLARE @CursorTable TABLE (
        cursor_customerID INT
    );
    
    INSERT INTO @CursorTable (cursor_customerID)
    SELECT customerID
    FROM customer_information;
    
    DECLARE @CurrentValue INT;

    SELECT TOP 1 @CurrentValue =cursor_customerID
    FROM @CursorTable;
    
    -- Start cursor-like loop
    WHILE @@ROWCOUNT > 0
    BEGIN
        if @CurrentValue in(select customerID from inserted) begin 
        set @flag=1;end
        
        -- Move to the next row
        DELETE FROM @CursorTable WHERE @CurrentValue in(select customerID from inserted) 
        SELECT TOP 1 @CurrentValue  FROM @CursorTable where @CurrentValue in(select customerID from inserted) 
       
    END;

	if @flag=0 begin
DECLARE @errorMessage varchar(100) = 'Customer does not exist';
        RAISERROR(@errorMessage, 16, 1);
end;
END

ALTER TABLE transaction_detail
  ADD PRIMARY KEY (TransactionID,ProductID);

  ALTER TABLE transaction_information
  ADD PRIMARY KEY (TransactionID);



CREATE TRIGGER decrease_quantity
ON transaction_information
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @finished INT = 0;
    DECLARE @cust INT;
    DECLARE @quant INT = 0;

    -- Create a temporary table to store ProductID and Quantity
    CREATE TABLE #my_temp_table (ProductID INT, Quantity INT);

    INSERT INTO #my_temp_table (ProductID, Quantity)
    SELECT ProductID, Quantity
    FROM transaction_detail
    WHERE TransactionID = (SELECT TransactionID FROM deleted);

    -- Declare the cursor
    DECLARE c1 CURSOR FOR
        SELECT ProductID
        FROM transaction_detail
        WHERE TransactionID = (SELECT TransactionID FROM deleted);

    -- Open the cursor
    OPEN c1;
    
    -- Fetch the first row from the cursor
    FETCH NEXT FROM c1 INTO @cust;

    -- Loop through the cursor rows
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @quant = Quantity
        FROM #my_temp_table
        WHERE ProductID = @cust; 

        UPDATE Product
        SET quantity_in_stock = quantity_in_stock + @quant
        WHERE ProductID = @cust;

        -- Fetch the next row from the cursor
        FETCH NEXT FROM c1 INTO @cust;
    END;

    -- Close and deallocate the cursor
    CLOSE c1;
    DEALLOCATE c1;

    -- Delete from transaction_detail
    DELETE td
    FROM transaction_detail td
    INNER JOIN deleted d ON td.TransactionID = d.TransactionID;
    
    -- Drop the temporary table
    DROP TABLE #my_temp_table;
END;

SELECT DISTINCT Pname FROM product;
SELECT TOP 3 * FROM product;
SELECT TOP 50 PERCENT * FROM product;
SELECT Name AS first_name FROM customer_information;

SELECT Pname FROM product WHERE Pname = ‘Surf’ AND UnitPrice = 55;
SELECT Pname FROM product WHERE Pname = ‘Surf’ OR UnitPrice = 55;
SELECT Pname FROM product WHERE UnitPrice BETWEEN 45 AND 55;
SELECT Pname FROM product WHERE Pname LIKE ‘%S%’;
SELECT Pname FROM product WHERE Pname IN (‘Nirma’, ‘Surf’, ‘Parker Pen’);
SELECT Pname FROM product WHERE Pname IS NOT NULL;

SELECT COUNT(*) FROM customer_information;
SELECT Pname, AVG(Quantity_in_stock) FROM product GROUP BY Pname;

SELECT COUNT(ProductID), Pname FROM product GROUP BY Pname HAVING COUNT(ProductID) > 2;
SELECT Pname FROM product ORDER BY quantity_in_stock DESC;
SELECT Pname FROM product ORDER BY quantity_in_stock OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;


SELECT Pname FROM product INNER JOIN category
ON product.CategoryID = category.CategoryID;

SELECT Pname FROM product FULL OUTER JOIN depleted_product ON product.ProductID = depleted_product.ProductID;

SELECT Pname FROM product WHERE EXISTS (SELECT USP FROM price_list WHERE ProductID = 1);

SELECT ProductID, Quantity_in_stock,
CASE
    WHEN Quantity_in_stock > 40 THEN 'The quantity is greater than 40'
    WHEN Quantity_in_stock = 40 THEN 'The quantity is 40'
    ELSE 'The quantity is under 40'
END AS QuantityText
FROM product;