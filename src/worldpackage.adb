package body WorldPackage with SPARK_Mode is
   procedure dischargeBattery is
   begin
      if car.gear /= PARKED then
         car.battery := car.battery - 1;
      end if;
   end dischargeBattery;

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
      if (value > 0 and Integer(car.speed) < Integer(world.curStreetSpeedLimit) and car.speed < MilesPerHour'Last) or (value < 0 and Integer(car.speed) > Integer(MilesPerHour'First) and car.speed > MilesPerHour'First) then
         car.speed := car.speed + value;
      end if;
   end modifySpeed;

   procedure emergencyStop is
   begin
      car.speed := 0;
   end emergencyStop;

   procedure generateSpeedLimit is
      optionRange : RandRange := RandRange(Integer(MilesPerHour'Last) / 10);
   begin
      world.curStreetSpeedLimit := MilesPerHour(RandGen.generate(optionRange) * 10);
   end generateSpeedLimit;

   procedure initialiseRoute is
   begin
      if world.destinationReached then
         world.numTurnsTaken := 0;
         world.destinationReached := False;

         generateSpeedLimit;

         world.numTurnsUntilDestination := WorldTurns(RandGen.generate(RandRange(WorldTurns'Last)));
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
      if Integer(world.numTurnsTaken) = Integer(world.numTurnsUntilDestination) then
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
      if world.destinationReached and Integer(car.speed) = 0 then
         return HAS_ARRIVED;
      elsif warnLowBattery then
         return LOW_BATTERY;
      elsif Integer(car.battery) <= Integer(car.speed) + 5 or car.battery <= MINIMUM_BATTERY then -- +5 so that the car does not use all the remaining battery to pull over
         return CHARGE_ENFORCED;
      end if;
      return GENERAL;
   end carConditionCheck;
end WorldPackage;
