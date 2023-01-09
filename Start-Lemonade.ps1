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

.PARAMETER celsius
When present, displays the temperature as Celsius.

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
.\Start-Lemonade.ps1 -celsius
Starts a new lemonade stand, using Celsius as the temperature scale.

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

If you enjoy this software, please do something kind for free.

History:
01.00 2023-Jan-07 Scott S. Initial release.

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

    # Use Celsius as the temperature scale
    [switch]$celsius

    # Skip the "now serving" wait loop
  , [switch]$nowait

)

# Define the temperature unit symbols
$FahrenheitUnit = "ºF";
$CelsiusUnit    = "ºC";

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

# Forecast data (includes percentage values and display names)
$forecast = [ordered]@{};
$forecast.sunny  = @(1.00, "Sunny");
$forecast.partly = @(0.90, "Partly Sunny");
$forecast.cloudy = @(0.70, "Mostly Cloudy");
$forecast.rainy  = @(0.40, "Rainy");
$forecast.stormy = @(0.10, "Stormy");

# Temperature data (uses Fahrenheit as the percentage values)
$temperature = @{};
$temperature.min      = 69;
$temperature.max      = 100;
$temperature.units    = $FahrenheitUnit;
$temperature.forecast = $null;
$temperature.value    = $null;

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
  $buffer[1] = "Lemonade Stand Week #$($weeks.current)";

  # Generate a random weather forecast and temperature
  $temperature.forecast = `
    (Get-Random -Minimum 0 -Maximum ($forecast.Keys.Count));
  $temperature.value = `
    (Get-Random -Minimum $temperature.min -Maximum $temperature.max);
  $formatted = $temperature.value.ToString("N0");
  if ($temperature.units -eq $CelsiusUnit)
  {
    $formatted = (($temperature.value -32) * (5/9)).ToString("N0");
  }
  $buffer[2] = "";
  $buffer[3] = "Weather Forecast:  " + `
               "$($formatted)$($temperature.units) " + `
               "$($forecast[$temperature.forecast][1])";

  # Calculate the potential sales as a percentage of the maximum value
  # (lower temperature = fewer sales, severe weather = fewer sales)
  $potential = [Math]::Floor($weeks.sales * `
                             ($temperature.value / 100) * `
                             $($forecast[$temperature.forecast][0]));
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
        "  $($inventory.cash.ToString("C2")) remaining";
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
        "  $($inventory.cash.ToString("C2")) remaining";
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
        "  $($inventory.cash.ToString("C2")) remaining";
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
  while ($price -le 0)
  {
    try
    {
      $raw = Read-Host -Prompt "How much should the lemonade cost?";
      [decimal]$price = ($raw -replace "[^0-9.]", ""); # strip non-numbers
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
  $sales = [Math]::Floor($potential * ($unit / $price));
  $set   = @($potential, $sales, `
             $inventory.cups, $inventory.lemons, $inventory.sugar);
  $sales = ($set | Sort-Object -Descending | Select -Last 1); # lowest value
  $margin           = $price - $unit;
  $gross            = $sales * $price;
  $net              = $sales * $margin;

  # Add a new row to the summary
  $weeks.summary += @{ sales = $sales; price = $price; };

  # Simulate a sense of time passing (each dot represents a sale)
  if (-not $nowait.IsPresent)
  {
    Write-Host -Object "`nNow Serving:";
    for ($i = 0; $i -lt $sales; $i++)
    {
      Write-Host -NoNewline -Object ". ";
      Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 2000);
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
    ("  Week $(($i + 1).ToString().PadLeft($padWeek)):  " + `
     "$($weeks.summary[$i]["sales"].ToString().PadLeft($padSale)) sold x " + `
     "$(($weeks.summary[$i]["price"]).ToString("C2")) ea.");
     $total = $total + $weeks.summary[$i]["sales"];
  }

  # Increment the week number
  if ($weeks.current -eq $weeks.total)
  {
    "  Total $total sold -- see you again next time!";
  }
  $weeks.current++;
  Read-Host -Prompt "`nPress ENTER to Continue";

}