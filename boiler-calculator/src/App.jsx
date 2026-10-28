import { useState, useMemo } from 'react';
import { Settings, Calculator, FileText, Anchor } from 'lucide-react';
import BoilerDiagram from './components/BoilerDiagram';
import Report from './components/Report';
import {
  getAccurateSaturationTemperature,
  getCalculationTemperatures,
  getAllowableStress,
  calculateShellThickness,
  calculateFurnaceThickness,
  calculateTubesheetThickness
} from './utils/mechanicalCalc';
import {
  calculateMainSteamNozzle,
  calculateSafetyValveNozzle,
  getBlowdownNozzle,
  getFeedwaterNozzle
} from './utils/nozzleCalc';
import './App.css';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');

  // General Parameters
  const [flowRate, setFlowRate] = useState(1000); // kg/h
  const [pressure, setPressure] = useState(8); // bar eff
  const [material, setMaterial] = useState('P265GH');
  const [steamVelocity, setSteamVelocity] = useState(20); // m/s

  // Geometry Overrides
  const [Di, setDi] = useState(1200); // Shell ID
  const [de, setDe] = useState(600); // Furnace OD
  const [l, setL] = useState(2500); // Furnace Length
  const [p, setP] = useState(70); // Tube pitch
  const [dt, setDt] = useState(51); // Tube OD

  // Perform Calculations
  const results = useMemo(() => {
    const P_abs_bar = pressure + 1;
    const P_MPa = pressure / 10;

    // Thermodynamics
    const ts = getAccurateSaturationTemperature(P_abs_bar);

    // Shell
    const tc_shell = getCalculationTemperatures(ts, 'shell');
    const f_shell = getAllowableStress(material, tc_shell);
    const shellCalc = calculateShellThickness(P_MPa, Di, f_shell);

    // Furnace
    const tc_furnace = getCalculationTemperatures(ts, 'furnace');
    const furnaceCalc = calculateFurnaceThickness(P_MPa, de, l);

    // Tubesheet
    const tc_tubesheet = getCalculationTemperatures(ts, 'tubesheet');
    const f_tubesheet = getAllowableStress(material, tc_tubesheet);
    const tubesheetCalc = calculateTubesheetThickness(P_MPa, f_tubesheet, p, dt);

    // Nozzles
    const steamNozzle = calculateMainSteamNozzle(flowRate, pressure, steamVelocity);
    const safetyNozzle = calculateSafetyValveNozzle(flowRate, pressure);
    const blowdownNozzle = getBlowdownNozzle(flowRate);
    const feedNozzle = getFeedwaterNozzle(flowRate);

    return {
      thermo: { ts },
      shell: { tc: tc_shell, f: f_shell, calc: shellCalc, e_nom: shellCalc.e_nom },
      furnace: { tc: tc_furnace, calc: furnaceCalc, e_nom: furnaceCalc.e_nom },
      tubesheet: { tc: tc_tubesheet, f: f_tubesheet, calc: tubesheetCalc, e_nom: tubesheetCalc.e_nom },
      steam: steamNozzle,
      safety: safetyNozzle,
      blowdown: blowdownNozzle,
      feedwater: feedNozzle
    };
  }, [flowRate, pressure, material, steamVelocity, Di, de, l, p, dt]);

  const presetFlow = (val) => setFlowRate(val);

  return (
    <div className="min-h-screen bg-slate-100 text-slate-800 font-sans pb-10">
      <header className="bg-slate-900 text-white p-4 shadow-md">
        <div className="max-w-6xl mx-auto flex items-center gap-3">
          <Anchor className="text-blue-400" size={28} />
          <h1 className="text-xl font-bold tracking-wider uppercase text-slate-200">
            EN 12953 Boiler Designer
          </h1>
        </div>
      </header>

      <main className="max-w-6xl mx-auto mt-8 grid grid-cols-1 lg:grid-cols-12 gap-8 px-4">
        {/* Sidebar Controls */}
        <div className="lg:col-span-4 space-y-6">
          <div className="bg-white p-6 rounded-lg shadow border border-slate-200">
            <div className="flex items-center gap-2 mb-4 text-slate-800 border-b pb-2">
              <Settings size={20} />
              <h2 className="font-semibold text-lg">General Parameters</h2>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">Steam Flow Rate (kg/h)</label>
                <div className="flex gap-2 mb-2">
                  <button onClick={() => presetFlow(500)} className={`flex-1 py-1 text-xs rounded border ${flowRate === 500 ? 'bg-blue-600 text-white border-blue-600' : 'bg-slate-50 text-slate-600 border-slate-300 hover:bg-slate-100'}`}>500</button>
                  <button onClick={() => presetFlow(1000)} className={`flex-1 py-1 text-xs rounded border ${flowRate === 1000 ? 'bg-blue-600 text-white border-blue-600' : 'bg-slate-50 text-slate-600 border-slate-300 hover:bg-slate-100'}`}>1000</button>
                  <button onClick={() => presetFlow(1500)} className={`flex-1 py-1 text-xs rounded border ${flowRate === 1500 ? 'bg-blue-600 text-white border-blue-600' : 'bg-slate-50 text-slate-600 border-slate-300 hover:bg-slate-100'}`}>1500</button>
                </div>
                <input type="number" value={flowRate} onChange={e => setFlowRate(Number(e.target.value))} className="w-full p-2 border rounded focus:ring-blue-500 focus:border-blue-500" />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">Design Pressure (bar eff)</label>
                <input type="number" value={pressure} onChange={e => setPressure(Number(e.target.value))} step="0.5" className="w-full p-2 border rounded" />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">Material (EN 10028-2)</label>
                <select value={material} onChange={e => setMaterial(e.target.value)} className="w-full p-2 border rounded">
                  <option value="P265GH">P265GH</option>
                  <option value="P295GH">P295GH</option>
                  <option value="P355GH">P355GH</option>
                  <option value="16Mo3">16Mo3</option>
                </select>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow border border-slate-200">
            <div className="flex items-center gap-2 mb-4 text-slate-800 border-b pb-2">
              <Calculator size={20} />
              <h2 className="font-semibold text-lg">Geometry Options</h2>
            </div>
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-500">Shell ID (mm)</label>
                  <input type="number" value={Di} onChange={e => setDi(Number(e.target.value))} className="w-full p-1 border rounded text-sm" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-500">Furnace OD (mm)</label>
                  <input type="number" value={de} onChange={e => setDe(Number(e.target.value))} className="w-full p-1 border rounded text-sm" />
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-slate-500">Target Steam Vel. (m/s)</label>
                <input type="number" value={steamVelocity} onChange={e => setSteamVelocity(Number(e.target.value))} className="w-full p-1 border rounded text-sm" />
                {results.steam.warning && <p className="text-xs text-red-500 mt-1">Warning: Velocity exceeds 25 m/s</p>}
              </div>
            </div>
          </div>
        </div>

        {/* Main Content Area */}
        <div className="lg:col-span-8">

          <div className="flex border-b border-slate-300 mb-6">
            <button
              onClick={() => setActiveTab('dashboard')}
              className={`px-6 py-3 font-medium text-sm flex items-center gap-2 ${activeTab === 'dashboard' ? 'border-b-2 border-blue-600 text-blue-700' : 'text-slate-500 hover:text-slate-700'}`}
            >
              <Anchor size={16} /> CAD Schematic
            </button>
            <button
              onClick={() => setActiveTab('report')}
              className={`px-6 py-3 font-medium text-sm flex items-center gap-2 ${activeTab === 'report' ? 'border-b-2 border-blue-600 text-blue-700' : 'text-slate-500 hover:text-slate-700'}`}
            >
              <FileText size={16} /> Calc Report
            </button>
          </div>

          {activeTab === 'dashboard' && (
            <div className="animate-fadeIn">
              <BoilerDiagram params={{Di, de}} results={results} />

              <div className="grid grid-cols-3 gap-4 mt-6">
                <div className="bg-white p-4 rounded shadow border-l-4 border-blue-500">
                  <p className="text-xs text-slate-500 uppercase tracking-wide">Shell Thickness</p>
                  <p className="text-2xl font-light text-slate-800">{results.shell.e_nom} <span className="text-sm">mm</span></p>
                </div>
                <div className="bg-white p-4 rounded shadow border-l-4 border-red-400">
                  <p className="text-xs text-slate-500 uppercase tracking-wide">Furnace Thick.</p>
                  <p className="text-2xl font-light text-slate-800">{results.furnace.e_nom} <span className="text-sm">mm</span></p>
                </div>
                <div className="bg-white p-4 rounded shadow border-l-4 border-amber-400">
                  <p className="text-xs text-slate-500 uppercase tracking-wide">Tubesheet</p>
                  <p className="text-2xl font-light text-slate-800">{results.tubesheet.e_nom} <span className="text-sm">mm</span></p>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'report' && (
            <div className="animate-fadeIn">
              <Report params={{flowRate, pressure, material, Di, de, l, p, dt}} results={results} />
            </div>
          )}

        </div>
      </main>
    </div>
  );
}

export default App;
