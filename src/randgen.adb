package body RandGen is
   function generate(n : in RandRange) return Integer is
   begin
      return Integer(RandInt.Random(generator) mod n + 1); -- +1 as Random is exclusive of the last value
   end generate;
begin
   RandInt.Reset(generator);
end RandGen;
