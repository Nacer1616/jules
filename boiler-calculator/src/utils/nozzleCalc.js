// Standard DNs (EN 10220 / ISO 6708)
const STANDARD_DN = [15, 20, 25, 32, 40, 50, 65, 80, 100, 125, 150, 200];

/**
 * Get nearest larger standard DN
 */
function getStandardDN(calc_dn, min_dn = 15) {
  const req = Math.max(calc_dn, min_dn);
  for (const dn of STANDARD_DN) {
    if (dn >= req) return dn;
  }
  return STANDARD_DN[STANDARD_DN.length - 1];
}

/**
 * Get specific volume of saturated steam at given absolute pressure
 * @param {number} P_abs_bar Absolute pressure in bar
 * @returns {number} Specific volume v'' in m³/kg
 */
function getSpecificVolume(P_abs_bar) {
  // Simplified lookup for v'' (m³/kg) around 8 bar eff (9 bar abs)
  // 9 bar abs: v'' ≈ 0.215 m³/kg
  // General approximation for saturated steam
  const table = [
    { p: 1, v: 1.694 },
    { p: 5, v: 0.3749 },
    { p: 8, v: 0.2404 },
    { p: 9, v: 0.2150 },
    { p: 10, v: 0.1944 },
    { p: 12, v: 0.1633 },
    { p: 15, v: 0.1317 }
  ];

  if (P_abs_bar <= table[0].p) return table[0].v;
  if (P_abs_bar >= table[table.length - 1].p) return table[table.length - 1].v;

  for (let i = 0; i < table.length - 1; i++) {
    if (P_abs_bar >= table[i].p && P_abs_bar <= table[i + 1].p) {
      const p1 = table[i].p;
      const p2 = table[i + 1].p;
      const v1 = table[i].v;
      const v2 = table[i + 1].v;
      return v1 + ((P_abs_bar - p1) / (p2 - p1)) * (v2 - v1);
    }
  }
  return 0.215;
}

/**
 * Calculate main steam nozzle
 * @param {number} flowRate Steam flow in kg/h
 * @param {number} pressure Effective pressure in bar
 * @param {number} velocity Target velocity in m/s (default 20)
 * @returns {object} Calculated diam, standard DN, and actual velocity
 */
export function calculateMainSteamNozzle(flowRate, pressure, velocity = 20) {
  const p_abs = pressure + 1; // bar abs
  const v_spec = getSpecificVolume(p_abs);

  // flow in m3/s
  const q_v = (flowRate * v_spec) / 3600;

  // d = sqrt(4 * q_v / (pi * w))
  const d_int = Math.sqrt((4 * q_v) / (Math.PI * velocity)) * 1000; // mm

  const dn = getStandardDN(d_int);

  // Actual velocity
  const actual_w = (4 * q_v) / (Math.PI * Math.pow(dn / 1000, 2));

  return {
    d_int,
    dn,
    velocity: actual_w,
    warning: actual_w > 25
  };
}

/**
 * Calculate safety valve nozzle according to EN 12953-8
 * @param {number} flowRate Boiler capacity in kg/h
 * @param {number} pressure Design pressure in bar eff
 * @returns {object} Safety valve minimum A0, diameter, and DN
 */
export function calculateSafetyValveNozzle(flowRate, pressure) {
  // P0 = 1.1 * P_timbre + P_atm (for safety valve discharging at 10% overpressure)
  const P0_bar_abs = (1.1 * pressure) + 1;
  const P0_MPa = P0_bar_abs / 10;

  // Simplified formula: A0 = qm / (C * Kdr * P0 * sqrt(M / ZT))
  // We'll use a direct saturated steam mass flux correlation (approximate ISO 4126)
  // For sat steam, capacity (kg/h) ≈ 5.1 * A0(mm2) * P0(bar_abs) * Kdr
  const Kdr = 0.72; // certified discharge coeff

  // A0 = flowRate / (5.1 * P0_bar_abs * Kdr)
  const A0 = flowRate / (5.1 * P0_bar_abs * Kdr);

  const d0 = Math.sqrt((4 * A0) / Math.PI);

  // According to EN 12953-8 minimum DN is 20
  const dn = getStandardDN(d0, 20);

  return {
    A0,
    d0,
    dn
  };
}

/**
 * Get blowdown (bottom) nozzle DN
 * @param {number} flowRate Boiler capacity in kg/h
 * @returns {object} DN size
 */
export function getBlowdownNozzle(flowRate) {
  // EN 12953-6 rules: Between DN 20 and DN 40 based on capacity
  let dn = 20;
  if (flowRate > 800) dn = 25;
  if (flowRate > 1500) dn = 32;
  if (flowRate > 3000) dn = 40;

  return { dn };
}

/**
 * Get feedwater nozzle
 * @param {number} flowRate Boiler capacity in kg/h
 * @returns {object} Feedwater DN and velocity
 */
export function getFeedwaterNozzle(flowRate) {
  // Pump factor 1.25, density water at 100°C ~ 958 kg/m3
  const q_m = flowRate * 1.25;
  const rho = 958;
  const q_v = q_m / rho / 3600; // m3/s

  const w = 1.2; // target velocity m/s
  const d_int = Math.sqrt((4 * q_v) / (Math.PI * w)) * 1000;

  const dn = getStandardDN(d_int, 15);
  const actual_w = (4 * q_v) / (Math.PI * Math.pow(dn / 1000, 2));

  return {
    d_int,
    dn,
    velocity: actual_w
  };
}
