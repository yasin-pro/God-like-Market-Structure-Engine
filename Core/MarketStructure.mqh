#ifndef __MARKET_STRUCTURE_MQH__
#define __MARKET_STRUCTURE_MQH__

// نیاز دارد ZigZag.mqh قبل از این include شده باشد

#define MAX_STRUCTURE_EVENTS 100
#define MAX_SWING_POINTS     100
#define MS_PANEL_LINES       32

//==================================================
// Enums / Structs
//==================================================
enum MarketBias
{
   BIAS_UNKNOWN = 0,
   BIAS_BULLISH = 1,
   BIAS_BEARISH = -1
};

enum StructureEventType
{
   STRUCT_EVENT_NONE = 0,
   STRUCT_EVENT_BULLISH_BOS,
   STRUCT_EVENT_BEARISH_BOS,
   STRUCT_EVENT_BULLISH_CHOCH,
   STRUCT_EVENT_BEARISH_CHOCH
};

struct SwingPoint
{
   datetime time;
   double   price;
   bool     isHigh;
   int      sourceLegIndex;
   double   sourceLegStrength;
   double   sourceLegNetPips;
   bool     isMajor;
   bool     isProtected;
   bool     isBroken;
   string   text;
};

struct StructureEvent
{
   int      id;
   datetime time;
   double   price;
   double   triggerPrice;
   int      type;
   int      biasBefore;
   int      biasAfter;
   int      triggerLegIndex;
   int      brokenLegIndex;
   string   text;
};


//==================================================
// Global State
//==================================================
static StructureEvent g_structureEvents[MAX_STRUCTURE_EVENTS];
static int            g_structureEventsCount = 0;

static SwingPoint     g_swings[MAX_SWING_POINTS];
static int            g_swingsCount = 0;

static int g_marketBias = BIAS_UNKNOWN;

// آخرین swing major
static double   g_lastMajorHighPrice = 0.0;
static datetime g_lastMajorHighTime  = 0;
static int      g_lastMajorHighLegIndex = -1;
static bool     g_hasLastMajorHigh = false;

static double   g_lastMajorLowPrice = 0.0;
static datetime g_lastMajorLowTime  = 0;
static int      g_lastMajorLowLegIndex = -1;
static bool     g_hasLastMajorLow = false;

// protected levels
static double   g_protectedHighPrice = 0.0;
static datetime g_protectedHighTime  = 0;
static int      g_protectedHighLegIndex = -1;
static bool     g_hasProtectedHigh = false;

static double   g_protectedLowPrice = 0.0;
static datetime g_protectedLowTime  = 0;
static int      g_protectedLowLegIndex = -1;
static bool     g_hasProtectedLow = false;

// برای جلوگیری از پردازش دوباره یک لگ
static int g_lastProcessedStructureLegIndex = -1;

// آخرین event
static int      g_lastEventType = STRUCT_EVENT_NONE;
static int      g_lastEventTriggerLegIndex = -1;
static double   g_lastEventPrice = 0.0;
static datetime g_lastEventTime = 0;

// پارامترهای فیلتر
static double g_msMinLegStrength = 35.0;
static double g_msMinLegPips     = 8.0;

//==================================================
// Prefixes
//==================================================
string MSPrefix(string symbol, ENUM_TIMEFRAMES timeframe)
{
   return "MS_" + symbol + "_" + IntegerToString((int)timeframe) + "_";
}

string MSPanelPrefix(string symbol, ENUM_TIMEFRAMES timeframe)
{
   return "MSP_" + symbol + "_" + IntegerToString((int)timeframe) + "_";
}

//==================================================
// Helpers
//==================================================
string BoolMark(bool v)
{
   return v ? "YES" : "NO";
}

string SafePrice(double price)
{
   if(price <= 0.0)
      return "-";
   return PriceText(price);
}

string SafeTime(datetime t)
{
   if(t <= 0)
      return "-";
   return ShortTime(t);
}

string EventDirectionText(int type)
{
   if(IsBullishStructureEvent(type)) return "BULLISH";
   if(IsBearishStructureEvent(type)) return "BEARISH";
   return "-";
}

color SwingColor(const SwingPoint &sp)
{
   if(sp.isProtected)
      return sp.isHigh ? clrAqua : clrOrange;

   return sp.isHigh ? clrLime : clrTomato;
}

string MarketBiasText(int bias)
{
   if(bias == BIAS_BULLISH) return "BULLISH";
   if(bias == BIAS_BEARISH) return "BEARISH";
   return "UNKNOWN";
}

color MarketBiasColor(int bias)
{
   if(bias == BIAS_BULLISH) return clrLime;
   if(bias == BIAS_BEARISH) return clrTomato;
   return clrSilver;
}

string StructureEventTypeText(int type)
{
   switch(type)
   {
      case STRUCT_EVENT_BULLISH_BOS:   return "BOS";
      case STRUCT_EVENT_BEARISH_BOS:   return "BOS";
      case STRUCT_EVENT_BULLISH_CHOCH: return "CHOCH";
      case STRUCT_EVENT_BEARISH_CHOCH: return "CHOCH";
   }
   return "NONE";
}

string StructureEventFullText(int type)
{
   switch(type)
   {
      case STRUCT_EVENT_BULLISH_BOS:   return "Bullish BOS";
      case STRUCT_EVENT_BEARISH_BOS:   return "Bearish BOS";
      case STRUCT_EVENT_BULLISH_CHOCH: return "Bullish CHOCH";
      case STRUCT_EVENT_BEARISH_CHOCH: return "Bearish CHOCH";
   }
   return "NONE";
}

color StructureEventColor(int type)
{
   switch(type)
   {
      case STRUCT_EVENT_BULLISH_BOS:   return clrLime;
      case STRUCT_EVENT_BULLISH_CHOCH: return clrAqua;
      case STRUCT_EVENT_BEARISH_BOS:   return clrTomato;
      case STRUCT_EVENT_BEARISH_CHOCH: return clrOrangeRed;
   }
   return clrSilver;
}

bool IsBullishStructureEvent(int type)
{
   return (type == STRUCT_EVENT_BULLISH_BOS || type == STRUCT_EVENT_BULLISH_CHOCH);
}

bool IsBearishStructureEvent(int type)
{
   return (type == STRUCT_EVENT_BEARISH_BOS || type == STRUCT_EVENT_BEARISH_CHOCH);
}

string SwingText(const SwingPoint &s)
{
   string side = s.isHigh ? "HIGH" : "LOW";
   string major = s.isMajor ? "MAJOR" : "MINOR";
   string prot  = s.isProtected ? "PROTECTED" : "OPEN";
   return side + " | " + major + " | " + prot;
}

//==================================================
// Reset
//==================================================
void ResetMarketStructureState()
{
   g_structureEventsCount = 0;
   g_swingsCount = 0;

   g_marketBias = BIAS_UNKNOWN;

   g_lastMajorHighPrice = 0.0;
   g_lastMajorHighTime = 0;
   g_lastMajorHighLegIndex = -1;
   g_hasLastMajorHigh = false;

   g_lastMajorLowPrice = 0.0;
   g_lastMajorLowTime = 0;
   g_lastMajorLowLegIndex = -1;
   g_hasLastMajorLow = false;

   g_protectedHighPrice = 0.0;
   g_protectedHighTime = 0;
   g_protectedHighLegIndex = -1;
   g_hasProtectedHigh = false;

   g_protectedLowPrice = 0.0;
   g_protectedLowTime = 0;
   g_protectedLowLegIndex = -1;
   g_hasProtectedLow = false;

   g_lastProcessedStructureLegIndex = -1;

   g_lastEventType = STRUCT_EVENT_NONE;
   g_lastEventTriggerLegIndex = -1;
   g_lastEventPrice = 0.0;
   g_lastEventTime = 0;
}

void ClearMarketStructureDrawings(string symbol, ENUM_TIMEFRAMES timeframe)
{
   DeleteObjectsByPrefix(MSPrefix(symbol, timeframe));
   DeleteObjectsByPrefix(MSPanelPrefix(symbol, timeframe));
}

//==================================================
// Config
//==================================================
void SetMarketStructureFilters(double minLegStrength, double minLegPips)
{
   g_msMinLegStrength = minLegStrength;
   g_msMinLegPips     = minLegPips;
}

//==================================================
// Accessors
//==================================================
int GetStructureEventsCount()
{
   return g_structureEventsCount;
}

bool GetStructureEventByIndex(int index, StructureEvent &ev)
{
   if(index < 0 || index >= g_structureEventsCount)
      return false;

   ev = g_structureEvents[index];
   return true;
}

bool GetLastStructureEvent(StructureEvent &ev)
{
   if(g_structureEventsCount <= 0)
      return false;

   ev = g_structureEvents[g_structureEventsCount - 1];
   return true;
}

int GetMarketBias()
{
   return g_marketBias;
}

int GetSwingCount()
{
   return g_swingsCount;
}

bool GetSwingByIndex(int index, SwingPoint &sp)
{
   if(index < 0 || index >= g_swingsCount)
      return false;

   sp = g_swings[index];
   return true;
}

//==================================================
// Store helpers
//==================================================
void StoreStructureEvent(const StructureEvent &ev)
{
   if(g_structureEventsCount < MAX_STRUCTURE_EVENTS)
   {
      g_structureEvents[g_structureEventsCount] = ev;
      g_structureEventsCount++;
      return;
   }

   for(int i = 1; i < MAX_STRUCTURE_EVENTS; i++)
      g_structureEvents[i - 1] = g_structureEvents[i];

   g_structureEvents[MAX_STRUCTURE_EVENTS - 1] = ev;
}

void StoreSwingPoint(const SwingPoint &sp)
{
   if(g_swingsCount < MAX_SWING_POINTS)
   {
      g_swings[g_swingsCount] = sp;
      g_swingsCount++;
      return;
   }

   for(int i = 1; i < MAX_SWING_POINTS; i++)
      g_swings[i - 1] = g_swings[i];

   g_swings[MAX_SWING_POINTS - 1] = sp;
}

//==================================================
// Panel
//==================================================
string MSPanelBgName(string symbol, ENUM_TIMEFRAMES timeframe)
{
   return MSPanelPrefix(symbol, timeframe) + "BG";
}

string MSPanelLineName(string symbol, ENUM_TIMEFRAMES timeframe, int index)
{
   return MSPanelPrefix(symbol, timeframe) + "LINE_" + IntegerToString(index);
}

bool CreateMSPanelBackground(string symbol, ENUM_TIMEFRAMES timeframe)
{
   string name = MSPanelBgName(symbol, timeframe);

   if(ObjectFind(0, name) == -1)
   {
      if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 8);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 18);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, 390);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, 510);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'10,14,20');
   ObjectSetInteger(0, name, OBJPROP_COLOR, C'60,70,85');
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}


bool CreateMSPanelLineObject(string symbol, ENUM_TIMEFRAMES timeframe, int index)
{
   string name = MSPanelLineName(symbol, timeframe, index);

   if(ObjectFind(0, name) == -1)
   {
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 18);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 28 + index * 15);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, (index == 0 ? 10 : 9));
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}


void SetMSPanelLine(string symbol, ENUM_TIMEFRAMES timeframe, int index, string text, color clr)
{
   string name = MSPanelLineName(symbol, timeframe, index);

   if(ObjectFind(0, name) == -1)
      CreateMSPanelLineObject(symbol, timeframe, index);

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

void ClearMSPanelLines(string symbol, ENUM_TIMEFRAMES timeframe)
{
   for(int i = 0; i < MS_PANEL_LINES; i++)
      SetMSPanelLine(symbol, timeframe, i, "", clrWhite);
}

void InitMarketStructurePanel(string symbol, ENUM_TIMEFRAMES timeframe)
{
   CreateMSPanelBackground(symbol, timeframe);

   for(int i = 0; i < MS_PANEL_LINES; i++)
      CreateMSPanelLineObject(symbol, timeframe, i);
}

void UpdateMarketStructurePanel(string symbol, ENUM_TIMEFRAMES timeframe)
{
   CreateMSPanelBackground(symbol, timeframe);
   ClearMSPanelLines(symbol, timeframe);

   int line = 0;

   SetMSPanelLine(symbol, timeframe, line++, "MARKET STRUCTURE DASHBOARD", clrAqua);
   SetMSPanelLine(symbol, timeframe, line++, "======================================", C'80,90,105');

   SetMSPanelLine(symbol, timeframe, line++, "Symbol            : " + symbol, clrWhite);
   SetMSPanelLine(symbol, timeframe, line++, "Timeframe         : " + TfToText(timeframe), clrWhite);
   SetMSPanelLine(symbol, timeframe, line++, "Bias              : " + MarketBiasText(g_marketBias), MarketBiasColor(g_marketBias));
   SetMSPanelLine(symbol, timeframe, line++, "Structure Events  : " + IntegerToString(g_structureEventsCount), clrWhite);
   SetMSPanelLine(symbol, timeframe, line++, "Stored Swings     : " + IntegerToString(g_swingsCount), clrWhite);
   SetMSPanelLine(symbol, timeframe, line++, "Last Proc Leg     : " + (g_lastProcessedStructureLegIndex >= 0 ? "#" + IntegerToString(g_lastProcessedStructureLegIndex) : "-"), clrSilver);

   SetMSPanelLine(symbol, timeframe, line++, "--------------------------------------", clrDimGray);
   SetMSPanelLine(symbol, timeframe, line++, "FILTERS", clrGold);
   SetMSPanelLine(symbol, timeframe, line++, "Min Strength      : " + DoubleToString(g_msMinLegStrength, 1), clrWhite);
   SetMSPanelLine(symbol, timeframe, line++, "Min Net Pips      : " + DoubleToString(g_msMinLegPips, 1), clrWhite);

   SetMSPanelLine(symbol, timeframe, line++, "--------------------------------------", clrDimGray);
   SetMSPanelLine(symbol, timeframe, line++, "MAJOR LEVELS", clrGold);

   if(g_hasLastMajorHigh)
      SetMSPanelLine(symbol, timeframe, line++, "Last Major High   : " + SafePrice(g_lastMajorHighPrice) + " | #" + IntegerToString(g_lastMajorHighLegIndex), clrLime);
   else
      SetMSPanelLine(symbol, timeframe, line++, "Last Major High   : -", clrSilver);

   if(g_hasLastMajorLow)
      SetMSPanelLine(symbol, timeframe, line++, "Last Major Low    : " + SafePrice(g_lastMajorLowPrice) + " | #" + IntegerToString(g_lastMajorLowLegIndex), clrTomato);
   else
      SetMSPanelLine(symbol, timeframe, line++, "Last Major Low    : -", clrSilver);

   SetMSPanelLine(symbol, timeframe, line++, "--------------------------------------", clrDimGray);
   SetMSPanelLine(symbol, timeframe, line++, "PROTECTED LEVELS", clrGold);

   if(g_hasProtectedHigh)
      SetMSPanelLine(symbol, timeframe, line++, "Protected High    : " + SafePrice(g_protectedHighPrice) + " | #" + IntegerToString(g_protectedHighLegIndex), clrAqua);
   else
      SetMSPanelLine(symbol, timeframe, line++, "Protected High    : -", clrSilver);

   if(g_hasProtectedLow)
      SetMSPanelLine(symbol, timeframe, line++, "Protected Low     : " + SafePrice(g_protectedLowPrice) + " | #" + IntegerToString(g_protectedLowLegIndex), clrOrange);
   else
      SetMSPanelLine(symbol, timeframe, line++, "Protected Low     : -", clrSilver);

   SetMSPanelLine(symbol, timeframe, line++, "--------------------------------------", clrDimGray);
   SetMSPanelLine(symbol, timeframe, line++, "LAST EVENT", clrGold);

   StructureEvent lastEv;
   if(GetLastStructureEvent(lastEv))
   {
      SetMSPanelLine(symbol, timeframe, line++, "Type              : " + StructureEventFullText(lastEv.type), StructureEventColor(lastEv.type));
      SetMSPanelLine(symbol, timeframe, line++, "Direction         : " + EventDirectionText(lastEv.type), StructureEventColor(lastEv.type));
      SetMSPanelLine(symbol, timeframe, line++, "Break Price       : " + PriceText(lastEv.price), clrWhite);
      SetMSPanelLine(symbol, timeframe, line++, "Trigger Price     : " + PriceText(lastEv.triggerPrice), clrWhite);
      SetMSPanelLine(symbol, timeframe, line++, "Trigger Leg       : #" + IntegerToString(lastEv.triggerLegIndex), clrWhite);
      SetMSPanelLine(symbol, timeframe, line++, "Broken Leg        : #" + IntegerToString(lastEv.brokenLegIndex), clrWhite);
      SetMSPanelLine(symbol, timeframe, line++, "Event Time        : " + SafeTime(lastEv.time), clrWhite);
      SetMSPanelLine(symbol, timeframe, line++, "Bias Shift        : " + MarketBiasText(lastEv.biasBefore) + " -> " + MarketBiasText(lastEv.biasAfter), clrSilver);
   }
   else
   {
      SetMSPanelLine(symbol, timeframe, line++, "Type              : none", clrSilver);
      SetMSPanelLine(symbol, timeframe, line++, "Direction         : -", clrSilver);
      SetMSPanelLine(symbol, timeframe, line++, "Break Price       : -", clrSilver);
      SetMSPanelLine(symbol, timeframe, line++, "Trigger Price     : -", clrSilver);
      SetMSPanelLine(symbol, timeframe, line++, "Trigger Leg       : -", clrSilver);
      SetMSPanelLine(symbol, timeframe, line++, "Broken Leg        : -", clrSilver);
      SetMSPanelLine(symbol, timeframe, line++, "Event Time        : -", clrSilver);
      SetMSPanelLine(symbol, timeframe, line++, "Bias Shift        : -", clrSilver);
   }

   SetMSPanelLine(symbol, timeframe, line++, "--------------------------------------", clrDimGray);
   SetMSPanelLine(symbol, timeframe, line++, "RECENT SWINGS", clrGold);

   int swingShow = MathMin(4, g_swingsCount);
   for(int i = 0; i < swingShow; i++)
   {
      int idx = g_swingsCount - 1 - i;
      if(idx < 0) break;

      SwingPoint sp = g_swings[idx];
      color c = SwingColor(sp);

      string txt =
         "#" + IntegerToString(sp.sourceLegIndex) + " | " +
         (sp.isHigh ? "SH" : "SL") + " | " +
         PriceText(sp.price) + " | " +
         (sp.isMajor ? "Major" : "Minor") + " | " +
         (sp.isProtected ? "Protected" : "Open");

      SetMSPanelLine(symbol, timeframe, line++, txt, c);
   }

   ChartRedraw(0);
}

//==================================================
// Drawing helpers
//==================================================
bool CreateOrUpdateTrend(
   string name,
   datetime time1,
   double price1,
   datetime time2,
   double price2,
   color clr,
   int width = 1,
   ENUM_LINE_STYLE style = STYLE_SOLID,
   bool rayRight = false
)
{
   if(ObjectFind(0, name) == -1)
   {
      if(!ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2))
         return false;
   }
   else
   {
      ObjectMove(0, name, 0, time1, price1);
      ObjectMove(0, name, 1, time2, price2);
   }

   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, rayRight);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}

bool CreateOrUpdateText(
   string name,
   datetime t,
   double price,
   string text,
   color clr,
   int fontSize = 10
)
{
   if(ObjectFind(0, name) == -1)
   {
      if(!ObjectCreate(0, name, OBJ_TEXT, 0, t, price))
         return false;
   }
   else
   {
      ObjectMove(0, name, 0, t, price);
   }

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   return true;
}

bool DrawHorizontalLevel(
   string name,
   datetime time1,
   datetime time2,
   double price,
   color clr,
   int width = 1,
   ENUM_LINE_STYLE style = STYLE_DOT
)
{
   return CreateOrUpdateTrend(name, time1, price, time2, price, clr, width, style, false);
}

void DrawProtectedLevels(string symbol, ENUM_TIMEFRAMES timeframe)
{
   datetime nowTime = iTime(symbol, timeframe, 1);
   if(nowTime == 0)
      nowTime = TimeCurrent();

   string prefix = MSPrefix(symbol, timeframe);

   if(g_hasProtectedHigh)
   {
      DrawHorizontalLevel(
         prefix + "PROTECTED_HIGH_LINE",
         g_protectedHighTime,
         nowTime,
         g_protectedHighPrice,
         clrAqua,
         2,
         STYLE_DASH
      );

      CreateOrUpdateText(
         prefix + "PROTECTED_HIGH_TEXT",
         nowTime,
         g_protectedHighPrice + 8 * _Point,
         "Protected High",
         clrAqua,
         9
      );
   }

   if(g_hasProtectedLow)
   {
      DrawHorizontalLevel(
         prefix + "PROTECTED_LOW_LINE",
         g_protectedLowTime,
         nowTime,
         g_protectedLowPrice,
         clrOrange,
         2,
         STYLE_DASH
      );

      CreateOrUpdateText(
         prefix + "PROTECTED_LOW_TEXT",
         nowTime,
         g_protectedLowPrice - 8 * _Point,
         "Protected Low",
         clrOrange,
         9
      );
   }
}

void DrawSwingPointOnChart(string symbol, ENUM_TIMEFRAMES timeframe, const SwingPoint &sp, int visualIndex)
{
   string prefix = MSPrefix(symbol, timeframe) + "SW_" + IntegerToString(visualIndex);

   color clr = sp.isProtected
      ? (sp.isHigh ? clrAqua : clrOrange)
      : (sp.isHigh ? clrLime : clrTomato);

   string txt = sp.isHigh ? "SH" : "SL";

   if(sp.isProtected)
      txt += " [P]";

   if(sp.isMajor)
      txt += " *";

   double offset = 8 * _Point;
   double y = sp.price;

   if(sp.isHigh)
      y += offset;
   else
      y -= offset;

   CreateOrUpdateText(prefix + "_TEXT", sp.time, y, txt, clr, 9);
}


void DrawRecentSwingPoints(string symbol, ENUM_TIMEFRAMES timeframe)
{
   string basePrefix = MSPrefix(symbol, timeframe) + "SW_";

   // پاک کردن آبجکت‌های swing قبلی تا چیزی از رسم‌های قدیمی باقی نماند
   for(int i = 0; i < 20; i++)
   {
      ObjectDelete(0, basePrefix + IntegerToString(i) + "_TEXT");
      ObjectDelete(0, basePrefix + IntegerToString(i) + "_LINE");
      ObjectDelete(0, basePrefix + IntegerToString(i) + "_PATH");
      ObjectDelete(0, basePrefix + IntegerToString(i) + "_TREND");
   }

   int drawCount = MathMin(8, g_swingsCount);
   for(int i = 0; i < drawCount; i++)
   {
      int idx = g_swingsCount - 1 - i;
      if(idx < 0) break;

      DrawSwingPointOnChart(symbol, timeframe, g_swings[idx], i);
   }
}


void DrawStructureEventOnChart(string symbol, ENUM_TIMEFRAMES timeframe, const StructureEvent &ev, datetime brokenTime)
{
   string prefix = MSPrefix(symbol, timeframe) + "EV_" + IntegerToString(ev.id);
   color clr = StructureEventColor(ev.type);

   // رسم سطح شکست
   DrawHorizontalLevel(prefix + "_BROKEN_LEVEL", brokenTime, ev.time, ev.price, clr, 2, STYLE_DASHDOTDOT);

   // رسم مسیر شکست (استفاده از triggerPrice دقیق ذخیره شده)
   CreateOrUpdateTrend(
      prefix + "_PATH",
      brokenTime,
      ev.price,
      ev.time,
      ev.triggerPrice, // اینجا از داده دقیق استفاده می‌شود
      clr, 2, STYLE_SOLID, false
   );

   // تنظیم مکان متن
   double offset = 15 * _Point;
   double labelPrice = (IsBullishStructureEvent(ev.type)) ? ev.price + offset : ev.price - offset;

   CreateOrUpdateText(prefix + "_LABEL", ev.time, labelPrice, ev.text, clr, 11);
}


//==================================================
// Validation / Swing Logic
//==================================================
bool IsLegStructurallyValid(const LegInfo &leg)
{
   if(leg.netMovePips < g_msMinLegPips)
      return false;

   if(leg.strength < g_msMinLegStrength)
      return false;

   return true;
}

bool IsLegMajorSwing(const LegInfo &leg)
{
   if(leg.netMovePips >= (g_msMinLegPips * 1.5))
      return true;

   if(leg.strength >= (g_msMinLegStrength * 1.35))
      return true;

   if(StringFind(leg.legTypeText, "IMPULSE") >= 0)
      return true;

   return false;
}

void AddSwingFromLeg(const LegInfo &leg)
{
   SwingPoint sp;

   sp.time = leg.endTime;
   sp.price = leg.endPrice;
   sp.isHigh = (leg.direction > 0);
   sp.sourceLegIndex = leg.index;
   sp.sourceLegStrength = leg.strength;
   sp.sourceLegNetPips = leg.netMovePips;
   sp.isMajor = IsLegMajorSwing(leg);
   sp.isProtected = false;
   sp.isBroken = false;
   sp.text = sp.isHigh ? "SWING_HIGH" : "SWING_LOW";

   StoreSwingPoint(sp);

   if(sp.isHigh)
   {
      if(!g_hasLastMajorHigh || sp.price > g_lastMajorHighPrice || sp.isMajor)
      {
         g_lastMajorHighPrice = sp.price;
         g_lastMajorHighTime = sp.time;
         g_lastMajorHighLegIndex = sp.sourceLegIndex;
         g_hasLastMajorHigh = true;
      }
   }
   else
   {
      if(!g_hasLastMajorLow || sp.price < g_lastMajorLowPrice || sp.isMajor)
      {
         g_lastMajorLowPrice = sp.price;
         g_lastMajorLowTime = sp.time;
         g_lastMajorLowLegIndex = sp.sourceLegIndex;
         g_hasLastMajorLow = true;
      }
   }
}

void UpdateProtectedLevelsFromBiasAndLeg(const LegInfo &leg)
{
   // در روند صعودی آخرین low معتبر protected low است
   if(g_marketBias == BIAS_BULLISH && leg.direction < 0)
   {
      g_protectedLowPrice = leg.endPrice;
      g_protectedLowTime = leg.endTime;
      g_protectedLowLegIndex = leg.index;
      g_hasProtectedLow = true;
   }

   // در روند نزولی آخرین high معتبر protected high است
   if(g_marketBias == BIAS_BEARISH && leg.direction > 0)
   {
      g_protectedHighPrice = leg.endPrice;
      g_protectedHighTime = leg.endTime;
      g_protectedHighLegIndex = leg.index;
      g_hasProtectedHigh = true;
   }

   // اگر bias هنوز نامشخص است، با هر دو طرف seed کن
   if(g_marketBias == BIAS_UNKNOWN)
   {
      if(leg.direction > 0)
      {
         g_protectedHighPrice = leg.endPrice;
         g_protectedHighTime = leg.endTime;
         g_protectedHighLegIndex = leg.index;
         g_hasProtectedHigh = true;
      }
      else if(leg.direction < 0)
      {
         g_protectedLowPrice = leg.endPrice;
         g_protectedLowTime = leg.endTime;
         g_protectedLowLegIndex = leg.index;
         g_hasProtectedLow = true;
      }
   }

   // swing array را هم sync کن
   for(int i = g_swingsCount - 1; i >= 0; i--)
   {
      g_swings[i].isProtected = false;

      if(g_hasProtectedHigh && g_swings[i].isHigh && g_swings[i].sourceLegIndex == g_protectedHighLegIndex)
         g_swings[i].isProtected = true;

      if(g_hasProtectedLow && !g_swings[i].isHigh && g_swings[i].sourceLegIndex == g_protectedLowLegIndex)
         g_swings[i].isProtected = true;
   }
}

bool IsSameStructureBreakAlreadyStored(int type, int triggerLegIndex, double price)
{
   if(g_lastEventType != type)
      return false;

   if(g_lastEventTriggerLegIndex != triggerLegIndex)
      return false;

   if(MathAbs(g_lastEventPrice - price) > (_Point * 0.5))
      return false;

   return true;
}

bool BuildStructureEventFromLeg(const LegInfo &leg, StructureEvent &ev, datetime &brokenTime)
{
   ev.id = 0;
   ev.time = 0;
   ev.price = 0.0;
   ev.type = STRUCT_EVENT_NONE;
   ev.biasBefore = g_marketBias;
   ev.biasAfter = g_marketBias;
   ev.triggerLegIndex = leg.index;
   ev.brokenLegIndex = -1;
   ev.text = "";
   
   ev.triggerPrice = leg.endPrice;
   
   brokenTime = 0;

   if(!IsLegStructurallyValid(leg))
      return false;

   // ----------------------------
   // Bullish side
   // ----------------------------
   if(leg.direction > 0)
   {
      // اول protected high برای CHOCH در bias نزولی
      if(g_marketBias == BIAS_BEARISH && g_hasProtectedHigh && leg.endPrice > g_protectedHighPrice)
      {
         ev.type = STRUCT_EVENT_BULLISH_CHOCH;
         ev.price = g_protectedHighPrice;
         ev.time = leg.endTime;
         ev.brokenLegIndex = g_protectedHighLegIndex;
         ev.text = "Bullish CHOCH";
         ev.biasAfter = BIAS_BULLISH;
         brokenTime = g_protectedHighTime;
         return true;
      }

      // بعد BOS بر اساس major high
      if((g_marketBias == BIAS_BULLISH || g_marketBias == BIAS_UNKNOWN) && g_hasLastMajorHigh && leg.endPrice > g_lastMajorHighPrice)
      {
         ev.type = STRUCT_EVENT_BULLISH_BOS;
         ev.price = g_lastMajorHighPrice;
         ev.time = leg.endTime;
         ev.brokenLegIndex = g_lastMajorHighLegIndex;
         ev.text = "Bullish BOS";
         ev.biasAfter = BIAS_BULLISH;
         brokenTime = g_lastMajorHighTime;
         return true;
      }
   }

   // ----------------------------
   // Bearish side
   // ----------------------------
   if(leg.direction < 0)
   {
      // اول protected low برای CHOCH در bias صعودی
      if(g_marketBias == BIAS_BULLISH && g_hasProtectedLow && leg.endPrice < g_protectedLowPrice)
      {
         ev.type = STRUCT_EVENT_BEARISH_CHOCH;
         ev.price = g_protectedLowPrice;
         ev.time = leg.endTime;
         ev.brokenLegIndex = g_protectedLowLegIndex;
         ev.text = "Bearish CHOCH";
         ev.biasAfter = BIAS_BEARISH;
         brokenTime = g_protectedLowTime;
         return true;
      }

      // بعد BOS بر اساس major low
      if((g_marketBias == BIAS_BEARISH || g_marketBias == BIAS_UNKNOWN) && g_hasLastMajorLow && leg.endPrice < g_lastMajorLowPrice)
      {
         ev.type = STRUCT_EVENT_BEARISH_BOS;
         ev.price = g_lastMajorLowPrice;
         ev.time = leg.endTime;
         ev.brokenLegIndex = g_lastMajorLowLegIndex;
         ev.text = "Bearish BOS";
         ev.biasAfter = BIAS_BEARISH;
         brokenTime = g_lastMajorLowTime;
         return true;
      }
   }
   
   

   return false;
}

void UpdateBiasFromEvent(const StructureEvent &ev)
{
   g_marketBias = ev.biasAfter;
}

void UpdateStateAfterEvent(const StructureEvent &ev)
{
   // بعد از CHOCH bullish، protected low جدید باید بعداً از پولبک نزولی تعیین شود
   if(ev.type == STRUCT_EVENT_BULLISH_CHOCH)
   {
      g_hasProtectedHigh = false;
   }
   else if(ev.type == STRUCT_EVENT_BEARISH_CHOCH)
   {
      g_hasProtectedLow = false;
   }
}

void SortLegsByIndexAscending(LegInfo &legs[], int count)
{
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = i + 1; j < count; j++)
      {
         if(legs[j].index < legs[i].index)
         {
            LegInfo tmp = legs[i];
            legs[i] = legs[j];
            legs[j] = tmp;
         }
      }
   }
}


//==================================================
// Rebuild / Init
//==================================================
void InitializeMarketStructure(string symbol, ENUM_TIMEFRAMES timeframe)
{
   ResetMarketStructureState();
   ClearMarketStructureDrawings(symbol, timeframe);
   InitMarketStructurePanel(symbol, timeframe);

   LegInfo legs[];
   int count = GetLastCompletedLegs(legs, 20);

   if(count > 1)
      SortLegsByIndexAscending(legs, count);

   for(int i = 0; i < count; i++)
   {
      LegInfo leg = legs[i];
      if(leg.index <= 0)
         continue;

      StructureEvent ev;
      datetime brokenTime = 0;

      // 1) اول event را با state قبلی تشخیص بده
      if(BuildStructureEventFromLeg(leg, ev, brokenTime))
      {
         if(!IsSameStructureBreakAlreadyStored(ev.type, ev.triggerLegIndex, ev.price))
         {
            ev.id = g_structureEventsCount + 1;
            StoreStructureEvent(ev);
            DrawStructureEventOnChart(symbol, timeframe, ev, brokenTime);

            UpdateBiasFromEvent(ev);
            UpdateStateAfterEvent(ev);

            g_lastEventType = ev.type;
            g_lastEventTriggerLegIndex = ev.triggerLegIndex;
            g_lastEventPrice = ev.price;
            g_lastEventTime = ev.time;
         }
      }

      // 2) بعد swing و levelها را ثبت کن
      if(IsLegStructurallyValid(leg))
         AddSwingFromLeg(leg);

      UpdateProtectedLevelsFromBiasAndLeg(leg);
      g_lastProcessedStructureLegIndex = leg.index;
   }

   DrawProtectedLevels(symbol, timeframe);
   DrawRecentSwingPoints(symbol, timeframe);
   UpdateMarketStructurePanel(symbol, timeframe);
}


//==================================================
// Main processing
//==================================================
bool ProcessClosedLegForMarketStructure(string symbol, ENUM_TIMEFRAMES timeframe, const LegInfo &leg)
{
   if(leg.index <= 0)
      return false;

   if(g_lastProcessedStructureLegIndex == leg.index)
   {
      DrawProtectedLevels(symbol, timeframe);
      DrawRecentSwingPoints(symbol, timeframe);
      UpdateMarketStructurePanel(symbol, timeframe);
      return false;
   }

   bool createdEvent = false;

   StructureEvent ev;
   datetime brokenTime = 0;

   // 1) event را با state قبلی تشخیص بده
   if(BuildStructureEventFromLeg(leg, ev, brokenTime))
   {
      if(!IsSameStructureBreakAlreadyStored(ev.type, ev.triggerLegIndex, ev.price))
      {
         ev.id = g_structureEventsCount + 1;
         StoreStructureEvent(ev);
         DrawStructureEventOnChart(symbol, timeframe, ev, brokenTime);

         UpdateBiasFromEvent(ev);
         UpdateStateAfterEvent(ev);

         g_lastEventType = ev.type;
         g_lastEventTriggerLegIndex = ev.triggerLegIndex;
         g_lastEventPrice = ev.price;
         g_lastEventTime = ev.time;

         Print(
            "[MS] ",
            ev.text,
            " | BiasBefore=", MarketBiasText(ev.biasBefore),
            " | BiasAfter=", MarketBiasText(ev.biasAfter),
            " | TriggerLeg=", ev.triggerLegIndex,
            " | BrokenLeg=", ev.brokenLegIndex,
            " | Price=", DoubleToString(ev.price, _Digits),
            " | Time=", TimeToString(ev.time, TIME_DATE | TIME_MINUTES)
         );

         createdEvent = true;
      }
   }

   // 2) بعد state را آپدیت کن
   if(IsLegStructurallyValid(leg))
      AddSwingFromLeg(leg);

   UpdateProtectedLevelsFromBiasAndLeg(leg);
   g_lastProcessedStructureLegIndex = leg.index;

   DrawProtectedLevels(symbol, timeframe);
   DrawRecentSwingPoints(symbol, timeframe);
   UpdateMarketStructurePanel(symbol, timeframe);

   return createdEvent;
}


bool UpdateMarketStructureFromLatestClosedLeg(string symbol, ENUM_TIMEFRAMES timeframe)
{
   LegInfo lastLeg;
   if(!GetLastClosedLeg(lastLeg))
   {
      DrawProtectedLevels(symbol, timeframe);
      DrawRecentSwingPoints(symbol, timeframe);
      UpdateMarketStructurePanel(symbol, timeframe);
      return false;
   }

   return ProcessClosedLegForMarketStructure(symbol, timeframe, lastLeg);
}

void RefreshMarketStructureVisuals(string symbol, ENUM_TIMEFRAMES timeframe)
{
   DrawProtectedLevels(symbol, timeframe);
   DrawRecentSwingPoints(symbol, timeframe);
   UpdateMarketStructurePanel(symbol, timeframe);
}

#endif
