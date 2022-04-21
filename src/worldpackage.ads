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
     and car.speed = 0
     and not (car.forceNeedsCharged
              or car.diagnosticsOn
              or (world.obstructionPresent and (car.forceNeedsCharged
                                                or car.gear = PARKED
                                                or gear /= REVERSING))
              or (car.battery <= MINIMUM_BATTERY and gear /= PARKED)),
     Contract_Cases => (car.speed > 0 and gear = PARKED => car.parkRequested and car.gear = car.gear'Old,
                        world.obstructionPresent => car.gear = REVERSING and car.speed = 0,
                        car.forceNeedsCharged and car.speed = 0 => car.gear = PARKED,
                        others => car.gear /= car.gear'Old);

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
     and car.battery > MINIMUM_BATTERY
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
     and world.curStreetSpeedLimit mod 10 = 0;

   procedure initialiseRoute with
     Global => (In_Out => world, Proof_In => car, Input => generator),
     Depends => (world => (world, generator)),
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.battery > MINIMUM_BATTERY
     and car.speed = 0
     and not (car.diagnosticsOn
              or car.forceNeedsCharged
              or world.obstructionPresent
              or (world.destinationReached
                  or (world.destinationReached
                      and world.numTurnsTaken = world.numTurnsUntilDestination)))
     and world.numTurnsUntilDestination > 0,
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
              or car.forceNeedsCharged
              or world.obstructionPresent
              or world.destinationReached)
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
