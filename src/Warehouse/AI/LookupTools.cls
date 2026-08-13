Class Warehouse.AI.LookupTools Extends %AI.Tool
{

/// Look up customer ID based on their email
Query LookUpCustomer(pEmail As %String) As %SQLQuery [ SqlProc ]
{
    SELECT 
    ID, CustomerId, DefaultDeliveryAddress, Organisation, Status, Trusted
    FROM Warehouse_Data.Customer WHERE ContactEmail = :pEmail
}

/// Retrieve a list of products
Query GetProducts() As %SQLQuery [SqlProc]{
    SELECT 
    ID, Active, Category, Name, OnOrder, Quantity, ReorderLevel, SKU, UnitPrice
    FROM Warehouse_Data.Product
}


/// Get orders based on Customer ID or Email
Query GetOrders(pCustomerId As %String ="", pCustomerEmail As %String = "") As %SQLQuery [SqlProc]{
    
    SELECT 
    ID, DeliveryAddress, OrderDate
    FROM Warehouse_Data.Order WHERE Customer=:pCustomerId OR Customer->ContactEmail=:pCustomerEmail
} 


}
