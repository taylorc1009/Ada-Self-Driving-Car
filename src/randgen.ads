with Ada.Numerics.Discrete_Random;

package RandGen is
   type RandRange is new Integer range 1..100;
   package RandInt is new Ada.Numerics.Discrete_Random(RandRange);
   use RandInt;
   
   generator : RandInt.Generator;

   function generate(n : in RandRange) return Integer with
     Pre => n <= RandRange'Last,
     Post => Integer(RandRange'First) <= generate'Result
     and generate'Result <= Integer(n);
end RandGen;
