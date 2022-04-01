package World with SPARK_Mode is
   type BatteryLevel is new Integer range 0..100;
   type MilesPerHour is new Integer range 0..70;
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

   procedure modifySpeed (direction : in Integer) with
     Pre => (direction = 1 or direction = -1) and
     car.gear /= PARKED and
     car.engineOn and
     car.battery > 0,
     Post => car.speed /= car.speed;
end World;
