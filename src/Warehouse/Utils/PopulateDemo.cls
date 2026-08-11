Class Warehouse.Utils.PopulateDemo
{

/// Populate all Warehouse data. Call: do ##class(Warehouse.Utils.PopulateDemo).PopulateAll()
ClassMethod PopulateAll() As %Status
{
    do ..CleanAll()
    set sc = ..PopulateProducts()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateSuppliers()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateCustomers()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateContractPrices()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateOrders()
    quit sc
}

ClassMethod CleanAll()
{
    do ##class(Warehouse.Data.OrderItem).%KillExtent()
    do ##class(Warehouse.Data.Order).%KillExtent()
    do ##class(Warehouse.Data.ContractPrice).%KillExtent()
    do ##class(Warehouse.Data.SupplierProduct).%KillExtent()
    do ##class(Warehouse.Data.Supplier).%KillExtent()
    do ##class(Warehouse.Data.Transactions).%KillExtent()
    do ##class(Warehouse.Data.StockMovement).%KillExtent()
    do ##class(Warehouse.Data.Product).%KillExtent()
    do ##class(Warehouse.Data.Customer).%KillExtent()
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
        set p = ##class(Warehouse.Data.Product).%New()
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

        // Log initial stock movement
        set mv = ##class(Warehouse.Data.StockMovement).%New()
        set mv.Product   = p
        set mv.Delta     = p.Quantity
        set mv.Reason    = "Initial stock"
        set mv.Timestamp = "2026-01-01 00:00:00"
        set sc = mv.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}

ClassMethod PopulateSuppliers() As %Status
{
    set sc = $$$OK

    set supplierData = $LISTBUILD(
        $LB("Sensortech Components",   "orders@sensortech.example",  "0161 234 5678", 7),
        $LB("Nordic Automation Supply","trade@nordicautomation.eu",  "0207 890 1234", 14),
        $LB("Cablecraft Ltd",          "sales@cablecraft.example",    "0121 456 7890", 5)
    )

    for i = 1:1:$LISTLENGTH(supplierData) {
        set item = $LIST(supplierData, i)
        set s = ##class(Warehouse.Data.Supplier).%New()
        set s.Name         = $LIST(item, 1)
        set s.ContactEmail = $LIST(item, 2)
        set s.Phone        = $LIST(item, 3)
        set s.LeadTimeDays = $LIST(item, 4)
        set sc = s.%Save()
        quit:$$$ISERR(sc)
    }
    quit:$$$ISERR(sc) sc

    // columns: SKU, SupplierName, LastOrderDate (YYYY-MM-DD), IsPreferred
    set spData = $LISTBUILD(
        $LB("TS-400", "Sensortech Components",    "2026-06-12", 1),
        $LB("TS-400", "Nordic Automation Supply", "2026-03-02", 0),
        $LB("TS-450", "Sensortech Components",    "2026-05-20", 1),
        $LB("GW-10",  "Nordic Automation Supply", "2026-06-01", 1),
        $LB("CBL-5M", "Cablecraft Ltd",            "2026-06-18", 1)
    )

    for i = 1:1:$LISTLENGTH(spData) {
        set item        = $LIST(spData, i)
        set sku         = $LIST(item, 1)
        set supName     = $LIST(item, 2)
        set orderDate   = $LIST(item, 3)
        set preferred   = $LIST(item, 4)

        set prod = ##class(Warehouse.Data.Product).SKUIndexOpen(sku)
        if '$ISOBJECT(prod) {
            write "WARNING: SKU "_sku_" not found, skipping",!
            continue
        }

        set sup = ##class(Warehouse.Data.Supplier).NameIndexOpen(supName)
        if '$ISOBJECT(sup) {
            write "WARNING: Supplier "_supName_" not found, skipping",!
            continue
        }

        set sp = ##class(Warehouse.Data.SupplierProduct).%New()
        set sp.Product       = prod
        set sp.Supplier      = sup
        set sp.LastOrderDate = $ZDATEH(orderDate, 3)
        set sp.IsPreferred   = preferred
        set sc = sp.%Save()
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
        set c = ##class(Warehouse.Data.Customer).%New()
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

ClassMethod PopulateContractPrices() As %Status
{
    set sc = $$$OK

    // columns: CustomerId, SKU, UnitPrice
    set priceData = $LISTBUILD(
        $LB("C1001", "TS-400", 72.00),
        $LB("C1002", "TS-450", 105.00)
    )

    for i = 1:1:$LISTLENGTH(priceData) {
        set item = $LIST(priceData, i)
        set custId = $LIST(item, 1)
        set sku    = $LIST(item, 2)
        set price  = $LIST(item, 3)

        set cust = ##class(Warehouse.Data.Customer).CustomerIdIndexOpen(custId)
        if '$ISOBJECT(cust) {
            write "WARNING: Customer "_custId_" not found, skipping",!
            continue
        }

        set prod = ##class(Warehouse.Data.Product).SKUIndexOpen(sku)
        if '$ISOBJECT(prod) {
            write "WARNING: SKU "_sku_" not found, skipping",!
            continue
        }

        set cp = ##class(Warehouse.Data.ContractPrice).%New()
        set cp.Customer  = cust
        set cp.Product   = prod
        set cp.UnitPrice = price
        set sc = cp.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}

ClassMethod PopulateOrders() As %Status
{
    set sc = $$$OK

    // columns: CustomerId, OrderDate, DeliveryAddress, SKU, Quantity, UnitPrice
    set orderData = $LISTBUILD(
        $LB("C1001", "2026-07-18", "Edinburgh Warehouse", "TS-400", 20, 72.00),
        $LB("C1002", "2026-07-02", "Glasgow Depot",       "TS-450", 10, 105.00)
    )

    for i = 1:1:$LISTLENGTH(orderData) {
        set item       = $LIST(orderData, i)
        set custId     = $LIST(item, 1)
        set orderDate  = $LIST(item, 2)
        set address    = $LIST(item, 3)
        set sku        = $LIST(item, 4)
        set qty        = $LIST(item, 5)
        set unitPrice  = $LIST(item, 6)

        set cust = ##class(Warehouse.Data.Customer).CustomerIdIndexOpen(custId)
        if '$ISOBJECT(cust) {
            write "WARNING: Customer "_custId_" not found, skipping",!
            continue
        }

        set prod = ##class(Warehouse.Data.Product).SKUIndexOpen(sku)
        if '$ISOBJECT(prod) {
            write "WARNING: SKU "_sku_" not found, skipping",!
            continue
        }

        set order = ##class(Warehouse.Data.Order).%New()
        set order.Customer        = cust
        set order.OrderDate       = $ZDATEH(orderDate, 3)
        set order.DeliveryAddress = address
        set order.Status         = "confirmed"

        set orderItem = ##class(Warehouse.Data.OrderItem).%New()
        set orderItem.Product   = prod
        set orderItem.Quantity  = qty
        set orderItem.UnitPrice = unitPrice
        do order.Items.Insert(orderItem)

        set sc = order.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}


}
