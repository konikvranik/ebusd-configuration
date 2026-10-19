import "@ebusd/ebus-typespec";
import "./_templates.tsp";
using Ebus;
using Ebus.Num;
using Ebus.Dtm;
using Ebus.Str;
namespace Vaillant;

namespace Hcmode_inc {
  // HC operation mode

  /** date/time */
  @inherit(rm)
  @ext(0)
  model DateTime {
    dcfstate: dcfstate;
    btime: btime;
    bdate: bdate;
    temp: temp2;
  }

  /** outside temperature */
  @inherit(rm)
  @ext(0x16)
  model Status16 {
    value: temp;
  }
  // HC operation mode2

  /** default *r */
  @base(MF, 0x11)
  model r_1 {}

  /** default *uw */
  @write
  @passive
  @base(MF, 0x10)
  model uw {}

  /** default *wi for user level "install" */
  @write
  @auth("install")
  @base(MF, 0x10)
  model wi_1 {}

  /** Operation mode.
   *  IMPORTANT (verified live on Protherm Ray 14 KE, SW0107/HW7503):
   *  Temperature overrides apply in ALL modes (auto included), but ONLY with
   *  values <= the setpoints on the appliance panel ("clamp"): higher values
   *  are ACKed and silently ignored (documented in the Ray service manual -
   *  the room controller cannot exceed the panel limits).
   *    - hcmode=0 (auto):  BOTH temperatures are applied (verified: panel
   *                        TUV 65 / heating 55, eBUS "auto;36.5;50;..." =>
   *                        boiler FlowTempDesired 36.5, HwcTempDesired 50.0)
   *    - hcmode=1 (off):   frost protection only
   *    - hcmode=2 (heat):  heating only, flowtempdesired applies
   *    - hcmode=3 (water): DHW priority, hwctempdesired applies (tank charges)
   *  The applied mode/values revert to the internal panel values approx.
   *  10-20 min after the last SetMode message - send periodically to keep them.
   *  Example - legionella thermal disinfection (weekly), with panel TUV >= 65:
   *    auto;50;65;50;0;0;0;0;0;0  => tank charges to 65C
   *    auto;50;50;50;0;0;0;0;0;0  => back to normal operation */
  @inherit(uw, wi_1)
  @ext(0)
  model SetMode {
    /** operating mode: 0=auto (heating+DHW), 1=off (frost protection only), 2=heat only, 3=water only (DHW priority) */
    hcmode: hcmode;
    /** heating flow temperature setpoint - applies in auto and heat modes, clamped by the panel heating setpoint */
    flowtempdesired: temp1;
    /** DHW storage temperature setpoint - applies in auto and water modes (tank charges to it), clamped by the panel TUV setpoint */
    hwctempdesired: temp1;
    /** DHW charging flow temperature - not used by this model */
    hwcflowtempdesired: temp0;

    @maxLength(1)
    ign: IGN;

    disablehc: BI0;
    disablehwctapping: BI1;
    disablehwcload: BI2;

    @maxLength(1)
    ign_1: IGN;

    remoteControlHcPump: BI0;
    releaseBackup: BI1;
    releaseCooling: BI2;
  }
  // potential last byte: currentmode,s,UCH,0=off;1=standby;2=heat;3=water

  /** Vorlauftemperatur/Rücklauftemperatur/Aussentemperatur/WW Temperatur/Speichertemperatur/Pumpenstatus */
  @inherit(r_1)
  @ext(1)
  model Status01 {
    /** flow temperature */
    temp: temp1;

    /** return temperature */
    temp_1: temp1;

    /** outside temperature */
    temp_2: temp2;

    /** hot water temperature */
    temp_3: temp1;

    /** storage temperature */
    temp_4: temp1;

    /** pump status */
    pumpstate: pumpstate;

    @maxLength(2)
    extra: HEX;
  }

  /** Betriebsart/Maximaltemperatur/ReglerCurrentTemp/Maximaltemperatur/ReglerCurrentTemp */
  @inherit(r_1)
  @ext(0x2)
  model Status02 {
    /** hot water mode */
    hwcmode: hwcmode;

    /** Nastavená hodnota pro teplotu nabíjení zásobníku */
    temp: temp0;

    /** Překročení teploty nabíjení zásobníku */
    temp_1: temp1;

    /** Max. teplota TV */
    temp_2: temp0;

    /** Max. teplota TV */
    temp_3: temp1;

    @maxLength(1)
    extra: HEX;
  }

  /** Status */
  @inherit(r_1)
  @ext(0x3)
  model Status {
    temp: temp;
    press: press;
    press_1: press;
    hcmode: hcmode2;
  }

  /** default *uw */
  @write
  @passive
  @base(MF, 0x12)
  model uw_1 {}

  /** Status circulation pump */
  @inherit(uw_1)
  @ext(0)
  model StatusCirPump {
    @values(Values_StatusCirPump)
    value: UCH;
  }

  enum Values_StatusCirPump {
    off: 0,
    on: 100,
  }
}
