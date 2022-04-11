package body WorldPackage with SPARK_Mode is
   procedure dischargeBattery is
   begin
      if car.gear /= PARKED then
         car.battery := car.battery - 1;
      end if;
   end dischargeBattery;

   procedure checkNeedsChargeEnforce is
   begin
      car.forceNeedsCharged := Integer(car.battery) <= Integer(car.speed) + 5; -- +5 so that the car does not use all the remaining battery to pull over
   end checkNeedsChargeEnforce;

   function warnLowBattery return Boolean is
   begin
      return car.battery <= MINIMUM_BATTERY and car.battery mod 5 = 0 and car.battery > 0; -- warnings will only be issued when the battery is at most 20%, and is a multiple of 5 as not to annoy the driver
   end warnLowBattery;

   procedure engineSwitch is
   begin
      if car.gear = PARKED and not (car.battery = 0 and not car.engineOn) and not car.diagnosticsOn then
         car.engineOn := car.engineOn /= True;
         if not car.engineOn then
            car.battery := 100;
         end if;
      end if;
   end engineSwitch;

   procedure changeGear (gear : in CarGear) is
   begin
      if car.engineOn and car.speed <= 0 and not car.diagnosticsOn and car.battery >= MINIMUM_BATTERY then
         car.gear := gear;
         if car.parkRequested then
            car.parkRequested := False;
         end if;
      elsif car.speed > 0 and gear = PARKED and not car.forceNeedsCharged then
         car.parkRequested := True;
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
      if (value > 0 and Integer'Value(car.speed'Image) < Integer'Value(world.curStreetSpeedLimit'Image)) or (value < 0 and Integer'Value(car.speed'Image) > Integer'Value(MilesPerHour'First'Image)) then
         car.speed := car.speed + value;
      end if;
   end modifySpeed;

   procedure emergencyStop is
   begin
      car.speed := 0;
   end emergencyStop;

   procedure generateSpeedLimit is
      maxSpeedOption : Integer := (Integer'Value(MilesPerHour'Last'Image) / 10) + 1; -- +1 as RandGen is exclusive of the last value
      optionRandRange : RandRange := RandRange'Value(maxSpeedOption'Image);
   begin
      world.curStreetSpeedLimit := RandGen.generate(optionRandRange) * 10;
      while world.curStreetSpeedLimit = 0 loop
         world.curStreetSpeedLimit := RandGen.generate(optionRandRange) * 10;
      end loop;
   end generateSpeedLimit;

   procedure initialiseRoute is
   begin
      if world.lastDestinationReached then
         world.numTurnsTaken := 0;
         world.lastDestinationReached := False;
         world.destinationReached := False;

         generateSpeedLimit;

         world.numTurnsUntilDestination := RandGen.generate(3);
         while world.numTurnsUntilDestination = 0 loop
            world.numTurnsUntilDestination := RandGen.generate(3);
         end loop;
      end if;
   end initialiseRoute;

   procedure carTurn is
   begin
      world.turnIncoming := world.turnIncoming /= True;
      if not world.turnIncoming then
         world.numTurnsTaken := world.numTurnsTaken + 1;
         generateSpeedLimit;
      end if;
   end carTurn;

   procedure arriveAtDestination is
   begin
      world.lastDestinationReached := True;
      changeGear(PARKED);
   end arriveAtDestination;

   procedure divertObstruction is
   begin
      world.obstructionPresent := world.obstructionPresent /= True;
      if world.obstructionPresent then
         changeGear(REVERSING);
      else
         changeGear(DRIVE);
      end if;
   end divertObstruction;

   function generateScenario return WorldScenario is
   begin
      if world.numTurnsTaken = Integer'Value(world.numTurnsUntilDestination'Image) then
         return (if RandGen.generate(100) < 15 then ARRIVED else NO_SCENARIO);
      elsif car.forceNeedsCharged or car.speed <= 0 then
         return NO_SCENARIO;
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
      if world.destinationReached and Integer'Value(car.speed'Image) = 0 then
         return HAS_ARRIVED;
      elsif warnLowBattery then
         return LOW_BATTERY;
      end if;
      return GENERAL;
   end carConditionCheck;
end WorldPackage;
