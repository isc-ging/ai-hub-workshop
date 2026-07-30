Class Demo.Interop.OrderRouter Extends Ens.BusinessProcess [ ClassType = persistent ]
{

Property TargetOperation As %String [ InitialExpression = "Demo.Interop.ToSupplierOperation" ];

Method OnRequest(pRequest As Demo.Interop.OrderRequest, Output pResponse As Ens.Response) As %Status
{
    Set tSC = $$$OK
    Set pResponse = ##class(Demo.Interop.OrderResponse).%New()

    &sql(SELECT sp.Supplier->ContactEmail, sp.Supplier->LeadTimeDays
         INTO :tEmail, :tLeadTime
         FROM Demo.SupplierProduct sp
         WHERE sp.Product = :pRequest.ProductId
         ORDER BY sp.IsPreferred DESC
         FETCH 1)

    If SQLCODE '= 0 {
        Set pResponse.StatusMessage = "No supplier found for product "_pRequest.ProductId
        Quit $$$OK
    }

    Set tSC = ..SendRequestSync(..TargetOperation, pRequest, .tOpResponse)
    If $$$ISERR(tSC) Quit tSC

    Set tProduct = ##class(Demo.Product).%OpenId(pRequest.ProductId)
    If $IsObject(tProduct) {
        Set tProduct.OnOrder = tProduct.OnOrder + pRequest.Quantity
        Set tSC = tProduct.%Save()
        If $$$ISERR(tSC) Quit tSC
    }

    Set pResponse.LeadTimeDays = tLeadTime
    Set pResponse.StatusMessage = "Order sent, expected lead time is "_tLeadTime_" days"

    Quit tSC
}

Storage Default
{
<Data name="OrderRouterDefaultData">
<Subscript>"OrderRouter"</Subscript>
<Value name="1">
<Value>TargetOperation</Value>
</Value>
</Data>
<DefaultData>OrderRouterDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
