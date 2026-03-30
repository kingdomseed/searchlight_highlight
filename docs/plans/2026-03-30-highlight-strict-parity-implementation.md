# Highlight Strict Parity Implementation Plan

Date: 2026-03-30

## Goal

Build `searchlight_highlight` as a strict-parity Dart reimplementation of
Orama Highlight.

## Architecture

Treat Orama Highlight source as the contract. Drive the implementation with
failing tests for:

- exported public API
- default options and strategy behavior
- HTML rendering
- position offsets
- trim semantics
- null and empty input tolerance

## Rules

- match Orama exactly where the audited implementation is clear
- if Orama is not a plugin, do not create a plugin just to fit Searchlight
- add no Dart-only ergonomic surface before parity is complete

## Execution Order

1. Bootstrap the package and lock the audited contract in docs.
2. Add failing public API parity tests.
3. Add failing behavior tests copied from the audited Orama scenarios.
4. Implement the minimal package code to make those tests pass.
5. Add a small example that exercises the public parity API honestly.
6. Finalize docs and verify with analyze, test, and pub dry-run.
