<#

.SYNOPSIS
Gets the best sales result for the lemonade stand.

.DESCRIPTION
Gets the best sales result given the potential sales and unit cost.
Used for testing the lemonade stand sales calculations.

Currency units are selected based on the current computer locale.

Please consider giving to cancer research.

.PARAMETER potential
The potential number of sales.

.PARAMETER unit
The item cost per unit (numeric without a currency symbol).

.INPUTS
None.

.OUTPUTS
A range of calculated sales and prices, as well as the best result.

.EXAMPLE 
.\Get-BestSalesResult.ps1 -potential 99 -unit 1.05
Gets the best sales result for the potential sales and unit cost.

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
01.00 2023-Jan-22 Scott S. Initial release.

.LINK
https://en.wikipedia.org/wiki/Lemonade_Stand

.LINK
https://braintumor.org/

.LINK
https://www.cancer.org/

#>

# Accept the command line parameters
param
(

    # Potential sales
    [int]$potential = 0

    # Unit cost
  , [float]$unit = 0.00

)

# Display the header text
Clear-Host;
"Potential Sales:  $potential";
"Unit Cost:        $($unit.ToString("C2"))";

# Define the maximum values
$maxsales = 0;
$maxprice = 0.00;
$maxgross = 0.00;
$maxnet   = 0.00;

# Loop through a range of prices
"`nSales at Prices";
for ($price = 0.25; $price -le 25.00; $price += 0.25)
{

  # Calculate the sales values
  #$sales  = [Math]::Floor($potential * ($unit / $price));
  $sales  = [Math]::Floor($potential * ($unit / [Math]::Pow($price, 1.5)));
  $margin = $price - $unit;
  $gross  = $sales * $price;
  $net    = $sales * $margin;

  # Skip invalid sales and losses
  if (($sales -gt 0) -and
      ($sales -le $potential) -and
      ($unit  -le $price))
  {

    # Save the maximum net profit values
    if ($net -gt $maxnet)
    {
      $maxsales = $sales;
      $maxprice = $price;
      $maxgross = $gross;
      $maxnet   = $net;
    }

    # Display the current calculated value
    "  $($sales.ToString().PadLeft(2)) sold x " + `
      "$($price.ToString("C2").PadLeft(6)) ea. = " + `
      "$($gross.ToString("C2").PadLeft(8)) for a net profit of " + `
      "$($net.ToString("C2").PadLeft(8))";

  }

}

# Display the best calculated value
"`nThe best sales result would be:";
"  $($maxsales.ToString().PadLeft(2)) sold x " + `
  "$($maxprice.ToString("C2").PadLeft(6)) ea. = " + `
  "$($maxgross.ToString("C2").PadLeft(8)) for a net profit of " + `
  "$($maxnet.ToString("C2").PadLeft(8))";
