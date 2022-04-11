with RandGen; use RandGen;

package WorldPackage with SPARK_Mode is
   -- Car
   type BatteryLevel is new Integer range 0..100;
   type MilesPerHour is new Integer range -3..20;
   type CarGear is (PARKED, DRIVE, REVERSING);
   MINIMUM_BATTERY : constant BatteryLevel := 20;

   type CarType is record
      battery : BatteryLevel := 100;
      forceNeedsCharged : Boolean := False;
      speed : MilesPerHour := 0;
      engineOn : Boolean := False;
      gear : CarGear := PARKED;
      parkRequested : Boolean := False;
      diagnosticsOn : Boolean := False;
   end record;

   car : CarType;

   procedure dischargeBattery with
     Pre => car.battery > 0
     and car.engineOn
     and car.gear /= PARKED,
     Post => car.battery = car.battery - 1;

   procedure checkNeedsChargeEnforce with
     Pre => car.engineOn
     and car.gear /= PARKED
     and not car.forceNeedsCharged
     and car.battery > 0;

   function warnLowBattery return Boolean with
     Pre => car.engineOn
     and car.battery > 0;

   procedure engineSwitch with
     Pre => car.gear = PARKED
     and not car.diagnosticsOn
     and car.speed = 0
     and car.battery > 0,
     Post => car.engineOn
     or not car.engineOn;

   procedure changeGear (gear : in CarGear) with
     Pre => car.engineOn = True
     and gear /= car.gear
     and not (car.speed > 0
              or (car.battery <= 10 and car.gear = PARKED)
              or car.diagnosticsOn),
     Post => car.gear = DRIVE
     or car.gear = REVERSING
     or car.gear = PARKED;

   procedure diagnosticsSwitch with
     Pre => not car.engineOn
     and car.gear = PARKED
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY,
     Post => car.diagnosticsOn
     or not car.diagnosticsOn;

   procedure modifySpeed (value : in MilesPerHour) with
     Pre => car.gear /= PARKED
     and car.engineOn
     and car.battery > 0
     and (value = 1 or value = -1)
     and not car.diagnosticsOn,
     Post => car.speed >= MilesPerHour'First
     and car.speed <= MilesPerHour'Last;

   procedure emergencyStop with
     Pre => car.speed > 0
     and car.engineOn
     and not car.diagnosticsOn
     and car.gear = DRIVE,
     Post => car.speed = 0;

   --World
   type WorldScenario is (ARRIVED, TURN, OBSTRUCTION, NO_SCENARIO); -- note that TURN is a special scenario as it has a higher probability of occurring
   type WorldMessage is (LOW_BATTERY, HAS_ARRIVED, GENERAL);

   type WorldType is record
      curStreetSpeedLimit : RandRange := 0;
      numTurnsUntilDestination : RandRange := 0;
      numTurnsTaken : Integer := 0;
      lastDestinationReached : Boolean := True;
      destinationReached : Boolean := False;
      turnIncoming : Boolean := False;
      obstructionPresent : Boolean := False;
   end record;

   world : WorldType;

   procedure generateSpeedLimit with
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.speed = 0
     and car.battery > 0
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => world.curStreetSpeedLimit > 0;

   procedure initialiseRoute with
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.battery > 0
     and car.speed = 0
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => world.curStreetSpeedLimit > 0
     and world.numTurnsUntilDestination > 0
     and not world.destinationReached
     and not world.lastDestinationReached;

   procedure carTurn with
     Pre => car.engineOn
     and car.speed = 0
     and car.battery > 0
     and car.gear = DRIVE
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => world.numTurnsTaken = world.numTurnsTaken + 1;

   procedure arriveAtDestination with
     Pre => car.engineOn
     and car.speed = 0
     and car.battery > 0
     and car.gear = DRIVE
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => world.lastDestinationReached
     and car.gear = PARKED;

   procedure divertObstruction with
     Pre => car.engineOn
     and car.speed = 0
     and car.battery > 0
     and car.gear = DRIVE
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => car.gear /= PARKED;

   function generateScenario return WorldScenario with
     Pre => car.engineOn
     and car.battery > 0
     and car.gear = DRIVE
     and not car.diagnosticsOn
     and not car.forceNeedsCharged
     and not car.parkRequested;

   function carConditionCheck return WorldMessage with
     Pre => car.engineOn
     and car.battery > 0
     and car.gear /= PARKED
     and not car.forceNeedsCharged
     and not car.diagnosticsOn;
end WorldPackage;
