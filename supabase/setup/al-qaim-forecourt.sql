-- =============================================================================
-- AL QAIM FILLING STATION CHAKWAL: part 6, the forecourt.
-- Run once, after parts 1 to 5.
--
--   Petrol Tank   15,000 L
--   Diesel Tank   25,000 L
--   Unit 1 = Nozzle 1, Nozzle 2   Diesel
--   Unit 2 = Nozzle 3, Nozzle 4   Diesel
--   Unit 3 = Nozzle 5, Nozzle 6   Petrol
--
-- Every meter starts at 0. The owner types each nozzle's real meter reading
-- under Settings -> pump units before the first day's readings: a meter is
-- read off the machine, never guessed.
--
-- Refuses to run once any reading exists, so it can never rewrite a trading
-- forecourt. One transaction: all of it or none of it.
-- =============================================================================
begin;

do $$
declare
  v_petrol uuid;
  v_diesel uuid;
  v_count  integer;
begin
  if exists (select 1 from public.nozzle_readings) then
    raise exception 'STOPPED: readings already exist. Change the forecourt from Settings instead. Nothing was changed.';
  end if;

  select id into v_petrol from public.tanks where fuel_type = 'petrol';
  select id into v_diesel from public.tanks where fuel_type = 'diesel';
  if v_petrol is null or v_diesel is null then
    raise exception 'STOPPED: expected one petrol tank and one diesel tank. Run parts 1 to 5 first. Nothing was changed.';
  end if;

  update public.tanks set capacity_litres = 15000 where id = v_petrol;
  update public.tanks set capacity_litres = 25000 where id = v_diesel;

  -- The seed made units 1 to 3 with nozzles A and B. Name them the way this
  -- pump does (1 to 6) and pipe each to its fuel.
  update public.nozzles n
     set nozzle_label = v.label,
         tank_id      = case when v.fuel = 'diesel' then v_diesel else v_petrol end
    from (values
            (1::smallint, 'A', '1', 'diesel'),
            (1::smallint, 'B', '2', 'diesel'),
            (2::smallint, 'A', '3', 'diesel'),
            (2::smallint, 'B', '4', 'diesel'),
            (3::smallint, 'A', '5', 'petrol'),
            (3::smallint, 'B', '6', 'petrol')
         ) as v (unit_number, old_label, label, fuel)
   where n.unit_number = v.unit_number
     and n.nozzle_label = v.old_label;
  get diagnostics v_count = row_count;
  if v_count <> 6 then
    raise exception 'STOPPED: expected to set up 6 nozzles, found %. Nothing was changed.', v_count;
  end if;
end;
$$;

-- What it looks like now. Expect 2 tanks and 6 nozzles exactly as listed above.
select 'tank' as what, t.name as name, t.fuel_type::text as fuel, t.capacity_litres::text as detail
  from public.tanks t
union all
select 'nozzle', 'Unit ' || n.unit_number || ' · Nozzle ' || n.nozzle_label, t.fuel_type::text,
       'meter starts at ' || n.starting_reading
  from public.nozzles n join public.tanks t on t.id = n.tank_id
 order by 1 desc, 2;

commit;
