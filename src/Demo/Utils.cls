Class Demo.Utils
{

/// Populate all Demo data. Call: do ##class(Demo.Utils).PopulateAll()
ClassMethod PopulateAll() As %Status
{
    do ..CleanAll()
    set sc = ..PopulateProducts()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateTransactions()
    quit:$$$ISERR(sc) sc
    set sc = ..PopulateSuppliers()
    quit sc
}

ClassMethod CleanAll()
{
    do ##class(Demo.SupplierProduct).%KillExtent()
    do ##class(Demo.Supplier).%KillExtent()
    do ##class(Demo.Transactions).%KillExtent()
    do ##class(Demo.StockMovement).%KillExtent()
    do ##class(Demo.Product).%KillExtent()
}

ClassMethod PopulateProducts() As %Status
{
    // columns: SKU, Name, Category, Quantity, UnitPrice, ReorderLevel, OnOrder
    set products = $LISTBUILD(
        $LB("HW-001", "Ceramic Dinner Set 12pc",    "Tableware",  45, 89.99,  10, 0),
        $LB("HW-002", "Stainless Steel Cookware Set","Cookware",   28, 149.99, 15, 0),
        $LB("HW-003", "Non-stick Frying Pan 28cm",  "Cookware",   62, 34.99,  20, 0),
        $LB("HW-004", "Bamboo Cutting Board Set",   "Kitchen",    18, 24.99,  15, 0),
        $LB("HW-005", "Glass Storage Jar Set 6pc",  "Kitchen",    55, 19.99,  20, 0),
        $LB("HW-006", "Egyptian Cotton Towel Set",  "Bathroom",    8, 44.99,  15, 12),
        $LB("HW-007", "Microfibre Duvet King",      "Bedding",    31, 79.99,  10, 0),
        $LB("HW-008", "Memory Foam Pillow Pair",    "Bedding",    24, 39.99,  20, 0),
        $LB("HW-009", "Scented Candle Collection",  "Decor",      72, 14.99,  25, 0),
        $LB("HW-010", "Wooden Photo Frame Set 3pc", "Decor",      19, 22.99,  20, 0),
        $LB("HW-011", "Cast Iron Casserole Dish",   "Cookware",    6, 59.99,  10, 20),
        $LB("HW-012", "Stoneware Mug Set 4pc",      "Tableware",  41, 29.99,  15, 0),
        $LB("HW-013", "Linen Table Runner",         "Tableware",  33, 17.99,  20, 0),
        $LB("HW-014", "Shower Caddy Stainless",     "Bathroom",   14, 27.99,  15, 0),
        $LB("HW-015", "Bath Mat Anti-slip",         "Bathroom",   47, 12.99,  25, 0),
        $LB("HW-016", "Kitchen Scale Digital",      "Kitchen",     7, 21.99,  10, 15),
        $LB("HW-017", "Herb Planter Set Ceramic",   "Decor",      26, 31.99,  15, 0),
        $LB("HW-018", "Wicker Storage Basket",      "Storage",    38, 18.99,  20, 0)
    )

    for i = 1:1:$LISTLENGTH(products) {
        set item = $LIST(products, i)
        set p = ##class(Demo.Product).%New()
        set p.SKU        = $LIST(item, 1)
        set p.Name       = $LIST(item, 2)
        set p.Category   = $LIST(item, 3)
        set p.Quantity   = $LIST(item, 4)
        set p.UnitPrice  = $LIST(item, 5)
        set p.ReorderLevel = $LIST(item, 6)
        set p.OnOrder    = $LIST(item, 7)
        set sc = p.%Save()
        quit:$$$ISERR(sc)

        // Log initial stock movement
        set mv = ##class(Demo.StockMovement).%New()
        set mv.Product   = p
        set mv.Delta     = p.Quantity
        set mv.Reason    = "Initial stock"
        set mv.Timestamp = "2025-01-01 00:00:00"
        set sc = mv.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}

ClassMethod PopulateTransactions() As %Status
{
    // Generate ~6 months of transactions, Jan-Jun 2025
    // Spread across products with random daily sales
    set sc = $$$OK

    set txnData = $LISTBUILD(
        $LB("HW-001", "2025-01-05",  3, 269.97),
        $LB("HW-003", "2025-01-07",  5, 174.95),
        $LB("HW-009", "2025-01-10",  8, 119.92),
        $LB("HW-012", "2025-01-12",  4, 119.96),
        $LB("HW-002", "2025-01-15",  2, 299.98),
        $LB("HW-007", "2025-01-20",  3, 239.97),
        $LB("HW-005", "2025-01-22",  6,  119.94),
        $LB("HW-015", "2025-01-28",  7,  90.93),
        $LB("HW-003", "2025-02-03",  4, 139.96),
        $LB("HW-008", "2025-02-08",  5, 199.95),
        $LB("HW-001", "2025-02-10",  2, 179.98),
        $LB("HW-011", "2025-02-14",  3, 179.97),
        $LB("HW-013", "2025-02-18",  6, 107.94),
        $LB("HW-004", "2025-02-22",  4,  99.96),
        $LB("HW-009", "2025-02-25", 10, 149.90),
        $LB("HW-006", "2025-03-02",  5, 224.95),
        $LB("HW-017", "2025-03-05",  4, 127.96),
        $LB("HW-002", "2025-03-10",  3, 449.97),
        $LB("HW-012", "2025-03-14",  6, 179.94),
        $LB("HW-003", "2025-03-18",  8, 279.92),
        $LB("HW-018", "2025-03-20",  5,  94.95),
        $LB("HW-010", "2025-03-25",  3,  68.97),
        $LB("HW-015", "2025-04-01",  9, 116.91),
        $LB("HW-007", "2025-04-04",  4, 319.96),
        $LB("HW-005", "2025-04-08",  7, 139.93),
        $LB("HW-001", "2025-04-12",  3, 269.97),
        $LB("HW-016", "2025-04-15",  4,  87.96),
        $LB("HW-009", "2025-04-20", 12, 179.88),
        $LB("HW-013", "2025-04-24",  5,  89.95),
        $LB("HW-008", "2025-04-28",  6, 239.94),
        $LB("HW-002", "2025-05-03",  2, 299.98),
        $LB("HW-004", "2025-05-07",  5, 124.95),
        $LB("HW-011", "2025-05-12",  4, 239.96),
        $LB("HW-017", "2025-05-16",  3,  95.97),
        $LB("HW-003", "2025-05-20",  6, 209.94),
        $LB("HW-014", "2025-05-23",  4, 111.96),
        $LB("HW-012", "2025-05-27",  5, 149.95),
        $LB("HW-001", "2025-06-02",  4, 359.96),
        $LB("HW-007", "2025-06-06",  3, 239.97),
        $LB("HW-009", "2025-06-10", 15, 224.85),
        $LB("HW-018", "2025-06-14",  6, 113.94),
        $LB("HW-005", "2025-06-18",  8, 159.92),
        $LB("HW-016", "2025-06-22",  3,  65.97),
        $LB("HW-015", "2025-06-25", 10, 129.90),
        $LB("HW-002", "2025-06-28",  2, 299.98)
    )

    for i = 1:1:$LISTLENGTH(txnData) {
        set item = $LIST(txnData, i)
        set sku  = $LIST(item, 1)
        set dateStr = $LIST(item, 2)
        set qty  = $LIST(item, 3)
        set tot  = $LIST(item, 4)

        set pId = ##class(Demo.Product).SKUIndexOpen(sku)
        if '$ISOBJECT(pId) {
            write "WARNING: SKU "_sku_" not found, skipping",!
            continue
        }

        set t = ##class(Demo.Transactions).%New()
        set t.Product  = pId
        // Convert YYYY-MM-DD to $H date
        set t.Date     = $ZDATEH(dateStr, 3)
        set t.Quantity = qty
        set t.Total    = tot
        set sc = t.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}

ClassMethod PopulateSuppliers() As %Status
{
    set sc = $$$OK

    // 4 suppliers
    set supplierData = $LISTBUILD(
        $LB("HomeCraft Wholesale",    "orders@homecraftws.co.uk",  "0161 234 5678", 7),
        $LB("Nordic Home Supplies",   "trade@nordichome.com",      "0207 890 1234", 14),
        $LB("Casa Direct Ltd",        "purchasing@casadirect.co.uk","0121 456 7890", 5),
        $LB("EuroHome Distributors",  "supply@eurohome.eu",        "0131 567 8901", 10)
    )

    for i = 1:1:$LISTLENGTH(supplierData) {
        set item = $LIST(supplierData, i)
        set s = ##class(Demo.Supplier).%New()
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
        $LB("HW-001", "HomeCraft Wholesale",   "2025-05-10", 1),
        $LB("HW-001", "Casa Direct Ltd",        "2025-02-20", 0),
        $LB("HW-002", "Nordic Home Supplies",   "2025-06-01", 1),
        $LB("HW-002", "EuroHome Distributors",  "2025-03-15", 0),
        $LB("HW-003", "HomeCraft Wholesale",    "2025-06-12", 1),
        $LB("HW-003", "Casa Direct Ltd",        "2025-04-08", 0),
        $LB("HW-004", "Casa Direct Ltd",        "2025-05-22", 1),
        $LB("HW-005", "HomeCraft Wholesale",    "2025-06-18", 1),
        $LB("HW-005", "Nordic Home Supplies",   "2025-01-30", 0),
        $LB("HW-006", "EuroHome Distributors",  "2025-04-14", 1),
        $LB("HW-006", "Nordic Home Supplies",   "2025-06-05", 0),
        $LB("HW-007", "Nordic Home Supplies",   "2025-05-30", 1),
        $LB("HW-008", "Nordic Home Supplies",   "2025-04-25", 1),
        $LB("HW-008", "HomeCraft Wholesale",    "2025-02-11", 0),
        $LB("HW-009", "Casa Direct Ltd",        "2025-06-20", 1),
        $LB("HW-010", "HomeCraft Wholesale",    "2025-03-18", 1),
        $LB("HW-011", "EuroHome Distributors",  "2025-01-15", 1),
        $LB("HW-011", "Casa Direct Ltd",        "2024-11-20", 0),
        $LB("HW-012", "HomeCraft Wholesale",    "2025-05-05", 1),
        $LB("HW-013", "EuroHome Distributors",  "2025-04-02", 1),
        $LB("HW-014", "Casa Direct Ltd",        "2025-03-28", 1),
        $LB("HW-015", "HomeCraft Wholesale",    "2025-06-10", 1),
        $LB("HW-016", "EuroHome Distributors",  "2024-12-05", 1),
        $LB("HW-016", "Nordic Home Supplies",   "2025-05-14", 0),
        $LB("HW-017", "Casa Direct Ltd",        "2025-05-19", 1),
        $LB("HW-018", "HomeCraft Wholesale",    "2025-06-14", 1)
    )

    for i = 1:1:$LISTLENGTH(spData) {
        set item        = $LIST(spData, i)
        set sku         = $LIST(item, 1)
        set supName     = $LIST(item, 2)
        set orderDate   = $LIST(item, 3)
        set preferred   = $LIST(item, 4)

        set prod = ##class(Demo.Product).SKUIndexOpen(sku)
        if '$ISOBJECT(prod) {
            write "WARNING: SKU "_sku_" not found, skipping",!
            continue
        }

        set sup = ##class(Demo.Supplier).NameIndexOpen(supName)
        if '$ISOBJECT(sup) {
            write "WARNING: Supplier "_supName_" not found, skipping",!
            continue
        }

        set sp = ##class(Demo.SupplierProduct).%New()
        set sp.Product       = prod
        set sp.Supplier      = sup
        set sp.LastOrderDate = $ZDATEH(orderDate, 3)
        set sp.IsPreferred   = preferred
        set sc = sp.%Save()
        quit:$$$ISERR(sc)
    }
    quit sc
}

ClassMethod TestService(id, quantity) As %Status
{
    set st =  ##class(Ens.Director).CreateBusinessService("OrderService", .service)
    set input = {"productId":(id), "quantity":(quantity)}

    set st = service.ProcessInput(input, .output)
    zw output.StatusMessage
    return $$$OK
}

}
