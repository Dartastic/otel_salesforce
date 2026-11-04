// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_salesforce/otel_salesforce.dart';

/// Traces Salesforce sObject calls with OpenTelemetry.
///
/// `otel_salesforce` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Salesforce sObject call in
/// [tracedSalesforceSobject]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'salesforce-example');

  // Wraps a Salesforce sObject REST call in a CLIENT span.
  final salesforceSobjectId = await tracedSalesforceSobject<String>(
    sobject: 'example',
    action: 'example',
    recordId: 'record_8f3a2c',
    apiVersion: '1',
    instanceUrl: 'https://api.example.com/v1/resource',
    invoke: () async {
      // Make the Salesforce sObject call here, then report what it returned.
      return 'salesforce_8f3a2c';
    },
  );
  OTelLog.info('tracedSalesforceSobject returned $salesforceSobjectId');

  // Wraps a SOQL query in a CLIENT span using db.* semconv with db.system=salesforce.
  final salesforceSoqlId = await tracedSalesforceSoql<String>(
    soql: 'example',
    apiVersion: '1',
    totalSize: 512,
    invoke: () async {
      // Make the Salesforce sObject call here, then report what it returned.
      return 'salesforce_8f3a2c';
    },
  );
  OTelLog.info('tracedSalesforceSoql returned $salesforceSoqlId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSalesforceInstrumentationAsync.
  await runWithoutSalesforceInstrumentationAsync(
    () => tracedSalesforceSobject<String>(
      sobject: 'example',
      action: 'example',
      recordId: 'record_8f3a2c',
      apiVersion: '1',
      instanceUrl: 'https://api.example.com/v1/resource',
      invoke: () async {
        return 'salesforce_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
