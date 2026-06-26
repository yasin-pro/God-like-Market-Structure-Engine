#property strict

#include "Utils/CandleUtils.mqh"
#include "Core/ZigZag.mqh"
#include "Core/MarketStructure.mqh"


datetime lastBarTime = 0;

//-----------------------------------------
// Example consumer function
//-----------------------------------------
void ProcessLastCompletedLegs(LegInfo &legs[], int count)
{
   for(int i = 0; i < count; i++)
   {
      LegInfo leg = legs[i];

      Print(
         "Leg #", leg.index,
         " | Direction=", GetLegDirectionText(leg.direction),
         " | Type=", leg.legTypeText,
         " | Strength=", DoubleToString(leg.strength, 2),
         " | Candles=", leg.candlesCount,
         " | NetPips=", DoubleToString(leg.netMovePips, 1)
      );
   }
}

//-----------------------------------------
// ICT / SMC style chart theme
//-----------------------------------------
void ApplyICTChartTheme()
{
   long chart_id = ChartID();

   color bg      = C'10,12,18';
   color fg      = C'210,214,220';
   color bull    = C'0,255,170';
   color bear    = C'255,95,95';
   color lineclr = C'160,170,180';
   color muted   = C'70,70,70';

   ChartSetInteger(chart_id, CHART_SHOW_GRID, false);
   ChartSetInteger(chart_id, CHART_SHOW_OHLC, false);
   ChartSetInteger(chart_id, CHART_SHOW_BID_LINE, false);
   ChartSetInteger(chart_id, CHART_SHOW_ASK_LINE, false);
   ChartSetInteger(chart_id, CHART_SHOW_VOLUMES, CHART_VOLUME_HIDE);

   ChartSetInteger(chart_id, CHART_AUTOSCROLL, true);
   ChartSetInteger(chart_id, CHART_SHIFT, true);
   ChartSetInteger(chart_id, CHART_SCALEFIX, false);

   ChartSetInteger(chart_id, CHART_MODE, CHART_CANDLES);

   ChartSetDouble(chart_id, CHART_SHIFT_SIZE, 20.0);

   ChartSetInteger(chart_id, CHART_COLOR_BACKGROUND, bg);
   ChartSetInteger(chart_id, CHART_COLOR_FOREGROUND, fg);

   ChartSetInteger(chart_id, CHART_COLOR_CHART_UP, bull);
   ChartSetInteger(chart_id, CHART_COLOR_CHART_DOWN, bear);

   ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BULL, bull);
   ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BEAR, bear);

   ChartSetInteger(chart_id, CHART_COLOR_CHART_LINE, lineclr);

   ChartSetInteger(chart_id, CHART_COLOR_GRID, bg);
   ChartSetInteger(chart_id, CHART_COLOR_STOP_LEVEL, muted);

   ChartSetInteger(chart_id, CHART_COLOR_VOLUME, muted);
   ChartSetInteger(chart_id, CHART_COLOR_ASK, bg);
   ChartSetInteger(chart_id, CHART_COLOR_BID, bg);

   ChartRedraw(chart_id);
}

int OnInit()
{
   lastBarTime = iTime(_Symbol, PERIOD_M15, 1);

   ApplyICTChartTheme();

   ClearSimpleZigZag(_Symbol, PERIOD_M15);
   InitializeRealtimeZigZag(_Symbol, PERIOD_M15);
   InitZigZagPanel(_Symbol, PERIOD_M15);

   SetMarketStructureFilters(35.0, 8.0);
   InitializeMarketStructure(_Symbol, PERIOD_M15);

   return INIT_SUCCEEDED;
}


void OnDeinit(const int reason)
{
   ClearSimpleZigZag(_Symbol, PERIOD_M15);
   ClearMarketStructureDrawings(_Symbol, PERIOD_M15);
}



void OnTick()
{
   if(!IsNewM15Candle(lastBarTime, _Symbol))
      return;

   bool changed = AddLatestZigZagSegment(_Symbol, PERIOD_M15);

   UpdateZigZagPanel(_Symbol, PERIOD_M15);

   if(changed)
      UpdateMarketStructureFromLatestClosedLeg(_Symbol, PERIOD_M15);
   else
      RefreshMarketStructureVisuals(_Symbol, PERIOD_M15);

   LegInfo lastLegs[];
   int count = GetLastCompletedLegsNewestFirst(lastLegs, 10);

   if(count > 0)
      ProcessLastCompletedLegs(lastLegs, count);
}
