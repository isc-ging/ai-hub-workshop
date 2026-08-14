---
slug: give-autonomy
id: cybeey7v6txt
type: challenge
title: Giving the agent autonomy
tabs:
- id: 3ozh5wlxjz3x
  title: Code
  type: service
  hostname: ai-hub-eap
  path: ?folder=/home/irisowner/ai-hub-workshop/src
  port: 8888
- id: szr5bb0ezov7
  title: IRIS
  type: terminal
  hostname: ai-hub-eap
  cmd: su - irisowner -s /usr/irissys/bin/iris session iris
- id: jd9bqj56fsfs
  title: IRIS
  type: service
  hostname: ai-hub-eap
  path: /csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=USER
  port: 52773
difficulty: ""
enhanced_loading: null
---

The previous step showed how we can create agent tools from basic SQL queries by extending `%AI.Tool`. In fact, all methods and class methods in these classes also become discoverable tools. As such, you can write advanced tools in ObjectScript or Embedded Python, giving the agent advanced control.

In this step, we will create tools to allow our emailing agent to create, validate and save a draft order, giving the agent autonomy.

> [!NOTE]
> One could build a SQL tool which allows the agent to write its own queries against the database. However, this could be security risk and should be carefully controlled with roles-based access controls or policies. Using individual targeted query tools mitigates this risk.


## Stateful tools

As with most object-oriented coding languages, functions in ObjectScript can either be a *static* class method, or an *instance* method. As a very brief introduction, this statement has two main practical consequences:

1. Methods require an object to be instantiated from the class to be used, whereas class methods can be used from anywhere. For example:

```objectscript
// Using a class method
do ##class(Sample.Demo).MyClassMethod()

// Using a Method
set obj = ##class(Sample.Demo).%New()
do obj.MyMethod()
```

2. Methods can access class properties. For example:

```objectscript

Class Sample.Demo extends %RegisteredObject
{
    Property Name As %String;

    Method GetName() As %String
    {
        return ..Name
    }

    Method SetName(pName As %String) As %Status
    {
        set ..Property = pName
    }

}

```

When using AI tools derived from extending `%AI.Tool`, tools can be stateful or non-stateful, which is equivalent to being a `static` method or `instance` method. The first part of the consideration — the instantiation — is irrelevant here, as this is handled in the background. However, the second part is highly relevant, tools created from methods, can save or retrieve information from class properties.

Tools are instantiated at the start of each session, and the tool properties are saved throughout the session, ensuring data saved to properties by one tool can the be available in the next.


### This example

We can make the most of this feature by providing separate tools for order **creation**, **validation** and **submission**. Between the sequential tool calls, the draft order will be saved as a Property of the tool class.

So, to begin, create a new file in `src/EmailAI` called `OrderTools.cls`. Then add the following:

- A property, `DraftOrder`, which should be an instance of `Warehouse.DraftOrder`. This class is available if you would like to take a look.
- A second property, `Validated`, a Boolean with an initial value of 0. This will provide a check to ensure the order has been deterministically validated.
- A parameter `REVIEWPRICETHRESHOLD`, and set it equal to 2000. This is a constant, which provides the threshold price above which an order *must* be reviewed.

Then create the following three methods. In the interests of time, the full methods are provided below, however feel free to write them yourself. The exact details of this logic are also not important, instead consider the key takeaways:
- Deterministic methods can be provided to AI agents
- Stateful features of using methods allow the same data to be accessed across different tools within the same session.


### Method Details:
- **CreateDraftOrder**:
    - Accepts the `ProductId`, `Quantity` of products, `CustomerId`, and an optional DeliveryAddress
    - Opens the `Warehouse.Data.Product` and `Warehouse.Data.Customer` objects by ID, returning an error string if either is not recognised.
    - Creates a new instance of `Warehouse.Data.DraftOrder`, and saves it to the `DraftOrder` property, setting Product, Customer, and Quantity.
    - Sets the `DraftOrder.DeliveryAddress` as the inputted delivery address, or, if none is inputted, to the Customer's `DefaultDeliveryAddress`

- **ValidateDraftOrder**:
    - Checks the `..DraftOrder.Quantity` is not greater than the quantity in stock (`..DraftOrder.Product.Quantity`).
    - Checks if total price (Order Quantity * `Product.UnitPrice`) exceeds `REVIEWPRICETHRESHOLD` — if so, `..DraftOrder.ReviewRequired` is set to 1
    - Checks the delivery address matches the customer's default address — if not, `..DraftOrder.ReviewRequired` is also set to 1
    - Checks that the product and customer are both correctly set.
    - Sets `..Validated = 1` on success.

- **SubmitDraftOrder**:
    - Checks the order has been validated using the `Validated` property, and returns a suitable error message if not.
    - Saves the `DraftOrder` property to the database with `.%Save()`




<details><summary style="color:#C0392B;font-weight:bold;">Methods</summary>

CreateDraftOrder:
```objectscript
    /// Enter the details for the draft order.
    /// The Customer Address is optional. If the order is being sent to the default customer delivery address, it should be left blank.
    /// After creation, the draft order MUST be validated, then submitted, or else it will be discarded.
    Method CreateDraftOrder(pProductId As %String, pQuantity As %Integer, pCustomerId As %String, pDeliveryAddress As %String ="") As %String
    {

        set product = ##class(Warehouse.Product).%OpenId(pProductId)
        if '$IsObject(product) quit "ERROR: Product ID not recognised"

        set customer = ##class(Warehouse.Customer).%OpenId(pCustomerId)
        if '$IsObject(customer) quit "ERROR: Customer ID not recognised"

        set ..DraftOrder = ##class(Warehouse.DraftOrder).%New()

        set ..DraftOrder.Product = product
        set ..DraftOrder.Quantity = pQuantity
        set ..DraftOrder.Customer = customer

        if (pDeliveryAddress = ""){
            set ..DraftOrder.DeliveryAddress = customer.DefaultDeliveryAddress
        }

        return "Draft order created, requires validation and submission or else it will be discarded"

    }
```


ValidateDraftOrder:
```objectscript
    /// MUST be run after creating the draft order
    Method ValidateDraftOrder() As %String{

        // Validated product is in stock
        if ..DraftOrder.Quantity> ..DraftOrder.Product.Quanity{
            quit "ERROR: Product low of stock, cannot continue with order"
        }

        // If order total is less than threshold, human review can be skipped
        if ((..DraftOrder.Quantity*..DraftOrder.Product.UnitPrice)>..#REVIEWPRICETHRESHOLD)
        {
            set ..DraftOrder.ReviewRequired = 1
        }

        // Check the delivery is to the known address for customer. If not, human review is required
        elseif ..DraftOrder.Customer.DefaultDeliveryAddress '= ..DraftOrder.DeliveryAddress{
            set ..DraftOrder.ReviewRequired = 1
        }
        else{
            set ..DraftOrder.ReviewRequired = 0
        }


        if '$IsObject(..DraftOrder.Product) || '$ISOBJECT(..DraftOrder.Customer){
            quit "ERROR: Required values not set"
        }

        set ..Validated = 1
        Return $$$OK

    }
```

SubmitDraftOrder:
```objectscript
    /// Must be run after the draft order is created and validated.
    /// Without this, the draft order will be discarded
    Method SubmitDraftOrder() As %String{

        if '..Validated {
            set errMsg = "ERROR: Order has not been validated. If ValidateOrder has not been run, run this before continuing. "
            set errMsg = errMsg _ "If it has been run, return the error to the user in structured output."

            quit errMsg
        }

        set st = ..DraftOrder.%Save()
        if st{
            return ..DraftOrder.%Id()
        } else{
            quit st
        }
    }
```

</details>


<details><summary style="color:#C0392B;font-weight:bold;">Full Class</summary>

```objectscript
Class EmailAI.OrderTools Extends %AI.Tool
{

    Property DraftOrder As Warehouse.DraftOrder;


    Property Validated As %Boolean [InitialExpression=0];


    /// Threshold price above which any order requires human review
    Parameter REVIEWPRICETHRESHOLD= 2000;

    /// Enter the details for the draft order.
    /// The Customer Address is optional. If the order is being sent to the default customer delivery address, it should be left blank.
    /// After creation, the draft order MUST be validated, then submitted, or else it will be discarded.
    Method CreateDraftOrder(pProductId As %String, pQuantity As %Integer, pCustomerId As %String, pDeliveryAddress As %String ="") As %String
    {

        set product = ##class(Warehouse.Product).%OpenId(pProductId)
        if '$IsObject(product) quit "ERROR: Product ID not recognised"

        set customer = ##class(Warehouse.Customer).%OpenId(pCustomerId)
        if '$IsObject(customer) quit "ERROR: Customer ID not recognised"

        set ..DraftOrder = ##class(Warehouse.DraftOrder).%New()

        set ..DraftOrder.Product = product
        set ..DraftOrder.Quantity = pQuantity
        set ..DraftOrder.Customer = customer

        if (pDeliveryAddress = ""){
            set ..DraftOrder.DeliveryAddress = customer.DefaultDeliveryAddress
        }

        return "Draft order created, requires validation and submission or else it will be discarded"

    }


    /// MUST be run after creating the draft order
    Method ValidateDraftOrder() As %String{

        // Validated product is in stock
        if ..DraftOrder.Quantity> ..DraftOrder.Product.Quanity{
            quit "ERROR: Product low of stock, cannot continue with order"
        }

        // If order total is less than threshold, human review can be skipped
        if ((..DraftOrder.Quantity*..DraftOrder.Product.UnitPrice)>..#REVIEWPRICETHRESHOLD)
        {
            set ..DraftOrder.ReviewRequired = 1
        }

        // Check the delivery is to the known address for customer. If not, human review is required
        elseif ..DraftOrder.Customer.DefaultDeliveryAddress '= ..DraftOrder.DeliveryAddress{
            set ..DraftOrder.ReviewRequired = 1
        }
        else{
            set ..DraftOrder.ReviewRequired = 0
        }


        if '$IsObject(..DraftOrder.Product) || '$ISOBJECT(..DraftOrder.Customer){
            quit "ERROR: Required values not set"
        }

        set ..Validated = 1
        Return $$$OK

    }

    /// Must be run after the draft order is created and validated.
    /// Without this, the draft order will be discarded
    Method SubmitDraftOrder() As %String{

        if '..Validated {
            set errMsg = "ERROR: Order has not been validated. If ValidateOrder has not been run, run this before continuing. "
            set errMsg = errMsg _ "If it has been run, return the error to the user in structured output."

            quit errMsg
        }

        set st = ..DraftOrder.%Save()
        if st{
            return ..DraftOrder.%Id()
        } else{
            quit st
        }
    }

}

```

</details>

### Giving the tools to the agent

Add the tools to the Warehouse.AI.ToolSet class. You can copy the same set-up as the previous example.

<details><summary style="color:#FFA489;font-weight:bold;">Hint</summary>

Open the `src/EmailAI/ToolSet.cls` file and add the following line to the xml definition:

```xml
<Include Class="EmailAI.OrderTools"/>
```

</details>

Finally, we can try out agent again, using the function we defined in the previous exercise:

Open the [Shell](tab-1) tab, and run the following:

```objectscript
set email = ##class(Utils.Emails).ReturnEmailString(3)

set output = ##class(EmailAI.Agent).ProcessEmail(email)

zw output
```

Hopefully the new agent has used the new tools to create a draft order! Let's move on to the final exercise where our agent in action in an interoperability production.