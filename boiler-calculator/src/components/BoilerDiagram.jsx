import React from 'react';

const BoilerDiagram = ({ params, results }) => {
  if (!results) return null;

  return (
    <div className="w-full bg-slate-900 rounded-lg p-4 border border-slate-700 flex flex-col items-center justify-center min-h-[400px]">
      <h3 className="text-slate-300 mb-4 text-sm uppercase tracking-widest font-semibold">2D Schematic - EN 12953</h3>
      <svg viewBox="0 0 800 500" className="w-full max-w-2xl h-auto" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
            <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#334155" strokeWidth="0.5"/>
          </pattern>
        </defs>

        {/* Grid Background */}
        <rect width="800" height="500" fill="url(#grid)" />

        {/* Outer Shell */}
        <rect x="100" y="100" width="600" height="300" rx="10" fill="none" stroke="#60a5fa" strokeWidth="4" />
        {/* Shell Thickness Indicator */}
        <line x1="700" y1="250" x2="730" y2="250" stroke="#94a3b8" strokeWidth="1" strokeDasharray="4" />
        <text x="735" y="254" fill="#60a5fa" fontSize="12" fontFamily="monospace">ec = {results.shell.e_nom} mm</text>
        <text x="120" y="90" fill="#60a5fa" fontSize="12" fontFamily="monospace">Di = {params.Di} mm</text>

        {/* Furnace Tube */}
        <rect x="100" y="300" width="500" height="80" fill="none" stroke="#f87171" strokeWidth="4" />
        <text x="610" y="345" fill="#f87171" fontSize="12" fontFamily="monospace">ef = {results.furnace.e_nom} mm</text>
        <text x="120" y="395" fill="#f87171" fontSize="12" fontFamily="monospace">de = {params.de} mm</text>

        {/* Tubesheets (front and back) */}
        <line x1="100" y1="100" x2="100" y2="400" stroke="#fbbf24" strokeWidth="6" />
        <line x1="700" y1="100" x2="700" y2="400" stroke="#fbbf24" strokeWidth="6" />
        <text x="35" y="250" fill="#fbbf24" fontSize="12" fontFamily="monospace" transform="rotate(-90 35,250)">ep = {results.tubesheet.e_nom} mm</text>

        {/* Main Steam Nozzle */}
        <rect x="380" y="50" width="40" height="50" fill="none" stroke="#cbd5e1" strokeWidth="3" />
        <line x1="400" y1="50" x2="400" y2="20" stroke="#cbd5e1" strokeWidth="2" strokeDasharray="4" />
        <text x="410" y="35" fill="#cbd5e1" fontSize="14" fontFamily="monospace" fontWeight="bold">DN {results.steam.dn}</text>
        <text x="410" y="50" fill="#94a3b8" fontSize="10" fontFamily="monospace">Steam</text>

        {/* Safety Valve Nozzle */}
        <rect x="250" y="50" width="30" height="50" fill="none" stroke="#a7f3d0" strokeWidth="3" />
        <text x="210" y="35" fill="#a7f3d0" fontSize="14" fontFamily="monospace" fontWeight="bold">DN {results.safety.dn}</text>
        <text x="210" y="50" fill="#94a3b8" fontSize="10" fontFamily="monospace">Safety</text>

        {/* Feedwater Nozzle */}
        <rect x="620" y="50" width="20" height="50" fill="none" stroke="#818cf8" strokeWidth="3" />
        <text x="650" y="35" fill="#818cf8" fontSize="14" fontFamily="monospace" fontWeight="bold">DN {results.feedwater.dn}</text>
        <text x="650" y="50" fill="#94a3b8" fontSize="10" fontFamily="monospace">Feed</text>

        {/* Blowdown Nozzle */}
        <rect x="380" y="400" width="40" height="50" fill="none" stroke="#fca5a5" strokeWidth="3" />
        <text x="430" y="440" fill="#fca5a5" fontSize="14" fontFamily="monospace" fontWeight="bold">DN {results.blowdown.dn}</text>
        <text x="430" y="455" fill="#94a3b8" fontSize="10" fontFamily="monospace">Blowdown</text>

        {/* Burner / Flame indicator */}
        <path d="M 120 340 Q 150 320 200 340 Q 150 360 120 340 Z" fill="#ef4444" opacity="0.8" />
        <path d="M 110 340 Q 140 330 180 340 Q 140 350 110 340 Z" fill="#fcd34d" />

        {/* Steam space indicator */}
        <line x1="100" y1="200" x2="700" y2="200" stroke="#3b82f6" strokeWidth="2" strokeDasharray="10 5" opacity="0.5" />
        <text x="120" y="190" fill="#3b82f6" fontSize="12" opacity="0.8" fontFamily="sans-serif">NWL</text>
      </svg>
    </div>
  );
};

export default BoilerDiagram;
