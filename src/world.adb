package body World with SPARK_Mode is
   procedure dischargeBattery is
   begin
      car.battery := car.battery - 1;
   end dischargeBattery;

   function warnLowBattery return Boolean is
   begin
      return car.battery < 20 and car.battery mod 5 = 0;
   end warnLowBattery;
end World;
