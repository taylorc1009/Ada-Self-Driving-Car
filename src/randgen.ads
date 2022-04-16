with Ada.Numerics.Discrete_Random;

package RandGen is
   type RandRange is new Integer range 1..100;
   package RandInt is new Ada.Numerics.Discrete_Random(RandRange);
   use RandInt;
   
   generator : RandInt.Generator;

   function generate(n : in RandRange) return Integer with
     Post => generate'Result <= Integer(n)
     and generate'Result >= Integer(RandRange'First)
     and generate'Result <= Integer(RandRange'Last);
end RandGen;
