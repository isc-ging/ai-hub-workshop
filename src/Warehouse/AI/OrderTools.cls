Class Warehouse.AI.OrderTools extends %AI.Tool
{

    Property Trusted As %Boolean [InitialExpression = 0]; 

    Property LookedUp As %Boolean [InitialExpression = 0];

    Property NewCustomer As %Boolean [InitialExpression = 0];

    Property CustomerEmail As %String [InitialExpression = 0]; 

    /// Retrieve the product information for a given product
    Query GetStock(pSKU) As %SQLQuery [SQLProc]
    {
        SELECT 
        Name, Quantity, UnitPrice, OnOrder 
        FROM Warehouse.Product
        WHERE SKU = :pSKU
    }


    Method LookUpCustomer(pEmail As %String) As %String{

        set sql = "SELECT Trusted FROM Warehouse.Customer WHERE Email = ? "

        set stmt = ##class(%SQL.Statement).New()
        set sc = stmt.%Prepare(sql)
        if 'sc{
            quit sc
        }

        set rs = stmt.%Execute(pEmail)

        if 'rs.%Next(){
            set ..NewCustomer = 1
            quit "The customer was not found in the database and must be a new customer. This requires human review."
        }

        set trusted = rs.%Get("Trusted")

        if rs.%Next(){
            quit $$$ERROR($$$GeneralError, "Multiple customers found for email: "_pEmail)
        }

        set ..Trusted = trusted

        if trusted{
            return "Customer is trusted, you may process the transaction"
        }
        else{
            return "Customer is untrusted, send for human review"
        }
    }
     


    Method ProcessTransaction(pOrders As %DynamicArray( ELEMENTTYPE="Warehouse.Email.AI.Utils.OrderItem" )) As %Status
    {

        if '..Trusted{
            if '..LookedUp{
                quit $$$ERROR($$$GeneralError,"Please look up customer before processing transaction")
            }
            quit $$$ERROR($$$GeneralError, "Customer is not trusted. ")
        }

        set sc = $$$OK
        set iter = pOrders.%GetIterator()
        while iter.%GetNext(.key, .value) {
            set orderSC = ##class(Warehouse.Utils.ProcessOrder).ProcessOrder(value.Id, value.Quantity)
            if $$$ISERR(orderSC) {
                set msg = "Order "_value.Id_" failed: "_$System.Status.GetErrorText(orderSC)
                set sc = $$$ADDSC(sc, $$$ERROR($$$GeneralError, msg))
            }
        }
        return sc
    }  

    


}