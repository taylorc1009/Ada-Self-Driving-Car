package body RandGen is
   function generate(n : in RandRange) return RandRange is
   begin
      return RandInt.Random(gen) mod n;
   end generate;
begin
   RandInt.Reset(gen);
end RandGen;
