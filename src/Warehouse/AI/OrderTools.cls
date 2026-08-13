Class Warehouse.AI.OrderTools Extends %AI.Tool
{

    Property DraftOrder As Warehouse.Data.DraftOrder; 


    Property Validated As %Boolean [InitialExpression=0];


    /// Threshold price above which any order requires human review
    Parameter REVIEWPRICETHRESHOLD= 2000;

    /// Enter the details for the draft order. 
    /// The Customer Address is optional. If the order is being sent to the default customer delivery address, it should be left blank.
    /// After creation, the draft order MUST be validated, then submitted, or else it will be discarded.
    Method CreateDraftOrder(pProductId As %String, pQuantity As %Integer, pCustomerId As %String, pDeliveryAddress As %String ="") As %String
    {
        
        set product = ##class(Warehouse.Data.Product).%OpenId(pProductId)
        if '$IsObject(product) quit "ERROR: Product ID not recognised"
        
        set customer = ##class(Warehouse.Data.Customer).%OpenId(pCustomerId)
        if '$IsObject(customer) quit "ERROR: Customer ID not recognised"

        set ..DraftOrder = ##class(Warehouse.Data.DraftOrder).%New()

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
