#ifndef __SIGNAL_TYPES_MQH__
#define __SIGNAL_TYPES_MQH__

enum SignalDirection
{
   SIGNAL_NONE = 0,
   SIGNAL_BUY  = 1,
   SIGNAL_SELL = -1
};

string GetSignalDirectionText(int direction)
{
   switch(direction)
   {
      case SIGNAL_BUY:  return "BUY";
      case SIGNAL_SELL: return "SELL";
      default:          return "NONE";
   }
}

struct StrategySignal
{
   bool            valid;
   bool            used;

   int             direction;

   datetime        signalTime;
   string          strategyName;
   string          symbol;
   ENUM_TIMEFRAMES timeframe;

   double          signalPrice;          // entry reference / trigger price

   double          stopLoss;             // optional strategy-defined SL
   double          takeProfit;           // optional strategy-defined TP
   double          invalidationPrice;    // setup invalidation level
   double          rrTarget;             // strategy preferred RR

   long            setupId;              // optional unique setup id
};

void ResetSignalStruct(StrategySignal &sig)
{
   sig.valid             = false;
   sig.used              = false;
   sig.direction         = SIGNAL_NONE;
   sig.signalTime        = 0;
   sig.strategyName      = "";
   sig.symbol            = "";
   sig.timeframe         = PERIOD_CURRENT;
   sig.signalPrice       = 0.0;
   sig.stopLoss          = 0.0;
   sig.takeProfit        = 0.0;
   sig.invalidationPrice = 0.0;
   sig.rrTarget          = 0.0;
   sig.setupId           = 0;
}

#endif
