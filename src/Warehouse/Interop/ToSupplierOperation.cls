Class Warehouse.Interop.ToSupplierOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method SendOrder(pRequest As Warehouse.Interop.OrderRequest, Output pResponse As Warehouse.Interop.OrderResponse) As %Status
{
    Set pResponse = ##class(Warehouse.Interop.OrderResponse).%New()
    Set pResponse.StatusMessage = "Order dispatched"
    Quit $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="Warehouse.Interop.OrderRequest">
    <Method>SendOrder</Method>
  </MapItem>
</MapItems>
}

}
