with Ada.Numerics.Discrete_Random;

package RandGen is
   type RandRange is new Integer range 0..100;
   package RandInt is new Ada.Numerics.Discrete_Random(RandRange);
   use RandInt;
   
   gen : RandInt.Generator;

   function generate(n : in RandRange) return Integer with
     Pre => 0 <= n and n <= 100,
     Post => generate'Result <= Integer(n);
end RandGen;
