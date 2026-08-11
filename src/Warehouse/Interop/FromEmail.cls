Class Warehouse.Interop.FromEmail extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.EMail.InboundAdapter";

Method OnProcessInput(pInput As %Net.MailMessage) As %Status
{
    Set sc = ##class(Warehouse.Interop.Messages.MailMessage).FromNetMail(pInput, .msg)
    Return:$$$ISERR(sc) sc

    $$$LOGINFO("Received email from: " _ msg.MailFrom _ " subject: " _ msg.Subject)

    set st = ..SendRequestAsync("Router",msg)

    Return sc
}

}
