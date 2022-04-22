with RandGen; use RandGen;

package WorldPackage with SPARK_Mode is
   -- Car
   type BatteryLevel is new Integer range 0..100;
   type MilesPerHour is new Integer range -3..20;
   type CarGear is (PARKED, DRIVE, REVERSING);
   MINIMUM_BATTERY : constant BatteryLevel := 20;
   WARNING_INTERMISSION : constant BatteryLevel := MINIMUM_BATTERY / 4;

   type CarType is record
      battery : BatteryLevel := 100;
      forceNeedsCharged : Boolean := False;
      speed : MilesPerHour := 0;
      engineOn : Boolean := False;
      gear : CarGear := PARKED;
      breaking : Boolean := False;
      parkRequested : Boolean := False;
      diagnosticsOn : Boolean := False;
   end record;

   car : CarType;

   procedure dischargeBattery with
     Global => (In_Out => car),
     Depends => (car => car),
     Pre => car.battery > 0
     and ((car.engineOn and car.gear /= PARKED)
          or not (not car.engineOn and car.gear = PARKED and not car.diagnosticsOn)),
     Post => car.battery = car.battery'Old - 1;

   function warnLowBattery return Boolean with
     Global => (Input => car),
     Post => (warnLowBattery'Result
              and car.battery mod WARNING_INTERMISSION = 0
              and car.battery <= MINIMUM_BATTERY
              and car.battery > 0)
     or (not warnLowBattery'Result
         and (car.battery mod WARNING_INTERMISSION > 0
              or car.battery > MINIMUM_BATTERY
              or car.battery = 0));

   procedure engineSwitch with
     Global => (In_Out => car),
     Depends => (car => car),
     Pre => car.gear = PARKED
     and not car.diagnosticsOn
     and car.speed = 0
     and car.battery > 0,
     Post => car.engineOn /= car.engineOn'Old;

   procedure changeGear (gear : in CarGear) with
     Global => (In_Out => car, Input => world),
     Depends => (car => (car, gear, world)),
     Pre => car.engineOn
     and gear /= car.gear
     and (car.speed = 0
          or (car.speed > 0 and gear = PARKED))
     and ((car.parkRequested
           xor world.obstructionPresent
           xor car.forceNeedsCharged)
          or not (car.parkRequested
                  or world.obstructionPresent
                  or car.forceNeedsCharged))
     and not (car.diagnosticsOn
              or (world.obstructionPresent and (car.speed /= 0 or gear /= REVERSING))
              or (car.forceNeedsCharged and (car.speed /= 0 or gear /= PARKED))
              or (gear /= PARKED and (car.battery <= MINIMUM_BATTERY
                                      or (car.parkRequested and car.speed = 0)))),
     Contract_Cases => (car.speed > 0 and gear = PARKED => car.parkRequested and car.gear = car.gear'Old,
                        world.obstructionPresent => car.gear = REVERSING and car.speed = 0,
                        (car.forceNeedsCharged or car.parkRequested) and car.speed = 0 => car.gear = PARKED,
                        others => car.gear /= car.gear'Old and car.gear = gear);

   procedure diagnosticsSwitch with
     Global => (In_Out => car),
     Depends => (car => car),
     Pre => not car.engineOn
     and car.gear = PARKED
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY,
     Post => car.diagnosticsOn /= car.diagnosticsOn'Old;

   function speedDecrementInvariant return Boolean is
     ((car.gear = REVERSING or (car.breaking and car.speed > 0))
      and not (car.breaking and car.speed < 0));

   procedure modifySpeed with
     Global => (In_Out => car, Input => world),
     Depends => (car => (car, world)),
     Pre => car.gear /= PARKED
     and car.engineOn
     and not car.diagnosticsOn
     and MilesPerHour'First <= car.speed
     and car.speed <= world.curStreetSpeedLimit
     and world.curStreetSpeedLimit >= 10
     and ((car.speed > 0 and car.gear = DRIVE)
          or (car.speed < 0 and car.gear = REVERSING)),
     Post => MilesPerHour'First <= car.speed
     and car.speed <= world.curStreetSpeedLimit,
     Contract_Cases => (car.breaking => (if car.speed'Old > 0 then 0 <= car.speed and car.speed < car.speed'Old
                                         elsif car.speed'Old < 0 then car.speed'Old < car.speed and car.speed <= 0
                                         else car.speed = 0 and car.speed = car.speed'Old),
                        others => car.speed = (if car.speed'Old = world.curStreetSpeedLimit and not speedDecrementInvariant then world.curStreetSpeedLimit
                                               elsif car.speed'Old = MilesPerHour'First and speedDecrementInvariant then MilesPerHour'First
                                               else car.speed'Old + (if speedDecrementInvariant then -1 else 1)));

   procedure emergencyStop with
     Global => (In_Out => (car, world)),
     Depends => (car => (car, world), world => world),
     Pre => car.speed > 0
     and car.battery > MINIMUM_BATTERY
     and car.engineOn
     and not (car.diagnosticsOn
              or car.forceNeedsCharged
              or world.obstructionPresent
              or car.parkRequested
              or world.turnIncoming
              or car.breaking)
     and car.gear = DRIVE
     and world.curStreetSpeedLimit >= 10,
     Post => car.speed = 0
     and world.obstructionPresent
     and car.gear = REVERSING;

   --World
   type WorldScenario is (ARRIVED, TURN, OBSTRUCTION, NO_SCENARIO); -- note that TURN is a special scenario as it has a higher probability of occurring
   type WorldMessage is (LOW_BATTERY, HAS_ARRIVED, CHARGE_ENFORCED, GENERAL, NO_MESSAGE);
   type WorldTurns is new Integer range 0..3;

   type WorldType is record
      curStreetSpeedLimit : MilesPerHour := 0;
      numTurnsUntilDestination : WorldTurns := 0;
      numTurnsTaken : WorldTurns := 0;
      destinationReached : Boolean := True; -- also used to determine whether the previous route was prematurely ended; will be False if this is the case
      turnIncoming : Boolean := False;
      obstructionPresent : Boolean := False;
   end record;

   world : WorldType;

   procedure generateSpeedLimit with
     Global => (In_Out => world, Proof_In => car, Input => generator),
     Depends => (world => (world, generator)),
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY
     and car.engineOn
     and not (car.diagnosticsOn
              or car.forceNeedsCharged),
     Post => world.curStreetSpeedLimit >= 10
     and world.curStreetSpeedLimit <= MilesPerHour'Last
     and world.curStreetSpeedLimit mod 10 = 0
     and world.turnIncoming = world.turnIncoming'Old
     and world.numTurnsTaken = world.numTurnsTaken'Old
     and world.numTurnsUntilDestination = world.numTurnsUntilDestination'Old;

   procedure initialiseRoute with
     Global => (In_Out => world, Proof_In => car, Input => generator),
     Depends => (world => (world, generator)),
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.battery > MINIMUM_BATTERY
     and car.speed = 0
     and (not world.destinationReached and world.curStreetSpeedLimit > 0)
     and not (car.diagnosticsOn
              or car.forceNeedsCharged
              or world.obstructionPresent)
     and world.numTurnsUntilDestination > 0,
     Post => world.curStreetSpeedLimit > 0
     and world.numTurnsUntilDestination > 0
     and not world.destinationReached;

   procedure carTurn with
     Global => (In_Out => (world, car), Input => generator),
     Depends => (world => (world, generator), car => (car, world)),
     Pre => car.engineOn
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY
     and car.gear = DRIVE
     and car.engineOn
     and not (car.diagnosticsOn
              or car.forceNeedsCharged
              or world.obstructionPresent
              or world.destinationReached)
     and Integer(world.numTurnsTaken) < Integer(world.numTurnsUntilDestination)
     and world.numTurnsUntilDestination > 0,
     Post => world.turnIncoming /= world.turnIncoming'Old
     and car.breaking = world.turnIncoming,
     Contract_Cases => (not world.turnIncoming => world.numTurnsTaken = world.numTurnsTaken'Old,
                        world.turnIncoming => world.numTurnsTaken > world.numTurnsTaken'Old);

   function generateScenario return WorldScenario with
     Global => (Input => (world, car, generator)),
     Pre => car.engineOn
     and car.battery > MINIMUM_BATTERY
     and car.gear = DRIVE
     and car.engineOn
     and not (car.diagnosticsOn
              or car.forceNeedsCharged
              or car.parkRequested
              or world.destinationReached
              or world.turnIncoming
              or world.obstructionPresent);

   function carConditionCheck return WorldMessage with
     Global => (Input => (world, car)),
     Pre => car.engineOn
     and car.battery > MINIMUM_BATTERY
     and car.gear /= PARKED
     and car.engineOn
     and not (car.diagnosticsOn
              or car.forceNeedsCharged);
end WorldPackage;
