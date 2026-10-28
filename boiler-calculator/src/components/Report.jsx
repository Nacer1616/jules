import React from 'react';

const Report = ({ params, results }) => {
  if (!results) return null;

  return (
    <div className="bg-white text-slate-800 p-8 rounded-lg shadow-lg border border-slate-200">
      <div className="flex justify-between items-end border-b-2 border-slate-800 pb-4 mb-6">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">EN 12953 Calculation Report</h2>
          <p className="text-sm text-slate-500 mt-1">Fire-tube Steam Boiler Design</p>
        </div>
        <div className="text-right text-sm">
          <p>Date: {new Date().toLocaleDateString()}</p>
          <p>Standard: NF EN 12953 Parts 3 & 8</p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-8 mb-8">
        <div>
          <h3 className="text-lg font-semibold bg-slate-100 p-2 rounded mb-3 border-l-4 border-slate-800">1. Design Parameters</h3>
          <table className="w-full text-sm">
            <tbody>
              <tr className="border-b"><td className="py-2 text-slate-600">Steam Flow Rate (D)</td><td className="py-2 text-right font-medium">{params.flowRate} kg/h</td></tr>
              <tr className="border-b"><td className="py-2 text-slate-600">Design Pressure (Pc)</td><td className="py-2 text-right font-medium">{params.pressure} bar eff</td></tr>
              <tr className="border-b"><td className="py-2 text-slate-600">Saturation Temp (ts)</td><td className="py-2 text-right font-medium">{results.thermo.ts.toFixed(1)} °C</td></tr>
              <tr className="border-b"><td className="py-2 text-slate-600">Material</td><td className="py-2 text-right font-medium">{params.material}</td></tr>
            </tbody>
          </table>
        </div>

        <div>
          <h3 className="text-lg font-semibold bg-slate-100 p-2 rounded mb-3 border-l-4 border-slate-800">2. Geometry Setup</h3>
          <table className="w-full text-sm">
            <tbody>
              <tr className="border-b"><td className="py-2 text-slate-600">Shell Int. Diameter (Di)</td><td className="py-2 text-right font-medium">{params.Di} mm</td></tr>
              <tr className="border-b"><td className="py-2 text-slate-600">Furnace Ext. Diameter (de)</td><td className="py-2 text-right font-medium">{params.de} mm</td></tr>
              <tr className="border-b"><td className="py-2 text-slate-600">Furnace Length (l)</td><td className="py-2 text-right font-medium">{params.l} mm</td></tr>
              <tr className="border-b"><td className="py-2 text-slate-600">Tube Pitch (p) / Ext. Dia (dt)</td><td className="py-2 text-right font-medium">{params.p} / {params.dt} mm</td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <div className="mb-8">
        <h3 className="text-lg font-semibold bg-slate-100 p-2 rounded mb-3 border-l-4 border-slate-800">3. Mechanical Calculations (EN 12953-3)</h3>
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-slate-50 border-b">
              <th className="text-left py-2 px-2 font-medium">Component</th>
              <th className="text-right py-2 px-2 font-medium">Temp (tc)</th>
              <th className="text-right py-2 px-2 font-medium">Stress (f)</th>
              <th className="text-right py-2 px-2 font-medium">Calc. Thick. (ec)</th>
              <th className="text-right py-2 px-2 font-medium text-blue-700">Nominal Thick.</th>
            </tr>
          </thead>
          <tbody>
            <tr className="border-b">
              <td className="py-2 px-2">Cylindrical Shell</td>
              <td className="text-right py-2 px-2">{results.shell.tc.toFixed(1)} °C</td>
              <td className="text-right py-2 px-2">{results.shell.f.toFixed(1)} MPa</td>
              <td className="text-right py-2 px-2">{results.shell.calc.ec_calc.toFixed(2)} mm</td>
              <td className="text-right py-2 px-2 font-bold text-blue-700">{results.shell.calc.e_nom} mm</td>
            </tr>
            <tr className="border-b">
              <td className="py-2 px-2">Furnace Tube (Plain)</td>
              <td className="text-right py-2 px-2">{results.furnace.tc.toFixed(1)} °C</td>
              <td className="text-right py-2 px-2">-</td>
              <td className="text-right py-2 px-2">{results.furnace.calc.ec_calc.toFixed(2)} mm</td>
              <td className="text-right py-2 px-2 font-bold text-blue-700">{results.furnace.calc.e_nom} mm</td>
            </tr>
            <tr className="border-b">
              <td className="py-2 px-2">Tubesheets (Welded)</td>
              <td className="text-right py-2 px-2">{results.tubesheet.tc.toFixed(1)} °C</td>
              <td className="text-right py-2 px-2">{results.tubesheet.f.toFixed(1)} MPa</td>
              <td className="text-right py-2 px-2">{results.tubesheet.calc.ec_calc.toFixed(2)} mm</td>
              <td className="text-right py-2 px-2 font-bold text-blue-700">{results.tubesheet.calc.e_nom} mm</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div>
        <h3 className="text-lg font-semibold bg-slate-100 p-2 rounded mb-3 border-l-4 border-slate-800">4. Nozzle Sizing</h3>
        <div className="grid grid-cols-2 gap-4">
          <div className="border rounded p-4">
            <h4 className="font-semibold text-sm mb-2 text-slate-700">Main Steam Departure</h4>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Selected DN:</span>
              <span className={`font-bold ${results.steam.warning ? 'text-red-600' : 'text-blue-700'}`}>DN {results.steam.dn}</span>
            </div>
            <div className="flex justify-between text-sm mt-1">
              <span className="text-slate-500">Actual Velocity:</span>
              <span className={results.steam.warning ? 'text-red-600' : ''}>{results.steam.velocity.toFixed(1)} m/s</span>
            </div>
          </div>

          <div className="border rounded p-4">
            <h4 className="font-semibold text-sm mb-2 text-slate-700">Safety Valves (EN 12953-8)</h4>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Selected DN:</span>
              <span className="font-bold text-blue-700">DN {results.safety.dn}</span>
            </div>
            <div className="flex justify-between text-sm mt-1">
              <span className="text-slate-500">Min Flow Area A0:</span>
              <span>{results.safety.A0.toFixed(1)} mm²</span>
            </div>
          </div>

          <div className="border rounded p-4">
            <h4 className="font-semibold text-sm mb-2 text-slate-700">Feedwater Inlet</h4>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Selected DN:</span>
              <span className="font-bold text-blue-700">DN {results.feedwater.dn}</span>
            </div>
            <div className="flex justify-between text-sm mt-1">
              <span className="text-slate-500">Velocity:</span>
              <span>{results.feedwater.velocity.toFixed(2)} m/s</span>
            </div>
          </div>

          <div className="border rounded p-4">
            <h4 className="font-semibold text-sm mb-2 text-slate-700">Bottom Blowdown</h4>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Selected DN:</span>
              <span className="font-bold text-blue-700">DN {results.blowdown.dn}</span>
            </div>
            <div className="flex justify-between text-sm mt-1">
              <span className="text-slate-500">Standard Ref:</span>
              <span>EN 12953-6</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Report;
