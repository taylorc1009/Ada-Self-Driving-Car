with RandGen; use RandGen;

package WorldPackage with SPARK_Mode is
   -- Car

   type BatteryLevel is new Integer range 0..100;
   type MilesPerHour is new Integer range -1..70;
   type CarGear is (PARKED, DRIVE, REVERSING);

   type CarType is record
      battery : BatteryLevel := 100;
      speed : MilesPerHour := 0;
      engineOn : Boolean := False;
      gear : CarGear := PARKED;
      diagnosticsOn : Boolean := False;
   end record;

   car : CarType;

   procedure dischargeBattery with
     Pre => car.battery > 0 and
     car.engineOn = True,
     Post => car.battery <= car.battery - 1;

   function warnLowBattery return Boolean;

   procedure engineSwitch with
     Pre => car.gear = PARKED and
     not car.diagnosticsOn,
     Post => car.engineOn /= car.engineOn;

   procedure changeGear (gear : in CarGear) with
     Pre => car.engineOn = True and
     gear /= car.gear and
     not (car.speed > 0 or
         (car.battery <= 10 and car.gear = PARKED) or
         car.diagnosticsOn),
     Post => car.gear /= car.gear;

   procedure diagnosticsSwitch with
     Pre => not car.engineOn and
     car.gear = PARKED and
     car.speed = 0 and
     car.battery >= 50,
     Post => car.diagnosticsOn /= car.diagnosticsOn;

   procedure modifySpeed (value : in MilesPerHour) with
     Pre => car.gear /= PARKED and
     car.engineOn and
     car.battery > 0 and
     (value = 1 or value = -1),
     Post => car.speed /= car.speed;


   --World
   type WorldScenario is (ARRIVED, TURN, OBSTRUCTION, NO_SCENARIO); -- note that TURN is a special scenario as it has a higher probability of occurring

   type WorldType is record
      curStreetSpeedLimit : RandRange := 0;
      numTurnsUntilDestination : RandRange := 0;
      numTurnsTaken : Integer := 0;
   end record;

   world : WorldType;

   procedure generateSpeedLimit;

   procedure initialiseRoute;

   procedure carTurned;

   function generateScenario return WorldScenario;
end WorldPackage;
