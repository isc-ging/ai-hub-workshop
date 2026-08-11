Class Warehouse.Utils.Emails Extends %RegisteredObject
{

    XData EmailOne [MimeType = "application/json"]
    {
        {
            "From": "purchasing@northwind.example",
            "Subject": "Temperature sensors",
            "Body": "Hi,\n\nCould you arrange an order for 20 of the TS-400 temperature sensors?\n\nPlease send them to our usual warehouse.\n\nThanks,\nSarah"
        }
    }

    ClassMethod ReturnEmail(id As %Integer) As %DynamicObject
    {
        set emailname = $CASE(id, 1:"EmailOne")

        Set xdata = ##class(%Dictionary.XDataDefinition).%OpenId("Warehouse.Utils.Emails||"_emailname)

        return {}.%FromJSON(xdata.Data)
    } 
    ClassMethod PrintEmail(email As %DynamicObject) As %String
    {
        Set body = "From: "_email.From_$char(13,10)
        Set body = body_"Subject: "_email.Subject_$char(13,10)
        Set body = body_$char(13,10)
        Set body = body_$replace(email.Body, $char(10), $char(13,10))

        w body
    }

}
