package body RandGen is
   function generate(n : in RandRange) return RandRange is
   begin
      return RandInt.Random(gen) mod n + 1; -- +1 as Random is exclusive of the last value
   end generate;
begin
   RandInt.Reset(gen);
end RandGen;
