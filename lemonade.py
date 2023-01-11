#!/usr/bin/env python3
"""Lemonade

To start the module from the REPL, import using:
    >>> from lemonade import start_lemonade
    >>> help(start_lemonade)
    >>> start_lemonade()
    
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
When True, displays the temperature as Celsius.

.PARAMETER nowait
When True, skips the "now serving" wait loop.

.INPUTS
None.

.OUTPUTS
A whole lot of fun.

.EXAMPLE 
start_lemonade()
Starts a new lemonade stand.

.EXAMPLE 
start_lemonade(celsius=True)
Starts a new lemonade stand, using Celsius as the temperature scale.

.EXAMPLE 
start_lemonade(nowait=True)
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
"""

from collections import OrderedDict
from os import system, name           # operating system specific
from random import randrange, uniform # random numbers
from types import SimpleNamespace     # namespaces

import locale # culture specific locale
import math   # math functions
import re     # regular expressions
import time   # time functions

# Set all of the locale category elements as default
# ex. print(locale.currency(12345.67, grouping=True))
locale.setlocale(locale.LC_ALL, '')

# Define the ASCII art (original image by Scott S.)
# (escapes backslashes and double-quotes)
ascii = """
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
   !!  \\..../     !!
   !!  (::::)O    !!
=======================
 \\___________________/
  | | | | | | | | | |
  | | | | | | | | | |
  | | | | | | | | | |
  | | | | | | | | | |
 v| | | | | | | | | |v
'\"'\"'\"'\"'\"'\"'\"'\"'\"'\"'\"'
"""


def clear():
    """Clears the screen, works across all platforms.
    """
    if (name == 'nt'):
        _ = system('cls')   # Microsoft Windows
    else:
        _ = system('clear') # All others
        
        
def start_lemonade(celsius=False, nowait=False):
    """Starts a new lemonade stand.
    Parameters
    celsius : Use Celsius as the temperature scale
    nowait  : Skip the "now serving" wait loop
    """
    
    # Get the ASCII art information
    lines = ascii.splitlines()
    del lines[0]                       # Delete the initial blank line
    width = len(lines[len(lines) - 1]) # Longest line of the ASCII image

    # Define the temperature unit symbols
    fahrenheit_unit = "ºF"
    celsius_unit    = "ºC"

    # Inventory data (contains the item levels)
    inventoryd = {
         'cups'   : 0,
         'lemons' : 0,
         'sugar'  : 0,
         'cash'   : 30.00,
         'start'  : 0.00
    }
    inventory = SimpleNamespace(**inventoryd)
    inventory.start = inventory.cash

    # Cups data (includes a calculated cost per unit)
    cupsd = {
        'cost'  : 2.50, # current price
        'count' : 25,   # servings per box
        'min'   : 0.99, # minimum price
        'unit'  : 0.00  # unit price
    }
    cups = SimpleNamespace(**cupsd)
    cups.unit = round(cups.cost / cups.count, 2)

    # Lemons data (includes a calculated cost per unit)
    lemonsd = {
        'cost'  : 4.00, # current price
        'count' : 8,    # servings per bag
        'min'   : 2.00, # minimum price
        'unit'  : 0.00  # unit price
    }
    lemons = SimpleNamespace(**lemonsd)
    lemons.unit = round(lemons.cost / lemons.count, 2)

    # Sugar data (includes a calculated cost per unit)
    sugard = {
        'cost'  : 3.00, # current price
        'count' : 15,   # servings per bag
        'min'   : 1.50, # minimum price
        'unit'  : 0.00  # unit price
    }
    sugar = SimpleNamespace(**sugard)
    sugar.unit  = round(sugar.cost / sugar.count, 2)

    # Weeks data (measures the session duration)
    weeksd = {
        'current' : 1,   # start with the 1st week
        'total'   : 12,  # span the 12 weeks of Summer
        'sales'   : 99,  # 99 maximum sales per week
        'summary' : []   # empty array
    }
    weeks = SimpleNamespace(**weeksd)

    # Forecast data (includes percentage values and display names)
    forecastd = OrderedDict()
    forecastd['sunny']  = [1.00, "Sunny"]
    forecastd['partly'] = [0.90, "Partly Sunny"]
    forecastd['cloudy'] = [0.70, "Mostly Cloudy"]
    forecastd['rainy']  = [0.40, "Rainy"]
    forecastd['stormy'] = [0.10, "Stormy"]

    # Temperature data (uses Fahrenheit as the percentage values)
    temperatured = {
        'min'      : 69,
        'max'      : 100,
        'units'    : fahrenheit_unit,
        'forecast' : None,
        'value'    : None
    }
    temperature = SimpleNamespace(**temperatured)
    
    # Check for Celsius
    if (celsius):
      temperature.units = celsius_unit

    # Start the main loop
    while (weeks.current <= weeks.total):

        # Create a new display buffer for the text messages
        clear()
        buffer = [None] * len(lines)
 
        # Display the current week number
        buffer[0] = ""
        buffer[1] = "Lemonade Stand Week #" + str(weeks.current)

        # Generate a random weather forecast and temperature
        temperature.forecast = randrange(0, len(forecastd))
        temperature.value = randrange(temperature.min, temperature.max)
        formatted = str(temperature.value)
        if (temperature.units == celsius_unit):
            formatted = str(round(((temperature.value - 32) * (5/9))))
        buffer[2] = ""
        buffer[3] = "Weather Forecast:  " + \
                    formatted + temperature.units + " " + \
                    forecastd[list(forecastd)[temperature.forecast]][1]

        # Calculate the potential sales as a percentage of the maximum value
        # (lower temperature = fewer sales, severe weather = fewer sales)
        forecast  = forecastd[list(forecastd)[temperature.forecast]][0]
        potential = math.floor(weeks.sales * \
                               (temperature.value / 100) * \
                               forecast)
        buffer[4] = "Estimated Sales:   " + str(potential) + " cups"

        # Update the cups cost
        cups.cost = cups.cost + round(uniform(-1.50, 1.50), 2)
        if (cups.cost < cups.min):
            cups.cost = cups.min
        cups.unit = round(cups.cost / cups.count, 2)

        # Update the lemons cost
        lemons.cost = lemons.cost + round(uniform(-1.50, 1.50), 2)
        if (lemons.cost < lemons.min):
            lemons.cost = lemons.min
        lemons.unit = round(lemons.cost / lemons.count, 2)

        # Update the sugar cost
        sugar.cost = sugar.cost + round(uniform(-1.50, 1.50), 2)
        if (sugar.cost < sugar.min):
            sugar.cost = sugar.min
        sugar.unit = round(sugar.cost / sugar.count, 2)

        # Display the updated item prices
        buffer[5] = ""
        buffer[6] = "Grocery Store Prices"
        buffer[7] = "  Cups:    " + \
                    locale.currency(cups.cost, grouping=True) + \
                    " box of " + str(cups.count)
        buffer[8] = "  Lemons:  " + \
                    locale.currency(lemons.cost, grouping=True) + \
                    " bag of " + str(lemons.count)
        buffer[9] = "  Sugar:   " + \
                    locale.currency(sugar.cost, grouping=True) + \
                    " bag for " + str(sugar.count) + " cups"

        # Calculate the unit cost
        unit = cups.unit + lemons.unit + sugar.unit
        buffer[10] = "           " + \
                     locale.currency(unit, grouping=True) + \
                     " cost per serving"

        # Display the current inventory
        buffer[11] = ""
        buffer[12] = "My Current Inventory"
        buffer[13] = "  Cups:    " + str(inventory.cups)
        buffer[14] = "  Lemons:  " + str(inventory.lemons)
        buffer[15] = "  Sugar:   " + str(inventory.sugar)

        # Display the current cash
        gainloss   = inventory.cash - inventory.start
        buffer[16] = ""
        buffer[17] = "My Cash:    " + \
                     locale.currency(inventory.cash, grouping=True)
        buffer[18] = "Gain/Loss:  " + \
                     locale.currency(gainloss, grouping=True)
        buffer[19] = ""
        
        # Output the display buffer
        # (combines the ASCII art with the text messages)
        for i in range(len(buffer)):
            print(lines[i].ljust(width) + "  " + buffer[i])

        # Read the number of cup boxes to purchase
        newcups = -1
        while (newcups < 0):
            try:
                newcups = int(input("How many boxes of cups to buy? "))
                if (newcups > 0):
                    cost = newcups * cups.cost
                    if (cost > inventory.cash):
                        raise Exception("You do not have enough cash.")
                    inventory.cups += (newcups * cups.count)
                    inventory.cash -= cost
                    print("  Purchased " + str(newcups) + \
                          " box(es) of cups for " + \
                          locale.currency(cost, grouping=True))
                    print("  " + \
                          locale.currency(inventory.cash, grouping=True) + \
                          " remaining")
                else:
                    print("  No additional cups were purchased")
            except Exception as e:
                print("  " + str(e))
                newcups = -1

        # Read the number of lemon bags to purchase
        newlemons = -1
        while (newlemons < 0):
            try:
                newlemons = int(input("How many bags of lemons to buy? "))
                if (newlemons > 0):
                    cost = newlemons * lemons.cost
                    if (cost > inventory.cash):
                        raise Exception("You do not have enough cash.")
                    inventory.lemons += (newlemons * lemons.count)
                    inventory.cash   -= cost
                    print("  Purchased " + str(newlemons) + \
                          " bag(s) of lemons for " + \
                          locale.currency(cost, grouping=True))
                    print("  " + \
                          locale.currency(inventory.cash, grouping=True) + \
                          " remaining")
                else:
                    print("  No additional lemons were purchased")
            except Exception as e:
                print("  " + str(e))
                newlemons = -1

        # Read the number of sugar bags to purchase
        newsugar = -1
        while (newsugar < 0):
            try:
                newsugar = int(input("How many bags of sugar to buy? "))
                if (newsugar > 0):
                    cost = newsugar * sugar.cost
                    if (cost > inventory.cash):
                        raise Exception("You do not have enough cash.")
                    inventory.sugar += (newsugar * sugar.count)
                    inventory.cash  -= cost
                    print("  Purchased " + str(newsugar) + \
                          " bag(s) of sugar for " + \
                          locale.currency(cost, grouping=True))
                    print("  " + \
                          locale.currency(inventory.cash, grouping=True) + \
                          " remaining")
                else:
                    print("  No additional sugar was purchased")
            except Exception as e:
                print("  " + str(e))
                newsugar = -1

        # Read the actual price
        price = 0.00
        while (price <= 0):
            try:
                raw   = input("How much should the lemonade cost? ")
                price = float(re.sub("[^0-9.]", "", raw))
                if (price <= 0):
                    raise Exception("The price must be greater than zero.")
            except Exception as e:
                print("  " + str(e))
                price = 0.00
        print("  Setting the price at " + \
              locale.currency(price, grouping=True))

        # Calculate the weekly sales based on price and lowest inventory level
        # (higher markup price = fewer sales, limited by the inventory on-hand)
        sales = math.floor(potential * (unit / price))
        sales = min(potential, sales, \
                    inventory.cups, inventory.lemons, \
                    inventory.sugar) # "min" returns lowest value
        margin = price - unit
        gross  = sales * price
        net    = sales * margin
        
        # Add a new row to the summary
        weeks.summary.append({ 'sales' : sales, 'price' : price })

        # Simulate a sense of time passing (each dot represents a sale)
        if (not nowait):
            print("\nNow Serving:")
            for i in range(sales):
                print(". ", end="", flush=True)
                time.sleep(randrange(500, 2000) / 1000)
            print()
                
        # Update the inventory levels to reflect consumption
        inventory.cups   = inventory.cups   - sales
        inventory.lemons = inventory.lemons - sales
        inventory.sugar  = inventory.sugar  - sales
        inventory.cash   = inventory.cash   + gross
        gainloss         = inventory.cash   - inventory.start
  
        # Display the calculated sales information
        clear()
        print("\nSales Results Week #" + \
              str(weeks.current) + " of " + str(weeks.total))
        print("  Unit Cost (per serving):  " + \
              locale.currency(unit, grouping=True))
        print("  Actual Price:             " + \
              locale.currency(price, grouping=True))
        print("  Profit Margin:            " + \
              locale.currency(margin, grouping=True))
        print("  Actual Sales:             " + \
              str(sales) + " x " + locale.currency(price, grouping=True))
        print("  Gross Profit:             " + \
              locale.currency(gross, grouping=True))
        print("  Net Profit:               " + \
              locale.currency(net, grouping=True))
        print("  Current Cash:             " + \
              locale.currency(inventory.cash, grouping=True))
        print("  Total Gain/Loss:          " + \
              locale.currency(gainloss, grouping=True))
        
        # Display the updated inventory levels
        print("\nRemaining Inventory")
        print("  Cups:                     " + str(inventory.cups))
        print("  Lemons:                   " + str(inventory.lemons))
        print("  Sugar:                    " + str(inventory.sugar))
  
        # Display the weekly sales summary
        pad_week = len(str(weeks.total))
        pad_sale = len(str(weeks.sales))
        total    = 0
        print("\nWeekly Sales Summary")
        for i in range(len(weeks.summary)):
            print("  Week " + str(i + 1).rjust(pad_week) + ":  " + \
                  str(weeks.summary[i]['sales']).rjust(pad_sale) + \
                  " sold x " + \
                  locale.currency(weeks.summary[i]['price'], grouping=True) + \
                  " ea.")
            total = total + weeks.summary[i]['sales']

        # Increment the week number
        if (weeks.current == weeks.total):
            print("  " + str(total) + " sold -- see you again next time!")
        weeks.current = weeks.current + 1
        input("\nPress ENTER to Continue")


# Start the module interactively
if __name__ == "__main__":
    start_lemonade()
