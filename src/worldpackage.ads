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
     and car.gear /= PARKED;

   function warnLowBattery return Boolean with
     Pre => car.engineOn
     and car.battery > MINIMUM_BATTERY;

   procedure engineSwitch with
     Pre => car.gear = PARKED
     and not car.diagnosticsOn
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY,
     Post => car.engineOn /= car.engineOn'Old;

   procedure changeGear (gear : in CarGear) with
     Pre => car.engineOn
     and not (car.speed > 0
              or car.forceNeedsCharged
              or car.diagnosticsOn),
     Post => --car.gear /= car.gear'Old and -- SPARK complains that it cannot prove this because the parameter "gear" could equal any gear
       car.gear = DRIVE
       or car.gear = PARKED
       or car.gear = REVERSING;

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
     and car.battery > MINIMUM_BATTERY
     and (value = 1 or value = -1)
     and not car.diagnosticsOn
     and MilesPerHour'First <= car.speed
     and car.speed <= MilesPerHour'Last,
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
   type WorldMessage is (LOW_BATTERY, HAS_ARRIVED, CHARGE_ENFORCED, GENERAL);

   type WorldType is record
      curStreetSpeedLimit : MilesPerHour := 0;
      numTurnsUntilDestination : RandRange := 0;
      numTurnsTaken : Integer := 0;
      destinationReached : Boolean := True; -- used to determine whether an old route was interuppted; will be False if this is the case
      turnIncoming : Boolean := False;
      obstructionPresent : Boolean := False;
   end record;

   world : WorldType;

   procedure generateSpeedLimit with
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => world.curStreetSpeedLimit >= 10
     and world.curStreetSpeedLimit <= MilesPerHour'Last
     and world.curStreetSpeedLimit mod 10 = 0;

   procedure initialiseRoute with
     Pre => car.engineOn
     and car.gear /= PARKED
     and car.battery > MINIMUM_BATTERY
     and car.speed = 0
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => --world.curStreetSpeedLimit > 0 -- cannot be ensured by this function as it is ensured by "generateSpeedLimit" instead
       world.numTurnsUntilDestination > 0
       and not world.destinationReached;

   procedure carTurn with
     Pre => car.engineOn
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY
     and car.gear = DRIVE
     and not car.diagnosticsOn
     and not car.forceNeedsCharged
     and world.numTurnsTaken < Integer(RandRange'Last);

   procedure divertObstruction with
     Pre => car.engineOn
     and car.speed = 0
     and car.battery > MINIMUM_BATTERY
     and ((car.gear = DRIVE and not world.obstructionPresent)
          or (car.gear = REVERSING and world.obstructionPresent))
     and car.gear /= PARKED
     and not car.diagnosticsOn
     and not car.forceNeedsCharged,
     Post => world.obstructionPresent /= world.obstructionPresent'Old;
     -- SPARK cannot prove that the gear will not be set to PARKED by this function, based on "changeGear" Preconditions
     --(car.gear = DRIVE and not world.obstructionPresent)
     --or (car.gear = REVERSING and world.obstructionPresent);

   function generateScenario return WorldScenario with
     Pre => car.engineOn
     and car.battery > MINIMUM_BATTERY
     and car.gear = DRIVE
     and not car.diagnosticsOn
     and not car.forceNeedsCharged
     and not car.parkRequested;

   function carConditionCheck return WorldMessage with
     Pre => car.engineOn
     and car.battery > MINIMUM_BATTERY
     and car.gear /= PARKED
     and not car.forceNeedsCharged
     and not car.diagnosticsOn;
end WorldPackage;
