#!/bin/bash
#
# Builds the SP-API Java client library from OpenAPI models.
#
# Produces two JARs:
#   1. sellingpartnerapi-aa-java-<AA_VERSION>.jar  (auth library)
#   2. selling-partner-api-<API_VERSION>.jar       (all SP-API clients)
#
# Versions are read from pom.xml files — no hardcoded versions in this script.
#
# JARs are installed to:
#   - This repo's lib/ (needed for the API build to find the AA dependency)
#   - Any sibling project directories (../*) that have a pom.xml referencing
#     selling-partner-api or sellingpartnerapi-aa-java
#
# Usage:
#   cd generate && bash compile.sh
#

set -e

# Resolve paths relative to this script, so it works from any working directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Read versions from the pom.xml files (single source of truth)
AA_VERSION=$(grep -m1 '<version>' clients/sellingpartner-api-aa-java/pom.xml | sed 's/.*<version>\(.*\)<\/version>.*/\1/')
API_VERSION=$(grep -m1 '<version>' generate/pom.xml | sed 's/.*<version>\(.*\)<\/version>.*/\1/')

echo "=========================================="
echo "  AA library version:  $AA_VERSION"
echo "  API client version:  $API_VERSION"
echo "=========================================="

# Discover sibling project directories that use these JARs
INSTALL_TARGETS=()
for dir in "$REPO_ROOT"/../*/; do
    [ -d "$dir" ] || continue
    [ "$dir" = "$REPO_ROOT/" ] && continue
    if [ -f "$dir/pom.xml" ] && grep -q "selling-partner-api\|sellingpartnerapi-aa-java" "$dir/pom.xml" 2>/dev/null; then
        resolved="$(cd "$dir" && pwd)"
        INSTALL_TARGETS+=("$resolved")
        echo "  Found consumer: $resolved"
    fi
done

if [ ${#INSTALL_TARGETS[@]} -eq 0 ]; then
    echo "  No sibling projects found that reference SP-API JARs."
    echo "  JARs will only be installed to this repo's lib/."
fi
echo ""

# ============================================================
# Step 1: Generate Java code from all API models
# ============================================================
echo ">>> Generating Java code from API models..."
rm -rf generated
mkdir -p generated/spapi/src/main/java/com/amazon/sellingpartner

basePackage="com.amazon.sellingpartner"

generate () {
    java -jar generate/swagger-codegen-cli.jar generate \
          --input-spec "$2" \
          --lang java \
          --template-dir clients/sellingpartner-api-aa-java/resources/swagger-codegen/templates \
          --output generated/spapi \
          --invoker-package "$basePackage" \
          --api-package "$basePackage.api.$1" \
          --model-package "$basePackage.model.$1" \
          --group-id "com.amazon" \
          --artifact-id "selling-partner-api" \
          --additional-properties dateLibrary=java8
}

# Core APIs
generate "awd" "models/amazon-warehousing-and-distribution-model/awd_2024-05-09.json"
generate "aplus" "models/aplus-content-api-model/aplusContent_2020-11-01.json"
generate "applicaitons" "models/application-management-api-model/application_2023-11-30.json"
generate "catalogv0" "models/catalog-items-api-model/catalogItemsV0.json"
generate "catalogv20" "models/catalog-items-api-model/catalogItems_2020-12-01.json"
generate "catalogv22" "models/catalog-items-api-model/catalogItems_2022-04-01.json"
generate "queries" "models/data-kiosk-api-model/dataKiosk_2023-11-15.json"
generate "easyship" "models/easy-ship-model/easyShip_2022-03-23.json"
generate "fbainbound" "models/fba-inbound-eligibility-api-model/fbaInbound.json"
generate "fbainventory" "models/fba-inventory-api-model/fbaInventory.json"
generate "feeds" "models/feeds-api-model/feeds_2021-06-30.json"
generate "finances" "models/finances-api-model/finances_2024-06-19.json"
generate "financestransfers" "models/finances-api-model/transfers_2024-06-01.json"
generate "fulfillmentinbound" "models/fulfillment-inbound-api-model/fulfillmentInboundV0.json"
generate "fulfillmentinboundbeta" "models/fulfillment-inbound-api-model/fulfillmentInbound_2024-03-20.json"
generate "fulfillmentoutbound" "models/fulfillment-outbound-api-model/fulfillmentOutbound_2020-07-01.json"
generate "listing" "models/listings-items-api-model/listingsItems_2021-08-01.json"
generate "listingrestrictions" "models/listings-restrictions-api-model/listingsRestrictions_2021-08-01.json"
generate "merchantfulfillment" "models/merchant-fulfillment-api-model/merchantFulfillmentV0.json"
generate "messaging" "models/messaging-api-model/messaging.json"
generate "notifications" "models/notifications-api-model/notifications.json"
generate "orders" "models/orders-api-model/orders_2026-01-01.json"
generate "productfees" "models/product-fees-api-model/productFeesV0.json"
generate "productpricing" "models/product-pricing-api-model/productPricing_2022-05-01.json"
generate "definitions" "models/product-type-definitions-api-model/definitionsProductTypes_2020-09-01.json"
generate "sellingpartners" "models/replenishment-api-model/replenishment-2022-11-07.json"
generate "reports" "models/reports-api-model/reports_2021-06-30.json"
generate "sales" "models/sales-api-model/sales.json"
generate "sellers" "models/sellers-api-model/sellers.json"
generate "services" "models/services-api-model/services.json"
generate "shipmentinvoicing" "models/shipment-invoicing-api-model/shipmentInvoicingV0.json"
generate "shipping" "models/shipping-api-model/shippingV2.json"
generate "solicitations" "models/solicitations-api-model/solicitations.json"
generate "supplysources" "models/supply-sources-api-model/supplySources_2020-07-01.json"
generate "tokens" "models/tokens-api-model/tokens_2021-03-01.json"
generate "uploads" "models/uploads-api-model/uploads_2020-11-01.json"

# Vendor / Direct Fulfillment APIs
generate "dfinventory" "models/vendor-direct-fulfillment-inventory-api-model/vendorDirectFulfillmentInventoryV1.json"
generate "dforders" "models/vendor-direct-fulfillment-orders-api-model/vendorDirectFulfillmentOrders_2021-12-28.json"
generate "dfpayments" "models/vendor-direct-fulfillment-payments-api-model/vendorDirectFulfillmentPaymentsV1.json"
generate "dfshipping" "models/vendor-direct-fulfillment-shipping-api-model/vendorDirectFulfillmentShipping_2021-12-28.json"
generate "dftransactions" "models/vendor-direct-fulfillment-transactions-api-model/vendorDirectFulfillmentTransactions_2021-12-28.json"
generate "dfsandbox" "models/vendor-direct-fulfillment-sandbox-test-data-api-model/vendorDirectFulfillmentSandboxData_2021-10-28.json"
generate "vendorinvoices" "models/vendor-invoices-api-model/vendorInvoices.json"
generate "vendororders" "models/vendor-orders-api-model/vendorOrders.json"
generate "vendorshipments" "models/vendor-shipments-api-model/vendorShipments.json"
generate "vendortransactionstatus" "models/vendor-transaction-status-api-model/vendorTransactionStatus.json"

# APIs added in 2.0.0
generate "appintegrations" "models/application-integrations-api-model/appIntegrations-2024-04-01.json"
generate "customerfeedback" "models/customer-feedback-api-model/customerFeedback_2024-06-01.json"
generate "deliverybyamazon" "models/delivery-by-amazon/deliveryShipmentInvoiceV2022-07-01.json"
generate "externalfulfillmentinventory" "models/external-fulfillment/externalFulfillmentInventory_2024-09-11.json"
generate "externalfulfillmentreturns" "models/external-fulfillment/externalFulfillmentReturns_2024-09-11.json"
generate "externalfulfillmentshipments" "models/external-fulfillment/externalFulfillmentShipments_2024-09-11.json"
generate "invoices" "models/invoices-api-model/InvoicesApiModel_2024-06-19.json"
generate "sellerwallet" "models/seller-wallet-api-model/sellerWallet_2024-03-01.json"
generate "vehicles" "models/vehicles-api-model/vehicles_2024-11-01.json"

# ============================================================
# Step 2: Build the AA (auth) library
# ============================================================
echo ""
echo ">>> Building AA library v${AA_VERSION}..."
cd clients/sellingpartner-api-aa-java
mvn clean package -DskipTests

AA_JAR="target/sellingpartnerapi-aa-java-${AA_VERSION}.jar"

# Install to this repo's lib (needed as dependency for API build)
mvn install:install-file \
    -Dfile="$AA_JAR" \
    -DgroupId=com.amazon.sellingpartnerapi \
    -DartifactId=sellingpartnerapi-aa-java \
    -Dversion="$AA_VERSION" \
    -Dpackaging=jar \
    -DlocalRepositoryPath="$REPO_ROOT/lib"

# Install to discovered consumer projects
for target in "${INSTALL_TARGETS[@]}"; do
    echo "  Installing AA library to $target/lib"
    mvn install:install-file \
        -Dfile="$AA_JAR" \
        -DgroupId=com.amazon.sellingpartnerapi \
        -DartifactId=sellingpartnerapi-aa-java \
        -Dversion="$AA_VERSION" \
        -Dpackaging=jar \
        -DlocalRepositoryPath="$target/lib"
done
cd "$REPO_ROOT"

# ============================================================
# Step 3: Copy okhttp3-compatible files + build API JAR
# ============================================================
echo ""
echo ">>> Building API client v${API_VERSION}..."
cp -a generate/JSON.java generated/spapi/src/main/java/com/amazon/sellingpartner/
cp -a generate/ProgressResponseBody.java generated/spapi/src/main/java/com/amazon/sellingpartner/
cp -a generate/ProgressRequestBody.java generated/spapi/src/main/java/com/amazon/sellingpartner/
cp -a generate/GzipRequestInterceptor.java generated/spapi/src/main/java/com/amazon/sellingpartner/
cp -a generate/HttpBasicAuth.java generated/spapi/src/main/java/com/amazon/sellingpartner/auth/
cp -r generate/pom.xml generated/spapi
cd generated/spapi
mvn clean package
cd "$REPO_ROOT"

API_JAR="generated/spapi/target/selling-partner-api-${API_VERSION}.jar"
API_SOURCES="generated/spapi/target/selling-partner-api-${API_VERSION}-sources.jar"
API_JAVADOC="generated/spapi/target/selling-partner-api-${API_VERSION}-javadoc.jar"

# ============================================================
# Step 4: Install API JAR to consumer projects
# ============================================================
for target in "${INSTALL_TARGETS[@]}"; do
    echo "  Installing API client to $target/lib"
    mvn install:install-file \
        -Dfile="$API_JAR" \
        -Dsources="$API_SOURCES" \
        -Djavadoc="$API_JAVADOC" \
        -DgroupId=com.amazon.sellingpartnerapi \
        -DartifactId=selling-partner-api \
        -Dversion="$API_VERSION" \
        -Dpackaging=jar \
        -DlocalRepositoryPath="$target/lib"
done

echo ""
echo "=========================================="
echo "  BUILD COMPLETE"
echo "  AA library:  sellingpartnerapi-aa-java-${AA_VERSION}.jar"
echo "  API client:  selling-partner-api-${API_VERSION}.jar"
echo ""
echo "  Installed to:"
echo "    - $REPO_ROOT/lib (AA only)"
for target in "${INSTALL_TARGETS[@]}"; do
    echo "    - $target/lib (both)"
done
echo ""
echo "  Next: update consumer pom.xml versions to"
echo "    sellingpartnerapi-aa-java: $AA_VERSION"
echo "    selling-partner-api:      $API_VERSION"
echo "=========================================="
