#ifndef __SIGNAL_BUS_MQH__
#define __SIGNAL_BUS_MQH__

#include "SignalTypes.mqh"

static StrategySignal g_lastSignal;

void InitializeSignalStorage()
{
   ResetSignalStruct(g_lastSignal);
}

void ResetSignal()
{
   ResetSignalStruct(g_lastSignal);
}

bool HasActiveSignal()
{
   return (g_lastSignal.valid && !g_lastSignal.used);
}

bool GetLastSignal(StrategySignal &sig)
{
   sig = g_lastSignal;
   return g_lastSignal.valid;
}

void MarkSignalAsUsed()
{
   g_lastSignal.used = true;
}

void CreateSignal(const StrategySignal &sig)
{
   g_lastSignal = sig;
}

void CreateSignal(int direction,
                  datetime signalTime,
                  double signalPrice,
                  string strategyName,
                  string symbol,
                  ENUM_TIMEFRAMES timeframe,
                  double stopLoss = 0.0,
                  double takeProfit = 0.0,
                  double invalidationPrice = 0.0,
                  double rrTarget = 0.0,
                  long setupId = 0)
{
   StrategySignal sig;
   ResetSignalStruct(sig);

   sig.valid             = true;
   sig.used              = false;
   sig.direction         = direction;
   sig.signalTime        = signalTime;
   sig.signalPrice       = signalPrice;
   sig.strategyName      = strategyName;
   sig.symbol            = symbol;
   sig.timeframe         = timeframe;
   sig.stopLoss          = stopLoss;
   sig.takeProfit        = takeProfit;
   sig.invalidationPrice = invalidationPrice;
   sig.rrTarget          = rrTarget;
   sig.setupId           = setupId;

   g_lastSignal = sig;
}

#endif
