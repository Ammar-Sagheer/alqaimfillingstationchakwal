-- =============================================================================
-- AL QAIM FILLING STATION CHAKWAL: the four placeholder suppliers removed.
-- Run on his database on 4 Oct 2026, after the forecourt setup.
--
-- Migration 067 seeds four placeholders ("Gas & Oil", "Fuel supplier 2",
-- "Fuel supplier 3", "Lubricant supplier") for an owner to rename. This pump
-- adds its real suppliers under Suppliers instead, so they were deleted while
-- nothing referred to them: no supplier entries, purchases, safe or bank
-- movements. Only rows still carrying the placeholder note are touched, so a
-- supplier he has since renamed or used is never removed. Safe to run again.
-- =============================================================================
delete from public.suppliers s
 where s.note = 'Placeholder. Rename it under Suppliers, or retire it.'
   and not exists (select 1 from public.supplier_ledger_entries e where e.supplier_id = s.id)
   and not exists (select 1 from public.fuel_purchases p where p.supplier_id = s.id)
   and not exists (select 1 from public.lubricant_purchases p where p.supplier_id = s.id);
