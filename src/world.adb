package body World with SPARK_Mode is
   procedure dischargeBattery is
   begin
      car.battery := car.battery - 1;
   end dischargeBattery;

   function warnLowBattery return Boolean is
   begin
      -- warnings will only be issued when the battery is at most 20%, and is a multiple of 5 as not to annoy the driver
      return car.battery <= 20 and car.battery mod 5 = 0 and car.battery > 0;
   end warnLowBattery;

   procedure engineSwitch is
   begin
      car.engineOn := car.engineOn /= True;
   end;

   procedure changeGear (gear : in CarGear) is
   begin
      car.gear := gear;
   end changeGear;
end World;
