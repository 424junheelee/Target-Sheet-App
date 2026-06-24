// MOA formulae from targets.py build_dist_config():
//   yards:  1 MOA = yards × 0.01047 in = yards × 0.01047 × 25.4 mm
//   metres: 1 MOA = metres × 1.09361 yd × 0.01047 in/yd × 25.4 mm/in

const double _inchesToMm = 25.4;
const double _moaInchesPerYard = 0.01047;
const double _metresToYards = 1.09361;

/// Physical size of 1 MOA at [yards] yards, in mm.
double moaSizeAtYards(double yards) =>
    yards * _moaInchesPerYard * _inchesToMm;

/// Physical size of 1 MOA at [metres] metres, in mm.
double moaSizeAtMetres(double metres) =>
    metres * _metresToYards * _moaInchesPerYard * _inchesToMm;
