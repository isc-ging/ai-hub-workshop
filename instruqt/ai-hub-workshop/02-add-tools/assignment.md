---
slug: add-tools
id: evrw3d9klx2b
type: challenge
title: Giving the agent tools
notes:
- type: text
  contents: |-
    Our agent is already providing value by extracting user intent from unstructured data. What if it could add insights from our data?

    Let's give our agent some tools.

    Agent tools are functions which the agent can autonomously use. LLMs have been trained to respond with structured outputs to request tool calls, with any number of parameters. The details of the tools available to the agent, including name, input parameters and description are automatically given to the agent in the system prommpt

    > **Click the right arrow for more information**
- type: text
  contents: In AI Hub, it is easy to create agent tools from InterSystems IRIS classes.
    Methods, ClassMethods and Query components can all become tool components. As
    such you can write tools in ObjectScript, SQL or Embedded Python. Of course you
    could also call outs to other languages, or add external MCP servers into InterSystems
    IRIS.
tabs:
- id: osn16gj0ojw9
  title: Code
  type: service
  hostname: ai-hub-eap
  path: ?folder=/home/irisowner/ai-hub-workshop/src/EmailAI
  port: 8888
- id: hyi7lktxnmou
  title: IRIS
  type: terminal
  hostname: ai-hub-eap
  cmd: su - irisowner -s /usr/irissys/bin/iris session iris
- id: ziffqmhjcvgc
  title: IRIS
  type: service
  hostname: ai-hub-eap
  path: /csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=USER
  port: 52773
difficulty: ""
enhanced_loading: null
---

To begin, we just want the agent to access the relevant data for the requests, this will speed up the process for the Procurement manager, as the data can be given along with user intent. You'll see that we've added a couple of new classes. We'll get to them shortly.


# Task 1: Creating the tool class

**In [VS Code](tab-0) create a new class in `src/EmailAI` called `LookUpTools.cls`.**

To create agent tools, the class should extend from `%AI.Tool`. After this, all Class Methods, Methods and Query Components will be serialised into agent tools.

**Using the SQL Explorer in [IRIS](tab-2) to find the relevant SQL tables, try to create the following tools using `Query` components.**

    - Look up the customer by email from `Warehouse.Customer`
    - Get a list of all products sold
    - Retrieve all the orders for a given customer

Query Components should return `%SQLQuery` and should have the keyword `[SqlProc]` to make them callable as a function.


<details>
<summary style="color:#FFA489;font-weight:bold;">Hint</summary>

The first tool looks like the following:

```
Class EmailAI.LookUpTools extends %AI.Tool
{

Query LookUpCustomer(pEmail As %String) As %SQLQuery [ SqlProc ]
{
    SELECT
    ID, CustomerId, DefaultDeliveryAddress, Organisation, Status, Trusted
    FROM Warehouse.Customer WHERE ContactEmail = :pEmail
}

}
```
</details>


<details>
<summary style="color:#C0392B;font-weight:bold;">Full Solution</summary>

The class should look something like this:

```objectscript
Class EmailAI.LookUpTools Extends %AI.Tool
{

    Query LookUpCustomer(pEmail As %String) As %SQLQuery [ SqlProc ]
    {
        SELECT
        ID, CustomerId, DefaultDeliveryAddress, Organisation, Status, Trusted
        FROM Warehouse.Customer WHERE ContactEmail = :pEmail
    }

    Query GetProducts() As %SQLQuery [SqlProc]{
        SELECT
        ID, Active, Category, Name, OnOrder, Quantity, ReorderLevel, SKU, UnitPrice
        FROM Warehouse.Product
    }

    Query GetOrders(pCustomerId As %String ="", pCustomerEmail As %String = "") As %SQLQuery [SqlProc]{

        SELECT
        ID, DeliveryAddress, OrderDate
        FROM Warehouse.Order WHERE Customer=:pCustomerId OR Customer->ContactEmail=:pCustomerEmail
    }

}

```
</details>

## (Optional) Task 2: Look at the agent view of the tool

This step isn't required, but it can be helpful to understand how agent tools work a bit better. Agent tools serialise into JSON Objects, and are sent to the agent.

To take a look at our tool class in this format, switch to the [Shell](tab-1) tab and run the following.

```run
set tools = ##class(EmailAI.LookUpTools).%New()
set toolObj = tools.%Discover()
zw toolObj
```

You will see the tool definition in JSON format, including the name and the input parameters. You may also see an empty `Description`. This description is taken from the class description defined with `///` comments above the class. You can also add descriptions to individual parameters.

In this case, a lack of description is probably fine — the tools are simple and the tool names are clear by themselves. However, adding descriptions can be crucial to give the agents context around when and how to use a tool.


## Task 3: Combining the tool with policies

Policies can be added to tools, providing an authorization layer (is this tool call allowed?) or an audit layer (logging tool results). Here, we just want a way to see the tool calls our agent makes.

A basic audit policy that prints the results is already available in src/EmailAI. You can take a look at how this works.

To combine the policy with the tools, the easiest way is to use a class which extends `%AI.ToolSet`. A toolset is a collection of tools, external MCP server connections, and policies. Toolsets can be used to combine, filter, include or exclude tools from different sources.

The toolset definition occurs in an XML XData block. The outline of this is already available in src/EmailAI/ToolSet.cls.

Add the Audit policy to the policies block and our Lookup tools class as an include block. The syntax for these is given below:

```xml
<!-- Add to the Policies block-->
<Audit Class="EmailAI.ConsoleAudit"/>
```


```xml
<!-- Add Directly to the <ToolSet> block-->
<Include Class="EmailAI.LookUpTools"/>
```

When you have done this, save the file.

## Task 4: Add the Tool to the Agent


Return to our `src/EmailAI/Agent.cls` file. From here, we can add tools a comma separated string list in the TOOLSETS parameter:

```
Parameter TOOLSETS = "EmailAI.ToolSet";
```

While you are here, add the following function to make using the agent easier:

```objectscript
ClassMethod ProcessEmail(pEmail as %String) As %DynamicObject
{
    // Create an initialise agent
    set agent = ##class(EmailAI.Agent).%New()
    set sc = agent.%Init()

    if $$$ISERR(sc){ quit sc} // Error handling

    set session = agent.CreateSession()

    set response = agent.Chat(session, pEmail)

    do session.%Save() // Save session to DB (Can access later)

    set responseObj = ##class(Utils.JSON).ExtractJSON(response.Content)

    return responseObj

}
```

Ensure you save the file to trigger auto-compiling.

## Task 5: test the agent again

Test the agent (via the process email function defined above) with the second email. To print the email use: `do ##class(Utils.Emails).PrintEmail(2)`, and to get the full version use `##class(Utils.Emails).ReturnEmailString(2)`.

Take a look at the responseObj with `zwrite`. You should see a structured description fo the email.

