/* With regards to your query, this report can be created in Zoho Analytics by using the following tables:

1. Stock In Flow Table
2. Stock Out Flow Table
3. FIFO Mapping Table
4. Purchase Order Items
5. Purchase Orders
6. Sales Order Items
7. Sales Orders

You can follow the below steps to create this query table:

1.Please make sure that you've included all the fields in these modules. You can follow the steps in this help link to include them: https://www.zoho.com/analytics/help/connectors/zoho-books.html#s7

2. Create a query table using this query: */

SELECT
		 'In' as "Type",
		 "Stock In Flow Table"."Stock In Flow ID" "PK",
		 "Stock In Flow Table"."Product ID" "Product ID",
		 "Stock In Flow Table"."Warehouse ID" "Warehouse ID",
		 "Stock In Flow Table"."Transaction Date" "Date",
		 "Stock In Flow Table"."Quantity In" as "Purchased Quantity",
		 0 as "Sold Quantity",
		 "Stock In Flow Table"."Total (BCY)",
		 0 as "Committed Stock"
FROM  "Stock In Flow Table" 
UNION ALL
 SELECT
		 'Out' as "Type",
		 "Stock Out Flow Table"."Stock Out Flow ID",
		 "Stock Out Flow Table"."Product ID",
		 "Stock Out Flow Table"."Warehouse ID",
		 "Stock Out Flow Table"."Transaction Date",
		 0,
		 -1 * "Stock Out Flow Table"."Quantity Out",
		 -1 * sum("FIFO Mapping Table"."Total (BCY)"),
		 0
FROM  "Stock Out Flow Table"
LEFT JOIN "FIFO Mapping Table" ON "Stock Out Flow Table"."Stock Out Flow ID"  = "FIFO Mapping Table"."Stock Out Flow ID"  
GROUP BY 1,
	 2,
	 3,
	 4,
	 5,
	  7 
UNION ALL
 SELECT
		 'Transfer' as "Type",
		 "Transfer Order Items"."Item ID",
		 "Transfer Order Items"."Product ID",
		 "Transfer Order Items"."Warehouse ID",
		 "Transfer Order"."Date",
		 if("Transfer Order"."Status"  = 'in_transit', 0, if("Transfer Order Items"."Transferred Quantity"  > 0, "Transfer Order Items"."Transferred Quantity", 0)),
		 if("Transfer Order Items"."Transferred Quantity"  < 0, "Transfer Order Items"."Transferred Quantity", 0),
		 "Inventory Adjustment Items"."Price (BCY)" * "Transfer Order Items"."Transferred Quantity",
		 0
FROM  "Transfer Order Items"
LEFT JOIN "Transfer Order" ON "Transfer Order Items"."Transfer Order ID"  = "Transfer Order"."Transfer Order ID" 
LEFT JOIN "Inventory Adjustment Items" ON "Inventory Adjustment Items"."Inventory Adjustment Item ID"  = "Transfer Order Items"."Item ID"  
UNION ALL
 SELECT
		 'Committed',
		 "Sales Order Items"."Item ID",
		 "Sales Order Items"."Product ID" "Product ID",
		 "Sales Order Items"."Warehouse ID",
		 "Sales Orders"."Order Date",
		 0,
		 0,
		 0,
		 ifnull(ifnull(SUM("Sales Order Items"."Quantity"), 0) -ifnull(SUM("Sales Order Items"."Quantity Invoiced"), 0) -ifnull(SUM("Sales Order Items"."Quantity Cancelled"), 0), 0) "Commited Stock"
FROM  "Sales Order Items"
LEFT JOIN "Sales Orders" ON "Sales Orders"."Sales Order ID"  = "Sales Order Items"."Sales Order ID"  
WHERE	 "Sales Orders"."Status"  not in ( 'draft'  , 'void'  )
GROUP BY 1,
	 2,
	 3,
	 4,
	  5 
