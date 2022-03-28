package body World with SPARK_Mode is
   procedure dischargeBattery is
   begin
      car.battery := car.battery - 1;
   end dischargeBattery;
end World;
