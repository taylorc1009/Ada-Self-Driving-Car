package body WorldPackage with SPARK_Mode is
   procedure dischargeBattery is
   begin
      if (car.engineOn and car.gear /= PARKED) or not (not car.engineOn and car.gear = PARKED and not car.diagnosticsOn) then
         car.battery := car.battery - 1;
      end if;
   end dischargeBattery;

   function warnLowBattery return Boolean is
   begin
      return car.battery <= MINIMUM_BATTERY and car.battery mod WARNING_INTERMISSION = 0 and car.battery > 0; -- warnings will only be issued when the battery is at most 20%, and is a multiple of 5 as not to annoy the driver
   end warnLowBattery;

   procedure engineSwitch is
   begin
      if car.gear = PARKED and not (car.battery = 0 and not car.engineOn) and not car.diagnosticsOn then
         car.engineOn := car.engineOn /= True;
         if not car.engineOn then
            car.battery := 100;
            car.forceNeedsCharged := False;
         end if;
      end if;
   end engineSwitch;

   procedure changeGear (gear : in CarGear) is
   begin
      if car.engineOn then
         if car.speed = 0 and not (car.diagnosticsOn or (gear /= PARKED and car.forceNeedsCharged) or (gear = PARKED and world.obstructionPresent) or gear = car.gear) then
            car.gear := gear;
            if car.parkRequested then
               car.parkRequested := False;
            end if;
         elsif car.speed > 0 and gear = PARKED and not (car.forceNeedsCharged or world.obstructionPresent) then
            car.parkRequested := True;
         end if;
         car.breaking := car.parkRequested;
      end if;
   end changeGear;

   procedure diagnosticsSwitch is
   begin
      if not car.engineOn and car.battery > MINIMUM_BATTERY and car.speed = 0 and car.gear = PARKED then
         car.diagnosticsOn := car.diagnosticsOn /= True;
      end if;
   end;

   procedure modifySpeed is
      value : MilesPerHour := 1;
      invariant : Boolean := speedDecrementInvariant;
   begin
      if ((not invariant and car.speed < world.curStreetSpeedLimit) or (invariant and car.speed > MilesPerHour'First)) and not (car.breaking and car.speed = 0) then
         if invariant then
            value := -1;
         end if;
         car.speed := car.speed + value;
      end if;
   end modifySpeed;

   procedure emergencyStop is
   begin
      car.speed := 0;
      world.obstructionPresent := True;
      changeGear(REVERSING);
   end emergencyStop;

   procedure generateSpeedLimit is
      optionRange : RandRange := RandRange(MilesPerHour'Last / SPEED_LIMIT_STEP_FACTOR);
   begin
      world.curStreetSpeedLimit := MilesPerHour(RandGen.generate(optionRange)) * SPEED_LIMIT_STEP_FACTOR;
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
      car.breaking := world.turnIncoming;
      if not world.turnIncoming then
         world.numTurnsTaken := world.numTurnsTaken + 1;
         generateSpeedLimit;
      end if;
   end carTurn;

   function generateScenario return WorldScenario is
   begin
      if not (world.turnIncoming or world.destinationReached or car.forceNeedsCharged or car.parkRequested or car.diagnosticsOn or world.obstructionPresent or car.gear /= DRIVE) then
         if car.forceNeedsCharged or car.speed <= 0 then
            return NO_SCENARIO;
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
               return (if Integer(world.numTurnsTaken) = Integer(world.numTurnsUntilDestination) then ARRIVED else TURN);
            when others =>
               return NO_SCENARIO;
         end case;
      end if;
      return NO_SCENARIO;
   end generateScenario;

   function carConditionCheck return WorldMessage is
   begin
      if world.destinationReached and Integer(car.speed) = 0 then
         return HAS_ARRIVED;
      elsif warnLowBattery then
         return LOW_BATTERY;
      elsif (Integer(car.battery) <= Integer(car.speed) + 5 or car.battery <= MINIMUM_BATTERY) and not car.forceNeedsCharged then -- +5 so that the car does not use all the remaining battery to pull over
         return CHARGE_ENFORCED;
      elsif car.gear /= PARKED then
         return GENERAL;
      end if;
      return NO_MESSAGE;
   end carConditionCheck;
end WorldPackage;
