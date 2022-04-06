package body WorldPackage with SPARK_Mode is
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
      if car.gear = PARKED and not (car.battery = 0 and not car.engineOn) then
         car.engineOn := car.engineOn /= True;
         if car.engineOn = False then
            car.battery := 100;
         end if;
      end if;
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

   procedure generateSpeedLimit is
   begin
      world.curStreetSpeedLimit := RandGen.generate(3) * 10;
      while world.curStreetSpeedLimit = 0 loop
         world.curStreetSpeedLimit := RandGen.generate(3) * 10;
      end loop;
   end generateSpeedLimit;

   procedure initialiseRoute is
   begin
      world.numTurnsTaken := 0;
      world.lastDestinationReached := False;

      generateSpeedLimit;

      world.numTurnsUntilDestination := RandGen.generate(5);
      while world.curStreetSpeedLimit = 0 loop
         world.numTurnsUntilDestination := RandGen.generate(5);
      end loop;
   end initialiseRoute;

   procedure carTurned is
   begin
      world.numTurnsTaken := world.numTurnsTaken + 1;
      generateSpeedLimit;
   end carTurned;

   function generateScenario return WorldScenario is
   begin
      if world.numTurnsTaken = Integer'Value(world.numTurnsUntilDestination'Image) then
         return ARRIVED;
      end if;
      case RandGen.generate(100) is
         when 1 | 2 | 3 | 4 | 5 => -- 5% chance of unusual scenario
            case RandGen.generate(1) is -- adjust this integer to match the number of world scenarios the car can encounter
               when 1 =>
                  return OBSTRUCTION;
               when others =>
                  return NO_SCENARIO; -- shouldn't occur as long as the integer above mathes the number of scenarios
            end case;
         when 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 => -- 10% chance of turning
            return TURN;
         when others =>
            return NO_SCENARIO;
      end case;
   end;
end WorldPackage;
