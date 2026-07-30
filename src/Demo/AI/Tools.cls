Class Demo.AI.Tools extends %AI.Tool
{

    Query GetProducts() As %SQLQuery [SqlProc]
    {
        SELECT 
        SKU, Category, Name, Quantity 
        FROM Demo.Product
    }

    Query GetProductToReorder() As %SQLQuery [SqlProc]
    {
        SELECT 
        ID, Name, Quantity, ReorderLevel, SKU, UnitPrice
        FROM Demo.Product WHERE Quantity < ReorderLevel

    }

    Query GetSalesByProduct() As %SQLQuery [SqlProc]
    {
        SELECT 
        Product AS ID, 
        Product->Name AS Name, 
        Sum(Quantity) AS "Total (Units)", 
        Sum(Total) As "Total ($)"
        FROM Demo.Transactions 
        GROUP BY Product 
    }

    ClassMethod SetStockLoss(productId, reason, delta) As %Status
    {
        set product = ##class(Demo.Product).%OpenId(productId, , .sc)
        if $$$ISERR(sc) return sc
        if '$isobject(product) return $$$ERROR($$$GeneralError, "Product not found: " _ productId)

        set product.Quantity = product.Quantity - delta
        set sc = product.%Save()
        if $$$ISERR(sc) return sc

        set movement = ##class(Demo.StockMovement).%New()
        set movement.Product = product
        set movement.Delta = -delta
        set movement.Reason = reason
        set movement.Reporter = $USERNAME
        set sc = movement.%Save()
        if $$$ISERR(sc) return sc

        Return $$$OK
    }

    ClassMethod OrderProduct(productId, quantity) As %String
    {
        
    set st =  ##class(Ens.Director).CreateBusinessService("OrderService", .service)
    set input = {"productId":(productId), "quantity":(quantity)}

    set st = service.ProcessInput(input, .output)
    return output.StatusMessage

    }

}