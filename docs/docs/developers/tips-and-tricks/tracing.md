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

Tracing is only enabled when the `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable is set. Otherwise, MarkUs does not load any OpenTelemetry code.

## Starting MarkUs with tracing

The `compose.otel.yaml` file adds an `otel-lgtm` service running [Grafana's otel-lgtm image](https://github.com/grafana/docker-otel-lgtm), which bundles an OpenTelemetry Collector, Grafana and Tempo (where the traces are stored). It also sets `OTEL_EXPORTER_OTLP_ENDPOINT` for the `rails`, `resque` and `resque-scheduler` services so that they send their traces to it.

To start MarkUs with tracing, pass both Compose files:

```bash
docker compose -f compose.yaml -f compose.otel.yaml up
```

To turn tracing off again, start MarkUs without `compose.otel.yaml` (the `--remove-orphans` option removes the `otel-lgtm` container):

```bash
docker compose up --remove-orphans
```

> 🗒️ **Note**: the otel-lgtm image is only meant for development. It keeps traces inside its container, so they are lost when the container is removed.

## Viewing traces

1. Use MarkUs as usual at `http://localhost:3000/csc108`.
2. Open Grafana at `http://localhost:3001` (you do not need to sign in), select **Explore**, and choose the **Tempo** data source.
3. Select **TraceQL**, enter one of the following queries, and select **Run query**:
    - `{ kind = server }` lists requests. Each request trace is named after the request's route (for example, `GET /csc108/courses/:course_id/assignments`), and contains spans for the database queries and views inside it.
    - `{ kind = consumer }` lists background jobs. Each job has two traces: one from Resque, and one from Active Job that contains the job's database queries.
4. Select a trace ID to open the trace, and select a span to see its details.

A job's trace is not part of the trace of the request that queued it. Instead, the two are linked: open the job's trace, select its first span, and select **View Linked Span** under **References** to open the request.

Tempo also contains short traces of database queries and Redis commands that MarkUs runs outside of requests and jobs (for example, `Course query`, or `HSET` from the Resque worker's heartbeat). The queries above leave these out.
