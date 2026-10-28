import { getCalculationTemperatures, calculateShellThickness, getAccurateSaturationTemperature } from './src/utils/mechanicalCalc.js';
import { calculateMainSteamNozzle } from './src/utils/nozzleCalc.js';

let allPassed = true;
function assert(condition, message) {
  if (!condition) {
    console.error('FAILED: ' + message);
    allPassed = false;
  } else {
    console.log('PASSED: ' + message);
  }
}

console.log("Running tests...");

// Test saturation temp (approx)
const ts = getAccurateSaturationTemperature(9); // 9 bar abs
assert(Math.abs(ts - 175.4) < 1.0, `Saturation temp is approx 175.4 at 9 bar abs. Got ${ts}`);

// Test calculation temp
const tc_shell = getCalculationTemperatures(175.4, 'shell');
assert(tc_shell === 195.4, `Shell calc temp should be ts + 20. Got ${tc_shell}`);

// Test shell thickness
const P_MPa = 0.8;
const Di = 1200;
const f = 130; // some dummy stress
const shellCalc = calculateShellThickness(P_MPa, Di, f);
// ec_calc = (0.8 * 1200) / (2 * 130 * 0.85 - 0.8) = 960 / 220.2 = 4.359
// total = 4.359 + 1 = 5.359. min is 6. nominal is 6
assert(shellCalc.e_nom === 6, `Shell thickness for dummy stress should be 6. Got ${shellCalc.e_nom}`);

// Test nozzles
const steam = calculateMainSteamNozzle(1000, 8, 20); // 1000 kg/h, 8 bar eff, 20 m/s
// v'' at 9 bar abs = 0.215
// q_v = 1000 * 0.215 / 3600 = 0.0597 m3/s
// A = q_v / 20 = 0.00298 m2
// d = sqrt(4 * A / pi) = sqrt(0.00379) = 0.0616 m = 61.6 mm
// next standard DN should be 65
assert(steam.dn === 65, `Main steam DN should be 65 for 1000kg/h at 8bar, 20m/s. Got ${steam.dn}`);

if (!allPassed) {
  process.exit(1);
}
console.log("All tests passed!");
