// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_salesforce_suppression.dart';

const _tracerName = 'dartastic_otel_libs_salesforce';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Salesforce sObject REST call in a CLIENT span.
Future<T> tracedSalesforceSobject<T>({
  required String sobject,
  required String action,
  required Future<T> Function() invoke,
  String? recordId,
  String? apiVersion,
  String? instanceUrl,
}) async {
  if (salesforceInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'salesforce.sobject': sobject,
    'salesforce.action': action,
    'salesforce.operation': '$sobject.$action',
  };
  if (recordId != null) m['salesforce.record.id'] = recordId;
  if (apiVersion != null) m['salesforce.api.version'] = apiVersion;
  if (instanceUrl != null) m['salesforce.instance_url'] = instanceUrl;

  final span = _tracer().startSpan(
    'salesforce $sobject.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

const _maxStatementLength = 1024;
String _truncate(String s) =>
    s.length <= _maxStatementLength ? s : s.substring(0, _maxStatementLength);

/// Wraps a SOQL query in a CLIENT span using db.* semconv with
/// db.system=salesforce.
Future<T> tracedSalesforceSoql<T>({
  required String soql,
  required Future<T> Function() invoke,
  String? apiVersion,
  int? totalSize,
}) async {
  if (salesforceInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'db.system': 'salesforce',
    'db.operation': 'query',
    'db.statement': _truncate(soql),
    'salesforce.query.language': 'SOQL',
  };
  if (apiVersion != null) m['salesforce.api.version'] = apiVersion;
  if (totalSize != null) m['salesforce.totalSize'] = totalSize;

  final span = _tracer().startSpan(
    'salesforce soql query',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
