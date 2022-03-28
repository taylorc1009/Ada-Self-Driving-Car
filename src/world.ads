package World with SPARK_Mode is
   type BatteryLevel is new Integer range 0..100;
   type MilesPerHour is new Integer range 0..70;
   type CarGear is (PARKED, DRIVE, REVERSING);

   type CarType is record
      battery : BatteryLevel := 100;
      speed : MilesPerHour := 0;
      engineOn : Boolean := False;
      gear : CarGear := PARKED;
   end record;

   car : CarType;

   procedure dischargeBattery with
     Pre => car.battery > 0 and
     car.engineOn = True,
     Post => car.battery <= car.battery - 1;

   function warnLowBattery return Boolean;

   procedure engineSwitch with
     Pre => car.gear = PARKED,
     Post => car.engineOn /= car.engineOn;

   procedure changeGear (gear : in CarGear) with
     Pre => car.engineOn = True and
     gear /= car.gear and not
     (car.speed > 0 and gear /= DRIVE);
end World;
