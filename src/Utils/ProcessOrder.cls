Class Utils.ProcessOrder extends %RegisteredObject
{
    ClassMethod ProcessOrder(pId As %String, quantity As %Integer, senderEmail As %String) As %Status
    {
        set sc = $$$OK

        set product = ##class(Warehouse.Product).%OpenId(pId, , .sc)
        $$$ThrowOnError(sc)
        if '$isobject(product) {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Product not found: " _ pId))
        }

        TSTART

        try {
            set product.Quantity = product.Quantity - quantity
            $$$ThrowOnError(product.%Save())

            set txn = ##class(Warehouse.Transactions).%New()
            set txn.Product = product
            set txn.Date = $HOROLOG
            set txn.Quantity = quantity
            set txn.Total = quantity * product.UnitPrice
            $$$ThrowOnError(txn.%Save())

            TCOMMIT
        } catch ex {
            if $TLevel > 0 {
                TROLLBACK
            }
            return ex.AsStatus()
        }

        do ##class(Utils.ProcessOrder).SendConfirmationEmail(senderEmail)
        return $$$OK
    }

    ClassMethod SendConfirmationEmail(senderEmail As %String) As %Status
    {
        Set sc = $$$OK
        // do something
        Return sc
    }

}
