# ADR 0006: Separate ledger sources from bibliographic works

## Status
Accepted for the v1.1.1 migration branch.

## Context
The frozen v1.1.1 specification defines Source IDs as publications or source clusters. The registry includes ordinary single publications, deliberately partial citations, paired studies, consensus/framework records, and umbrella literature clusters. Treating every `SRC-###` as exactly one bibliographic work would either destroy the frozen ledger identity or require fictitious merged citations.

## Decision
`SRC-###` remains the immutable ledger source identity in `sources`.

Individual publications, reports, statements, or other bibliographic works are stored in `bibliographic_works`.

`source_works` is the ordered many-to-many membership bridge between the two.

The raw registry wording from the frozen artifact may be retained in `sources.registry_text`. Bibliographic normalization may add structure but may not silently upgrade a PARTIAL or OPEN source to CLOSED.

## Consequences
- SRC-066 can remain one ledger source while containing two distinct 2003 works.
- SRC-067 can remain an umbrella literature cluster without inventing a single DOI/title.
- A future bibliographic correction can be audited at the work layer without renumbering historical ledger Source IDs.
- Evidence remains distinct from both source containers and bibliographic works.
- A source cluster cannot independently support a score promotion when the frozen ledger requires study-level closure.

## Rejected alternative
One `sources` row per publication with direct DOI/PMID fields as the sole representation. This fails for source clusters and would erase the source semantics of the frozen ledger.
