Class Warehouse.AI.LookupTools Extends %AI.Tool
{

Query LookUpCustomer(pEmail As %String) As %SQLQuery [ SqlProc ]
{
    SELECT 
    ID, CustomerId, DefaultDeliveryAddress, Organisation, Status, Trusted
    FROM Warehouse_Data.Customer WHERE ContactEmail = :pEmail
}

Query GetProducts() As %SQLQuery [SqlProc]{
    SELECT 
    ID, Active, Category, Name, OnOrder, Quantity, ReorderLevel, SKU, UnitPrice
    FROM Warehouse_Data.Product
}

Query GetOrders(pCustomerId As %String ="", pCustomerEmail As %String = "") As %SQLQuery [SqlProc]{
    
    SELECT 
    ID, DeliveryAddress, OrderDate, Status
    FROM Warehouse_Data.Order WHERE Customer=:pCustomerId OR Customer->ContactEmail=:pEmail
} 


}
