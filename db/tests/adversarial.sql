-- Adversarial database fixtures
-- These tests intentionally attempt forbidden states.
-- Execute against a disposable test database after schema + migrations.
--
-- Harness rule: a test passes only when the specific expected failure occurs.
-- Unrelated FK, type, syntax, or trigger failures MUST fail the test.

-- A1: CMC 4 without causal manipulation must fail for