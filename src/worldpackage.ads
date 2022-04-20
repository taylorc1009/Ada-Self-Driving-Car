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
     Post => car.battery < car.battery'Old;

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
     and not (car.speed > 0
              or car.forceNeedsCharged
              or car.diagnosticsOn
              or (car.speed < 0 and gear /= DRIVE)
              or (world.obstructionPresent and car.forceNeedsCharged))
     and gear /= car.gear,
     Post => (if car.speed > 0 and gear = PARKED and not car.forceNeedsCharged then car.parkRequested
              elsif gear = PARKED and not world.obstructionPresent then not car.parkRequested
              elsif gear /= car.gear and not (gear = PARKED and world.obstructionPresent) then car.gear /= car.gear'Old
              elsif world.obstructionPresent then car.gear /= PARKED);

   procedure diagnosticsSwitch with
     Global => (In_Out => car),
     Depends => (car => car),
     Pre => not car.engineOn
     and car.gear = PARKED
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY,
     Post => car.diagnosticsOn /= car.diagnosticsOn'Old;

   procedure modifySpeed (value : in MilesPerHour) with
     Global => (In_Out => car, Input => world),
     Depends => (car => (car, world, value)),
     Pre => car.gear /= PARKED
     and car.engineOn
     and car.battery > MINIMUM_BATTERY
     and (if car.breaking then (if car.speed > 0 then value = -1
                                elsif car.speed < 0 then value = 1)
          elsif car.gear = REVERSING then value = -1
          else value = -1)
     and not car.diagnosticsOn
     and MilesPerHour'First <= car.speed
     and car.speed <= world.curStreetSpeedLimit
     and world.curStreetSpeedLimit >= 10,
     Post => MilesPerHour'First <= car.speed
     and car.speed <= world.curStreetSpeedLimit
     and (if car.breaking then (if car.speed'Old > 0 then 0 <= car.speed and car.speed < car.speed'Old
                                elsif car.speed'Old < 0 then car.speed > car.speed'Old and car.speed <= 0
                                else car.speed = car.speed'Old)
          else car.speed = (if car.speed'Old = world.curStreetSpeedLimit and value > 0 then world.curStreetSpeedLimit
                            elsif car.speed'Old = MilesPerHour'First and value < 0 then MilesPerHour'First
                            else car.speed'Old + value));

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
      destinationReached : Boolean := True; -- used to determine whether an old route was interuppted; will be False if this is the case
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
     and world.curStreetSpeedLimit mod 10 = 0;

   procedure initialiseRoute with
     Global => (In_Out => world, Proof_In => car, Input => generator),
     Depends => (world => (world, generator)),
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.battery > MINIMUM_BATTERY
     and car.speed = 0
     and not car.diagnosticsOn
     and not car.forceNeedsCharged
     and world.numTurnsUntilDestination > 0
     and (not world.destinationReached
          or (world.destinationReached and world.numTurnsTaken = world.numTurnsUntilDestination)),
     Post => --world.curStreetSpeedLimit > 0 -- cannot be proved by this function as it is ensured by "generateSpeedLimit" instead
       world.numTurnsUntilDestination > 0;
       --and not world.destinationReached; -- for some reason, SPARK cannot prove this even though if it is ever True, the procedure will make it False

   procedure carTurn with
     Global => (In_Out => (world, car), Input => generator),
     Depends => (world => (world, generator), car => (car, world)),
     Pre => car.engineOn
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY
     and car.gear = DRIVE
     and car.engineOn
     and not (car.diagnosticsOn
              or car.forceNeedsCharged)
     and Integer(world.numTurnsTaken) < Integer(WorldTurns'Last);
     --Post => (world.turnIncoming /= world.turnIncoming'Old)
     --and (if world.turnIncoming then world.numTurnsTaken = world.numTurnsTaken'Old
     --     else world.numTurnsTaken > world.numTurnsTaken'Old);

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
              or world.obstructionPresent)
     and not car.parkRequested;

   function carConditionCheck return WorldMessage with
     Global => (Input => (world, car)),
     Pre => car.engineOn
     and car.battery > MINIMUM_BATTERY
     and car.gear /= PARKED
     and car.engineOn
     and not (car.diagnosticsOn
              or car.forceNeedsCharged);
end WorldPackage;
