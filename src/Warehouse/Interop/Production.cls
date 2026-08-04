Class Warehouse.Interop.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Warehouse.Interop.Production" LogGeneralTraceEvents="false">
  <Description>Order routing production</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="OrderService" ClassName="Warehouse.Interop.OrderService" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetProcess">OrderRouter</Setting>
  </Item>
  <Item Name="OrderRouter" ClassName="Warehouse.Interop.OrderRouter" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetOperation">ToSupplierOperation</Setting>
  </Item>
  <Item Name="ToSupplierOperation" ClassName="Warehouse.Interop.ToSupplierOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
