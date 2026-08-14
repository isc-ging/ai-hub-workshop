Class EmailInterop.Router extends Ens.BusinessProcess
{
    Property EmailParserTarget As Ens.DataType.ConfigName;

    Property OrderTarget As Ens.DataType.ConfigName;

    Property SupportTarget As Ens.DataType.ConfigName;

    Property HumanTarget As Ens.DataType.ConfigName;

    Parameter SETTINGS = "EmailParserTarget:Basic,OrderTarget:Basic,SupportTarget:Basic,HumanTarget:Basic";

    Method OnRequest(pInput As EmailInterop.Messages.MailMessage) As %Status{

        set status = ..SendRequestSync(..EmailParserTarget,pInput, .pOutput )


        Set target = $CASE(pOutput.Category,
            "Order":   ..OrderTarget,
            "Support": ..SupportTarget,
            "Other": ..HumanTarget,
             : ..HumanTarget
        )



        $$$LOGINFO("Email Has been categorised as "_pOutput.Category_"and is being routed to")


        set followUpRequest = pOutput.%ConstructClone()

        set status = ..SendRequestAsync(target, followUpRequest, 1)

        return status

    }

    Method OnResponse(pInput As %Persistent) As %Status{
        return $$$OK
    }


Storage Default
{
<Data name="RouterDefaultData">
<Subscript>"Router"</Subscript>
<Value name="1">
<Value>EmailParserTarget</Value>
</Value>
<Value name="2">
<Value>OrderTarget</Value>
</Value>
<Value name="3">
<Value>SupportTarget</Value>
</Value>
<Value name="4">
<Value>HumanTarget</Value>
</Value>
</Data>
<DefaultData>RouterDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
