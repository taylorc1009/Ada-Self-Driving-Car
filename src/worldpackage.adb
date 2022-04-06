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
      if car.gear = PARKED and not (car.battery = 0 and not car.engineOn) and not car.diagnosticsOn then
         car.engineOn := car.engineOn /= True;
         if car.engineOn = False then
            car.battery := 100;
         end if;
      end if;
   end engineSwitch;

   procedure changeGear (gear : in CarGear) is
   begin
      if car.engineOn and car.speed = 0 and not car.diagnosticsOn then
         car.gear := gear;
      end if;
   end changeGear;

   procedure diagnosticsSwitch is
   begin
      if not car.engineOn and car.battery > 0 and car.speed = 0 and car.gear = PARKED then
         car.diagnosticsOn := car.diagnosticsOn /= True;
      end if;
   end;

   procedure modifySpeed (value : in MilesPerHour) is
   begin
      if (value > 0 and Integer'Value(car.speed'Image) < Integer'Value(world.curStreetSpeedLimit'Image)) or (value < 0 and Integer'Value(car.speed'Image) > 0) then
         car.speed := car.speed + value;
      end if;
   end modifySpeed;

   procedure emergencyStop is
   begin
      car.speed := 0;
   end emergencyStop;

   procedure generateSpeedLimit is
   begin
      world.curStreetSpeedLimit := RandGen.generate(2) * 10;
      while world.curStreetSpeedLimit = 0 loop
         world.curStreetSpeedLimit := RandGen.generate(2) * 10;
      end loop;
   end generateSpeedLimit;

   procedure initialiseRoute is
   begin
      world.numTurnsTaken := 0;
      world.lastDestinationReached := False;

      generateSpeedLimit;

      world.numTurnsUntilDestination := RandGen.generate(3);
      while world.numTurnsUntilDestination = 0 loop
         world.numTurnsUntilDestination := RandGen.generate(3);
      end loop;
   end initialiseRoute;

   procedure carTurned is
   begin
      world.numTurnsTaken := world.numTurnsTaken + 1;
      world.turnIncoming := False;
      generateSpeedLimit;
   end carTurned;

   procedure arriveAtDestination is
   begin
      world.destinationReached := True;
      world.lastDestinationReached := True;
      changeGear(PARKED);
   end arriveAtDestination;

   function generateScenario return WorldScenario is
   begin
      if world.numTurnsTaken = Integer'Value(world.numTurnsUntilDestination'Image) then
         return ARRIVED;
      end if;
      case RandGen.generate(100) is
         when 1 | 2 | 3 | 4 | 5 => -- 5% chance of unusual scenario
            case RandGen.generate(1) is -- adjust this integer to match the number of world scenarios the car can encounter
               when 0 =>
                  return OBSTRUCTION;
               when others =>
                  return NO_SCENARIO; -- shouldn't occur as long as the integer above mathes the number of scenarios
            end case;
         when 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 => -- 10% chance of turning
            return TURN;
         when others =>
            return NO_SCENARIO;
      end case;
   end generateScenario;

   function carConditionCheck return WorldMessage is
   begin
      if warnLowBattery then
         return LOW_BATTERY;
      elsif world.destinationReached and Integer'Value(car.speed'Image) = 0 then
         return HAS_ARRIVED;
      end if;
      return GENERAL;
   end carConditionCheck;
end WorldPackage;
