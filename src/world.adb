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

   procedure diagnosticsSwitch is
   begin
      car.diagnosticsOn := car.diagnosticsOn /= True;
   end;

   procedure modifySpeed (value : in MilesPerHour) is
   begin
      car.speed := car.speed + value;
   end modifySpeed;

   procedure initialiseRoute is
   begin
      world.numTurnsTaken := 0;

      world.curStreetSpeedLimit := RandGen.generate(7) * 10;
      while world.curStreetSpeedLimit = 0 loop
         world.curStreetSpeedLimit := RandGen.generate(7) * 10;
      end loop;

      world.numTurnsUntilDestination := RandGen.generate(10);
      while world.curStreetSpeedLimit = 0 loop
         world.numTurnsUntilDestination := RandGen.generate(10);
      end loop;
   end initialiseRoute;
end World;
