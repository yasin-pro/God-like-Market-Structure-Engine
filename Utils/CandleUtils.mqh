#ifndef __CANDLE_UTILS_MQH__
#define __CANDLE_UTILS_MQH__

bool IsNewCandle(ENUM_TIMEFRAMES timeframe, datetime &storedBarTime, string symbol = "")
{
   if(symbol == "")
      symbol = _Symbol;

   datetime currentBarTime = iTime(symbol, timeframe, 1);

   if(currentBarTime == 0)
      return false;

   if(currentBarTime == storedBarTime)
      return false;

   storedBarTime = currentBarTime;
   return true;
}

bool IsNewM15Candle(datetime &storedBarTime, string symbol = "")
{
   if(symbol == "")
      symbol = _Symbol;

   return IsNewCandle(PERIOD_M15, storedBarTime, symbol);
}

#endif
