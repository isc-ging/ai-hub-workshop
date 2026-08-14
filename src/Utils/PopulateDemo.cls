Class Utils.PopulateDemo
{

/// Populate all Warehouse data. Call: do ##class(Utils.PopulateDemo).PopulateAll()
ClassMethod PopulateAll() As %Status
{
    do ..CleanAll()
    set sc = ..PopulateProducts()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateCustomers()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateOrders()
    quit sc
}

ClassMethod CleanAll()
{
    do ##class(Warehouse.Order).%KillExtent()
    do ##class(Warehouse.Transactions).%KillExtent()
    do ##class(Warehouse.Product).%KillExtent()
    do ##class(Warehouse.Customer).%KillExtent()
}

ClassMethod PopulateProducts() As %Status
{
    // columns: SKU, Name, Category, Quantity, UnitPrice, ReorderLevel, OnOrder, Active
    set products = $LISTBUILD(
        $LB("TS-400", "Industrial temperature sensor",     "Sensors",  120, 80.00,  20, 0,  1),
        $LB("TS-450", "High-accuracy temperature sensor",  "Sensors",   45, 115.00, 15, 0,  1),
        $LB("GW-10",  "Sensor gateway",                    "Gateways",  30, 240.00, 10, 5,  1),
        $LB("CBL-5M", "Five-metre extension cable",        "Cables",   200, 9.50,   40, 0,  1)
    )

    for i = 1:1:$LISTLENGTH(products) {
        set item = $LIST(products, i)
        set p = ##class(Warehouse.Product).%New()
        set p.SKU        = $LIST(item, 1)
        set p.Name       = $LIST(item, 2)
        set p.Category   = $LIST(item, 3)
        set p.Quantity   = $LIST(item, 4)
        set p.UnitPrice  = $LIST(item, 5)
        set p.ReorderLevel = $LIST(item, 6)
        set p.OnOrder    = $LIST(item, 7)
        set p.Active     = $LIST(item, 8)
        set sc = p.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}



ClassMethod PopulateCustomers() As %Status
{
    set sc = $$$OK

    // columns: CustomerId, Organisation, ContactEmail, Status, Trusted, DefaultDeliveryAddress
    // Trusted = 1 means orders pass through automatically; 0 requires human review
    set customerData = $LISTBUILD(
        $LB("C1001", "Northwind Heating Ltd", "purchasing@northwind.example", "active", 1, "Edinburgh Warehouse"),
        $LB("C1002", "Alpine Facilities",      "orders@alpine.example",        "active", 1, "Glasgow Depot"),
        $LB("C1003", "Citywide Engineering",   "buying@citywide.example",      "active", 0, "Manchester Site Office")
    )

    for i = 1:1:$LISTLENGTH(customerData) {
        set item = $LIST(customerData, i)
        set c = ##class(Warehouse.Customer).%New()
        set c.CustomerId              = $LIST(item, 1)
        set c.Organisation            = $LIST(item, 2)
        set c.ContactEmail            = $LIST(item, 3)
        set c.Status                  = $LIST(item, 4)
        set c.Trusted                 = $LIST(item, 5)
        set c.DefaultDeliveryAddress  = $LIST(item, 6)
        set sc = c.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}

ClassMethod PopulateOrders() As %Status
{
    set sc = $$$OK

    // columns: CustomerId, OrderDate, DeliveryAddress, SKU, Quantity
    set orderData = $LISTBUILD(
        $LB("C1001", "2026-07-18", "Edinburgh Warehouse", "TS-400", 20),
        $LB("C1002", "2026-07-02", "Glasgow Depot",       "TS-450", 10)
    )

    for i = 1:1:$LISTLENGTH(orderData) {
        set item      = $LIST(orderData, i)
        set custId    = $LIST(item, 1)
        set orderDate = $LIST(item, 2)
        set address   = $LIST(item, 3)
        set sku       = $LIST(item, 4)
        set qty       = $LIST(item, 5)

        set cust = ##class(Warehouse.Customer).%OpenId(custId)
        if '$ISOBJECT(cust) {
            write "WARNING: Customer "_custId_" not found, skipping",!
            continue
        }

        set prod = ##class(Warehouse.Product).%OpenId(sku)
        if '$ISOBJECT(prod) {
            write "WARNING: SKU "_sku_" not found, skipping",!
            continue
        }

        set order = ##class(Warehouse.Order).%New()
        set order.Customer        = cust
        set order.OrderDate       = $ZDATEH(orderDate, 3)
        set order.DeliveryAddress = address
        set order.Product         = prod
        set order.Quantity        = qty

        set sc = order.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}


}
