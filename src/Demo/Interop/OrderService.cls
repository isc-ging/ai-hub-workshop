Class Demo.Interop.OrderService Extends Ens.BusinessService
{

Property TargetProcess As %String [ InitialExpression = "Demo.Interop.OrderRouter" ];

Method OnProcessInput(pInput As %Library.RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
    Set tRaw = pInput
    Set tProductId = pInput.productId
    Set tQuantity  = pInput.quantity

    Set tRequest = ##class(Demo.Interop.OrderRequest).%New()
    Set tRequest.ProductId = tProductId
    Set tRequest.Quantity  = tQuantity

    Set tSC = ..SendRequestSync(..TargetProcess, tRequest, .tResponse)
    If $$$ISERR(tSC) Quit tSC

    Set pOutput = tResponse
    Quit tSC
}

}
