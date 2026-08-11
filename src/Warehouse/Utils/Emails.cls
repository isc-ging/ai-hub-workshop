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

    XData EmailTwo [MimeType = "application/json"]
    {
        {
            "From": "purchasing@northwind.example",
            "Subject": "Repeat order",
            "Body": "Hi,\n\nCan we have another batch of the temperature sensors we ordered last time?\n\nWe need them at the usual location.\n\nThanks,\nSarah"
        }
    }

    XData EmailThree [MimeType = "application/json"]
    {
        {
            "From": "purchasing@northwind.example",
            "Subject": "Order request",
            "Body": "Hi,\n\nPlease order 20 TS-400 temperature sensors and send them to our usual warehouse.\n\nThanks,\nSarah"
        }
    }

    XData EmailFour [MimeType = "application/json"]
    {
        {
            "From": "purchasing@northwind.example",
            "Subject": "Large sensor order",
            "Body": "Hi,\n\nPlease order 40 TS-400 temperature sensors and send them to our usual warehouse.\n\nThanks,\nSarah"
        }
    }

    XData EmailFive [MimeType = "application/json"]
    {
        {
            "From": "purchasing@northwind.example",
            "Subject": "Order and new address",
            "Body": "Hi,\n\nPlease order 20 TS-400 sensors.\n\nDo not use our usual warehouse. Send them to:\n\nTemporary Project Site\n14 Example Road\nEdinburgh\n\nThanks,\nSarah"
        }
    }

    ClassMethod ReturnEmail(id As %Integer) As %DynamicObject
    {
        set emailname = $CASE(id, 1:"EmailOne", 2:"EmailTwo", 3:"EmailThree", 4:"EmailFour", 5:"EmailFive")

        Set xdata = ##class(%Dictionary.XDataDefinition).%OpenId("Warehouse.Utils.Emails||"_emailname)

        return {}.%FromJSON(xdata.Data)
    }

    ClassMethod ReturnEmailString(id){
        set obj = ##class(Warehouse.Utils.Emails).ReturnEmail(id)
        return obj.%ToJSON()
    }

    ClassMethod PrintEmail(id AS %Integer) As %String
    {
        set email = ##class(Warehouse.Utils.Emails).ReturnEmail(id)
        Set body = "From: "_email.From_$char(13,10)
        Set body = body_"Subject: "_email.Subject_$char(13,10)
        Set body = body_$char(13,10)
        Set body = body_$replace(email.Body, $char(10), $char(13,10))

        w body
    }

}
