
<p align="center">
  <img src="image.png">
</p>


# Market Structure Analysis Engine

A modular MQL5 analysis framework for realtime market structure, ZigZag legs, swing detection, and structure-based trading research.

## Overview

This project is built around three core modules:

- `CandleUtils.mqh`: candle utility helpers and bar-state logic
- `ZigZag.mqh`: realtime leg detection, leg strength measurement, reversal confirmation, and swing generation
- `MarketStructure.mqh`: swing structure analysis, BOS/CHOCH detection, bias tracking, protected levels, and chart visualization

Together, these modules form a reusable analytical engine for understanding price action in a structured way.

## What It Does

- Detects bullish and bearish legs in realtime
- Measures leg strength, quality, and internal candle composition
- Detects swing highs and swing lows
- Classifies swings as major or minor
- Tracks protected highs and protected lows
- Identifies BOS (Break of Structure)
- Identifies CHOCH (Change of Character)
- Maintains bullish, bearish, or unknown market bias
- Adapts to market volatility using dynamic thresholds
- Displays structure information directly on the chart

## Trading Concepts Covered

### Leg Analysis
The engine splits price action into directional legs and measures:

- start and end price
- duration
- candle count
- net move vs total move
- efficiency
- bullish, bearish, and doji composition
- with-leg and against-leg pressure

### Reversal Detection
The ZigZag logic does not rely on a single fixed condition. It combines:

- opposite candle pressure
- pivot/fractal confirmation
- dynamic retracement logic
- adaptive thresholds based on market range and volatility

### Market Structure
The structure layer interprets swings and events to build a structural view of the market:

- major swing highs and lows
- protected levels
- BOS and CHOCH events
- bias transitions
- historical structure events

### Visualization
The project also draws the analytical state on chart:

- leg lines
- swing markers
- protected levels
- structure labels
- dashboard panel
- current bias and last structural event

## Best Use Cases

This framework is useful as a base for:

- continuation strategies
- reversal strategies
- structure-based entries
- pullback entries
- strength-filtered setups
- market regime filtering
- custom discretionary trading tools

It is not a complete auto-trading system by itself. Instead, it provides the analytical foundation needed to build one.

## Architecture

```text
Main Script
├── CandleUtils.mqh
├── ZigZag.mqh
└── MarketStructure.mqh
```

### Responsibilities

- `CandleUtils.mqh`: low-level candle and bar helpers
- `ZigZag.mqh`: leg engine, strength model, reversal logic, swing extraction
- `MarketStructure.mqh`: structure interpretation, bias, BOS/CHOCH, protected levels

## Strengths

- modular design
- clear state management
- reusable components
- adaptive market modeling
- realtime structural analysis
- strong chart visualization support

## Current Limitations

- no complete entry/exit execution model
- no risk management layer
- no multi-timeframe confirmation layer
- limited liquidity-concept modeling
- analysis and visualization are still closely related in parts of the code

## Potential Extensions

- order block detection
- fair value gap detection
- liquidity sweep logic
- multi-timeframe structure alignment
- entry confirmation engine
- position sizing and risk manager
- logging and backtesting layer

## Summary

This project is a solid MQL5 market structure engine for research and strategy development. It provides a structured understanding of price action by combining realtime ZigZag detection, leg strength analysis, swing classification, and market structure interpretation.

If you are building a trading framework around structure, this code is a strong foundation.

---

## Support Development

If you find this project useful and want to support continued development, you can donate.

TRX Wallet:

```
TG6yyH3JRA7zEqQ8aUvvzhRwRAS4k6z7hv
```

---

## License

MIT License

---

## Author

GitHub: https://github.com/yasin-pro

