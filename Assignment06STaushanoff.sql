--*************************************************************************--
-- Title: Assignment06
-- Author: STaushanoff
-- Desc: This file demonstrates how to use Views
-- Change Log: When,Who,What
-- 2025-08-15 S. Taushanoff, Finished Assignment 
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_STaushanoff')
	 Begin 
	  Alter Database [Assignment06DB_STaushanoff] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_STaushanoff;
	 End
	Create Database Assignment06DB_STaushanoff;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_STaushanoff;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10 -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, UnitsInStock + 20 -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go
/*
-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

*/ --Don't need this anymore, got the views done. 

/********************************* Questions and Answers *********************************/
print 
'NOTES------------------------------------------------------------------------------------ 
 1) You can use any name you like for you views, but be descriptive and consistent
 2) You can use your working code from assignment 5 for much of this assignment
 3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5% pts): How can you create BACIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!

/*Basic view is essentially a view/copy of the original table with the 
opportunity to add some aliases.  We introduce schema binding which according to the notes 
keeps tables from changing so much view does not work anymore.  According to online sources,
it prevents underlying tables from being altered in a way that could affect the view - such as locking
columns that are referenced in the view, or preventing tables from being dropped.  
*/

GO
Create View vCategories WITH SCHEMABINDING
    AS  
        SELECT CategoryID, CategoryName
        FROM dbo.Categories as c 
GO

Create View vEmployees WITH SCHEMABINDING
    AS  
        SELECT EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID
        FROM dbo.Employees as e
GO

Create View vInventories WITH SCHEMABINDING
    AS  
        SELECT InventoryID, InventoryDate, EmployeeID, ProductID, Count
        FROM dbo.Inventories as i
GO

Create View vProducts WITH SCHEMABINDING
    AS  
        SELECT ProductID, ProductName, CategoryID, UnitPrice
        FROM dbo.Products as p
GO

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?

/*Use permissions on objects (here, tables) using Grant, Deny and tables to Public and Groups
*/
--First, the Deny Lines for the original tables
DENY SELECT ON Categories to Public;
DENY SELECT ON Employees to Public;
DENY SELECT ON Products to Public;
DENY SELECT ON Inventories to Public;

--Now, the grating permission to the views 
GRANT SELECT ON vCategories to Public; 
GRANT SELECT ON vEmployees to Public; 
GRANT SELECT ON vProducts to Public; 
GRANT SELECT ON vInventories to Public; 

-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!

/*Important point here is to not put the ORDER BY in the view script.
ORDER BY should go when the select statement is called
*/


GO
CREATE VIEW vProdCat
    AS
        SELECT vc.CategoryName as Category , vp.ProductName as Product, vp.UnitPrice as 'Price per Unit' FROM vProducts as vp
        INNER JOIN vCategories as vc
        ON vp.CategoryID = vc.CategoryID  --ORDER BY is not performed here, find it down in the Select statements at the end of the file.
GO

-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!

GO
CREATE VIEW vInvCountDate 
    AS
        SELECT vp.ProductName as Product, vi.InventoryDate as 'Date', vi.Count as 'Count' FROM vProducts as vp 
        JOIN vInventories as vi 
        ON vp.ProductID = vi.ProductID --ORDER BY again down at the end of the script

GO


-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!

-- Here is are the rows selected from the view:

-- InventoryDate	EmployeeName
-- 2017-01-01	    Steven Buchanan
-- 2017-02-01	    Robert King
-- 2017-03-01	    Anne Dodsworth

GO
CREATE VIEW vInvEmp 
    AS
        SELECT DISTINCT vi.InventoryDate as 'Date', ve.EmployeeFirstName + ' ' + ve.EmployeeLastName as 'Name'
        FROM vInventories as vi 
        INNER JOIN vEmployees as ve
        ON vi.EmployeeID = ve.EmployeeID

GO

-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!

GO
--Use a bridge table
CREATE VIEW vInventoryCheck 
    AS 
        SELECT  vc.CategoryName as Category, vp.ProductName as Product, vi.InventoryDate as 'Date', vi.Count as COUNT
        FROM vProducts as vp 
        INNER JOIN vCategories as vc ON vc.CategoryID = vp.CategoryID
        INNER JOIN vInventories as vi ON vp.ProductID = vi.ProductID 
GO

-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!
GO
--Use more bridge tables
CREATE VIEW vInventoryCheckEmp 
    AS 
        SELECT vc.CategoryName as Category, vp.ProductName as Product, vi.InventoryDate as 'Date', vi.Count as COUNT, ve.EmployeeFirstName + ' ' + ve.EmployeeLastName as 'Name'
        FROM vProducts as vp
        INNER JOIN vCategories as vc ON vc.CategoryID = vp.CategoryID
        INNER JOIN vInventories as vi ON vp.ProductID = vi.ProductID 
        INNER JOIN vEmployees as ve ON vi.EmployeeID = ve.EmployeeID
GO

-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 
GO
--WHERE selection at end of script, called when we call the view up.  

CREATE VIEW vInventoryCheckEmpDetail
    AS 
        SELECT vc.CategoryName as Category, vp.ProductName as Product, vi.InventoryDate as 'Date', vi.Count as COUNT, ve.EmployeeFirstName + ' ' + ve.EmployeeLastName as 'Name'
        FROM vProducts as vp 
        INNER JOIN vCategories as vc ON vc.CategoryID = vp.CategoryID
        INNER JOIN vInventories as vi ON vp.ProductID = vi.ProductID 
        INNER JOIN vEmployees as ve ON vi.EmployeeID = ve.EmployeeID
GO

-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

--Self Join!  In a view!  Copied right from the last assignment 

GO
CREATE VIEW vManagerEmployee
    AS 
        SELECT m.EmployeeFirstName + ' ' +  m.EmployeeLastName as 'Manager', e.EmployeeFirstName + ' ' + e.EmployeeLastName as 'Employee Name'
        FROM Employees as e
        INNER JOIN Employees as m ON m.EmployeeID = e.ManagerID 
GO  


-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views? Also show the Employee's Manager Name and order the data by 
-- Category, Product, InventoryID, and Employee.

GO
CREATE VIEW vMasterInventory 
    AS
        SELECT  --Using the multiple lines to declare each column because there are far too many for a single line here.  
            vc.CategoryID as 'Category ID',
            vc.CategoryName as 'Category',
            vp.ProductID as 'Product ID',
            vp.ProductName as 'Product',
            vp.UnitPrice as 'Unit Price',
            vi.InventoryID as 'Inventory ID',
            vi.InventoryDate as 'Date',
            vi.Count as 'Count',
            ve.EmployeeID as 'Employee ID',
            ve.EmployeeFirstName + ' ' + EmployeeLastName as 'Name',
            Choose(ve.ManagerID, 'Davolio', 'Andrew Fuller', 'Leverling', 'Peacock', 'Steven Buchanen', 'Suyama', 'King', 'Callahan', 'Dodsworth') as 'Manager'  --Good opportunity to use the choose function to avoid the self-join 
        FROM vCategories as vc 
        JOIN vProducts as vp ON vc.CategoryID = vp.CategoryID
        JOIN vInventories as vi ON vi.ProductID = vp.ProductID 
        JOIN vEmployees as ve ON vi.EmployeeID = ve.EmployeeID




GO


-- Test your Views (NOTE: You must change the your view names to match what I have below!)
Print 'Note: You will get an error until the views are created!'
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * FROM vProdCat ORDER BY Category, Product --Order by uses aliases established with view, not original column names
Select * From [dbo].[vInvCountDate] ORDER BY Product, 'Date', Count
Select * From [dbo].[vInvEmp] ORDER BY 'Date'
Select * From [dbo].[vInventoryCheck] ORDER BY Category, Product, 'Date', Count
Select * From [dbo].[vInventoryCheckEmp] ORDER BY 'Date', Category, Product, 'Name'
Select * From [dbo].[vInventoryCheckEmpDetail] WHERE Product IN ('Chai', 'Chang') ORDER BY Category, 'Date', 'Name'
Select * From [dbo].[vManagerEmployee] ORDER BY 'Manager', 'Employee Name'
Select * From [dbo].[vMasterInventory] ORDER BY 'Category ID', 'Product ID','Inventory ID', 'Name'

/***************************************************************************************/
