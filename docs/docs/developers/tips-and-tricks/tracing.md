---
permalink: /developers/tips-and-tricks/tracing/
title: Viewing Traces in Development
parent: Tips and Tricks
grand_parent: Developers
nav_order: 5
---
# Viewing Traces in Development
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

- TOC
{:toc}

MarkUs can record [OpenTelemetry](https://opentelemetry.io/) traces of the requests it handles and the background jobs it runs. A trace shows how long a request or job took and what it did, including its database queries (with the values removed) and the views it rendered.

Tracing is controlled by the `telemetry` [settings](../../administrators/configuration.md#settings). It is off unless `telemetry.enabled` is `true`, and MarkUs then sends traces to the OTLP endpoint at `telemetry.endpoint`. When tracing is off, MarkUs does not load any OpenTelemetry code.

## Starting MarkUs with tracing

The `telemetry` [profile](https://docs.docker.com/compose/how-tos/profiles/) in `compose.yaml` adds an `otel-lgtm` service running [Grafana's otel-lgtm image](https://github.com/grafana/docker-otel-lgtm), which bundles an OpenTelemetry Collector, Grafana and Tempo (where the traces are stored). `compose.yaml` also sets `telemetry.endpoint` to this service, using the `MARKUS__TELEMETRY__ENDPOINT` environment variable.

To start MarkUs with tracing, turn on the setting and the profile:

```bash
MARKUS__TELEMETRY__ENABLED=true docker compose --profile telemetry up
```

Alternatively, to keep tracing on, add the following to `config/settings/development.local.yml` and start MarkUs with `docker compose --profile telemetry up`:

```yaml
telemetry:
  enabled: true
```

To turn tracing off again, start MarkUs as usual with `docker compose up` (after removing the setting from `config/settings/development.local.yml`, if you added it there). To stop the `otel-lgtm` container, run `docker compose stop otel-lgtm`.

> 🗒️ **Note**: the otel-lgtm image is only meant for development. It keeps traces inside its container, so they are lost when the container is removed.

## Viewing traces

1. Use MarkUs as usual at `http://localhost:3000/csc108`.
2. Open Grafana at `http://localhost:3001` (you do not need to sign in), select **Explore**, and choose the **Tempo** data source.
3. Select **TraceQL**, enter one of the following queries, and select **Run query**:
    - `{ kind = server }` lists requests. Each request trace is named after the request's route (for example, `GET /csc108/courses/:course_id/assignments`), and contains spans for the database queries and views inside it.
    - `{ kind = consumer }` lists background jobs. Each job trace is named after the job's queue (for example, `DEFAULT_QUEUE process`), and contains spans for the job's database queries.
4. Select a trace ID to open the trace, and select a span to see its details.

A job's trace is not part of the trace of the request that queued it. Instead, the two are linked: open the job's trace, select its first span, and select **View Linked Span** under **References** to open the request.

Tempo also contains one-span traces of the database queries that Action Cable runs when a page connects to it, outside of any request. The queries above leave these out.
