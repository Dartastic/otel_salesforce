// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_salesforce/otel_salesforce.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_salesforce-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Account.create records CLIENT span', () async {
    await tracedSalesforceSobject<String>(
      sobject: 'Account',
      action: 'create',
      apiVersion: 'v60.0',
      invoke: () async => '001-1',
    );
    final a = attrsOf(spans.findSpanByName('salesforce Account.create')!);
    expect(a['salesforce.sobject'], 'Account');
    expect(a['salesforce.action'], 'create');
    expect(a['salesforce.operation'], 'Account.create');
    expect(a['salesforce.api.version'], 'v60.0');
  });

  test('SOQL records db.* attrs', () async {
    await tracedSalesforceSoql<String>(
      soql: 'SELECT Id FROM Account LIMIT 10',
      apiVersion: 'v60.0',
      totalSize: 10,
      invoke: () async => 'rows',
    );
    final a = attrsOf(spans.findSpanByName('salesforce soql query')!);
    expect(a['db.system'], 'salesforce');
    expect(a['db.operation'], 'query');
    expect(a['db.statement'], 'SELECT Id FROM Account LIMIT 10');
    expect(a['salesforce.query.language'], 'SOQL');
    expect(a['salesforce.totalSize'], 10);
  });

  test('suppression skips spans', () async {
    await runWithoutSalesforceInstrumentationAsync(() async {
      await tracedSalesforceSobject<String>(
        sobject: 'Account',
        action: 'create',
        invoke: () async => 'a',
      );
    });
    expect(spans.findSpansStartingWith('salesforce '), isEmpty);
  });
}
