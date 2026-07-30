Class Demo.Interop.ToSupplierOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method SendOrder(pRequest As Demo.Interop.OrderRequest, Output pResponse As Demo.Interop.OrderResponse) As %Status
{
    Set pResponse = ##class(Demo.Interop.OrderResponse).%New()
    Set pResponse.StatusMessage = "Order dispatched"
    Quit $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Demo.Interop.OrderRequest">
    <Method>SendOrder</Method>
  </MapItem>
</MapItems>
}

}
