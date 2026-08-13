Class Warehouse.AI.OrderTools Extends %AI.Tool
{

Property DraftOrder As Warehouse.Data.DraftOrder;

/// Threshold price above which an order requires human review
Parameter REVIEWPRICETHRESHOLD = 2000;

/// Look up the product and customer, build a draft order in memory, and return
/// the facts needed to decide whether the order requires human review.
/// This tool does NOT decide ReviewRequired - use the returned facts plus your
/// instructions to make that judgment, then call SubmitDraftOrder with your decision.
/// Insufficient stock is a hard stop: no draft is built and an ERROR is returned.
Method PrepareOrder(pProductId As %String, pQuantity As %Integer, pCustomerId As %String, pDeliveryAddress As %String = "") As %String
{
    set product = ##class(Warehouse.Data.Product).%OpenId(pProductId)
    if '$IsObject(product) quit "ERROR: Product ID not recognised"

    set customer = ##class(Warehouse.Data.Customer).%OpenId(pCustomerId)
    if '$IsObject(customer) quit "ERROR: Customer ID not recognised"

    if pQuantity > product.Quantity {
        quit "ERROR: Product low on stock, cannot continue with order. Requested "_pQuantity_", available "_product.Quantity
    }

    set resolvedAddress = pDeliveryAddress
    if (resolvedAddress = "") {
        set resolvedAddress = customer.DefaultDeliveryAddress
    }

    set ..DraftOrder = ##class(Warehouse.Data.DraftOrder).%New()
    set ..DraftOrder.Product = product
    set ..DraftOrder.Quantity = pQuantity
    set ..DraftOrder.Customer = customer
    set ..DraftOrder.DeliveryAddress = resolvedAddress

    set totalPrice = pQuantity * product.UnitPrice
    set addressMatches = (resolvedAddress = customer.DefaultDeliveryAddress)

    set facts = {}
    set facts.sufficientStock = 1
    set facts.totalPrice = totalPrice
    set facts.reviewPriceThreshold = ..#REVIEWPRICETHRESHOLD
    set facts.deliveryAddress = resolvedAddress
    set facts.customerDefaultAddress = customer.DefaultDeliveryAddress
    set facts.addressMatches = addressMatches
    set facts.customerTrusted = customer.Trusted
    set facts.note = "Draft order prepared but not saved. Decide ReviewRequired from these facts (e.g. totalPrice > reviewPriceThreshold, or addressMatches = false, or customerTrusted = false), then call SubmitDraftOrder with your decision and a ReasonForReview if required."

    quit facts.%ToJSON()
}

/// Commit the draft order prepared by PrepareOrder, recording the agent's review decision.
/// Must be called after PrepareOrder in the same session, or the draft is discarded.
Method SubmitDraftOrder(pReviewRequired As %Boolean, pReasonForReview As %String = "") As %String
{
    if '$IsObject(..DraftOrder) {
        quit "ERROR: No draft order to submit. Call PrepareOrder first."
    }

    set ..DraftOrder.ReviewRequired = pReviewRequired

    set st = ..DraftOrder.%Save()
    if st {
        quit "Draft Order submitted. Order ID: "_..DraftOrder.%Id()
    } else {
        quit $System.Status.GetErrorText(st)
    }
}

}
