---
slug: add-tools
id: evrw3d9klx2b
type: challenge
title: Add Tools
difficulty: ""
enhanced_loading: null
---

Our agent is already providing value by extracting user intent from unstructured data. What if it could add insights from our data? Let's give our agent some tools.

To begin, we just want the agent to access the relevant data for the requests, this will speed up the process for the Procurement manager, as the data can be given directly, along with user intent.

In [VS Code](tab-0) create a new class in `src/Warehouse` called `LookupTools.cls`.


To create agent tools, the class should extend from `%AI.Tool`. After this, all Class Methods, Methods and Query Components will be serialised into agent tools.

Using the SQL Explorer in the Management Portal, try to create the following tools using Query components.

    - Look up the customer by email from `Warehouse_Data.Customer`
    - Get a list of all products sold
    -

Query Components should return `%SQLQuery` and should have the keyword `[SqlProc]` to make them runnable.


<details>
<summary>Hint</summary>

The first tool looks like the following:

```
Class Warehouse.AI.LookUpTools extends %AI.Tool
{

Query LookUpCustomer(pEmail As %String) As %SQLQuery [ SqlProc ]
{
    SELECT
    ID, CustomerId, DefaultDeliveryAddress, Organisation, Status, Trusted
    FROM Warehouse_Data.Customer WHERE ContactEmail = :pEmail
}

}
```
</details>


<details>
<summary>Full Solution</summary>

The class should look as follows:

```objectscript
Class Warehouse.AI.LookupTools Extends %AI.Tool
{

    Query LookUpCustomer(pEmail As %String) As %SQLQuery [ SqlProc ]
    {
        SELECT
        ID, CustomerId, DefaultDeliveryAddress, Organisation, Status, Trusted
        FROM Warehouse_Data.Customer WHERE ContactEmail = :pEmail
    }

    Query GetProducts() As %SQLQuery [SqlProc]{
        SELECT
        ID, Active, Category, Name, OnOrder, Quantity, ReorderLevel, SKU, UnitPrice
        FROM Warehouse_Data.Product
    }

    Query GetOrders(pCustomerId As %String ="", pCustomerEmail As %String = "") As %SQLQuery [SqlProc]{

        SELECT
        ID, DeliveryAddress, OrderDate
        FROM Warehouse_Data.Order WHERE Customer=:pCustomerId OR Customer->ContactEmail=:pCustomerEmail
    }

}

```
</details>

## Making tool calls visible with policies

Policies can be added to tools, providing an authorization layer (is this tool call allowed?) or an audit layer (logging tool results). Here, we just want a way to see the tool calls our agent makes.

A basic audit policy that prints the results is already available in src/Warehouse/AI. You can take a look at how this works.

To combine the policy with the tools, the easiest way is to use a class which extends `%AI.ToolSet`. A toolset is a collection of tools, external MCP server connections, and policies. Toolsets can be used to combine, filter, include or exclude tools from different sources.

The toolset definition occurs in an XML XData block. The outline of this is already available in src/Warehouse.AI.ToolSet.

Add the Audit policy to the policies block and our Lookup tools class as an include block. The syntax for these is given below:

```xml
<!-- Add to the Policies block-->
<Audit Class="Warehouse.AI.ConsoleAudit"/>

<!-- Add Directly to the <ToolSet> block-->
<Include Class="Warehouse.AI.LookupTools"/>
```

When you have done this, save the file.

## Adding Tools to the Agent


Return to our `src/Warehouse/AI/Agent.cls` file. From here, we can add tools a comma separated string list in the TOOLSETS parameter:

```
Parameter TOOLSETS = "Warehouse.AI.ToolSet";
```

While you are here, add the following function to make using the agent easier:

```objectscript
ClassMethod ProcessEmail(pEmail as %String) As %DynamicObject
{
    // Create an initialise agent
    set agent = ##class(Warehouse.AI.Agent).%New()
    set sc = agent.%Init()

    if $$$ISERR(sc){ quit sc} // Error handling

    set session = agent.CreateSession()

    set response = agent.Chat(session, pEmail)

    do session.%Save() // Save session to DB (Can access later)

    set responseObj = ##class(Warehouse.Utils.JSON).ExtractJSON(response.Content)

    return responseObj

}
```

Ensure you save the file to trigger auto-compiling.

## Try the agent again

Test the agent (via the process email function defined above) with the second email. To print the email use: `do ##class(Warehouse.Utils.Emails).PrintEmail(2)`, and to get the full version use `##class(Warehouse.Utils.Emails).ReturnEmailString(2)`.

Take a look at the responseObj with `zwrite`. You should see a structured description fo the email.

