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
   *  hcmode and flowtempdesired take effect; flowtempdesired applies in auto
   *  and heat modes (shows up in property d.05, clamped by the panel heating
   *  maximum).
   *  hwctempdesired WORKS as a temporary override of the panel DHW setpoint
   *  (verified by A/B test: periodic "auto;f;50;50" pins the tank at 50 and
   *  d.06/d.07 read 50; after the telegrams stop, both revert to the panel
   *  setpoint and the tank charges there). Values above the panel setpoint
   *  were not tested (panel was already at 65 here).
   *  d.06 HwcTempDesired / d.07 StorageTempDesired mirror the EFFECTIVE
   *  target but update SLOWLY (minutes / charge cycle boundaries) - do not
   *  judge acceptance of a write by reading them back seconds later.
   *  hwcflowtempdesired is the DHW charge flow cap: the boiler charges with
   *  flow ~= hwctempdesired + 2..3K margin but not beyond hwcflowtempdesired,
   *  so a target above hwcflowtempdesired is physically unreachable (verified:
   *  target 65 + hwcflow 50 => tank stagnant at ~50 for a full hour; target 65
   *  + hwcflow 80 => flow 67.5, tank charges to 65). Keep it above the target.
   *  New values apply at charge-cycle start / within minutes; a running tank
   *  charge is not aborted instantly.
   *  The applied mode/values revert to the internal panel values approx.
   *  10-20 min after the last SetMode message - send periodically to keep them. */
  @inherit(uw, wi_1)
  @ext(0)
  model SetMode {
    /** operating mode: 0=auto (heating+DHW), 1=off (frost protection only), 2=heat only, 3=water only (DHW priority) */
    hcmode: hcmode;
    /** heating flow temperature setpoint - applies in auto and heat modes, clamped by the panel heating setpoint */
    flowtempdesired: temp1;
    /** DHW storage temperature setpoint - overrides the panel DHW setpoint while refreshed periodically (see header note) */
    hwctempdesired: temp1;
    /** DHW charging flow temperature - cap for the charge flow; keep above hwctempdesired or the target is unreachable (see header note) */
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
