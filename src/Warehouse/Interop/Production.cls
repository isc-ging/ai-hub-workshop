Class Warehouse.Interop.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Warehouse.Interop.Production" LogGeneralTraceEvents="false">
  <Description>Order routing production</Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="FromEmail" Category="" ClassName="Warehouse.Interop.FromEmail" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="POP3Server">mailpit</Setting>
    <Setting Target="Adapter" Name="POP3Port">1110</Setting>
    <Setting Target="Adapter" Name="Credentials">mailpit</Setting>
    <Setting Target="Adapter" Name="MatchTo">@warehouse.com</Setting>
  </Item>
  <Item Name="ToEmailParsingAgent" Category="" ClassName="Warehouse.Interop.BO.ToEmailParsingAgent" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Router" Category="" ClassName="Warehouse.Interop.Router" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="EmailParserTarget">ToEmailParsingAgent</Setting>
    <Setting Target="Host" Name="HumanTarget">ToHumanReview</Setting>
    <Setting Target="Host" Name="OrderTarget">ToOrderAgent</Setting>
  </Item>
  <Item Name="ToOrderAgent" Category="" ClassName="Warehouse.Interop.BO.ToOrderAgent" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="ToHumanReview" Category="" ClassName="Warehouse.Interop.BO.ToHumanReview" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="SMTPServer">mailpit</Setting>
    <Setting Target="Adapter" Name="SMTPPort">1025</Setting>
    <Setting Target="Adapter" Name="From">warehouse-ai@warehouse.local</Setting>
  </Item>
</Production>
}

}
