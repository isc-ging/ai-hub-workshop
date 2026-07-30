Class Demo.Interop.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Demo.Interop.Production" LogGeneralTraceEvents="false">
  <Description>Order routing production</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="OrderService" ClassName="Demo.Interop.OrderService" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetProcess">OrderRouter</Setting>
  </Item>
  <Item Name="OrderRouter" ClassName="Demo.Interop.OrderRouter" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetOperation">ToSupplierOperation</Setting>
  </Item>
  <Item Name="ToSupplierOperation" ClassName="Demo.Interop.ToSupplierOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
