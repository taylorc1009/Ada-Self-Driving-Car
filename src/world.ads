package World with SPARK_Mode is
   type BatteryLevel is new Integer range 0..100;
   type MilesPerHour is new Integer range 0..70;
   type EngineState is new Boolean;
   type CurrentGear is (PARKED, DRIVE, REVERSING);

   type CarType is record
      battery : BatteryLevel := 100;
      speed : MilesPerHour := 0;
      engineOn : EngineState := False;
      gear : CurrentGear := PARKED;
   end record;

   car : CarType;

   procedure dischargeBattery with
     Pre => car.battery > 0,
     Post => car.battery <= car.battery - 1 and
     car.engineOn = True;
end World;
