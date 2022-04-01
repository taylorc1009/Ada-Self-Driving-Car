with Ada.Numerics.Discrete_Random;

package RandGen is
   type RandRange is new Integer range 0..100;
   package RandInt is new Ada.Numerics.Discrete_Random(RandRange);
   use RandInt;
   
   gen : RandInt.Generator;

   function generate(n : in RandRange) return RandRange;
end RandGen;
