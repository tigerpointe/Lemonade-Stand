<#

.SYNOPSIS
Implements a lemonade stand simulation.

.DESCRIPTION
You've decided to run a lemonade stand on each Saturday of the Summer.
Purchase your inventory of cups, lemons and sugar from the grocery store.
Price your lemonade based on the cost of ingredients, weather forecast, etc.
Lowering your prices will sell more lemonade but return less on each sale.
You might be able to sell more lemonade on hot days at higher prices.
Try to maximize your profits before the Summer ends.

Currency units are selected based on the current computer locale.

Please consider giving to cancer research.

.PARAMETER title
Specifies an alternate title for the lemonade stand.

.PARAMETER celsius
When present, displays the temperature as Celsius.

.PARAMETER noglyphs
When present, the weather glyphs will not be displayed.

.PARAMETER nowait
When present, skips the "now serving" wait loop.

.INPUTS
None.

.OUTPUTS
A whole lot of fun.

.EXAMPLE 
.\Start-Lemonade.ps1
Starts a new lemonade stand.

.EXAMPLE 
.\Start-Lemonade.ps1 -title "Penny's Lemonade"
Starts a new lemonade stand, with an alternate title value.
The title value can be up to 30 characters in length.

.EXAMPLE 
.\Start-Lemonade.ps1 -celsius
Starts a new lemonade stand, using Celsius as the temperature scale.

.EXAMPLE 
.\Start-Lemonade.ps1 -noglyphs
Starts a new lemonade stand, without displaying the weather glyphs.
Older console windows may not fully support these UTF8 encoded characters.

.EXAMPLE 
.\Start-Lemonade.ps1 -nowait
Starts a new lemonade stand, skipping the "now serving" wait loop.

.NOTES
MIT License

Copyright (c) 2023 TigerPointe Software, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Most console windows support UTF8 encoding.  If you do not see the weather
glyphs (such as the clouds, rain or sun), your console window most likely does
not have UTF8 encoding enabled.  Be sure to start the game with the "noglyphs"
option enabled to avoid displaying the invalid character symbols.

Dedicated to fond memories of "Lemonade Stand" on the Commodore 64.
If you enjoy this software, please do something kind for free.

History:
01.00 2023-Jan-07 Scott S. Initial release.
01.01 2023-Jan-18 Scott S. Removed extra parenthesis from calculations.
02.00 2023-Jan-22 Scott S. Revised sales calculation, added best price.

.LINK
https://en.wikipedia.org/wiki/Lemonade_Stand

.LINK
https://en.wikipedia.org/wiki/ASCII_art

.LINK
https://braintumor.org/

.LINK
https://www.cancer.org/

#>

# Accept the command line parameters
param
(

    # Specifies the title of the lemonade stand
    [string]$title = "Lemonade Stand"

    # Use Celsius as the temperature scale
  , [switch]$celsius

    # Do not display the weather glyphs (limited UTF8 console support)
  , [switch]$noglyphs

    # Skip the "now serving" wait loop
  , [switch]$nowait

)

# Define the ASCII art (original image by Scott S.)
$ascii = @"
 .===================.
 |  FRESH  LEMONADE  |
 '==================='
   !!             !!
   !!             !!
   !!             !!
   !!             !!
   !!             !!
   !!             !!
   !!  ______     !!
   !!  \..../     !!
   !!  (::::)O    !!
=======================
 \___________________/
  | | | | | | | | | |
  | | | | | | | | | |
  | | | | | | | | | |
  | | | | | | | | | |
 v| | | | | | | | | |v
'"'"'"'"'"'"'"'"'"'"'"'
"@;
$ascii = $ascii.Replace("`r",""); # Standardize the CrLf to use the Lf only
$lines = $ascii.Split("`n");      # Split the ASCII image on the Lf
$width = $lines[$lines.Count - 1].Length; # Longest line of the ASCII image

# Define the temperature unit symbols
$FahrenheitUnit = "ºF";
$CelsiusUnit    = "ºC";

# Inventory data (contains the item levels)
$inventory = @{};
$inventory.cups   = 0;
$inventory.lemons = 0;
$inventory.sugar  = 0;
$inventory.cash   = 30.00;
$inventory.start  = $inventory.cash;

# Cups data (includes a calculated cost per unit)
$cups = @{};
$cups.cost  = 2.50; # current price
$cups.count = 25;   # servings per box
$cups.min   = 0.99; # minimum price
$cups.unit  = [Math]::Round($cups.cost / $cups.count, 2);

# Lemons data (includes a calculated cost per unit)
$lemons = @{};
$lemons.cost  = 4.00; # current price
$lemons.count = 8;    # servings per bag
$lemons.min   = 2.00; # minimum price
$lemons.unit  = [Math]::Round($lemons.cost / $lemons.count, 2);

# Sugar data (includes a calculated cost per unit)
$sugar = @{};
$sugar.cost  = 3.00; # current price
$sugar.count = 15;   # servings per bag
$sugar.min   = 1.50; # minimum price
$sugar.unit  = [Math]::Round($sugar.cost / $sugar.count, 2);

# Weeks data (measures the session duration)
$weeks = @{};
$weeks.current = 1;   # start with the 1st week
$weeks.total   = 12;  # span the 12 weeks of Summer
$weeks.sales   = 99;  # 99 maximum sales per week
$weeks.summary = @(); # empty array

# Forecast data (includes percentage values, UTF8 glyphs and display names)
$forecast = [ordered]@{};
$forecast.sunny  = @(1.00, 0x2600, "Sunny");
$forecast.partly = @(0.90, 0x26C5, "Partly Sunny");
$forecast.cloudy = @(0.70, 0x2601, "Mostly Cloudy");
$forecast.rainy  = @(0.40, 0x2602, "Rainy");
$forecast.stormy = @(0.10, 0x26C8, "Stormy");

# Temperature data (uses Fahrenheit as the percentage values)
$temperature = @{};
$temperature.min      = 69;
$temperature.max      = 100;
$temperature.units    = $FahrenheitUnit;
$temperature.forecast = $null;
$temperature.value    = $null;

# Score data (based on actual vs. maximum net sales)
$score = @{};
$score.value = 0.00;
$score.total = 0.00;

# Gets the sales amount
# Multiply the potential sales by a ratio of unit cost to actual price; the
# exponent results in the values falling along a curve, rather than along a
# straight line, resulting in more realistic sales values at each price
function Get-SalesAmount
{
  param(
      [int]$potential # potential sales
    , [decimal]$unit  # unit cost
    , [decimal]$price # actual price
  )
  return [Math]::Floor($potential * ($unit / [Math]::Pow($price, 1.5)));
}

# Sanity check the title
if ([String]::IsNullOrWhiteSpace($title))
{
  $title = "";
}
elseif ($title.Trim().Length -gt 30)
{
  $title = "$($title.Trim().Substring(0, 30))... ";
}
else
{
  $title = "$($title.Trim()) ";
}

# Check for Celsius
if ($celsius.IsPresent)
{
  $temperature.units = $CelsiusUnit;
}

# Start the main loop
while ($weeks.current -le $weeks.total)
{

  # Create a new display buffer for the text messages
  Clear-Host;
  $buffer = [string[]]::new($lines.Count);

  # Display the current week number
  $buffer[0] = "";
  $buffer[1] = "$($title)Week #$($weeks.current)";

  # Generate a random weather forecast and temperature
  $temperature.forecast = `
    (Get-Random -Minimum 0 -Maximum $forecast.Keys.Count);
  $temperature.value = `
    (Get-Random -Minimum $temperature.min -Maximum $temperature.max);
  $formatted = $temperature.value.ToString("N0");
  if ($temperature.units -eq $CelsiusUnit)
  {
    $formatted = (($temperature.value - 32) * (5/9)).ToString("N0");
  }
  $glyph = "";
  if (-not $noglyphs.IsPresent)
  {
    $glyph = [char]$forecast[$temperature.forecast][1];
  }
  $buffer[2] = "";
  $buffer[3] = "Weather Forecast:  " + `
               "$formatted$($temperature.units) " + `
               "$($forecast[$temperature.forecast][2]) $glyph";

  # Calculate the potential sales as a percentage of the maximum value
  # (lower temperature = fewer sales, severe weather = fewer sales)
  $potential = [Math]::Floor($weeks.sales * `
                             ($temperature.value / 100) * `
                             ($forecast[$temperature.forecast][0]));
  $buffer[4] = "Estimated Sales:   $potential cups";

  # Update the cups cost
  $cups.cost = $cups.cost + `
               [Math]::Round((Get-Random -Minimum -1.50 -Maximum 1.50), 2);
  if ($cups.cost -lt $cups.min) { $cups.cost = $cups.min; }
  $cups.unit = [Math]::Round($cups.cost / $cups.count, 2);

  # Update the lemons cost
  $lemons.cost = $lemons.cost + `
                 [Math]::Round((Get-Random -Minimum -1.50 -Maximum 1.50), 2);
  if ($lemons.cost -lt $lemons.min) { $lemons.cost = $lemons.min; }
  $lemons.unit = [Math]::Round($lemons.cost / $lemons.count, 2);

  # Update the sugar cost
  $sugar.cost = $sugar.cost + `
                [Math]::Round((Get-Random -Minimum -1.50 -Maximum 1.50), 2);
  if ($sugar.cost -lt $sugar.min) { $sugar.cost = $sugar.min; }
  $sugar.unit = [Math]::Round($sugar.cost / $sugar.count, 2);

  # Display the updated item prices
  $buffer[5] = "";
  $buffer[6] = "Grocery Store Prices";
  $buffer[7] = `
    "  Cups:    $($cups.cost.ToString("C2")) box of $($cups.count)";
  $buffer[8] = `
    "  Lemons:  $($lemons.cost.ToString("C2")) bag of $($lemons.count)";
  $buffer[9] = `
    "  Sugar:   $($sugar.cost.ToString("C2")) bag for $($sugar.count) cups";
  
  # Calculate the unit cost
  $unit = $cups.unit + $lemons.unit + $sugar.unit;
  $buffer[10] = "           $($unit.ToString("C2")) cost per serving";

  # Display the current inventory
  $buffer[11] = "";
  $buffer[12] = "My Current Inventory";
  $buffer[13] = "  Cups:    $($inventory.cups)";
  $buffer[14] = "  Lemons:  $($inventory.lemons)";
  $buffer[15] = "  Sugar:   $($inventory.sugar)";

  # Display the current cash
  $gainloss   = $inventory.cash - $inventory.start;
  $buffer[16] = "";
  $buffer[17] = "My Cash:    $($inventory.cash.ToString("C2"))";
  $buffer[18] = "Gain/Loss:  $($gainloss.ToString("C2"))";
  $buffer[19] = "";

  # Output the display buffer (combines the ASCII art with the text messages)
  for ($i = 0; $i -lt $buffer.Count; $i++)
  {
    "$($lines[$i].PadRight($width))  $($buffer[$i])";
  }

  # Read the number of cup boxes to purchase
  [int]$newcups = -1;
  while ($newcups -lt 0)
  {
    try
    {
      [int]$newcups = Read-Host -Prompt "How many boxes of cups to buy?";
      if ($newcups -gt 0)
      {
        $cost = $newcups * $cups.cost;
        if ($cost -gt $inventory.cash)
        { 
          throw "You do not have enough cash.";
        }
        $inventory.cups = $inventory.cups + ($newcups * $cups.count);
        $inventory.cash = $inventory.cash - $cost; 
        "  Purchased $newcups box(es) of cups for $($cost.ToString("C2"))";
        "  $($inventory.cups) cup inventory, " + `
          "$($inventory.cash.ToString("C2")) cash remaining";
      }
      else
      {
        "  No additional cups were purchased";
      }
    }
    catch
    {
      Write-Host -ForegroundColor Yellow -Object "  $_";
      $newcups = -1;
    }
  }

  # Read the number of lemon bags to purchase
  [int]$newlemons = -1;
  while ($newlemons -lt 0)
  {
    try
    {
      [int]$newlemons = Read-Host -Prompt "How many bags of lemons to buy?";
      if ($newlemons -gt 0)
      {
        $cost = $newlemons * $lemons.cost;
        if ($cost -gt $inventory.cash)
        { 
          throw "You do not have enough cash.";
        }
        $inventory.lemons = $inventory.lemons + ($newlemons * $lemons.count);
        $inventory.cash = $inventory.cash - $cost;
        "  Purchased $newlemons bag(s) of lemons for $($cost.ToString("C2"))";
        "  $($inventory.lemons) lemon inventory, " + `
          "$($inventory.cash.ToString("C2")) cash remaining";
      }
      else
      {
        "  No additional lemons were purchased";
      }
    }
    catch
    {
      Write-Host -ForegroundColor Yellow -Object "  $_";
      $newlemons = -1;
    }
  }

  # Read the number of sugar bags to purchase
  [int]$newsugar = -1;
  while ($newsugar -lt 0)
  {
    try
    {
      [int]$newsugar = Read-Host -Prompt "How many bags of sugar to buy?";
      if ($newsugar -gt 0)
      {
        $cost = $newsugar * $sugar.cost;
        if ($cost -gt $inventory.cash)
        { 
          throw "You do not have enough cash.";
        }
        $inventory.sugar = $inventory.sugar + ($newsugar * $sugar.count);
        $inventory.cash = $inventory.cash - $cost;
        "  Purchased $newsugar bag(s) of sugar for $($cost.ToString("C2"))";
        "  $($inventory.sugar) sugar inventory, " + `
          "$($inventory.cash.ToString("C2")) cash remaining";
      }
      else
      {
        "  No additional sugar was purchased";
      }
    }
    catch
    {
      Write-Host -ForegroundColor Yellow -Object "  $_";
      $newsugar = -1;
    }
  }

  # Read the actual price
  [decimal]$price = 0.00;
  while ($price -le 0.00)
  {
    try
    {
      $raw = Read-Host -Prompt "How much should the lemonade cost?";
      [decimal]$price = ($raw -replace "[^0-9.-]", ""); # strip non-numbers
      if ($price -le 0.00)
      {
        throw "The price must be greater than zero.";
      }
    }
    catch
    {
      Write-Host -ForegroundColor Yellow -Object "  $_";
      $price = 0.00;
    }
  }
  "  Setting the price at $($price.ToString("C2"))";

  # Calculate the weekly sales based on price and lowest inventory level
  # (higher markup price = fewer sales, limited by the inventory on-hand)
  $sales  = (Get-SalesAmount -potential $potential `
                             -unit $unit `
                             -price $price);
  $set    = @($potential, $sales, `
              $inventory.cups, $inventory.lemons, $inventory.sugar);
  $sales  = ($set | Sort-Object -Descending | Select -Last 1); # lowest value
  $margin = $price - $unit;
  $gross  = $sales * $price;
  $net    = $sales * $margin;

  # Add a new row to the summary
  $weeks.summary += @{ sales = $sales; price = $price; };

  # Simulate a sense of time passing (each dot represents a sale)
  if (-not $nowait.IsPresent)
  {
    Write-Host -Object "`nNow Serving:";
    for ($i = 0; $i -lt $sales; $i++)
    {
      Write-Host -NoNewline -Object ". ";
      Start-Sleep -Milliseconds (Get-Random -Minimum 250 -Maximum 1500);
    }
    Write-Host;
  }

  # Update the inventory levels to reflect consumption
  $inventory.cups   = $inventory.cups   - $sales;
  $inventory.lemons = $inventory.lemons - $sales;
  $inventory.sugar  = $inventory.sugar  - $sales;
  $inventory.cash   = $inventory.cash   + $gross;
  $gainloss         = $inventory.cash   - $inventory.start;

  # Display the calculated sales information
  Clear-Host;
  "`nSales Results Week #$($weeks.current) of $($weeks.total)";
  "  Unit Cost (per serving):  $($unit.ToString("C2"))";
  "  Actual Price:             $($price.ToString("C2"))";
  "  Profit Margin:            $($margin.ToString("C2"))";
  "  Actual Sales:             $sales x $($price.ToString("C2"))";
  "  Gross Profit:             $($gross.ToString("C2"))";
  "  Net Profit:               $($net.ToString("C2"))";
  "  Current Cash:             $($inventory.cash.ToString("C2"))";
  "  Total Gain/Loss:          $($gainloss.ToString("C2"))";

  # Display the updated inventory levels
  "`nRemaining Inventory";
  "  Cups:                     $($inventory.cups)";
  "  Lemons:                   $($inventory.lemons)";
  "  Sugar:                    $($inventory.sugar)";

  # Display the weekly sales summary
  $padWeek = $weeks.total.ToString().Length;
  $padSale = $weeks.sales.ToString().Length;
  $total   = 0;
  "`nWeekly Sales Summary";
  for ($i = 0; $i -lt $weeks.summary.Count; $i++)
  {
    "  Week $(($i + 1).ToString().PadLeft($padWeek)):  " + `
      "$($weeks.summary[$i]["sales"].ToString().PadLeft($padSale)) sold x " + `
      "$(($weeks.summary[$i]["price"]).ToString("C2")) ea.";
    $total = $total + $weeks.summary[$i]["sales"];
  }

  # Loop through a range of prices to find the highest net profit
  $maxsales = 0;
  $maxprice = 0.00;
  $maxgross = 0.00;
  $maxnet   = 0.00;
  $minnet   = $net;
  for ($price = 0.25; $price -le 25.00; $price += 0.25)
  {
    $sales  = (Get-SalesAmount -potential $potential `
                               -unit $unit `
                               -price $price);
    $margin = $price - $unit;
    $gross  = $sales * $price;
    $net    = $sales * $margin;
    if (($sales -gt 0) -and `
        ($sales -le $potential) -and `
        ($unit  -le $price))
    {
      if ($net -gt $maxnet)
      {
        $maxsales = $sales;
        $maxprice = $price;
        $maxgross = $gross;
        $maxnet   = $net;
      }
    }
  }
  if ($maxnet -gt $minnet)
  {
    "`nYour sales could have been:";
    "  $maxsales sold x " + `
      "$($maxprice.ToString("C2")) ea. = " + `
      "$($maxgross.ToString("C2")) for a net profit of " + `
      "$($maxnet.ToString("C2"))";
    if ($inventory.cups   -le 0) { "  You ran out of cups.";   }
    if ($inventory.lemons -le 0) { "  You ran out of lemons."; }
    if ($inventory.sugar  -le 0) { "  You ran out of sugar.";  }
  }
  else
  {
    "`nCongratulations -- your sales were perfect!";
  }

  # Increment the score counters
  $score.value = $score.value + $minnet;
  $score.total = $score.total + $maxnet;
  
  # Increment the week number
  if ($weeks.current -eq $weeks.total)
  {
    $success = [Math]::round(($score.value / $score.total) * 100);
    "`nYou've made $($score.value.ToString("C2")) " + `
      "out of a possible $($score.total.ToString("C2")) " + `
      "for a score of $success%";
    "You've sold $total total cups -- see you again next time!";
  }
  $weeks.current++;
  Read-Host -Prompt "`nPress ENTER to Continue";

}