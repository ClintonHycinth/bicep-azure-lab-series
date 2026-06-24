#!/bin/bash

# Bicep Azure Lab Series - Teardown Script
# This script deletes all resource groups created by the lab series.
# Run this in Azure Cloud Shell when you want to clean up all resources.

set -e

ENVIRONMENT=${1:-dev}

echo "Starting teardown for environment: $ENVIRONMENT"
echo "This will delete all resource groups for the $ENVIRONMENT environment."
echo "Press Ctrl+C within 10 seconds to cancel..."
sleep 10

echo "Deleting rg-networking-$ENVIRONMENT..."
az group delete \
  --name "rg-networking-$ENVIRONMENT" \
  --yes \
  --no-wait

echo "Deleting rg-compute-$ENVIRONMENT..."
az group delete \
  --name "rg-compute-$ENVIRONMENT" \
  --yes \
  --no-wait

echo "Teardown initiated for environment: $ENVIRONMENT"
echo "Resource groups are being deleted in the background."
echo "Check the Azure portal to confirm deletion is complete."